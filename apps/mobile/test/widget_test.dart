import 'package:dio/dio.dart';
import 'package:ai_guardian/app/providers.dart';
import 'package:ai_guardian/app/design_system.dart';
import 'package:ai_guardian/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(onConnectivityChanged: (_) {});

  int postCalls = 0;
  bool failStatistics = false;
  final List<String> getMapRequests = [];
  final List<(String, Map<String, dynamic>)> postRequests = [];

  @override
  Future<Map<String, dynamic>> getMap(String path) async {
    getMapRequests.add(path);
    if (path.contains('/dashboard/statistics')) {
      if (failStatistics &&
          (path.contains('/dashboard/statistics') ||
              path.startsWith('/api/v1/history') ||
              path.endsWith('/health'))) {
        throw DioException(requestOptions: RequestOptions(path: path));
      }
      return {
        'security_score': 82,
        'total_scans': 7,
        'threats_detected': 2,
        'safe_scans': 3,
        'suspicious_scans': 4,
        'security_score_formula': 'server calculated',
        'threat_distribution': const [],
        'recommendations': const ['Review recently used account passwords.'],
        'last_scan_timestamp': null,
      };
    }
    if (path.startsWith('/api/v1/history')) {
      return {
        'items': const [
          {
            'id': 'scan-1',
            'scan_type': 'url',
            'risk_score': 12,
            'risk_category': 'SAFE',
            'summary': 'A real API result',
            'created_at': '2026-11-25T10:00:00Z',
            'indicators': [],
          },
        ],
        'page': 1,
        'limit': 20,
        'total': 1,
      };
    }
    if (path.endsWith('/health')) {
      return {'status': 'ok', 'service': 'AI Guardian', 'version': '2.0.0'};
    }
    if (path.endsWith('/learning/progress')) {
      return {'completed_lessons': <String>[], 'quiz_results': <dynamic>[]};
    }
    return {};
  }

  @override
  Future<List<dynamic>> getList(String path) async => [
    {
      'id': 'phishing',
      'title': 'Phishing awareness',
      'localized_title': {
        'uk': 'Усвідомлення фішингу',
        'en': 'Phishing awareness',
      },
      'level': 'beginner',
    },
  ];

  @override
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    postCalls++;
    postRequests.add((path, Map<String, dynamic>.from(body)));
    if (path == '/api/v1/assistant/chat') {
      return {'answer': 'Example response from the test API.'};
    }
    return {
      'risk_score': 12,
      'risk_category': 'SAFE',
      'indicators': [],
      'explanations': [],
      'recommended_actions': [],
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeApiClient api;
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    api = _FakeApiClient();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiProvider.overrideWithValue(api),
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
        child: const AiGuardianApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('dashboard displays values returned by the API', (tester) async {
    await pumpApp(tester);

    expect(find.text('Оцінка безпеки'), findsWidgets);
    expect(find.text('82/100'), findsOneWidget);
    expect(find.text('7'), findsWidgets);
    expect(find.text('A real API result'), findsOneWidget);
    expect(
      find.text('Review recently used account passwords.'),
      findsOneWidget,
    );
    expect(find.text('2 перевірки з високим ризиком'), findsOneWidget);
    expect(find.bySemanticsLabel('Огляд'), findsWidgets);
  });

  testWidgets('dashboard renders the shared workspace heading and motion safely', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('AI GUARDIAN / SECURITY WORKSPACE'), findsOneWidget);
    expect(find.byType(PageHeading), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid URLs are rejected without an API request', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Сканер посилань').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('url-input')), 'not a URL');
    await tester.tap(find.text('Перевірити адресу'));
    await tester.pumpAndSettle();

    expect(
      find.text('Введіть коректну вебадресу з HTTP або HTTPS.'),
      findsOneWidget,
    );
    expect(api.postCalls, 0);
  });

  testWidgets('password analysis stays local and discloses its limits', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Центр паролів').first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('password-input')),
      'A-long-example-Passphrase-984!',
    );
    await tester.tap(find.text('Перевірити на пристрої'));
    await tester.pumpAndSettle();

    expect(find.textContaining('/100'), findsOneWidget);
    expect(
      find.textContaining('не розрахунок ентропії чи часу зламу'),
      findsOneWidget,
    );
    expect(find.textContaining('не надсилається на сервер'), findsOneWidget);
    expect(api.postCalls, 0);
  });

  testWidgets(
    'email analysis validates fields and submits exact message text',
    (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Захист пошти').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Проаналізувати лист'));
      await tester.pumpAndSettle();
      expect(api.postCalls, 0);

      await tester.enterText(
        find.byKey(const Key('email-sender')),
        'sender@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('email-body')),
        '  Hello\nworld  ',
      );
      await tester.tap(find.text('Проаналізувати лист'));
      await tester.pumpAndSettle();

      expect(api.postCalls, 1);
      expect(api.postRequests.single.$1, '/api/v1/scanner/email');
      expect(api.postRequests.single.$2['body'], '  Hello\nworld  ');
      expect(find.text('Низький ризик'), findsOneWidget);
    },
  );

  testWidgets('QR input is checked by the API before showing its verdict', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('QR-сканер').first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('qr-content')),
      'https://example.com',
    );
    await tester.tap(find.text('Перевірити вміст'));
    await tester.pumpAndSettle();

    expect(api.postRequests.single.$1, '/api/v1/scanner/qr');
    expect(find.text('Низький ризик'), findsOneWidget);
    expect(find.text('Відкрити посилання'), findsOneWidget);
  });

  testWidgets('assistant example prompt sends a real API request', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('AI-помічник').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Які типові ознаки фішингового листа?'));
    await tester.pumpAndSettle();

    expect(api.postRequests.single.$1, '/api/v1/assistant/chat');
    expect(
      api.postRequests.single.$2['message'],
      'Які типові ознаки фішингового листа?',
    );
    expect(find.text('Очистити розмову'), findsOneWidget);
    await tester.tap(find.text('Очистити розмову'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Запитайте про підозрілі листи, безпечний перегляд або захист облікового запису.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('history sorting uses the API supported sort parameter', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Історія загроз').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Спочатку старіші').last);
    await tester.pumpAndSettle();

    expect(api.getMapRequests.last, contains('sort=oldest'));
  });

  testWidgets('settings switch theme and language throughout the app', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Налаштування').first);
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.text('Налаштування').last)).brightness,
      Brightness.dark,
    );
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Налаштування').last)).brightness,
      Brightness.light,
    );

    await tester.tap(find.text('Англійська'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Link scanner'), findsOneWidget);
  });

  testWidgets('dashboard adapts across supported desktop sizes', (
    tester,
  ) async {
    await pumpApp(tester);
    for (final size in [
      const Size(1280, 720),
      const Size(1366, 768),
      const Size(1600, 900),
      const Size(1920, 1080),
      const Size(2560, 1440),
    ]) {
      tester.view.physicalSize = size;
      await tester.pump();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(PageScaffold), findsOneWidget);
    }
  });

  testWidgets('desktop sidebar can collapse and expand', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Згорнути бічну панель'));
    await tester.pumpAndSettle();
    expect(preferences.getBool('sidebar_expanded'), isFalse);
    expect(find.text('Сканер посилань'), findsNothing);
    expect(find.byTooltip('Розгорнути бічну панель'), findsOneWidget);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiProvider.overrideWithValue(api),
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
        child: const AiGuardianApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Сканер посилань'), findsNothing);
    expect(find.byTooltip('Розгорнути бічну панель'), findsOneWidget);

    await tester.tap(find.byTooltip('Розгорнути бічну панель'));
    await tester.pumpAndSettle();
    expect(preferences.getBool('sidebar_expanded'), isTrue);
    expect(find.text('Сканер посилань'), findsOneWidget);
  });

  testWidgets('offline dashboard explains which local checks remain usable', (
    tester,
  ) async {
    api.failStatistics = true;
    await pumpApp(tester);

    expect(find.text('Актуальні дані дашборда недоступні'), findsOneWidget);
    expect(find.text('Доступно на цьому пристрої'), findsOneWidget);
    expect(
      find.text('Перевірте шаблони пароля, не надсилаючи його.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('application menu opens product information', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Меню застосунку'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Про AI Guardian'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('AI Guardian об’єднує інструменти безпеки.'),
      findsOneWidget,
    );
  });

  testWidgets('all navigation destinations open their existing screens', (
    tester,
  ) async {
    await pumpApp(tester);
    const destinations = [
      'Огляд',
      'Сканер посилань',
      'Захист пошти',
      'QR-сканер',
      'Центр паролів',
      'AI-помічник',
      'Історія загроз',
      'Навчальний центр',
      'Налаштування',
      'Перевірка процесів',
    ];

    for (final size in [
      const Size(1280, 720),
      const Size(1366, 768),
      const Size(1600, 900),
      const Size(1920, 1080),
      const Size(2560, 1440),
    ]) {
      tester.view.physicalSize = size;
      await tester.pump();
      for (final destination in destinations) {
        final destinationFinder = find.text(destination).first;
        await tester.ensureVisible(destinationFinder);
        await tester.pumpAndSettle();
        await tester.tap(destinationFinder);
        await tester.pumpAndSettle();
        expect(find.byType(PageScaffold), findsOneWidget);
      }
    }
  });
}
