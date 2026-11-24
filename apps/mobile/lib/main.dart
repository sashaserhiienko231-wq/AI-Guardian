import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

const baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);
const apiToken = String.fromEnvironment('API_AUTH_TOKEN');

void main() {
  runApp(const ProviderScope(child: AiGuardianApp()));
}

class ApiClient {
  ApiClient() : dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    headers: apiToken.isEmpty ? null : {'Authorization': 'Bearer $apiToken'},
  ));
  final Dio dio;

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async =>
      (await dio.post(path, data: body)).data as Map<String, dynamic>;
  Future<List<dynamic>> getList(String path) async =>
      (await dio.get(path)).data as List<dynamic>;
  Future<Map<String, dynamic>> getMap(String path) async =>
      (await dio.get(path)).data as Map<String, dynamic>;
}

final apiProvider = Provider<ApiClient>((ref) => ApiClient());
class LocaleController extends Notifier<bool> {
  @override
  bool build() => true;
  void setLocale(bool uk) => state = uk;
  void toggle() => state = !state;
}

final localeProvider = NotifierProvider<LocaleController, bool>(LocaleController.new);

class AiGuardianApp extends ConsumerWidget {
  const AiGuardianApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShell(location: state.uri.path, child: child),
          routes: [
            GoRoute(path: '/dashboard', builder: (_, _) => const DashboardPage()),
            GoRoute(path: '/link', builder: (_, _) => const UrlScannerPage()),
            GoRoute(path: '/email', builder: (_, _) => const EmailPage()),
            GoRoute(path: '/qr', builder: (_, _) => const QrPage()),
            GoRoute(path: '/password', builder: (_, _) => const PasswordPage()),
            GoRoute(path: '/assistant', builder: (_, _) => const AssistantPage()),
            GoRoute(path: '/history', builder: (_, _) => const HistoryPage()),
            GoRoute(path: '/learning', builder: (_, _) => const LearningPage()),
            GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
          ],
        ),
      ],
    );
    return MaterialApp.router(
      title: 'AI Guardian',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080D18),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFF8B5CF6),
          surface: Color(0xFF111827),
        ),
        cardTheme: const CardThemeData(color: Color(0xFF111827), elevation: 0),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0D1526),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF263449))),
        ),
      ),
      routerConfig: router,
    );
  }
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  static const destinations = [
    ('/dashboard', Icons.dashboard_outlined, 'Dashboard'),
    ('/link', Icons.link, 'Link Scanner'),
    ('/email', Icons.mail_outline, 'Email Guardian'),
    ('/qr', Icons.qr_code_scanner, 'QR Scanner'),
    ('/password', Icons.password, 'Passwords'),
    ('/assistant', Icons.auto_awesome, 'AI Assistant'),
    ('/history', Icons.history, 'History'),
    ('/learning', Icons.school_outlined, 'Learning'),
    ('/settings', Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUk = ref.watch(localeProvider);
    final compact = MediaQuery.sizeOf(context).width < 760;
    final index = destinations.indexWhere((item) => item.$1 == location);
    if (!compact) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: MediaQuery.sizeOf(context).width >= 1180,
              backgroundColor: const Color(0xFF0C1220),
              selectedIndex: index < 0 ? 0 : index,
              onDestinationSelected: (i) => context.go(destinations[i].$1),
              destinations: destinations.map((d) => NavigationRailDestination(icon: Icon(d.$2), label: Text(isUk ? _ukLabel(d.$3) : d.$3))).toList(),
            ),
            Expanded(child: child),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C1220),
        title: Text(isUk ? 'AI Guardian' : 'AI Guardian'),
        actions: [
          TextButton(onPressed: () => ref.read(localeProvider.notifier).toggle(), child: Text(isUk ? 'EN' : 'УК')),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (i) => context.go(destinations[i].$1),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Main'),
          NavigationDestination(icon: Icon(Icons.link), label: 'URL'),
          NavigationDestination(icon: Icon(Icons.mail_outline), label: 'Email'),
          NavigationDestination(icon: Icon(Icons.password), label: 'Password'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      floatingActionButton: index == 4 ? null : null,
    );
  }
}

String _ukLabel(String label) => switch (label) {
  'Dashboard' => 'Огляд',
  'Link Scanner' => 'Сканер посилань',
  'Email Guardian' => 'Захист пошти',
  'QR Scanner' => 'QR-сканер',
  'Passwords' => 'Паролі',
  'AI Assistant' => 'AI-помічник',
  'History' => 'Історія',
  'Learning' => 'Навчання',
  'Settings' => 'Налаштування',
  _ => label,
};

class PageScaffold extends StatelessWidget {
  const PageScaffold({super.key, required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 18),
        child,
      ]),
    ),
  );
}

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});
  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  Map<String, dynamic>? data;
  String? error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    try {
      final value = await ref.read(apiProvider).getMap('/api/v1/dashboard/statistics');
      if (mounted) setState(() => data = value);
    } catch (_) {
      if (mounted) setState(() => error = 'Cannot connect to API');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUk = ref.watch(localeProvider);
    return PageScaffold(
      title: isUk ? 'Огляд захисту' : 'Security overview',
      child: error != null
          ? _ErrorCard(message: error!, onRetry: _load)
          : data == null
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(builder: (context, constraints) {
                  final cards = [
                    ('${data!['security_score']}', isUk ? 'Рівень захисту' : 'Security score'),
                    ('${data!['total_scans']}', isUk ? 'Усього сканувань' : 'Total scans'),
                    ('${data!['threats_detected']}', isUk ? 'Загрози' : 'Threats'),
                    ('${data!['safe_scans']}', isUk ? 'Безпечні' : 'Safe'),
                  ];
                  final width = constraints.maxWidth;
                  final cardWidth = width < 500 ? (width - 12) / 2 : (width - 36) / 4;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: cards.map((item) => SizedBox(
                          width: cardWidth,
                          child: Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [Text(item.$1, style: const TextTheme().headlineMedium?.copyWith(color: const Color(0xFF38BDF8), fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(item.$2)],
                          ))),
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                      Card(child: Padding(padding: const EdgeInsets.all(18), child: SizedBox(height: 220, child: PieChart(PieChartData(
                        sections: [
                          PieChartSectionData(value: (data!['threats_detected'] as num).toDouble(), title: isUk ? 'Загрози' : 'Threats', color: const Color(0xFFEF4444), radius: 55),
                          PieChartSectionData(value: (data!['safe_scans'] as num).toDouble(), title: isUk ? 'Безпечно' : 'Safe', color: const Color(0xFF22C55E), radius: 55),
                          PieChartSectionData(value: ((data!['suspicious_scans'] as num) - (data!['threats_detected'] as num)).clamp(0, 999999).toDouble(), title: isUk ? 'Підозріло' : 'Suspicious', color: const Color(0xFFF59E0B), radius: 55),
                        ],
                      ))))),
                    ],
                  );
                }),
    );
  }
}

class UrlScannerPage extends ConsumerStatefulWidget {
  const UrlScannerPage({super.key});
  @override
  ConsumerState<UrlScannerPage> createState() => _UrlScannerPageState();
}

class _UrlScannerPageState extends ConsumerState<UrlScannerPage> {
  final controller = TextEditingController();
  Map<String, dynamic>? result;
  bool loading = false;
  String? error;

  Future<void> scan() async {
    setState(() { loading = true; error = null; result = null; });
    try {
      final value = await ref.read(apiProvider).post('/api/v1/scanner/url', {'url': controller.text.trim()});
      if (mounted) setState(() => result = value);
    } catch (e) {
      if (mounted) setState(() => error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUk = ref.watch(localeProvider);
    return PageScaffold(
      title: isUk ? 'Сканер посилань' : 'Link scanner',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(controller: controller, key: const Key('url-input'), onSubmitted: (_) => scan(), decoration: const InputDecoration(hintText: 'https://example.com')),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: loading ? null : scan, icon: const Icon(Icons.radar), label: Text(isUk ? 'Сканувати' : 'Scan URL')),
        if (loading) const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
        if (error != null) _ErrorCard(message: error!, onRetry: scan),
        if (result != null) _ScanResult(result: result!, link: controller.text.trim()),
      ]),
    );
  }
}

class EmailPage extends ConsumerStatefulWidget {
  const EmailPage({super.key});
  @override
  ConsumerState<EmailPage> createState() => _EmailPageState();
}

class _EmailPageState extends ConsumerState<EmailPage> {
  final sender = TextEditingController();
  final subject = TextEditingController();
  final body = TextEditingController();
  Map<String, dynamic>? result;
  bool loading = false;
  String? error;

  Future<void> scan() async {
    setState(() { loading = true; error = null; result = null; });
    try {
      final value = await ref.read(apiProvider).post('/api/v1/scanner/email', {'sender': sender.text, 'subject': subject.text, 'body': body.text});
      if (mounted) setState(() => result = value);
    } catch (e) {
      if (mounted) setState(() => error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUk = ref.watch(localeProvider);
    return PageScaffold(title: isUk ? 'Захист пошти' : 'Email Guardian', child: Column(children: [
      TextField(controller: sender, key: const Key('email-sender'), decoration: const InputDecoration(labelText: 'Sender')),
      const SizedBox(height: 10),
      TextField(controller: subject, key: const Key('email-subject'), decoration: const InputDecoration(labelText: 'Subject')),
      const SizedBox(height: 10),
      TextField(controller: body, key: const Key('email-body'), minLines: 5, maxLines: 10, decoration: const InputDecoration(labelText: 'Message')),
      const SizedBox(height: 12),
      FilledButton(onPressed: loading ? null : scan, child: Text(isUk ? 'Аналізувати' : 'Analyze')),
      if (loading) const CircularProgressIndicator(),
      if (error != null) _ErrorCard(message: error!, onRetry: scan),
      if (result != null) _ScanResult(result: result!),
    ]));
  }
}

class QrPage extends ConsumerStatefulWidget {
  const QrPage({super.key});
  @override
  ConsumerState<QrPage> createState() => _QrPageState();
}

class _QrPageState extends ConsumerState<QrPage> {
  final controller = TextEditingController();
  final scannerController = MobileScannerController(
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  Map<String, dynamic>? result;
  String? error;
  bool detected = false;

  @override
  void dispose() {
    scannerController.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> analyzeContent(String content) async {
    if (content.isEmpty) return;
    controller.text = content;
    try {
      final value = await ref.read(apiProvider).post('/api/v1/scanner/qr', {'content': content});
      if (mounted) setState(() { result = value; detected = true; });
      await scannerController.stop();
    } catch (e) {
      if (mounted) setState(() => error = _friendlyError(e));
    }
  }

  Future<void> scan() async {
    try {
      await analyzeContent(controller.text);
    } catch (e) {
      if (mounted) setState(() => error = _friendlyError(e));
    }
  }

  Future<void> pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    await scannerController.analyzeImage(file.path);
  }

  Future<void> switchCamera() async {
    await scannerController.switchCamera();
  }

  Future<void> toggleTorch() async {
    await scannerController.toggleTorch();
  }

  @override
  Widget build(BuildContext context) => PageScaffold(
    title: ref.watch(localeProvider) ? 'QR-сканер' : 'QR Scanner',
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Card(
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 280,
          child: MobileScanner(
            controller: scannerController,
            onDetect: (capture) {
              if (detected) return;
              for (final barcode in capture.barcodes) {
                final value = barcode.rawValue;
                if (value != null && value.isNotEmpty) {
                  analyzeContent(value);
                  return;
                }
              }
            },
          ),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        FilledButton.tonalIcon(onPressed: switchCamera, icon: const Icon(Icons.cameraswitch), label: const Text('Camera')),
        FilledButton.tonalIcon(onPressed: toggleTorch, icon: const Icon(Icons.flashlight_on), label: const Text('Flash')),
        FilledButton.tonalIcon(onPressed: pickImage, icon: const Icon(Icons.image_outlined), label: const Text('Image')),
      ]),
      const SizedBox(height: 12),
      TextField(controller: controller, key: const Key('qr-content'), decoration: const InputDecoration(hintText: 'Decoded QR content')),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: scan, icon: const Icon(Icons.qr_code_scanner), label: const Text('Analyze preview')),
      if (error != null) _ErrorCard(message: error!, onRetry: scan),
      if (result != null) _ScanResult(result: result!, link: controller.text.trim()),
    ]),
  );
}

class PasswordPage extends StatelessWidget {
  const PasswordPage({super.key});
  @override
  Widget build(BuildContext context) => const _PasswordLocalPage();
}

class _PasswordLocalPage extends ConsumerStatefulWidget {
  const _PasswordLocalPage();
  @override
  ConsumerState<_PasswordLocalPage> createState() => _PasswordLocalPageState();
}

class _PasswordLocalPageState extends ConsumerState<_PasswordLocalPage> {
  final controller = TextEditingController();
  int? score;
  String? feedback;

  void analyze() {
    final password = controller.text;
    if (password.isEmpty) {
      setState(() => feedback = 'Enter a password to analyze it locally');
      return;
    }
    var value = 0;
    if (password.length >= 16) {
      value += 50;
    } else if (password.length >= 12) {
      value += 35;
    } else {
      value += 10;
    }
    if (RegExp(r'[a-z]').hasMatch(password) && RegExp(r'[A-Z]').hasMatch(password)) {
      value += 15;
    }
    if (RegExp(r'[0-9]').hasMatch(password)) {
      value += 15;
    }
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      value += 20;
    }
    if ({'password', '123456', 'qwerty'}.contains(password.toLowerCase())) {
      value = 5;
    }
    setState(() {
      score = value.clamp(0, 100);
      feedback = score! >= 75 ? 'Strong pattern — still use a unique password and password manager.' : 'Weak pattern — use at least 16 characters with mixed types.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isUk = ref.watch(localeProvider);
    return PageScaffold(title: isUk ? 'Центр паролів' : 'Password security', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(controller: controller, obscureText: true, key: const Key('password-input'), decoration: const InputDecoration(labelText: 'Password')),
      const SizedBox(height: 12),
      FilledButton(onPressed: analyze, child: const Text('Analyze locally')),
      if (feedback != null) ...[
        const SizedBox(height: 16),
        Text('Risk-adjusted strength: $score/100', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(feedback!),
      ],
      const SizedBox(height: 12),
      const Card(child: ListTile(leading: Icon(Icons.privacy_tip_outlined), title: Text('Privacy guarantee'), subtitle: Text('This password never leaves this device and is not sent to or stored by the backend.'))),
    ]));
  }
}

class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});
  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final controller = TextEditingController();
  final messages = <Map<String, String>>[];

  Future<void> send() async {
    final message = controller.text.trim();
    if (message.isEmpty) return;
    setState(() => messages.add({'role': 'user', 'text': message}));
    controller.clear();
    try {
      final result = await ref.read(apiProvider).post('/api/v1/assistant/chat', {'message': message});
      if (mounted) setState(() => messages.add({'role': 'assistant', 'text': result['answer'] as String}));
    } catch (e) {
      if (mounted) setState(() => messages.add({'role': 'assistant', 'text': _friendlyError(e)}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUk = ref.watch(localeProvider);
    return PageScaffold(title: isUk ? 'AI-помічник з безпеки' : 'AI security assistant', child: Column(children: [
      const Card(child: ListTile(leading: Icon(Icons.info_outline), title: Text('AI disclosure'), subtitle: Text('Answers are educational and are not verified security findings.'))),
      const SizedBox(height: 12),
      SizedBox(height: 320, child: ListView.builder(
        reverse: true,
        itemCount: messages.length,
        itemBuilder: (_, i) {
          final message = messages[messages.length - 1 - i];
          final assistant = message['role'] == 'assistant';
          return Align(alignment: assistant ? Alignment.centerLeft : Alignment.centerRight, child: Card(
            color: assistant ? const Color(0xFF172033) : const Color(0xFF0B5E77),
            child: Padding(padding: const EdgeInsets.all(12), child: SizedBox(width: 320, child: Text(message['text']!))),
          ));
        },
      )),
      TextField(controller: controller, key: const Key('assistant-input'), onSubmitted: (_) => send(), decoration: InputDecoration(hintText: isUk ? 'Запитайте про загрозу' : 'Ask about a threat')),
      const SizedBox(height: 8),
      FilledButton.icon(onPressed: send, icon: const Icon(Icons.send), label: Text(isUk ? 'Надіслати' : 'Send')),
    ]));
  }
}

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});
  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  List<dynamic>? items;
  String? error;
  final search = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  Future<void> load() async {
    try {
      final value = await ref.read(apiProvider).getMap('/api/v1/history?limit=100');
      setState(() => items = value['items'] as List<dynamic>);
    } catch (e) {
      setState(() => error = _friendlyError(e));
    }
  }

  Future<void> delete(String id) async {
    await ref.read(apiProvider).dio.delete('/api/v1/history/$id');
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final isUk = ref.watch(localeProvider);
    final visible = (items ?? []).where((item) => '${item['scan_type']} ${item['risk_category']}'.toLowerCase().contains(search.text.toLowerCase())).toList();
    return PageScaffold(title: isUk ? 'Історія загроз' : 'Threat history', child: Column(children: [
      TextField(controller: search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search history')),
      const SizedBox(height: 12),
      if (error != null) _ErrorCard(message: error!, onRetry: load),
      if (items == null && error == null) const CircularProgressIndicator(),
      if (visible.isEmpty && items != null) const Card(child: ListTile(leading: Icon(Icons.inbox_outlined), title: Text('No matching scans'))),
      ...visible.map((item) => Card(child: ListTile(
        leading: Icon(item['risk_score'] >= 40 ? Icons.warning_amber : Icons.shield_outlined),
        title: Text('${item['scan_type']} • ${item['risk_category']}'),
        subtitle: Text('Risk ${item['risk_score']} • ${item['created_at']}'),
        trailing: IconButton(key: Key('delete-${item['id']}'), tooltip: 'Delete', onPressed: () => delete(item['id'] as String), icon: const Icon(Icons.delete_outline)),
      ))),
    ]));
  }
}

class LearningPage extends ConsumerStatefulWidget {
  const LearningPage({super.key});
  @override
  ConsumerState<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends ConsumerState<LearningPage> {
  List<dynamic>? lessons;
  String? error;

  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  Future<void> load() async {
    try {
      final value = await ref.read(apiProvider).getList('/api/v1/learning/lessons');
      setState(() => lessons = value);
    } catch (e) {
      setState(() => error = _friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUk = ref.watch(localeProvider);
    return PageScaffold(title: isUk ? 'Навчальний центр' : 'Learning center', child: Column(children: [
      if (error != null) _ErrorCard(message: error!, onRetry: load),
      if (lessons == null && error == null) const CircularProgressIndicator(),
      if (lessons != null) ...lessons!.map((lesson) {
        final title = isUk ? (lesson['localized_title']['uk'] as String) : (lesson['title'] as String);
        return Card(child: ListTile(
          leading: const Icon(Icons.menu_book_outlined),
          title: Text(title),
          subtitle: Text('${lesson['level']} • quiz available'),
          trailing: FilledButton(onPressed: () => _showLesson(context, title), child: const Text('Open')),
        ));
      }),
    ]));
  }

  void _showLesson(BuildContext context, String title) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: const Text('Pause, verify unexpected requests through an official channel, and never share passwords or payment details.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Complete lesson'))],
      ),
    );
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUk = ref.watch(localeProvider);
    return PageScaffold(title: isUk ? 'Налаштування' : 'Settings', child: Column(children: [
      Card(child: SwitchListTile(title: const Text('Dark theme'), value: true, onChanged: (_) {})),
      Card(child: SwitchListTile(title: const Text('Ukrainian interface'), value: isUk, onChanged: (value) => ref.read(localeProvider.notifier).setLocale(value))),
      const Card(child: ListTile(title: Text('Guest mode'), subtitle: Text('No account or password is required.'))),
      const Card(child: ListTile(title: Text('Retention'), subtitle: Text('Scan history retention is configured on the backend.'))),
    ]));
  }
}

class _ScanResult extends StatelessWidget {
  const _ScanResult({required this.result, this.link});
  final Map<String, dynamic> result;
  final String? link;

  Future<void> _openLink(BuildContext context) async {
    final uri = Uri.tryParse(link ?? '');
    if (uri == null || !uri.hasScheme || !{'http', 'https'}.contains(uri.scheme)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This result does not contain a safe web link.')),
      );
      return;
    }

    final score = (result['risk_score'] as num).toInt();
    if (score >= 40) {
      final indicators = (result['indicators'] as List<dynamic>? ?? [])
          .map((item) => item['title'] as String)
          .toList();
      final reasons = indicators.isNotEmpty
          ? indicators.join(', ')
          : ((result['explanations'] as List<dynamic>? ?? []).join(', '));
      final proceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 36),
          title: const Text('Suspicious link detected'),
          content: Text(
            'We found this link suspicious for: ${reasons.isEmpty ? 'potential phishing indicators' : reasons}.\n\n'
            'Are you sure you want to proceed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Proceed'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link.')),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final score = result['risk_score'] as num;
    final indicators = (result['indicators'] as List<dynamic>? ?? []).cast<Map>();
    final explanations = (result['explanations'] as List<dynamic>? ?? []).cast<String>();
    final actions = (result['recommended_actions'] as List<dynamic>? ?? []).cast<String>();
    return Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(score >= 65 ? Icons.dangerous : score >= 40 ? Icons.warning_amber : Icons.verified_outlined, color: score >= 65 ? Colors.red : score >= 40 ? Colors.orange : Colors.green),
        const SizedBox(width: 8),
        Text('${result['risk_category']} • $score/100', style: Theme.of(context).textTheme.titleLarge),
      ]),
      if (indicators.isNotEmpty) ...[
        const SizedBox(height: 12),
        const Text('Detected indicators', style: TextStyle(fontWeight: FontWeight.bold)),
        ...indicators.map((item) => Text('• ${item['title']}')),
      ],
      if (explanations.isNotEmpty) ...[
        const SizedBox(height: 12),
        ...explanations.map((item) => Text(item)),
      ],
      if (actions.isNotEmpty) ...[
        const SizedBox(height: 12),
        const Text('Recommended actions', style: TextStyle(fontWeight: FontWeight.bold)),
        ...actions.map((item) => Text('• $item')),
      ],
      if (result['ml_prediction'] is Map) ...[
        const SizedBox(height: 12),
        const Text('ML prediction', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('Probabilistic classification: ${result['ml_prediction']['prediction']}'),
        Text('Confidence: ${result['ml_prediction']['confidence']}'),
        const Text('This is not a confirmed threat.'),
      ],
      if (link != null) ...[
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => _openLink(context),
          icon: const Icon(Icons.open_in_new),
          label: Text(score >= 40 ? 'Review and open link' : 'Open link'),
        ),
      ],
    ])));
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(
    leading: const Icon(Icons.error_outline, color: Colors.redAccent),
    title: Text(message),
    trailing: TextButton(onPressed: onRetry, child: const Text('Retry')),
  ));
}

String _friendlyError(Object error) {
  if (error is DioException) {
    if (error.response?.statusCode == 422) return 'The input is invalid or incomplete.';
    return 'API unavailable or request timed out.';
  }
  return 'An unexpected error occurred.';
}
