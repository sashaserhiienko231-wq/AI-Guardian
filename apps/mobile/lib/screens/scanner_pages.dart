import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../app/design_system.dart';
import '../app/providers.dart';
import '../app/strings.dart';
import 'shared_widgets.dart';

class UrlScannerPage extends ConsumerStatefulWidget {
  const UrlScannerPage({super.key});

  @override
  ConsumerState<UrlScannerPage> createState() => _UrlScannerPageState();
}

class _UrlScannerPageState extends ConsumerState<UrlScannerPage> {
  final _controller = TextEditingController();
  Map<String, dynamic>? _result;
  String? _error;
  List<dynamic>? _recentScans;
  String? _recentError;
  bool _loading = false;
  bool _loadingRecent = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadRecentScans);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    if (_loading) return;
    final strings = AppStrings(ref.read(localeProvider));
    final value = _controller.text.trim();
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        !{'http', 'https'}.contains(uri.scheme.toLowerCase())) {
      setState(() {
        _error = strings.invalidUrl;
        _result = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await ref.read(apiProvider).post('/api/v1/scanner/url', {
        'url': value,
      });
      if (mounted) setState(() => _result = result);
      await _loadRecentScans();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = friendlyApiError(
            error,
            ukrainian: ref.read(localeProvider),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pasteFromClipboard(AppStrings strings) async {
    try {
      final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
      final value = clipboard?.text?.trim();
      if (value == null || value.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(strings.clipboardEmpty)));
        }
        return;
      }
      setState(() {
        _controller.text = value;
        _error = null;
        _result = null;
      });
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.clipboardReadError)));
      }
    }
  }

  Future<void> _loadRecentScans() async {
    setState(() {
      _loadingRecent = true;
      _recentError = null;
    });
    try {
      final response = await ref
          .read(apiProvider)
          .getMap('/api/v1/history?page=1&limit=5&scan_type=url');
      final items = response['items'];
      if (mounted) {
        setState(() => _recentScans = items is List ? items : const []);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _recentError = friendlyApiError(
            error,
            ukrainian: ref.read(localeProvider),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingRecent = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(ref.watch(localeProvider));
    return PageScaffold(
      title: strings.linkScanner,
      subtitle: strings.linkSubtitle,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SurfaceCard(
                accent: GuardianColors.cyan,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.scanUrlLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: GuardianSpace.md),
                    TextField(
                      controller: _controller,
                      key: const Key('url-input'),
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.go,
                      autocorrect: false,
                      enableSuggestions: false,
                      onSubmitted: (_) => _scan(),
                      onChanged: (_) {
                        if (_error == strings.invalidUrl) {
                          setState(() => _error = null);
                        }
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.language_rounded),
                        suffixIcon: IconButton(
                          tooltip: strings.pasteFromClipboard,
                          onPressed: _loading
                              ? null
                              : () => _pasteFromClipboard(strings),
                          icon: const Icon(Icons.content_paste_rounded),
                        ),
                        labelText: strings.scanUrlLabel,
                        hintText: strings.scanUrlHint,
                        errorText: _error == strings.invalidUrl ? _error : null,
                      ),
                    ),
                    const SizedBox(height: GuardianSpace.lg),
                    FilledButton.icon(
                      onPressed: _loading ? null : _scan,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.radar_rounded),
                      label: Text(
                        _loading ? strings.scanProgress : strings.scanUrlAction,
                      ),
                    ),
                  ],
                ),
              ),
              if (_loading) ...[
                const SizedBox(height: GuardianSpace.lg),
                LinearProgressIndicator(
                  borderRadius: BorderRadius.circular(GuardianRadius.pill),
                ),
              ],
              if (_error != null && _error != strings.invalidUrl) ...[
                const SizedBox(height: GuardianSpace.lg),
                ErrorPanel(
                  message: _error!,
                  retryLabel: strings.retry,
                  onRetry: _scan,
                ),
              ],
              if (_result != null) ...[
                const SizedBox(height: GuardianSpace.xl),
                SectionHeading(strings.scanResult),
                const SizedBox(height: GuardianSpace.md),
                ScanResultCard(
                  result: _result!,
                  strings: strings,
                  link: _controller.text.trim(),
                ),
                const SizedBox(height: GuardianSpace.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _controller.clear();
                      _result = null;
                      _error = null;
                    }),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(strings.scanAgain),
                  ),
                ),
              ],
              const SizedBox(height: GuardianSpace.xxl),
              _RecentUrlScans(
                strings: strings,
                scans: _recentScans,
                loading: _loadingRecent,
                error: _recentError,
                onRetry: _loadRecentScans,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentUrlScans extends StatelessWidget {
  const _RecentUrlScans({
    required this.strings,
    required this.scans,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final AppStrings strings;
  final List<dynamic>? scans;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeading(
          strings.recentActivity,
          trailing: TextButton(
            onPressed: () => context.go('/history'),
            child: Text(strings.viewAll),
          ),
        ),
        const SizedBox(height: GuardianSpace.md),
        if (loading && scans == null)
          LoadingState(message: strings.loading)
        else if (error != null)
          ErrorPanel(
            message: error!,
            retryLabel: strings.retry,
            onRetry: onRetry,
          )
        else if (scans == null || scans!.isEmpty)
          EmptyState(
            icon: Icons.link_off_rounded,
            title: strings.noHistory,
            message: strings.noScansYet,
          )
        else
          for (final scan in scans!)
            if (scan is Map) _RecentUrlScan(scan: scan, strings: strings),
      ],
    ),
  );
}

class _RecentUrlScan extends StatelessWidget {
  const _RecentUrlScan({required this.scan, required this.strings});

  final Map scan;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final score = scan['risk_score'] is num ? scan['risk_score'] as num : null;
    final color = riskColor(score);
    final summary = scan['summary']?.toString() ?? '';
    final date = scan['created_at']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GuardianSpace.sm),
      child: Row(
        children: [
          Icon(Icons.link_rounded, color: color),
          const SizedBox(width: GuardianSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  riskLabel(strings, scan['risk_category']),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (summary.isNotEmpty)
                  Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (date.isNotEmpty)
                  Text(
                    date,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (score != null)
            StatusBadge(label: '${score.toInt()}/100', color: color),
        ],
      ),
    );
  }
}

class EmailPage extends ConsumerStatefulWidget {
  const EmailPage({super.key});

  @override
  ConsumerState<EmailPage> createState() => _EmailPageState();
}

class _EmailPageState extends ConsumerState<EmailPage> {
  final _sender = TextEditingController();
  final _subject = TextEditingController();
  final _body = TextEditingController();
  Map<String, dynamic>? _result;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _sender.dispose();
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    if (_loading) return;
    final strings = AppStrings(ref.read(localeProvider));
    if (_sender.text.trim().isEmpty &&
        _subject.text.trim().isEmpty &&
        _body.text.trim().isEmpty) {
      setState(() {
        _error = strings.emailInputRequired;
        _result = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await ref.read(apiProvider).post('/api/v1/scanner/email', {
        'sender': _sender.text.trim(),
        'subject': _subject.text.trim(),
        'body': _body.text,
      });
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = friendlyApiError(
            error,
            ukrainian: ref.read(localeProvider),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(ref.watch(localeProvider));
    return PageScaffold(
      title: strings.emailProtection,
      subtitle: strings.emailSubtitle,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final form = SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      strings.emailWorkspaceHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: GuardianSpace.lg),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final stacked = constraints.maxWidth < 620;
                        final senderField = TextField(
                          controller: _sender,
                          key: const Key('email-sender'),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) {
                            if (_error == strings.emailInputRequired) {
                              setState(() => _error = null);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: strings.sender,
                            hintText: strings.senderHint,
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                            ),
                          ),
                        );
                        final subjectField = TextField(
                          controller: _subject,
                          key: const Key('email-subject'),
                          onChanged: (_) {
                            if (_error == strings.emailInputRequired) {
                              setState(() => _error = null);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: strings.subject,
                            prefixIcon: const Icon(Icons.subject_rounded),
                          ),
                        );
                        if (stacked) {
                          return Column(
                            children: [
                              senderField,
                              const SizedBox(height: GuardianSpace.md),
                              subjectField,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: senderField),
                            const SizedBox(width: GuardianSpace.md),
                            Expanded(child: subjectField),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: GuardianSpace.md),
                    TextField(
                      controller: _body,
                      key: const Key('email-body'),
                      minLines: 6,
                      maxLines: 10,
                      onChanged: (_) {
                        if (_error == strings.emailInputRequired) {
                          setState(() => _error = null);
                        }
                      },
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        labelText: strings.message,
                        hintText: strings.emailBodyHint,
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 120),
                          child: Icon(Icons.mail_outline_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(height: GuardianSpace.md),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: GuardianSpace.sm,
                      runSpacing: GuardianSpace.xs,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 17,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        Text(
                          strings.emailPrivacy,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        Text(
                          '${_body.text.length} ${strings.characters}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: GuardianSpace.lg),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _analyze,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.manage_search_rounded),
                        label: Text(
                          _loading ? strings.loading : strings.analyzeEmail,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              final result = _EmailResultPanel(
                strings: strings,
                result: _result,
                error: _error,
                loading: _loading,
                onRetry: _analyze,
              );
              if (constraints.maxWidth < 940) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    form,
                    const SizedBox(height: GuardianSpace.lg),
                    result,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: form),
                  const SizedBox(width: GuardianSpace.lg),
                  Expanded(flex: 4, child: result),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmailResultPanel extends StatelessWidget {
  const _EmailResultPanel({
    required this.strings,
    required this.result,
    required this.error,
    required this.loading,
    required this.onRetry,
  });

  final AppStrings strings;
  final Map<String, dynamic>? result;
  final String? error;
  final bool loading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (result != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeading(strings.scanResult),
          const SizedBox(height: GuardianSpace.md),
          ScanResultCard(result: result!, strings: strings),
        ],
      );
    }
    if (error != null) {
      return ErrorPanel(
        message: error!,
        retryLabel: strings.retry,
        onRetry: onRetry,
      );
    }
    return SurfaceCard(
      padding: const EdgeInsets.all(GuardianSpace.xl),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: loading
            ? Column(
                key: const ValueKey('email-progress'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeading(strings.scanResult),
                  const SizedBox(height: GuardianSpace.lg),
                  const LinearProgressIndicator(),
                  const SizedBox(height: GuardianSpace.md),
                  Text(strings.loading),
                ],
              )
            : Column(
                key: const ValueKey('email-empty'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.mark_email_read_outlined,
                    color: GuardianColors.violet,
                    size: 26,
                  ),
                  const SizedBox(height: GuardianSpace.md),
                  Text(
                    strings.scanResult,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: GuardianSpace.sm),
                  Text(
                    strings.emailWorkspaceHint,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
