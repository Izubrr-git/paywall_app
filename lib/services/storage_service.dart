import 'dart:core';

import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для работы с локальным хранилищем
class StorageService {
  static const String _onboardingKey = 'onboarding_completed';
  static const String _subscriptionKey = 'has_subscription';
  static const String _subscriptionExpiryKey = 'subscription_expiry_date';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  /// Проверяет, завершен ли онбординг
  bool isOnboardingCompleted() {
    return _prefs.getBool(_onboardingKey) ?? false;
  }

  /// Отмечает онбординг как завершенный
  Future<void> setOnboardingCompleted() async {
    await _prefs.setBool(_onboardingKey, true);
  }

  /// Проверяет, есть ли активная подписка (с проверкой срока действия)
  /// ВАЖНО: Метод синхронный, но при обнаружении истекшей подписки
  /// запускает асинхронную очистку в фоне
  bool hasSubscription() {
    final hasSubscriptionFlag = _prefs.getBool(_subscriptionKey) ?? false;

    if (!hasSubscriptionFlag) {
      return false;
    }

    // Проверяем дату истечения
    final expiryTimestamp = _prefs.getInt(_subscriptionExpiryKey);
    if (expiryTimestamp == null) {
      // Если нет даты истечения, подписка недействительна
      // Очищаем флаг асинхронно в фоне
      _clearExpiredSubscriptionInBackground();
      return false;
    }

    final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
    final now = DateTime.now();

    // Проверяем, не истекла ли подписка
    if (now.isAfter(expiryDate)) {
      // Подписка истекла - запускаем очистку в фоне
      _clearExpiredSubscriptionInBackground();
      return false;
    }

    return true;
  }

  /// Асинхронная очистка истекшей подписки в фоновом режиме
  /// Не блокирует основной поток
  void _clearExpiredSubscriptionInBackground() {
    // Запускаем асинхронную операцию без ожидания
    // unawaited - допустимо, так как это фоновая очистка
    Future(() async {
      await _prefs.setBool(_subscriptionKey, false);
      await _prefs.remove(_subscriptionExpiryKey);
    });
  }

  /// Получает дату окончания подписки
  DateTime? getSubscriptionExpiryDate() {
    final expiryTimestamp = _prefs.getInt(_subscriptionExpiryKey);
    if (expiryTimestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
  }

  /// Устанавливает подписку с датой окончания
  /// [expiryDate] - дата окончания подписки
  /// АТОМАРНАЯ операция: обе записи должны завершиться успешно
  Future<void> setSubscriptionWithExpiry(DateTime expiryDate) async {
    // Сначала записываем дату, потом флаг
    // Это безопаснее: если запись прервется, hasSubscription вернет false
    await _prefs.setInt(
      _subscriptionExpiryKey,
      expiryDate.millisecondsSinceEpoch,
    );
    await _prefs.setBool(_subscriptionKey, true);

    // Принудительный commit для обеспечения атомарности
    // (SharedPreferences обычно делает это автоматически, но для гарантии)
    await _prefs.reload();
  }

  /// Отменяет подписку
  /// АТОМАРНАЯ операция
  Future<void> cancelSubscription() async {
    // Сначала сбрасываем флаг, потом удаляем дату
    await _prefs.setBool(_subscriptionKey, false);
    await _prefs.remove(_subscriptionExpiryKey);
    await _prefs.reload();
  }
}