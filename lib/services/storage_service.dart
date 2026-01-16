import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для работы с локальным хранилищем
class StorageService {
  static const String _onboardingKey = 'onboarding_completed';
  static const String _subscriptionKey = 'has_subscription';

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

  /// Проверяет, есть ли активная подписка
  bool hasSubscription() {
    return _prefs.getBool(_subscriptionKey) ?? false;
  }

  /// Устанавливает статус подписки
  Future<void> setSubscription(bool value) async {
    await _prefs.setBool(_subscriptionKey, value);
  }
}