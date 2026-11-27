import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/design_system.dart';
import '../app/providers.dart';
import '../app/strings.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _checkingApi = false;
  String? _apiVersion;
  String? _apiError;

  Future<void> _checkApi() async {
    setState(() {
      _checkingApi = true;
      _apiError = null;
    });
    try {
      final result = await ref.read(apiProvider).getMap('/api/v1/health');
      if (mounted) setState(() => _apiVersion = result['version']?.toString());
    } catch (error) {
      if (mounted) {
        setState(
          () => _apiError = friendlyApiError(
            error,
            ukrainian: ref.read(localeProvider),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingApi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(ref.watch(localeProvider));
    final ukrainian = ref.watch(localeProvider);
    final dark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final apiStatus = ref.watch(apiConnectivityProvider);
    final statusColor = switch (apiStatus) {
      ApiConnectivity.unknown => GuardianColors.warning,
      ApiConnectivity.connected => GuardianColors.success,
      ApiConnectivity.unavailable => GuardianColors.danger,
    };
    final statusLabel = switch (apiStatus) {
      ApiConnectivity.unknown => strings.apiNotChecked,
      ApiConnectivity.connected => strings.apiConnected,
      ApiConnectivity.unavailable => strings.apiUnavailable,
    };

    return PageScaffold(
      title: strings.settings,
      subtitle: strings.settingsSubtitle,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeading(strings.preferences),
              const SizedBox(height: GuardianSpace.md),
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.dark_mode_outlined),
                      title: Text(strings.darkTheme),
                      subtitle: Text(strings.darkThemeDescription),
                      value: dark,
                      onChanged: (value) =>
                          ref.read(themeModeProvider.notifier).setDark(value),
                    ),
                    Divider(
                      height: 1,
                      indent: GuardianSpace.xl,
                      endIndent: GuardianSpace.xl,
                      color: Theme.of(context).dividerColor,
                    ),
                    ListTile(
                      leading: const Icon(Icons.translate_rounded),
                      title: Text(strings.language),
                      trailing: SegmentedButton<bool>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: true,
                            label: Text(strings.ukrainian),
                          ),
                          ButtonSegment(
                            value: false,
                            label: Text(strings.english),
                          ),
                        ],
                        selected: {ukrainian},
                        onSelectionChanged: (selection) => ref
                            .read(localeProvider.notifier)
                            .setLocale(selection.first),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GuardianSpace.xl),
              SectionHeading(strings.apiStatus),
              const SizedBox(height: GuardianSpace.md),
              SurfaceCard(
                padding: const EdgeInsets.all(GuardianSpace.lg),
                child: Row(
                  children: [
                    Icon(
                      apiStatus == ApiConnectivity.connected
                          ? Icons.cloud_done_outlined
                          : apiStatus == ApiConnectivity.unavailable
                          ? Icons.cloud_off_outlined
                          : Icons.cloud_outlined,
                      color: statusColor,
                    ),
                    const SizedBox(width: GuardianSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusLabel,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (_apiVersion != null)
                            Text(
                              '${strings.appVersion}: $_apiVersion',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (_apiError != null)
                            Text(
                              _apiError!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _checkingApi ? null : _checkApi,
                      icon: _checkingApi
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded),
                      label: Text(strings.retry),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GuardianSpace.xl),
              SectionHeading(strings.privacy),
              const SizedBox(height: GuardianSpace.md),
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.lock_outline_rounded,
                        color: GuardianColors.success,
                      ),
                      title: Text(strings.passwordCenter),
                      subtitle: Text(strings.passwordPrivacy),
                    ),
                    Divider(
                      height: 1,
                      indent: GuardianSpace.xl,
                      endIndent: GuardianSpace.xl,
                      color: Theme.of(context).dividerColor,
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_outline_rounded),
                      title: Text(strings.guestMode),
                    ),
                    Divider(
                      height: 1,
                      indent: GuardianSpace.xl,
                      endIndent: GuardianSpace.xl,
                      color: Theme.of(context).dividerColor,
                    ),
                    ListTile(
                      leading: const Icon(Icons.history_rounded),
                      title: Text(strings.retention),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GuardianSpace.xl),
              SectionHeading(strings.system),
              const SizedBox(height: GuardianSpace.md),
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.monitor_heart_outlined),
                      title: Text(strings.processSafety),
                      subtitle: Text(strings.processSafetyDescription),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.go('/processes'),
                    ),
                    Divider(
                      height: 1,
                      indent: GuardianSpace.xl,
                      endIndent: GuardianSpace.xl,
                      color: Theme.of(context).dividerColor,
                    ),
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: Text(strings.appInformation),
                      subtitle: Text('${strings.appVersion}: 2.0.0'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
