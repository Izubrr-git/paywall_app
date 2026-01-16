import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/subscription_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSubscription = ref.watch(subscriptionStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Главный экран'),
        actions: [
          // Кнопка для сброса подписки (для тестирования)
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(subscriptionStatusProvider.notifier).cancelSubscription();
            },
            tooltip: 'Отменить подписку',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Добро пожаловать!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              hasSubscription ? 'У вас есть активная подписка' : 'Подписка неактивна',
              style: TextStyle(
                fontSize: 16,
                color: hasSubscription ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 40),
            const Text('Контент для подписчиков'),
          ],
        ),
      ),
    );
  }
}