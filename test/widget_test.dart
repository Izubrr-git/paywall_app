import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paywall_app/providers/subscription_provider.dart';
import 'package:paywall_app/services/storage_service.dart';
import 'package:paywall_app/router/app_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    // Очищаем SharedPreferences перед каждым тестом
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  /// Helper для создания приложения с нужными overrides
  Widget createTestApp() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(routerProvider);
          return MaterialApp.router(
            routerConfig: router,
          );
        },
      ),
    );
  }

  group('Интеграционные тесты - Навигация', () {
    testWidgets('Первый запуск → должен показать экран онбординга', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Должен отобразиться экран онбординга
      expect(find.text('Добро пожаловать!'), findsOneWidget);
    });

    testWidgets('После онбординга → должен перейти на Paywall', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Проверяем что мы на первом экране онбординга
      expect(find.text('Добро пожаловать!'), findsOneWidget);

      // Нажимаем "Продолжить" на первом экране
      await tester.tap(find.text('Продолжить'));
      await tester.pumpAndSettle();

      // Должен переключиться на второй экран онбординга
      expect(find.text('Эксклюзивный контент'), findsOneWidget);

      // Нажимаем "Начать" на втором экране
      await tester.tap(find.text('Начать'));
      await tester.pumpAndSettle();

      // Должен перейти на экран Paywall
      expect(find.text('Получите полный доступ'), findsOneWidget);
    });

    testWidgets('После покупки → должен перейти на Home экран', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Проходим онбординг
      await tester.tap(find.text('Продолжить'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Начать'));
      await tester.pumpAndSettle();

      // Выбираем годовую подписку (она выбрана по умолчанию)
      expect(find.text('Годовая подписка'), findsOneWidget);

      // Нажимаем кнопку "Продолжить"
      final continueButton = find.text('Продолжить за 7990 ₽/год');
      await tester.tap(continueButton);
      await tester.pump(); // Начинаем эмуляцию покупки

      // Должен появиться индикатор загрузки
      expect(find.text('🛒 Эмуляция покупки...'), findsOneWidget);

      // Ждем завершения эмуляции (2 секунды + немного времени на переход)
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Должны попасть на Home экран
      expect(find.text('Премиум контент'), findsOneWidget);
      expect(find.text('👋 Добро пожаловать!'), findsOneWidget);
    });

    testWidgets('При повторном запуске с подпиской → сразу на Home', (tester) async {
      // Устанавливаем активную подписку через StorageService
      final storage = StorageService(prefs);
      final futureDate = DateTime.now().add(const Duration(days: 30));
      await storage.setSubscriptionWithExpiry(futureDate);
      await storage.setOnboardingCompleted();

      // Запускаем приложение
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Должны сразу попасть на Home экран
      expect(find.text('Премиум контент'), findsOneWidget);
      expect(find.text('👋 Добро пожаловать!'), findsOneWidget);
    });
  });

  group('Тестовые сценарии - Месячная подписка', () {
    testWidgets('Покупка месячной подписки → дата истечения через 1 месяц', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Проходим на Paywall
      await tester.tap(find.text('Продолжить'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Начать'));
      await tester.pumpAndSettle();

      // Выбираем месячную подписку
      await tester.tap(find.text('Месячная подписка'));
      await tester.pumpAndSettle();

      // Покупаем
      final continueButton = find.text('Продолжить за 999 ₽/мес');
      await tester.tap(continueButton);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Проверяем что подписка активна
      final storage = StorageService(prefs);
      expect(storage.hasSubscription(), true);

      // Проверяем дату истечения
      final expiryDate = storage.getSubscriptionExpiryDate();
      expect(expiryDate, isNotNull);

      final now = DateTime.now();
      final expectedDate = DateTime(now.year, now.month + 1, now.day);
      expect(expiryDate!.year, expectedDate.year);
      expect(expiryDate.month, expectedDate.month);
    });

    testWidgets('Эмуляция: через месяц → автоматическая деактивация', (tester) async {
      // Устанавливаем истекшую месячную подписку
      final storage = StorageService(prefs);
      final expiredDate = DateTime.now().subtract(const Duration(days: 31));
      await storage.setSubscriptionWithExpiry(expiredDate);
      await storage.setOnboardingCompleted();

      // Запускаем приложение
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Подписка истекла, должны быть на Paywall
      expect(find.text('Получите полный доступ'), findsOneWidget);
      expect(storage.hasSubscription(), false);
    });
  });

  group('Тестовые сценарии - Годовая подписка', () {
    testWidgets('Покупка годовой подписки → дата истечения через 1 год', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Проходим на Paywall
      await tester.tap(find.text('Продолжить'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Начать'));
      await tester.pumpAndSettle();

      // Годовая подписка выбрана по умолчанию, покупаем
      final continueButton = find.text('Продолжить за 7990 ₽/год');
      await tester.tap(continueButton);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Проверяем дату истечения
      final storage = StorageService(prefs);
      final expiryDate = storage.getSubscriptionExpiryDate();
      expect(expiryDate, isNotNull);

      final now = DateTime.now();
      final expectedDate = DateTime(now.year + 1, now.month, now.day);
      expect(expiryDate!.year, expectedDate.year);
      expect(expiryDate.month, expectedDate.month);
    });

    testWidgets('Эмуляция: через год → автоматическая деактивация', (tester) async {
      // Устанавливаем истекшую годовую подписку
      final storage = StorageService(prefs);
      final expiredDate = DateTime.now().subtract(const Duration(days: 366));
      await storage.setSubscriptionWithExpiry(expiredDate);
      await storage.setOnboardingCompleted();

      // Запускаем приложение
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Подписка истекла, должны быть на Paywall
      expect(find.text('Получите полный доступ'), findsOneWidget);
      expect(storage.hasSubscription(), false);
    });
  });

  group('Тестовые сценарии - Попытки обхода', () {
    testWidgets('Без подписки не может попасть на Home', (tester) async {
      // Только завершили онбординг, но подписки нет
      final storage = StorageService(prefs);
      await storage.setOnboardingCompleted();

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Должны быть на Paywall, а не на Home
      expect(find.text('Получите полный доступ'), findsOneWidget);
      expect(find.text('Премиум контент'), findsNothing);
    });

    testWidgets('Истекшая подписка → редирект на Paywall', (tester) async {
      // Устанавливаем истекшую подписку
      final storage = StorageService(prefs);
      final expiredDate = DateTime.now().subtract(const Duration(days: 1));
      await storage.setSubscriptionWithExpiry(expiredDate);
      await storage.setOnboardingCompleted();

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Должны быть перенаправлены на Paywall
      expect(find.text('Получите полный доступ'), findsOneWidget);
      expect(find.text('Премиум контент'), findsNothing);
    });
  });

  group('Функциональность Home экрана', () {
    testWidgets('Home экран отображает дату окончания подписки', (tester) async {
      // Устанавливаем активную подписку
      final storage = StorageService(prefs);
      final expiryDate = DateTime(2026, 6, 15);
      await storage.setSubscriptionWithExpiry(expiryDate);
      await storage.setOnboardingCompleted();

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Проверяем что отображается дата окончания
      expect(find.textContaining('Активна до:'), findsOneWidget);
      expect(find.textContaining('15 июня 2026'), findsOneWidget);
    });

    testWidgets('Кнопка отмены подписки работает', (tester) async {
      // Устанавливаем активную подписку
      final storage = StorageService(prefs);
      final futureDate = DateTime.now().add(const Duration(days: 30));
      await storage.setSubscriptionWithExpiry(futureDate);
      await storage.setOnboardingCompleted();

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Нажимаем кнопку отмены подписки
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      // Должен появиться диалог подтверждения
      expect(find.text('Отменить подписку?'), findsOneWidget);

      // Подтверждаем отмену
      await tester.tap(find.text('Отменить подписку'));
      await tester.pumpAndSettle();

      // Должны быть перенаправлены на Paywall
      expect(find.text('Получите полный доступ'), findsOneWidget);
      expect(storage.hasSubscription(), false);
    });
  });

  group('Unit тесты - StorageService', () {
    test('должен возвращать false для неактивной подписки', () {
      final storage = StorageService(prefs);
      expect(storage.hasSubscription(), false);
    });

    test('должен сохранять и возвращать активную подписку', () async {
      final storage = StorageService(prefs);
      final futureDate = DateTime.now().add(const Duration(days: 30));

      await storage.setSubscriptionWithExpiry(futureDate);

      expect(storage.hasSubscription(), true);
    });

    test('должен деактивировать истекшую подписку', () async {
      final storage = StorageService(prefs);
      final pastDate = DateTime.now().subtract(const Duration(days: 1));

      await storage.setSubscriptionWithExpiry(pastDate);

      expect(storage.hasSubscription(), false);
    });
  });
}