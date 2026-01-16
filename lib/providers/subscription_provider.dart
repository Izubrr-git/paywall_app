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