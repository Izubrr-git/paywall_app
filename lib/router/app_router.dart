import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/onboarding_provider.dart';
import '../providers/subscription_provider.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/paywall/paywall_screen.dart';
import '../screens/home/home_screen.dart';

/// Провайдер GoRouter с логикой редиректов
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/onboarding',
    redirect: (BuildContext context, GoRouterState state) {
      final hasSubscription = ref.read(subscriptionStatusProvider);
      final onboardingCompleted = ref.read(onboardingStatusProvider);
      final currentPath = state.uri.path;

      // Если есть подписка - всегда на /home
      if (hasSubscription) {
        if (currentPath != '/home') {
          return '/home';
        }
        return null;
      }

      // Если нет подписки, но онбординг завершен - на /paywall
      if (onboardingCompleted) {
        if (currentPath == '/onboarding') {
          return '/paywall';
        }
        if (currentPath == '/home') {
          return '/paywall';
        }
        return null;
      }

      // Если онбординг не завершен - на /onboarding
      if (!onboardingCompleted) {
        if (currentPath != '/onboarding') {
          return '/onboarding';
        }
        return null;
      }

      return null;
    },
    refreshListenable: _RouterRefreshNotifier(ref),
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/paywall',
        name: 'paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
});

/// Notifier для обновления роутера при изменении состояния
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    // Слушаем изменения подписки
    ref.listen(subscriptionStatusProvider, (_, __) {
      notifyListeners();
    });

    // Слушаем изменения онбординга
    ref.listen(onboardingStatusProvider, (_, __) {
      notifyListeners();
    });
  }
}