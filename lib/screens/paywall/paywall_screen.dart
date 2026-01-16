import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/subscription_provider.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выберите подписку'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Экран подписки',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('Получите доступ ко всем возможностям'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                // Покупаем подписку
                await ref.read(subscriptionStatusProvider.notifier).purchaseSubscription();
                // Переходим на главный экран (редирект произойдет автоматически)
                if (context.mounted) {
                  context.go('/home');
                }
              },
              child: const Text('Оформить подписку'),
            ),
          ],
        ),
      ),
    );
  }
}