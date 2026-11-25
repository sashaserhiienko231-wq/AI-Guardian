import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app/app_shell.dart';
import 'app/design_system.dart';
import 'app/providers.dart';
import 'screens/assistant_page.dart';
import 'screens/dashboard_page.dart';
import 'screens/history_page.dart';
import 'screens/learning_page.dart';
import 'screens/password_page.dart';
import 'screens/process_safety_page.dart';
import 'screens/qr_scanner_page.dart';
import 'screens/scanner_pages.dart';
import 'screens/settings_page.dart';

void main() {
  runApp(const ProviderScope(child: AiGuardianApp()));
}

GoRouter _createRouter() => GoRouter(
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(location: state.uri.path, child: child),
      routes: [
        _route('/dashboard', const DashboardPage()),
        _route('/link', const UrlScannerPage()),
        _route('/email', const EmailPage()),
        _route('/qr', const QrScannerPage()),
        _route('/password', const PasswordPage()),
        _route('/assistant', const AssistantPage()),
        _route('/history', const HistoryPage()),
        _route('/learning', const LearningPage()),
        _route('/settings', const SettingsPage()),
        _route('/processes', const ProcessSafetyPage()),
      ],
    ),
  ],
);

GoRoute _route(String path, Widget child) => GoRoute(
  path: path,
  pageBuilder: (context, state) => CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 160),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.012),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  ),
);

class AiGuardianApp extends ConsumerStatefulWidget {
  const AiGuardianApp({super.key});

  @override
  ConsumerState<AiGuardianApp> createState() => _AiGuardianAppState();
}

class _AiGuardianAppState extends ConsumerState<AiGuardianApp> {
  late final GoRouter _router = _createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'AI Guardian',
      debugShowCheckedModeBanner: false,
      theme: GuardianTheme.light(),
      darkTheme: GuardianTheme.dark(),
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
