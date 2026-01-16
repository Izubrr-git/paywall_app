import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_service.dart';

/// Провайдер для SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences должен быть переопределен в main.dart');
});

/// Провайдер для StorageService
final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StorageService(prefs);
});

/// Провайдер для состояния подписки
/// Автоматически загружает состояние из SharedPreferences при старте
final subscriptionStatusProvider = StateNotifierProvider<SubscriptionStatusNotifier, bool>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SubscriptionStatusNotifier(storage);
});

/// Типы подписки
enum SubscriptionType {
  monthly,  // Месячная подписка
  yearly,   // Годовая подписка
}

/// Notifier для управления состоянием подписки
class SubscriptionStatusNotifier extends StateNotifier<bool> {
  final StorageService _storage;

  /// Конструктор загружает текущее состояние подписки из SharedPreferences
  /// Автоматически проверяет срок действия при загрузке
  SubscriptionStatusNotifier(this._storage) : super(_storage.hasSubscription());

  /// Геттер для проверки статуса подписки
  bool get isSubscribed => state;

  /// Получить дату окончания подписки
  DateTime? get expiryDate => _storage.getSubscriptionExpiryDate();

  /// Метод покупки/активации подписки с указанием типа
  /// [type] - тип подписки (месяц или год)
  /// Сохраняет подписку с соответствующей датой истечения
  Future<void> purchaseSubscription(SubscriptionType type) async {
    final now = DateTime.now();
    final DateTime expiryDate;

    // Вычисляем дату окончания в зависимости от типа подписки
    switch (type) {
      case SubscriptionType.monthly:
        expiryDate = DateTime(now.year, now.month + 1, now.day);
        break;
      case SubscriptionType.yearly:
        expiryDate = DateTime(now.year + 1, now.month, now.day);
        break;
    }

    await _storage.setSubscriptionWithExpiry(expiryDate);
    state = true;
  }

  /// Метод отмены подписки (для тестирования или реальной отмены)
  /// Удаляет подписку и дату истечения из хранилища
  Future<void> cancelSubscription() async {
    await _storage.cancelSubscription();
    state = false;
  }

  /// Принудительная проверка актуальности подписки
  /// Полезно вызывать при возобновлении приложения
  void checkSubscriptionValidity() {
    state = _storage.hasSubscription();
  }
}