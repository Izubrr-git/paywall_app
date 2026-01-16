import 'package:flutter_riverpod/legacy.dart';
import '../services/storage_service.dart';
import 'subscription_provider.dart';

/// Провайдер для проверки статуса онбординга
final onboardingStatusProvider = StateNotifierProvider<OnboardingStatusNotifier, bool>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return OnboardingStatusNotifier(storage);
});

class OnboardingStatusNotifier extends StateNotifier<bool> {
  final StorageService _storage;

  OnboardingStatusNotifier(this._storage) : super(_storage.isOnboardingCompleted());

  /// Отметить онбординг как завершенный
  Future<void> completeOnboarding() async {
    await _storage.setOnboardingCompleted();
    state = true;
  }
}