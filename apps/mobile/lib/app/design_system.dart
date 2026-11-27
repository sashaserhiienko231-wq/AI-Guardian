import 'package:flutter/material.dart';

abstract final class GuardianColors {
  static const background = Color(0xFF080B14);
  static const sidebar = Color(0xFF0D1220);
  static const surface = Color(0xFF121A2A);
  static const elevated = Color(0xFF192337);
  static const violet = Color(0xFF8B5CF6);
  static const cyan = Color(0xFF22C7F2);
  static const text = Color(0xFFF8FAFC);
  static const muted = Color(0xFF94A3B8);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const border = Color(0xFF263449);
}

abstract final class GuardianSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;
}

abstract final class GuardianRadius {
  static const small = 10.0;
  static const medium = 16.0;
  static const large = 22.0;
  static const pill = 999.0;
}

abstract final class GuardianTheme {
  static ThemeData dark() => _buildTheme(
    brightness: Brightness.dark,
    background: GuardianColors.background,
    surface: GuardianColors.surface,
    text: GuardianColors.text,
    muted: GuardianColors.muted,
  );

  static ThemeData light() => _buildTheme(
    brightness: Brightness.light,
    background: const Color(0xFFF5F7FB),
    surface: Colors.white,
    text: const Color(0xFF172033),
    muted: const Color(0xFF64748B),
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color text,
    required Color muted,
  }) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: GuardianColors.violet,
      brightness: brightness,
      primary: GuardianColors.violet,
      secondary: GuardianColors.cyan,
      surface: surface,
      error: GuardianColors.danger,
    );
    final outline = dark ? GuardianColors.border : const Color(0xFFE2E8F0);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      dividerColor: outline,
      textTheme:
          (dark
                  ? Typography.material2021().white
                  : Typography.material2021().black)
              .apply(
                bodyColor: text,
                displayColor: text,
                fontFamily: 'Segoe UI',
              ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GuardianRadius.medium),
          side: BorderSide(color: outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF0D1422) : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        hintStyle: TextStyle(color: muted),
        labelStyle: TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GuardianRadius.small),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GuardianRadius.small),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GuardianRadius.small),
          borderSide: const BorderSide(
            color: GuardianColors.violet,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GuardianRadius.small),
          borderSide: const BorderSide(color: GuardianColors.danger),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 46),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GuardianRadius.small),
          ),
          overlayColor: GuardianColors.cyan.withValues(alpha: 0.12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GuardianRadius.small),
          ),
          side: BorderSide(color: outline),
          overlayColor: GuardianColors.violet.withValues(alpha: 0.1),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GuardianRadius.small),
          ),
        ),
      ),
      iconTheme: IconThemeData(color: muted),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: dark ? GuardianColors.elevated : const Color(0xFF172033),
          borderRadius: BorderRadius.circular(GuardianRadius.small),
        ),
        textStyle: const TextStyle(color: Colors.white),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GuardianRadius.small),
        ),
      ),
    );
  }
}

class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final horizontalPadding = constraints.maxWidth < 600
          ? GuardianSpace.lg
          : constraints.maxWidth < 1100
          ? GuardianSpace.xl
          : GuardianSpace.xxl;

      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            GuardianSpace.xl,
            horizontalPadding,
            GuardianSpace.xxl,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageHeading(title: title, subtitle: subtitle),
                  const SizedBox(height: GuardianSpace.xl),
                  child,
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style:
            (MediaQuery.sizeOf(context).width < 700
                    ? Theme.of(context).textTheme.headlineSmall
                    : Theme.of(context).textTheme.headlineMedium)
                ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      ),
      const SizedBox(height: GuardianSpace.xs),
      Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      ?trailing,
    ],
  );
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(GuardianSpace.xl),
    this.color,
    this.accent,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: color ?? theme.cardTheme.color,
        borderRadius: BorderRadius.circular(GuardianRadius.medium),
        border: Border.all(
          color:
              accent?.withValues(alpha: 0.3) ??
              theme.dividerColor.withValues(alpha: 0.65),
        ),
        boxShadow: theme.brightness == Brightness.dark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      padding: padding,
      child: child,
    );
  }
}

class InteractiveSurfaceCard extends StatefulWidget {
  const InteractiveSurfaceCard({
    super.key,
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.all(GuardianSpace.lg),
    this.accent,
  });

  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final Color? accent;

  @override
  State<InteractiveSurfaceCard> createState() => _InteractiveSurfaceCardState();
}

class _InteractiveSurfaceCardState extends State<InteractiveSurfaceCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(GuardianRadius.medium),
          border: Border.all(
            color:
                widget.accent?.withValues(alpha: _hovered ? 0.55 : 0.3) ??
                theme.dividerColor.withValues(alpha: _hovered ? 0.95 : 0.65),
          ),
          boxShadow: theme.brightness == Brightness.dark
              ? [
                  BoxShadow(
                    color: (_hovered ? GuardianColors.violet : Colors.black)
                        .withValues(alpha: _hovered ? 0.14 : 0.12),
                    blurRadius: _hovered ? 24 : 16,
                    offset: Offset(0, _hovered ? 10 : 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(GuardianRadius.medium),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(GuardianRadius.medium),
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
    this.caption,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  final String? caption;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(GuardianSpace.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(GuardianRadius.small),
              ),
              child: Icon(icon, size: 19, color: tint),
            ),
            const SizedBox(width: GuardianSpace.sm),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: tint,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: GuardianSpace.lg),
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        if (caption != null) ...[
          const SizedBox(height: GuardianSpace.xs),
          Text(
            caption!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    ),
  );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(GuardianRadius.pill),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
        ] else ...[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
        ],
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(GuardianSpace.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: GuardianColors.violet.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(GuardianRadius.medium),
            ),
            child: Icon(icon, color: GuardianColors.violet, size: 27),
          ),
          const SizedBox(height: GuardianSpace.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: GuardianSpace.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: GuardianSpace.lg),
            action!,
          ],
        ],
      ),
    ),
  );
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(GuardianSpace.xxl),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: GuardianSpace.md),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    required this.width,
    required this.height,
    this.radius = GuardianRadius.small,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class ErrorPanel extends StatelessWidget {
  const ErrorPanel({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    accent: GuardianColors.danger,
    padding: const EdgeInsets.all(GuardianSpace.lg),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: GuardianColors.danger),
        const SizedBox(width: GuardianSpace.md),
        Expanded(child: Text(message)),
        const SizedBox(width: GuardianSpace.md),
        TextButton(onPressed: onRetry, child: Text(retryLabel)),
      ],
    ),
  );
}
