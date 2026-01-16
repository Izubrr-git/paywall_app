import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_service.dart';

// ============================================================================
// Subscription Provider - Управление состоянием подписки
// ============================================================================
//
// Использование в виджетах:
//
// 1. Чтение состояния подписки:
//    ```dart
//    final isSubscribed = ref.watch(subscriptionStatusProvider);
//    ```
//
// 2. Покупка подписки:
//    ```dart
//    await ref.read(subscriptionStatusProvider.notifier).purchaseSubscription();
//    ```
//
// 3. Отмена подписки:
//    ```dart
//    await ref.read(subscriptionStatusProvider.notifier).cancelSubscription();
//    ```
//
// Состояние автоматически сохраняется в SharedPreferences и загружается при старте.
// ============================================================================

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

/// Notifier для управления состоянием подписки
class SubscriptionStatusNotifier extends StateNotifier<bool> {
  final StorageService _storage;

  /// Конструктор загружает текущее состояние подписки из SharedPreferences
  SubscriptionStatusNotifier(this._storage) : super(_storage.hasSubscription());

  /// Геттер для проверки статуса подписки
  bool get isSubscribed => state;

  /// Метод покупки/активации подписки
  /// Сохраняет true в SharedPreferences и обновляет состояние
  Future<void> purchaseSubscription() async {
    await _storage.setSubscription(true);
    state = true;
  }

  /// Метод отмены подписки (для тестирования или реальной отмены)
  /// Сохраняет false в SharedPreferences и обновляет состояние
  Future<void> cancelSubscription() async {
    await _storage.setSubscription(false);
    state = false;
  }
}