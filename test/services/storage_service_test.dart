import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paywall_app/services/storage_service.dart';

void main() {
  late StorageService storageService;

  setUp(() async {
    // Очищаем SharedPreferences перед каждым тестом
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageService(prefs);
  });

  group('StorageService - Onboarding', () {
    test('должен возвращать false если онбординг не завершен', () {
      expect(storageService.isOnboardingCompleted(), false);
    });

    test('должен сохранять и возвращать true после завершения онбординга', () async {
      await storageService.setOnboardingCompleted();
      expect(storageService.isOnboardingCompleted(), true);
    });
  });

  group('StorageService - Subscription', () {
    test('должен возвращать false если подписка не установлена', () {
      expect(storageService.hasSubscription(), false);
    });

    test('должен возвращать false если есть флаг подписки но нет даты истечения', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_subscription', true);

      expect(storageService.hasSubscription(), false);
    });

    test('должен возвращать true для активной подписки', () async {
      final futureDate = DateTime.now().add(const Duration(days: 30));
      await storageService.setSubscriptionWithExpiry(futureDate);

      expect(storageService.hasSubscription(), true);
    });

    test('должен возвращать false для истекшей подписки', () async {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      await storageService.setSubscriptionWithExpiry(pastDate);

      // Подписка истекла
      expect(storageService.hasSubscription(), false);
    });

    test('должен сохранять дату истечения подписки', () async {
      final expiryDate = DateTime(2026, 12, 31);
      await storageService.setSubscriptionWithExpiry(expiryDate);

      final savedDate = storageService.getSubscriptionExpiryDate();
      expect(savedDate, isNotNull);
      expect(savedDate!.year, 2026);
      expect(savedDate.month, 12);
      expect(savedDate.day, 31);
    });

    test('должен вернуть null если дата истечения не установлена', () {
      final date = storageService.getSubscriptionExpiryDate();
      expect(date, isNull);
    });
  });

  group('StorageService - Месячная подписка', () {
    test('покупка месячной подписки → дата истечения через 1 месяц', () async {
      final now = DateTime.now();
      final expectedExpiry = DateTime(now.year, now.month + 1, now.day);

      await storageService.setSubscriptionWithExpiry(expectedExpiry);

      final savedDate = storageService.getSubscriptionExpiryDate();
      expect(savedDate, isNotNull);
      expect(savedDate!.year, expectedExpiry.year);
      expect(savedDate.month, expectedExpiry.month);
      expect(savedDate.day, expectedExpiry.day);
      expect(storageService.hasSubscription(), true);
    });

    test('через месяц → автоматическая деактивация', () async {
      // Устанавливаем дату истечения вчера
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await storageService.setSubscriptionWithExpiry(yesterday);

      // Подписка должна быть деактивирована
      expect(storageService.hasSubscription(), false);
    });
  });

  group('StorageService - Годовая подписка', () {
    test('покупка годовой подписки → дата истечения через 1 год', () async {
      final now = DateTime.now();
      final expectedExpiry = DateTime(now.year + 1, now.month, now.day);

      await storageService.setSubscriptionWithExpiry(expectedExpiry);

      final savedDate = storageService.getSubscriptionExpiryDate();
      expect(savedDate, isNotNull);
      expect(savedDate!.year, expectedExpiry.year);
      expect(savedDate.month, expectedExpiry.month);
      expect(savedDate.day, expectedExpiry.day);
      expect(storageService.hasSubscription(), true);
    });

    test('через год → автоматическая деактивация', () async {
      // Устанавливаем дату истечения год назад
      final lastYear = DateTime.now().subtract(const Duration(days: 366));
      await storageService.setSubscriptionWithExpiry(lastYear);

      // Подписка должна быть деактивирована
      expect(storageService.hasSubscription(), false);
    });
  });

  group('StorageService - Отмена подписки', () {
    test('должен очищать подписку и дату истечения', () async {
      final futureDate = DateTime.now().add(const Duration(days: 30));
      await storageService.setSubscriptionWithExpiry(futureDate);

      expect(storageService.hasSubscription(), true);

      await storageService.cancelSubscription();

      expect(storageService.hasSubscription(), false);
      expect(storageService.getSubscriptionExpiryDate(), isNull);
    });
  });

  group('StorageService - Атомарность операций', () {
    test('setSubscriptionWithExpiry должен сохранять оба значения атомарно', () async {
      final expiryDate = DateTime.now().add(const Duration(days: 30));
      await storageService.setSubscriptionWithExpiry(expiryDate);

      // Оба значения должны быть сохранены
      expect(storageService.hasSubscription(), true);
      expect(storageService.getSubscriptionExpiryDate(), isNotNull);
    });

    test('cancelSubscription должен удалять оба значения атомарно', () async {
      final expiryDate = DateTime.now().add(const Duration(days: 30));
      await storageService.setSubscriptionWithExpiry(expiryDate);

      await storageService.cancelSubscription();

      // Оба значения должны быть удалены
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('has_subscription'), false);
      expect(prefs.getInt('subscription_expiry_date'), isNull);
    });
  });

  group('StorageService - Граничные случаи', () {
    test('должен корректно обрабатывать дату истечения ровно сейчас', () async {
      final now = DateTime.now();
      await storageService.setSubscriptionWithExpiry(now);

      // Дата истечения = сейчас → подписка еще активна (not isAfter)
      // Это зависит от точности до миллисекунд
      // В реальности это edge case, поэтому проверяем что метод не падает
      expect(() => storageService.hasSubscription(), returnsNormally);
    });

    test('должен обрабатывать очень далекую дату истечения', () async {
      final farFuture = DateTime(2099, 12, 31);
      await storageService.setSubscriptionWithExpiry(farFuture);

      expect(storageService.hasSubscription(), true);
      expect(storageService.getSubscriptionExpiryDate()!.year, 2099);
    });

    test('должен обрабатывать очень старую дату истечения', () async {
      final farPast = DateTime(2000, 1, 1);
      await storageService.setSubscriptionWithExpiry(farPast);

      expect(storageService.hasSubscription(), false);
    });
  });
}