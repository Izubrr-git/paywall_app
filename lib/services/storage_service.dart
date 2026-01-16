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
  bool hasSubscription() {
    final hasSubscriptionFlag = _prefs.getBool(_subscriptionKey) ?? false;

    if (!hasSubscriptionFlag) {
      return false;
    }

    // Проверяем дату истечения
    final expiryTimestamp = _prefs.getInt(_subscriptionExpiryKey);
    if (expiryTimestamp == null) {
      // Если нет даты истечения, подписка недействительна
      return false;
    }

    final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
    final now = DateTime.now();

    // Проверяем, не истекла ли подписка
    if (now.isAfter(expiryDate)) {
      // Подписка истекла - автоматически деактивируем
      _prefs.setBool(_subscriptionKey, false);
      return false;
    }

    return true;
  }

  /// Получает дату окончания подписки
  DateTime? getSubscriptionExpiryDate() {
    final expiryTimestamp = _prefs.getInt(_subscriptionExpiryKey);
    if (expiryTimestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
  }

  /// Устанавливает подписку с датой окончания
  /// [expiryDate] - дата окончания подписки
  Future<void> setSubscriptionWithExpiry(DateTime expiryDate) async {
    await _prefs.setBool(_subscriptionKey, true);
    await _prefs.setInt(_subscriptionExpiryKey, expiryDate.millisecondsSinceEpoch);
  }

  /// Отменяет подписку
  Future<void> cancelSubscription() async {
    await _prefs.setBool(_subscriptionKey, false);
    await _prefs.remove(_subscriptionExpiryKey);
  }
}