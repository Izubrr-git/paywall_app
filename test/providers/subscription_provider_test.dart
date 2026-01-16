import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paywall_app/providers/subscription_provider.dart';
import 'package:paywall_app/services/storage_service.dart';

void main() {
  late ProviderContainer container;
  late SharedPreferences prefs;

  setUp(() async {
    // Очищаем SharedPreferences перед каждым тестом
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    // Создаем контейнер провайдеров
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('SubscriptionProvider - Инициализация', () {
    test('должен загружать false из пустого хранилища', () {
      final subscriptionStatus = container.read(subscriptionStatusProvider);
      expect(subscriptionStatus, false);
    });

    test('должен загружать true из хранилища с активной подпиской', () async {
      // Устанавливаем подписку через StorageService
      final storage = StorageService(prefs);
      final futureDate = DateTime.now().add(const Duration(days: 30));
      await storage.setSubscriptionWithExpiry(futureDate);

      // Создаем новый контейнер для загрузки состояния
      final newContainer = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final subscriptionStatus = newContainer.read(subscriptionStatusProvider);
      expect(subscriptionStatus, true);

      newContainer.dispose();
    });

    test('должен загружать false для истекшей подписки', () async {
      final storage = StorageService(prefs);
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      await storage.setSubscriptionWithExpiry(pastDate);

      final newContainer = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final subscriptionStatus = newContainer.read(subscriptionStatusProvider);
      expect(subscriptionStatus, false);

      newContainer.dispose();
    });
  });

  group('SubscriptionProvider - Покупка месячной подписки', () {
    test('должен устанавливать дату истечения через 1 месяц', () async {
      final notifier = container.read(subscriptionStatusProvider.notifier);

      await notifier.purchaseSubscription(SubscriptionType.monthly);

      // Проверяем статус
      expect(container.read(subscriptionStatusProvider), true);

      // Проверяем дату истечения
      final expiryDate = notifier.expiryDate;
      expect(expiryDate, isNotNull);

      final now = DateTime.now();
      final expectedDate = DateTime(now.year, now.month + 1, now.day);

      expect(expiryDate!.year, expectedDate.year);
      expect(expiryDate.month, expectedDate.month);
      expect(expiryDate.day, expectedDate.day);
    });

    test('должен сохранять подписку в SharedPreferences', () async {
      final notifier = container.read(subscriptionStatusProvider.notifier);

      await notifier.purchaseSubscription(SubscriptionType.monthly);

      // Проверяем что данные сохранены
      expect(prefs.getBool('has_subscription'), true);
      expect(prefs.getInt('subscription_expiry_date'), isNotNull);
    });

    test('эмуляция: через месяц → автоматическая деактивация', () async {
      // Устанавливаем истекшую дату вручную через StorageService
      final storage = StorageService(prefs);
      final expiredDate = DateTime.now().subtract(const Duration(days: 1));
      await storage.setSubscriptionWithExpiry(expiredDate);

      // Проверяем валидность
      final notifier = container.read(subscriptionStatusProvider.notifier);
      notifier.checkSubscriptionValidity();

      expect(container.read(subscriptionStatusProvider), false);
    });
  });

  group('SubscriptionProvider - Покупка годовой подписки', () {
    test('должен устанавливать дату истечения через 1 год', () async {
      final notifier = container.read(subscriptionStatusProvider.notifier);

      await notifier.purchaseSubscription(SubscriptionType.yearly);

      // Проверяем статус
      expect(container.read(subscriptionStatusProvider), true);

      // Проверяем дату истечения
      final expiryDate = notifier.expiryDate;
      expect(expiryDate, isNotNull);

      final now = DateTime.now();
      final expectedDate = DateTime(now.year + 1, now.month, now.day);

      expect(expiryDate!.year, expectedDate.year);
      expect(expiryDate.month, expectedDate.month);
      expect(expiryDate.day, expectedDate.day);
    });

    test('эмуляция: через год → автоматическая деактивация', () async {
      // Устанавливаем дату истечения год назад
      final storage = StorageService(prefs);
      final expiredDate = DateTime.now().subtract(const Duration(days: 366));
      await storage.setSubscriptionWithExpiry(expiredDate);

      // Проверяем валидность
      final notifier = container.read(subscriptionStatusProvider.notifier);
      notifier.checkSubscriptionValidity();

      expect(container.read(subscriptionStatusProvider), false);
    });
  });

  group('SubscriptionProvider - Отмена подписки', () {
    test('должен деактивировать подписку', () async {
      final notifier = container.read(subscriptionStatusProvider.notifier);

      // Сначала покупаем
      await notifier.purchaseSubscription(SubscriptionType.monthly);
      expect(container.read(subscriptionStatusProvider), true);

      // Затем отменяем
      await notifier.cancelSubscription();
      expect(container.read(subscriptionStatusProvider), false);
    });

    test('должен удалять дату истечения', () async {
      final notifier = container.read(subscriptionStatusProvider.notifier);

      await notifier.purchaseSubscription(SubscriptionType.monthly);
      expect(notifier.expiryDate, isNotNull);

      await notifier.cancelSubscription();
      expect(notifier.expiryDate, isNull);
    });

    test('должен очищать данные из SharedPreferences', () async {
      final notifier = container.read(subscriptionStatusProvider.notifier);

      await notifier.purchaseSubscription(SubscriptionType.monthly);
      await notifier.cancelSubscription();

      expect(prefs.getBool('has_subscription'), false);
      expect(prefs.getInt('subscription_expiry_date'), isNull);
    });
  });

  group('SubscriptionProvider - Проверка актуальности', () {
    test('checkSubscriptionValidity должен обновлять state при истекшей подписке', () async {
      final notifier = container.read(subscriptionStatusProvider.notifier);

      // Устанавливаем активную подписку
      await notifier.purchaseSubscription(SubscriptionType.monthly);
      expect(container.read(subscriptionStatusProvider), true);

      // Вручную устанавливаем истекшую дату
      final storage = StorageService(prefs);
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      await storage.setSubscriptionWithExpiry(pastDate);

      // Проверяем актуальность (эмуляция возобновления приложения)
      notifier.checkSubscriptionValidity();

      expect(container.read(subscriptionStatusProvider), false);
    });

    test('checkSubscriptionValidity должен сохранять state для активной подписки', () async {
      final notifier = container.read(subscriptionStatusProvider.notifier);

      await notifier.purchaseSubscription(SubscriptionType.monthly);
      expect(container.read(subscriptionStatusProvider), true);

      // Проверяем актуальность
      notifier.checkSubscriptionValidity();

      expect(container.read(subscriptionStatusProvider), true);
    });
  });

  group('SubscriptionProvider - isSubscribed getter', () {
    test('должен возвращать текущее состояние подписки', () async {
      final notifier = container.read(subscriptionStatusProvider.notifier);

      expect(notifier.isSubscribed, false);

      await notifier.purchaseSubscription(SubscriptionType.monthly);

      expect(notifier.isSubscribed, true);

      await notifier.cancelSubscription();

      expect(notifier.isSubscribed, false);
    });
  });

  group('SubscriptionProvider - Конкурентные операции', () {
    test('множественные покупки не должны создавать гонку данных', () async {
      final notifier = container.read(subscriptionStatusProvider.notifier);

      // Запускаем две покупки одновременно
      await Future.wait([
        notifier.purchaseSubscription(SubscriptionType.monthly),
        notifier.purchaseSubscription(SubscriptionType.yearly),
      ]);

      // Подписка должна быть активна
      expect(container.read(subscriptionStatusProvider), true);

      // Дата истечения должна быть установлена
      expect(notifier.expiryDate, isNotNull);
    });
  });
}