import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/design_system.dart';
import '../app/providers.dart';
import '../app/strings.dart';
import 'shared_widgets.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  static const _pageSize = 20;

  final _searchController = TextEditingController();
  Timer? _searchTimer;
  List<dynamic>? _items;
  String? _error;
  String _scanType = 'all';
  String _severity = 'all';
  String _dateRange = 'all';
  String _sort = 'newest';
  int _page = 1;
  int _total = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final query = <String, String>{
      'page': '$_page',
      'limit': '$_pageSize',
      'sort': _sort,
    };
    if (_scanType != 'all') query['scan_type'] = _scanType;
    final search = _searchController.text.trim();
    if (search.isNotEmpty) query['q'] = search;
    final path = Uri(
      path: '/api/v1/history',
      queryParameters: query,
    ).toString();

    try {
      final response = await ref.read(apiProvider).getMap(path);
      final items = response['items'];
      if (items is! List) {
        throw const FormatException('History response did not contain items.');
      }
      if (mounted) {
        setState(() {
          _items = items;
          _total = response['total'] is num
              ? (response['total'] as num).toInt()
              : items.length;
        });
      }
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

  void _searchChanged(String _) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _page = 1);
      _load();
    });
  }

  void _changeScanType(String? value) {
    if (value == null) return;
    setState(() {
      _scanType = value;
      _page = 1;
    });
    _load();
  }

  void _changeSort(String? value) {
    if (value == null) return;
    setState(() {
      _sort = value;
      _page = 1;
    });
    _load();
  }

  Future<void> _delete(String id) async {
    final strings = AppStrings(ref.read(localeProvider));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline, color: GuardianColors.danger),
        title: Text(strings.deleteScan),
        content: Text(strings.deleteScanConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: GuardianColors.danger,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(apiProvider).dio.delete('/api/v1/history/$id');
      if (!mounted) return;
      if ((_items?.length ?? 0) <= 1 && _page > 1) {
        setState(() => _page -= 1);
      }
      await _load();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = friendlyApiError(
            error,
            ukrainian: ref.read(localeProvider),
          ),
        );
      }
    }
  }

  List<dynamic> _visibleItems() {
    final now = DateTime.now();
    final cutoff = switch (_dateRange) {
      'day' => now.subtract(const Duration(days: 1)),
      'week' => now.subtract(const Duration(days: 7)),
      'month' => now.subtract(const Duration(days: 30)),
      _ => null,
    };

    return (_items ?? [])
        .where((item) {
          if (item is! Map) return false;
          final score = item['risk_score'] is num
              ? item['risk_score'] as num
              : null;
          if (_severity == 'low' && (score == null || score >= 20)) {
            return false;
          }
          if (_severity == 'elevated' &&
              (score == null || score < 20 || score >= 40)) {
            return false;
          }
          if (_severity == 'high' && (score == null || score < 40)) {
            return false;
          }
          if (cutoff != null) {
            final created = DateTime.tryParse(
              item['created_at']?.toString() ?? '',
            );
            if (created == null || created.isBefore(cutoff)) return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(ref.watch(localeProvider));
    final visible = _visibleItems();
    final pageCount = (_total / _pageSize).ceil().clamp(1, 1 << 30);

    return PageScaffold(
      title: strings.threatHistory,
      subtitle: strings.historySubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SurfaceCard(
            padding: const EdgeInsets.all(GuardianSpace.lg),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 760;
                final search = TextField(
                  controller: _searchController,
                  onChanged: _searchChanged,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    hintText: strings.searchHistory,
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: strings.cancel,
                            onPressed: () {
                              _searchController.clear();
                              _searchChanged('');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                );
                final type = _FilterDropdown(
                  label: strings.scanType,
                  value: _scanType,
                  items: [
                    ('all', strings.allTypes),
                    ('url', strings.urlType),
                    ('email', strings.emailType),
                    ('qr', strings.qrType),
                  ],
                  onChanged: _changeScanType,
                );
                final sort = _FilterDropdown(
                  label: strings.sortBy,
                  value: _sort,
                  items: [
                    ('newest', strings.newestFirst),
                    ('oldest', strings.oldestFirst),
                    ('risk_high', strings.highestRiskFirst),
                    ('risk_low', strings.lowestRiskFirst),
                  ],
                  onChanged: _changeSort,
                );
                if (stacked) {
                  return Column(
                    children: [
                      search,
                      const SizedBox(height: GuardianSpace.md),
                      type,
                      const SizedBox(height: GuardianSpace.md),
                      _buildLocalFilters(strings),
                      const SizedBox(height: GuardianSpace.md),
                      sort,
                    ],
                  );
                }
                return Column(
                  children: [
                    search,
                    const SizedBox(height: GuardianSpace.md),
                    Row(
                      children: [
                        Expanded(child: type),
                        const SizedBox(width: GuardianSpace.md),
                        Expanded(
                          child: _FilterDropdown(
                            label: strings.severity,
                            value: _severity,
                            items: [
                              ('all', strings.allLevels),
                              ('low', strings.lowRisk),
                              ('elevated', strings.elevatedRisk),
                              ('high', strings.highRisk),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _severity = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: GuardianSpace.md),
                    Row(
                      children: [
                        Expanded(
                          child: _FilterDropdown(
                            label: strings.dateRange,
                            value: _dateRange,
                            items: [
                              ('all', strings.anyDate),
                              ('day', strings.lastDay),
                              ('week', strings.lastWeek),
                              ('month', strings.lastMonth),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _dateRange = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: GuardianSpace.md),
                        Expanded(child: sort),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: GuardianSpace.lg),
            ErrorPanel(
              message: _error!,
              retryLabel: strings.retry,
              onRetry: _load,
            ),
          ],
          const SizedBox(height: GuardianSpace.lg),
          if (_loading && _items == null)
            LoadingState(message: strings.loading)
          else if (!_loading && _items != null && visible.isEmpty)
            EmptyState(
              icon: Icons.search_off_rounded,
              title: _items!.isEmpty
                  ? strings.noHistory
                  : strings.noHistoryMatching,
              message: _items!.isEmpty
                  ? strings.noScansYet
                  : strings.noHistoryMatching,
              action: _items!.isEmpty
                  ? FilledButton.icon(
                      onPressed: () => context.go('/link'),
                      icon: const Icon(Icons.radar_rounded),
                      label: Text(strings.scanLink),
                    )
                  : null,
            )
          else
            Column(
              children: [
                for (final item in visible)
                  if (item is Map)
                    Padding(
                      padding: const EdgeInsets.only(bottom: GuardianSpace.md),
                      child: _HistoryCard(
                        item: item,
                        strings: strings,
                        onDelete: () => _delete(item['id']?.toString() ?? ''),
                      ),
                    ),
              ],
            ),
          if (_total > _pageSize) ...[
            const SizedBox(height: GuardianSpace.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _page <= 1 || _loading
                      ? null
                      : () {
                          setState(() => _page -= 1);
                          _load();
                        },
                  icon: const Icon(Icons.chevron_left_rounded),
                  label: Text(strings.previousPage),
                ),
                const SizedBox(width: GuardianSpace.lg),
                Text('${strings.pageOf} $_page ${strings.of} $pageCount'),
                const SizedBox(width: GuardianSpace.lg),
                OutlinedButton.icon(
                  onPressed: _page >= pageCount || _loading
                      ? null
                      : () {
                          setState(() => _page += 1);
                          _load();
                        },
                  icon: const Icon(Icons.chevron_right_rounded),
                  label: Text(strings.nextPage),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocalFilters(AppStrings strings) => Column(
    children: [
      _FilterDropdown(
        label: strings.severity,
        value: _severity,
        items: [
          ('all', strings.allLevels),
          ('low', strings.lowRisk),
          ('elevated', strings.elevatedRisk),
          ('high', strings.highRisk),
        ],
        onChanged: (value) {
          if (value != null) setState(() => _severity = value);
        },
      ),
      const SizedBox(height: GuardianSpace.md),
      _FilterDropdown(
        label: strings.dateRange,
        value: _dateRange,
        items: [
          ('all', strings.anyDate),
          ('day', strings.lastDay),
          ('week', strings.lastWeek),
          ('month', strings.lastMonth),
        ],
        onChanged: (value) {
          if (value != null) setState(() => _dateRange = value);
        },
      ),
    ],
  );
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<(String, String)> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(
      labelText: label,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: GuardianSpace.md,
        vertical: GuardianSpace.xs,
      ),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        isDense: true,
        items: [
          for (final item in items)
            DropdownMenuItem(value: item.$1, child: Text(item.$2)),
        ],
        onChanged: onChanged,
      ),
    ),
  );
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.item,
    required this.strings,
    required this.onDelete,
  });

  final Map item;
  final AppStrings strings;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final score = item['risk_score'] is num ? item['risk_score'] as num : null;
    final color = riskColor(score);
    final type = strings.scanTypeLabel(item['scan_type']);
    final category = riskLabel(strings, item['risk_category']);
    final date = item['created_at']?.toString() ?? '';
    final summary = item['summary']?.toString() ?? '';

    return SurfaceCard(
      padding: const EdgeInsets.symmetric(
        horizontal: GuardianSpace.lg,
        vertical: GuardianSpace.md,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final metadata = Wrap(
            spacing: GuardianSpace.sm,
            runSpacing: GuardianSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusBadge(label: category, color: color),
              if (score != null)
                StatusBadge(
                  label: '${score.toInt()}/100',
                  color: color,
                  icon: Icons.speed_rounded,
                ),
            ],
          );
          final details = Expanded(
            child: InkWell(
              onTap: () => _showDetails(context),
              borderRadius: BorderRadius.circular(GuardianRadius.small),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: GuardianSpace.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (summary.isNotEmpty) ...[
                      const SizedBox(height: GuardianSpace.xs),
                      Text(
                        summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (date.isNotEmpty) ...[
                      const SizedBox(height: GuardianSpace.xs),
                      Text(
                        date,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined, color: color),
                    const SizedBox(width: GuardianSpace.sm),
                    details,
                    IconButton(
                      key: Key('delete-${item['id']}'),
                      tooltip: strings.delete,
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: GuardianSpace.sm),
                metadata,
              ],
            );
          }

          return Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(GuardianRadius.small),
                ),
                child: Icon(Icons.shield_outlined, color: color),
              ),
              const SizedBox(width: GuardianSpace.md),
              details,
              const SizedBox(width: GuardianSpace.md),
              metadata,
              const SizedBox(width: GuardianSpace.sm),
              IconButton(
                key: Key('delete-${item['id']}'),
                tooltip: strings.delete,
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final indicators = item['indicators'] is List
        ? (item['indicators'] as List)
              .map(
                (indicator) => indicator is Map
                    ? indicator['title']?.toString() ??
                          indicator['description']?.toString() ??
                          ''
                    : indicator.toString(),
              )
              .where((value) => value.isNotEmpty)
              .toList()
        : const <String>[];
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.scanDetails),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _DetailField(
                  label: strings.scanType,
                  value: strings.scanTypeLabel(item['scan_type']),
                ),
                _DetailField(
                  label: strings.severity,
                  value: riskLabel(strings, item['risk_category']),
                ),
                _DetailField(
                  label: strings.securityScore,
                  value: item['risk_score']?.toString() ?? '—',
                ),
                _DetailField(
                  label: strings.scanSummary,
                  value: item['summary']?.toString() ?? '—',
                ),
                if (item['created_at'] != null)
                  _DetailField(
                    label: strings.dateRange,
                    value: item['created_at'].toString(),
                  ),
                if (indicators.isNotEmpty) ...[
                  const SizedBox(height: GuardianSpace.md),
                  SectionHeading(strings.indicatorTitle),
                  for (final indicator in indicators)
                    Padding(
                      padding: const EdgeInsets.only(top: GuardianSpace.sm),
                      child: Text('• $indicator'),
                    ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
        ],
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: GuardianSpace.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: GuardianSpace.xs),
        SelectableText(value),
      ],
    ),
  );
}
