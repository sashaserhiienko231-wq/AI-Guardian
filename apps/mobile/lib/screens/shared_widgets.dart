import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/design_system.dart';
import '../app/strings.dart';

String riskLabel(AppStrings strings, Object? value) {
  switch (value?.toString().toUpperCase()) {
    case 'SAFE':
    case 'LOW':
      return strings.riskSafe;
    case 'SUSPICIOUS':
    case 'MEDIUM':
      return strings.riskSuspicious;
    case 'MALICIOUS':
    case 'HIGH':
      return strings.riskMalicious;
    default:
      return value?.toString().isNotEmpty == true
          ? value.toString()
          : strings.riskUnknown;
  }
}

Color riskColor(num? score) {
  if (score == null) return GuardianColors.muted;
  if (score >= 40) return GuardianColors.danger;
  if (score >= 20) return GuardianColors.warning;
  return GuardianColors.success;
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map(
        (item) => {
          for (final entry in item.entries)
            if (entry.key is String) entry.key as String: entry.value,
        },
      )
      .toList(growable: false);
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList(growable: false);
}

class ScanResultCard extends StatelessWidget {
  const ScanResultCard({
    super.key,
    required this.result,
    required this.strings,
    this.link,
  });

  final Map<String, dynamic> result;
  final AppStrings strings;
  final String? link;

  Uri? _webUri() {
    final uri = Uri.tryParse(link?.trim() ?? '');
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        !{'http', 'https'}.contains(uri.scheme.toLowerCase())) {
      return null;
    }
    return uri;
  }

  Future<void> _openLink(BuildContext context) async {
    final uri = _webUri();
    if (uri == null) {
      _showMessage(context, strings.unsafeLink);
      return;
    }

    final score = result['risk_score'];
    if (score == null || score is! num || score >= 20) {
      final proceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: GuardianColors.warning,
            size: 36,
          ),
          title: Text(strings.suspiciousLinkTitle),
          content: Text(
            score is num
                ? strings.suspiciousLinkPrompt
                : strings.uncertainLinkPrompt,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(strings.openLink),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      _showMessage(context, strings.couldNotOpenLink);
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final rawScore = result['risk_score'];
    final score = rawScore is num ? rawScore : null;
    final color = riskColor(score);
    final indicators = _mapList(result['indicators']);
    final explanations = _stringList(result['explanations']);
    final actions = _stringList(result['recommended_actions']);
    final prediction = result['ml_prediction'];
    final predictionMap = prediction is Map
        ? {
            for (final entry in prediction.entries)
              if (entry.key is String) entry.key as String: entry.value,
          }
        : null;
    final webUri = _webUri();

    return SurfaceCard(
      accent: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(GuardianRadius.small),
                ),
                child: Icon(
                  score == null
                      ? Icons.help_outline
                      : score >= 40
                      ? Icons.gpp_bad_outlined
                      : score >= 20
                      ? Icons.warning_amber_rounded
                      : Icons.verified_user_outlined,
                  color: color,
                ),
              ),
              const SizedBox(width: GuardianSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      riskLabel(strings, result['risk_category']),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      strings.scanResult,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                score == null ? '—' : '${score.toInt()}/100',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: GuardianSpace.lg),
          if (score != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(GuardianRadius.pill),
              child: LinearProgressIndicator(
                value: (score / 100).clamp(0, 1).toDouble(),
                minHeight: 7,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          if (indicators.isNotEmpty) ...[
            const SizedBox(height: GuardianSpace.xl),
            SectionHeading(strings.indicatorTitle),
            const SizedBox(height: GuardianSpace.sm),
            for (final indicator in indicators)
              _DetailLine(
                icon: Icons.flag_outlined,
                text:
                    indicator['title']?.toString() ??
                    indicator['description']?.toString() ??
                    strings.riskUnknown,
              ),
          ],
          if (explanations.isNotEmpty) ...[
            const SizedBox(height: GuardianSpace.lg),
            SectionHeading(strings.explanations),
            const SizedBox(height: GuardianSpace.sm),
            for (final explanation in explanations)
              _DetailLine(icon: Icons.info_outline, text: explanation),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: GuardianSpace.lg),
            SectionHeading(strings.recommendedActions),
            const SizedBox(height: GuardianSpace.sm),
            for (final action in actions)
              _DetailLine(
                icon: Icons.arrow_forward_rounded,
                text: action,
                tint: GuardianColors.cyan,
              ),
          ],
          if (predictionMap != null) ...[
            const SizedBox(height: GuardianSpace.lg),
            SectionHeading(strings.modelPrediction),
            const SizedBox(height: GuardianSpace.sm),
            Text(
              '${strings.probabilisticPrediction}: ${predictionMap['prediction'] ?? '—'}',
            ),
            if (predictionMap['confidence'] != null)
              Text(
                '${strings.confidence}: ${predictionMap['confidence']}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: GuardianSpace.xs),
            Text(
              strings.notConfirmedThreat,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (webUri != null) ...[
            const SizedBox(height: GuardianSpace.xl),
            FilledButton.icon(
              onPressed: () => _openLink(context),
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(
                score == null || score >= 20
                    ? strings.reviewAndOpen
                    : strings.openLink,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text, this.tint});

  final IconData icon;
  final String text;
  final Color? tint;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: GuardianSpace.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Icon(
            icon,
            size: 16,
            color: tint ?? Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: GuardianSpace.sm),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
