import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/subscription_provider.dart';

enum SubscriptionPlan { monthly, yearly }

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  SubscriptionPlan _selectedPlan = SubscriptionPlan.yearly;
  bool _isPurchasing = false;

  // Цены за подписку
  static const double monthlyPrice = 999.0;
  static const double yearlyPrice = 7990.0;
  static const double yearlyMonthlyEquivalent = yearlyPrice / 12;
  static const double savingsPercent =
      ((monthlyPrice * 12 - yearlyPrice) / (monthlyPrice * 12)) * 100;

  Future<void> _handlePurchase() async {
    setState(() {
      _isPurchasing = true;
    });

    // Эмуляция процесса покупки (задержка 2 секунды)
    await Future.delayed(const Duration(seconds: 2));

    // Определяем тип подписки в зависимости от выбранного плана
    final subscriptionType = _selectedPlan == SubscriptionPlan.monthly
        ? SubscriptionType.monthly
        : SubscriptionType.yearly;

    // Вызываем метод покупки подписки с указанием типа
    await ref
        .read(subscriptionStatusProvider.notifier)
        .purchaseSubscription(subscriptionType);

    setState(() {
      _isPurchasing = false;
    });

    // Переход на главный экран
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isPurchasing
            ? _buildPurchasingState()
            : _buildPaywallContent(),
      ),
    );
  }

  Widget _buildPurchasingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
          ),
          const SizedBox(height: 24),
          const Text(
            '🛒 Эмуляция покупки...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Обработка платежа',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaywallContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Заголовок
                  const Text(
                    'Получите полный доступ',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Выберите подходящий тариф',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Преимущества подписки
                  _buildFeatureItem(
                    icon: Icons.check_circle,
                    title: 'Весь премиум контент',
                    description: 'Статьи, видео, руководства',
                  ),
                  _buildFeatureItem(
                    icon: Icons.check_circle,
                    title: 'Без рекламы',
                    description: 'Комфортное использование',
                  ),
                  _buildFeatureItem(
                    icon: Icons.check_circle,
                    title: 'Ранний доступ',
                    description: 'К новым материалам',
                  ),

                  const SizedBox(height: 32),

                  // Варианты подписки
                  _buildSubscriptionCard(
                    plan: SubscriptionPlan.yearly,
                    title: 'Годовая подписка',
                    price: yearlyPrice,
                    pricePerMonth: yearlyMonthlyEquivalent,
                    badge: 'Выгода ${savingsPercent.toStringAsFixed(0)}%',
                    isPopular: true,
                  ),
                  const SizedBox(height: 16),
                  _buildSubscriptionCard(
                    plan: SubscriptionPlan.monthly,
                    title: 'Месячная подписка',
                    price: monthlyPrice,
                    pricePerMonth: monthlyPrice,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Кнопка "Продолжить"
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _handlePurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  _selectedPlan == SubscriptionPlan.yearly
                      ? 'Продолжить за ${yearlyPrice.toStringAsFixed(0)} ₽/год'
                      : 'Продолжить за ${monthlyPrice.toStringAsFixed(0)} ₽/мес',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.green,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard({
    required SubscriptionPlan plan,
    required String title,
    required double price,
    required double pricePerMonth,
    String? badge,
    bool isPopular = false,
  }) {
    final isSelected = _selectedPlan == plan;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = plan;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.shade50 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.deepPurple
                                  : Colors.black87,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${pricePerMonth.toStringAsFixed(0)} ₽/месяц',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.deepPurple : Colors.grey,
                      width: 2,
                    ),
                    color: isSelected ? Colors.deepPurple : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Всего: ${price.toStringAsFixed(0)} ₽',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.deepPurple : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}