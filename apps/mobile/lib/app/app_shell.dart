import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'design_system.dart';
import 'providers.dart';
import 'strings.dart';

enum _NavigationGroup { protection, intelligence, system }

enum _ApplicationMenuAction { settings, about }

class _Destination {
  const _Destination(this.path, this.icon, this.group, this.label);

  final String path;
  final IconData icon;
  final _NavigationGroup group;
  final String Function(AppStrings strings) label;
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static final _destinations = <_Destination>[
    _Destination(
      '/dashboard',
      Icons.shield_outlined,
      _NavigationGroup.protection,
      (strings) => strings.overview,
    ),
    _Destination(
      '/link',
      Icons.link_rounded,
      _NavigationGroup.protection,
      (strings) => strings.linkScanner,
    ),
    _Destination(
      '/email',
      Icons.mark_email_read_outlined,
      _NavigationGroup.protection,
      (strings) => strings.emailProtection,
    ),
    _Destination(
      '/qr',
      Icons.qr_code_scanner_rounded,
      _NavigationGroup.protection,
      (strings) => strings.qrScanner,
    ),
    _Destination(
      '/password',
      Icons.password_rounded,
      _NavigationGroup.protection,
      (strings) => strings.passwordCenter,
    ),
    _Destination(
      '/assistant',
      Icons.auto_awesome_outlined,
      _NavigationGroup.intelligence,
      (strings) => strings.assistant,
    ),
    _Destination(
      '/history',
      Icons.manage_search_rounded,
      _NavigationGroup.intelligence,
      (strings) => strings.threatHistory,
    ),
    _Destination(
      '/learning',
      Icons.school_outlined,
      _NavigationGroup.intelligence,
      (strings) => strings.learningCenter,
    ),
    _Destination(
      '/settings',
      Icons.tune_rounded,
      _NavigationGroup.system,
      (strings) => strings.settings,
    ),
    _Destination(
      '/processes',
      Icons.monitor_heart_outlined,
      _NavigationGroup.system,
      (strings) => strings.processSafety,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings(ref.watch(localeProvider));
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 820;
    final canExpand = width >= 1180;
    final expanded = canExpand && ref.watch(sidebarExpandedProvider);
    final index = _destinations.indexWhere(
      (destination) => destination.path == location,
    );
    final current = _destinations[index < 0 ? 0 : index];

    if (compact) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const _BrandMark(size: 30),
              const SizedBox(width: GuardianSpace.sm),
              Text(strings.appName),
            ],
          ),
          leading: Builder(
            builder: (context) => IconButton(
              tooltip: strings.openNavigation,
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu_rounded),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: GuardianSpace.md),
              child: _ApiStatusChip(compact: true),
            ),
          ],
        ),
        drawer: Drawer(
          width: 300,
          child: _NavigationPanel(
            selectedPath: location,
            expanded: true,
            onNavigate: (path) {
              Navigator.of(context).pop();
              context.go(path);
            },
          ),
        ),
        body: child,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _NavigationPanel(
            selectedPath: location,
            expanded: expanded,
            onNavigate: context.go,
          ),
          Expanded(
            child: Column(
              children: [
                _DesktopHeader(
                  current: current,
                  expanded: expanded,
                  showSidebarToggle: canExpand,
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationPanel extends ConsumerWidget {
  const _NavigationPanel({
    required this.selectedPath,
    required this.expanded,
    required this.onNavigate,
  });

  final String selectedPath;
  final bool expanded;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings(ref.watch(localeProvider));
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final destinations = AppShell._destinations;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: expanded ? 252 : 82,
      decoration: BoxDecoration(
        color: dark ? GuardianColors.sidebar : const Color(0xFFEFF2F8),
        border: Border(
          right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.7)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final panelExpanded = constraints.maxWidth >= 200;
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    panelExpanded ? 20 : 16,
                    18,
                    16,
                    22,
                  ),
                  child: Row(
                    children: [
                      const _BrandMark(size: 38),
                      if (panelExpanded) ...[
                        const SizedBox(width: GuardianSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.appName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                strings.workspace,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: panelExpanded ? 12 : 8,
                    ),
                    children: [
                      for (final group in _NavigationGroup.values) ...[
                        if (panelExpanded)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
                            child: Text(
                              _groupLabel(strings, group),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                letterSpacing: 1.15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        else if (group != _NavigationGroup.protection)
                          const SizedBox(height: GuardianSpace.md),
                        for (final destination in destinations.where(
                          (item) => item.group == group,
                        ))
                          _NavigationItem(
                            destination: destination,
                            selected: selectedPath == destination.path,
                            expanded: panelExpanded,
                            strings: strings,
                            onTap: () => onNavigate(destination.path),
                          ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    panelExpanded ? 14 : 8,
                    GuardianSpace.md,
                    panelExpanded ? 14 : 8,
                    GuardianSpace.md,
                  ),
                  child: _SidebarFooter(
                    expanded: panelExpanded,
                    strings: strings,
                    onLocaleChanged: () =>
                        ref.read(localeProvider.notifier).toggle(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _groupLabel(AppStrings strings, _NavigationGroup group) =>
      switch (group) {
        _NavigationGroup.protection => strings.protection,
        _NavigationGroup.intelligence => strings.intelligence,
        _NavigationGroup.system => strings.system,
      };
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.destination,
    required this.selected,
    required this.expanded,
    required this.strings,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final bool expanded;
  final AppStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = GuardianColors.violet;
    final foreground = selected
        ? selectedColor
        : theme.colorScheme.onSurfaceVariant;
    final background = selected
        ? selectedColor.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.16 : 0.11,
          )
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Tooltip(
        message: expanded ? '' : destination.label(strings),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(GuardianRadius.small),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(GuardianRadius.small),
            hoverColor: selectedColor.withValues(alpha: 0.08),
            child: SizedBox(
              height: 46,
              child: Row(
                children: [
                  if (selected)
                    Container(
                      width: 3,
                      height: 24,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        borderRadius: BorderRadius.circular(
                          GuardianRadius.pill,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 3),
                  SizedBox(width: expanded ? 13 : 11),
                  Icon(destination.icon, size: 19, color: foreground),
                  if (expanded) ...[
                    const SizedBox(width: GuardianSpace.md),
                    Expanded(
                      child: Text(
                        destination.label(strings),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: foreground,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({
    required this.expanded,
    required this.strings,
    required this.onLocaleChanged,
  });

  final bool expanded;
  final AppStrings strings;
  final VoidCallback onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Divider(color: theme.dividerColor.withValues(alpha: 0.7)),
        Tooltip(
          message: expanded
              ? ''
              : strings.uk
              ? strings.english
              : strings.ukrainian,
          child: InkWell(
            onTap: onLocaleChanged,
            borderRadius: BorderRadius.circular(GuardianRadius.small),
            child: SizedBox(
              height: 42,
              child: Row(
                mainAxisAlignment: expanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  const SizedBox(width: GuardianSpace.sm),
                  Icon(
                    Icons.translate_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  if (expanded) ...[
                    const SizedBox(width: GuardianSpace.md),
                    Expanded(
                      child: Text(
                        strings.language,
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                    Text(
                      strings.uk ? 'UA' : 'EN',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: GuardianColors.cyan,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: GuardianSpace.sm),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DesktopHeader extends ConsumerWidget {
  const _DesktopHeader({
    required this.current,
    required this.expanded,
    required this.showSidebarToggle,
  });

  final _Destination current;
  final bool expanded;
  final bool showSidebarToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings(ref.watch(localeProvider));
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 1440;
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: GuardianSpace.xl),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          if (showSidebarToggle) ...[
            IconButton(
              tooltip: expanded
                  ? strings.collapseSidebar
                  : strings.expandSidebar,
              onPressed: () =>
                  ref.read(sidebarExpandedProvider.notifier).toggle(),
              icon: Icon(
                expanded
                    ? Icons.keyboard_double_arrow_left_rounded
                    : Icons.keyboard_double_arrow_right_rounded,
              ),
            ),
            const SizedBox(width: GuardianSpace.sm),
          ],
          Flexible(
            child: Text(
              strings.workspace,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: GuardianSpace.sm),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 17,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Flexible(
            child: Text(
              current.label(strings),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          _ApiStatusChip(compact: compact),
          const SizedBox(width: GuardianSpace.md),
          IconButton(
            tooltip: strings.settings,
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: GuardianSpace.sm),
          const _BrandMark(size: 34),
          const SizedBox(width: GuardianSpace.xs),
          PopupMenuButton<_ApplicationMenuAction>(
            tooltip: strings.applicationMenu,
            onSelected: (action) {
              switch (action) {
                case _ApplicationMenuAction.settings:
                  context.go('/settings');
                case _ApplicationMenuAction.about:
                  showAboutDialog(
                    context: context,
                    applicationName: strings.appName,
                    applicationVersion: '2.0.0',
                    applicationIcon: const _BrandMark(size: 36),
                    children: [Text(strings.aboutDescription)],
                  );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _ApplicationMenuAction.settings,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.settings_outlined),
                  title: Text(strings.settings),
                ),
              ),
              PopupMenuItem(
                value: _ApplicationMenuAction.about,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline_rounded),
                  title: Text(strings.aboutApplication),
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
    );
  }
}

class _ApiStatusChip extends ConsumerWidget {
  const _ApiStatusChip({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings(ref.watch(localeProvider));
    final status = ref.watch(apiConnectivityProvider);
    final color = switch (status) {
      ApiConnectivity.unknown => GuardianColors.warning,
      ApiConnectivity.connected => GuardianColors.success,
      ApiConnectivity.unavailable => GuardianColors.danger,
    };
    final label = switch (status) {
      ApiConnectivity.unknown => strings.apiNotChecked,
      ApiConnectivity.connected => strings.apiConnected,
      ApiConnectivity.unavailable => strings.apiUnavailable,
    };

    return Tooltip(
      message: '${strings.apiStatus}: $label',
      child: StatusBadge(
        label: compact ? 'API' : label,
        color: color,
        icon: status == ApiConnectivity.unknown
            ? Icons.help_outline
            : status == ApiConnectivity.connected
            ? Icons.check_circle_outline
            : Icons.cloud_off_outlined,
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [GuardianColors.violet, GuardianColors.cyan],
      ),
      borderRadius: BorderRadius.circular(GuardianRadius.small),
      boxShadow: [
        BoxShadow(
          color: GuardianColors.violet.withValues(alpha: 0.24),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Icon(Icons.shield_rounded, size: size * 0.62, color: Colors.white),
  );
}
