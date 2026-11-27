import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/design_system.dart';
import '../app/providers.dart';
import '../app/strings.dart';
import '../services/process_scanner.dart';

class ProcessSafetyPage extends ConsumerStatefulWidget {
  const ProcessSafetyPage({super.key});

  @override
  ConsumerState<ProcessSafetyPage> createState() => _ProcessSafetyPageState();
}

class _ProcessSafetyPageState extends ConsumerState<ProcessSafetyPage> {
  final ProcessScanner _scanner = ProcessScanner();
  ProcessScanReport? _report;
  String? _error;
  bool _scanning = false;

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _error = null;
      _report = null;
    });
    try {
      final result = await _scanner.scan();
      if (mounted) setState(() => _report = result);
    } on PlatformException {
      if (mounted) {
        setState(
          () => _error = AppStrings(ref.read(localeProvider)).processReadError,
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is UnsupportedError
              ? AppStrings(ref.read(localeProvider)).platformUnavailable
              : AppStrings(ref.read(localeProvider)).unexpectedError,
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(ref.watch(localeProvider));

    return PageScaffold(
      title: strings.processSafety,
      subtitle: strings.processSubtitle,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SurfaceCard(
                accent: GuardianColors.cyan,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: GuardianColors.cyan,
                    ),
                    const SizedBox(width: GuardianSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StatusBadge(
                            label: strings.windowsOnly,
                            color: GuardianColors.cyan,
                            icon: Icons.desktop_windows_outlined,
                          ),
                          const SizedBox(height: GuardianSpace.md),
                          Text(strings.processSafetyDisclosure),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!ProcessScanner.isSupported) ...[
                const SizedBox(height: GuardianSpace.lg),
                SurfaceCard(
                  child: ListTile(
                    leading: const Icon(Icons.desktop_windows_outlined),
                    title: Text(strings.platformUnavailable),
                  ),
                ),
              ] else ...[
                const SizedBox(height: GuardianSpace.lg),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: _scanning ? null : _scan,
                    icon: _scanning
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.manage_search_rounded),
                    label: Text(
                      _scanning
                          ? strings.scanningProcesses
                          : strings.runProcessCheck,
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: GuardianSpace.lg),
                  _ProcessError(
                    message: _error!,
                    label: strings.retry,
                    onRetry: _scan,
                  ),
                ],
                if (_report case final report?) ...[
                  const SizedBox(height: GuardianSpace.xl),
                  if (report.findings.isEmpty)
                    SurfaceCard(
                      accent: GuardianColors.success,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: GuardianColors.success,
                          ),
                          const SizedBox(width: GuardianSpace.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.noProcessesMatched,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: GuardianSpace.sm),
                                Text(strings.processNoGuarantee),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    SurfaceCard(
                      accent: GuardianColors.warning,
                      color: GuardianColors.warning.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.08
                            : 0.12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: GuardianColors.warning,
                          ),
                          const SizedBox(width: GuardianSpace.md),
                          Expanded(
                            child: Text(
                              '${report.findings.length} ${strings.processesNeedReview}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (report.unreadableProcesses > 0)
                            Text(
                              '${report.unreadableProcesses} ${strings.unreadableProcesses}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: GuardianSpace.md),
                    Text(
                      strings.processReviewAdvice,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: GuardianSpace.md),
                    for (final finding in report.findings)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: GuardianSpace.sm,
                        ),
                        child: SurfaceCard(
                          padding: const EdgeInsets.all(GuardianSpace.lg),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.running_with_errors_outlined,
                                color: GuardianColors.warning,
                              ),
                              const SizedBox(width: GuardianSpace.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      finding.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: GuardianSpace.xs),
                                    SelectableText(
                                      'PID ${finding.processId} · ${strings.processFindingReason}',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProcessError extends StatelessWidget {
  const _ProcessError({
    required this.message,
    required this.label,
    required this.onRetry,
  });

  final String message;
  final String label;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    accent: GuardianColors.danger,
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: GuardianColors.danger),
        const SizedBox(width: GuardianSpace.md),
        Expanded(child: Text(message)),
        TextButton(onPressed: onRetry, child: Text(label)),
      ],
    ),
  );
}
