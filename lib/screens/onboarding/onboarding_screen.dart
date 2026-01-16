import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добро пожаловать'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Экран онбординга',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('Узнайте о возможностях приложения'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                // Отмечаем онбординг как завершенный
                await ref.read(onboardingStatusProvider.notifier).completeOnboarding();
                // Переходим на экран подписки
                if (context.mounted) {
                  context.go('/paywall');
                }
              },
              child: const Text('Далее'),
            ),
          ],
        ),
      ),
    );
  }
}