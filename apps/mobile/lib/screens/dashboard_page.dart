import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/design_system.dart';
import '../app/providers.dart';
import '../app/strings.dart';
import 'shared_widgets.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  Map<String, dynamic>? _statistics;
  List<dynamic>? _recentScans;
  String? _statisticsError;
  String? _historyError;
  String? _serviceVersion;
  bool _loadingStatistics = true;
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    await Future.wait([
      _loadStatistics(),
      _loadRecentScans(),
      _loadServiceHealth(),
    ]);
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _loadingStatistics = true;
      _statisticsError = null;
    });
    try {
      final value = await ref
          .read(apiProvider)
          .getMap('/api/v1/dashboard/statistics');
      if (mounted) setState(() => _statistics = value);
    } catch (error) {
      if (mounted) {
        setState(
          () => _statisticsError = friendlyApiError(
            error,
            ukrainian: ref.read(localeProvider),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingStatistics = false);
    }
  }

  Future<void> _loadRecentScans() async {
    setState(() {
      _loadingHistory = true;
      _historyError = null;
    });
    try {
      final value = await ref
          .read(apiProvider)
          .getMap('/api/v1/history?page=1&limit=5');
      final items = value['items'];
      if (mounted) {
        setState(() => _recentScans = items is List ? items : const []);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _historyError = friendlyApiError(
            error,
            ukrainian: ref.read(localeProvider),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _loadServiceHealth() async {
    try {
      final value = await ref.read(apiProvider).getMap('/api/v1/health');
      if (mounted) {
        setState(() => _serviceVersion = value['version']?.toString());
      }
    } catch (_) {
      if (mounted) setState(() => _serviceVersion = null);
    }
  }

  int _number(String key) {
    final value = _statistics?[key];
    return value is num ? value.toInt() : 0;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(ref.watch(localeProvider));
    return PageScaffold(
      title: strings.overview,
      subtitle: strings.dashboardSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_statisticsError != null) ...[
            ErrorPanel(
              message: _statisticsError!,
              retryLabel: strings.retry,
              onRetry: _load,
            ),
            const SizedBox(height: GuardianSpace.lg),
          ],
          if (_loadingStatistics && _statistics == null)
            const _DashboardSkeleton()
          else if (_statistics != null)
            _buildDashboard(context, strings),
          const SizedBox(height: GuardianSpace.xxl),
          SectionHeading(strings.quickActions),
          const SizedBox(height: GuardianSpace.md),
          _QuickActions(strings: strings),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, AppStrings strings) {
    final total = _number('total_scans');
    final rawScore = _statistics?['security_score'];
    final score = rawScore is num ? rawScore.toInt() : null;
    final hasMeaningfulScore = total > 0 && score != null;
    final threats = _number('threats_detected');
    final safe = _number('safe_scans');
    final elevated = (_number('suspicious_scans') - threats).clamp(0, 1 << 30);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProtectionSummary(
          strings: strings,
          score: hasMeaningfulScore ? score.toInt() : null,
          totalScans: total,
          healthVersion: _serviceVersion,
        ),
        const SizedBox(height: GuardianSpace.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 590 ? 2 : 4;
            final spacing = GuardianSpace.md;
            final cardWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: MetricCard(
                    icon: Icons.radar_rounded,
                    label: strings.totalScans,
                    value: '$total',
                    tint: GuardianColors.cyan,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: MetricCard(
                    icon: Icons.gpp_bad_outlined,
                    label: strings.threatsDetected,
                    value: '$threats',
                    tint: GuardianColors.danger,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: MetricCard(
                    icon: Icons.verified_user_outlined,
                    label: strings.safeScans,
                    value: '$safe',
                    tint: GuardianColors.success,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: MetricCard(
                    icon: Icons.insights_outlined,
                    label: strings.securityScore,
                    value: hasMeaningfulScore ? '$score/100' : '—',
                    tint: GuardianColors.violet,
                    caption: total == 0 ? strings.noScansYet : null,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: GuardianSpace.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 820;
            final chart = _RiskProfileChart(
              strings: strings,
              safe: safe,
              elevated: elevated,
              high: threats,
              total: total,
            );
            final recent = _RecentActivity(
              strings: strings,
              items: _recentScans,
              loading: _loadingHistory,
              error: _historyError,
              onRetry: _loadRecentScans,
            );
            if (stacked) {
              return Column(
                children: [
                  chart,
                  const SizedBox(height: GuardianSpace.lg),
                  recent,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: chart),
                const SizedBox(width: GuardianSpace.lg),
                Expanded(flex: 6, child: recent),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SurfaceCard(
        child: Row(
          children: [
            const SkeletonBlock(width: 108, height: 108, radius: 54),
            const SizedBox(width: GuardianSpace.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBlock(width: 150, height: 18),
                  const SizedBox(height: GuardianSpace.md),
                  SkeletonBlock(
                    width: MediaQuery.sizeOf(context).width * 0.3,
                    height: 24,
                  ),
                  const SizedBox(height: GuardianSpace.sm),
                  const SkeletonBlock(width: 360, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: GuardianSpace.lg),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 590 ? 2 : 4;
          final gap = GuardianSpace.md;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var index = 0; index < 4; index++)
                SurfaceCard(
                  padding: const EdgeInsets.all(GuardianSpace.lg),
                  child: SizedBox(
                    width: width - GuardianSpace.xl,
                    height: 76,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SkeletonBlock(width: 38, height: 38),
                        SkeletonBlock(width: 112, height: 14),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: GuardianSpace.lg),
      Row(
        children: [
          Expanded(
            child: SurfaceCard(
              child: Column(
                children: const [
                  SkeletonBlock(width: 160, height: 20),
                  SizedBox(height: GuardianSpace.lg),
                  SkeletonBlock(width: 175, height: 175, radius: 88),
                ],
              ),
            ),
          ),
          const SizedBox(width: GuardianSpace.lg),
          Expanded(
            flex: 2,
            child: SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBlock(width: 180, height: 20),
                  SizedBox(height: GuardianSpace.xl),
                  SkeletonBlock(width: 400, height: 40),
                  SizedBox(height: GuardianSpace.md),
                  SkeletonBlock(width: 350, height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _ProtectionSummary extends StatelessWidget {
  const _ProtectionSummary({
    required this.strings,
    required this.score,
    required this.totalScans,
    required this.healthVersion,
  });

  final AppStrings strings;
  final int? score;
  final int totalScans;
  final String? healthVersion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.all(GuardianSpace.xl),
      accent: GuardianColors.violet,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          final scoreView = SizedBox(
            width: 112,
            height: 112,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 104,
                  height: 104,
                  child: CircularProgressIndicator(
                    value: score == null ? 0 : (score! / 100).clamp(0, 1),
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    backgroundColor: theme.colorScheme.onSurface.withValues(
                      alpha: 0.08,
                    ),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      GuardianColors.cyan,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      score == null ? '—' : '$score',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: GuardianColors.cyan,
                      ),
                    ),
                    Text(
                      score == null ? '' : '/100',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
          final summary = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusBadge(
                label: totalScans == 0
                    ? strings.noScansYet
                    : strings.securityScore,
                color: totalScans == 0
                    ? GuardianColors.warning
                    : GuardianColors.cyan,
                icon: totalScans == 0
                    ? Icons.hourglass_empty_rounded
                    : Icons.shield_outlined,
              ),
              const SizedBox(height: GuardianSpace.md),
              Text(
                totalScans == 0 ? strings.noScansYet : strings.securityScore,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: GuardianSpace.sm),
              Text(
                strings.scoreFormula,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: GuardianSpace.md),
              Row(
                children: [
                  Icon(
                    healthVersion == null
                        ? Icons.cloud_outlined
                        : Icons.cloud_done_outlined,
                    size: 17,
                    color: healthVersion == null
                        ? GuardianColors.warning
                        : GuardianColors.success,
                  ),
                  const SizedBox(width: GuardianSpace.sm),
                  Text(
                    healthVersion == null
                        ? strings.apiNotChecked
                        : '${strings.apiConnected} · v$healthVersion',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                scoreView,
                const SizedBox(height: GuardianSpace.lg),
                summary,
              ],
            );
          }
          return Row(
            children: [
              scoreView,
              const SizedBox(width: GuardianSpace.xl),
              Expanded(child: summary),
            ],
          );
        },
      ),
    );
  }
}

class _RiskProfileChart extends StatelessWidget {
  const _RiskProfileChart({
    required this.strings,
    required this.safe,
    required this.elevated,
    required this.high,
    required this.total,
  });

  final AppStrings strings;
  final int safe;
  final int elevated;
  final int high;
  final int total;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(strings.riskProfile),
        const SizedBox(height: GuardianSpace.lg),
        if (total == 0)
          EmptyState(
            icon: Icons.pie_chart_outline_rounded,
            title: strings.noScansYet,
            message: strings.noDashboardData,
          )
        else ...[
          SizedBox(
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 48,
                    sections: [
                      if (safe > 0)
                        PieChartSectionData(
                          value: safe.toDouble(),
                          color: GuardianColors.success,
                          radius: 25,
                          showTitle: false,
                        ),
                      if (elevated > 0)
                        PieChartSectionData(
                          value: elevated.toDouble(),
                          color: GuardianColors.warning,
                          radius: 25,
                          showTitle: false,
                        ),
                      if (high > 0)
                        PieChartSectionData(
                          value: high.toDouble(),
                          color: GuardianColors.danger,
                          radius: 25,
                          showTitle: false,
                        ),
                    ],
                    centerSpaceColor: Colors.transparent,
                  ),
                ),
                Text(
                  '$total',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: GuardianSpace.md),
          _LegendLine(
            label: strings.lowRisk,
            value: safe,
            color: GuardianColors.success,
          ),
          _LegendLine(
            label: strings.elevatedRisk,
            value: elevated,
            color: GuardianColors.warning,
          ),
          _LegendLine(
            label: strings.highRisk,
            value: high,
            color: GuardianColors.danger,
          ),
        ],
      ],
    ),
  );
}

class _LegendLine extends StatelessWidget {
  const _LegendLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: GuardianSpace.xs),
    child: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: GuardianSpace.sm),
        Expanded(child: Text(label)),
        Text(
          '$value',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({
    required this.strings,
    required this.items,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final AppStrings strings;
  final List<dynamic>? items;
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
        if (loading && items == null)
          LoadingState(message: strings.loading)
        else if (error != null)
          ErrorPanel(
            message: error!,
            retryLabel: strings.retry,
            onRetry: onRetry,
          )
        else if (items == null || items!.isEmpty)
          EmptyState(
            icon: Icons.inbox_outlined,
            title: strings.noHistory,
            message: strings.noScansYet,
          )
        else
          for (final item in items!)
            if (item is Map) _ActivityItem(item: item, strings: strings),
      ],
    ),
  );
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({required this.item, required this.strings});

  final Map item;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final score = item['risk_score'] is num ? item['risk_score'] as num : null;
    final color = riskColor(score);
    final scanType = strings.scanTypeLabel(item['scan_type']);
    final date = item['created_at']?.toString() ?? '';
    final summary = item['summary']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GuardianSpace.sm),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(GuardianRadius.small),
            ),
            child: Icon(Icons.shield_outlined, size: 19, color: color),
          ),
          const SizedBox(width: GuardianSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scanType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: GuardianSpace.sm),
          StatusBadge(
            label: score == null ? '—' : '${score.toInt()}',
            color: color,
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: GuardianSpace.md,
    runSpacing: GuardianSpace.md,
    children: [
      _QuickAction(
        icon: Icons.link_rounded,
        label: strings.scanLink,
        color: GuardianColors.cyan,
        onTap: () => context.go('/link'),
      ),
      _QuickAction(
        icon: Icons.mark_email_read_outlined,
        label: strings.reviewEmail,
        color: GuardianColors.violet,
        onTap: () => context.go('/email'),
      ),
      _QuickAction(
        icon: Icons.monitor_heart_outlined,
        label: strings.checkProcesses,
        color: GuardianColors.warning,
        onTap: () => context.go('/processes'),
      ),
    ],
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, color: color),
    label: Text(label),
  );
}
