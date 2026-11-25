import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/design_system.dart';
import '../app/providers.dart';
import '../app/strings.dart';

class PasswordPage extends ConsumerStatefulWidget {
  const PasswordPage({super.key});

  @override
  ConsumerState<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends ConsumerState<PasswordPage> {
  final _controller = TextEditingController();
  bool _obscure = true;
  int? _score;
  int? _groupCount;
  String? _feedback;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _analyze() {
    final password = _controller.text;
    final strings = AppStrings(ref.read(localeProvider));
    if (password.isEmpty) {
      setState(() {
        _score = null;
        _groupCount = null;
        _feedback = strings.passwordEmpty;
      });
      return;
    }

    final groups = <bool>[
      RegExp('[a-z]').hasMatch(password),
      RegExp('[A-Z]').hasMatch(password),
      RegExp('[0-9]').hasMatch(password),
      RegExp('[^A-Za-z0-9]').hasMatch(password),
    ];
    var score = switch (password.length) {
      >= 20 => 56,
      >= 16 => 47,
      >= 12 => 34,
      >= 8 => 21,
      _ => 8,
    };
    score += groups.where((present) => present).length * 9;
    if (RegExp(r'^(.)\1+$').hasMatch(password)) score -= 32;
    if (RegExp(
      r'^(0123|1234|2345|3456|4567|5678|6789|abcd|qwer)',
      caseSensitive: false,
    ).hasMatch(password)) {
      score -= 18;
    }
    if ({'password', '123456', 'qwerty'}.contains(password.toLowerCase())) {
      score = 2;
    }

    setState(() {
      _score = score.clamp(0, 100);
      _groupCount = groups.where((present) => present).length;
      _feedback = _score! >= 75
          ? strings.passwordStrongTip
          : strings.passwordWeakTip;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(ref.watch(localeProvider));
    final score = _score;
    final color = score == null
        ? GuardianColors.muted
        : score >= 75
        ? GuardianColors.success
        : score >= 45
        ? GuardianColors.warning
        : GuardianColors.danger;
    final strengthLabel = score == null
        ? strings.passwordStrength
        : score >= 75
        ? strings.strong
        : score >= 45
        ? strings.moderate
        : strings.weak;

    return PageScaffold(
      title: strings.passwordCenter,
      subtitle: strings.passwordSubtitle,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SurfaceCard(
                accent: GuardianColors.violet,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.passwordLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: GuardianSpace.md),
                    TextField(
                      controller: _controller,
                      key: const Key('password-input'),
                      obscureText: _obscure,
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: (_) => setState(() {
                        _score = null;
                        _groupCount = null;
                        _feedback = null;
                      }),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.key_rounded),
                        labelText: strings.passwordLabel,
                        suffixIcon: IconButton(
                          tooltip: _obscure
                              ? strings.showPassword
                              : strings.hidePassword,
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: GuardianSpace.lg),
                    FilledButton.icon(
                      onPressed: _analyze,
                      icon: const Icon(Icons.fact_check_outlined),
                      label: Text(strings.analyzeLocally),
                    ),
                    if (_feedback != null && score == null) ...[
                      const SizedBox(height: GuardianSpace.md),
                      Text(
                        _feedback!,
                        style: const TextStyle(color: GuardianColors.danger),
                      ),
                    ],
                  ],
                ),
              ),
              if (score != null) ...[
                const SizedBox(height: GuardianSpace.lg),
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              strengthLabel,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            '$score/100',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: GuardianSpace.md),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          GuardianRadius.pill,
                        ),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          minHeight: 9,
                          backgroundColor: color.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      const SizedBox(height: GuardianSpace.lg),
                      Wrap(
                        spacing: GuardianSpace.sm,
                        runSpacing: GuardianSpace.sm,
                        children: [
                          _PasswordFact(
                            label: strings.passwordLength,
                            value: '${_controller.text.length}',
                          ),
                          _PasswordFact(
                            label: strings.characterGroups,
                            value: '${_groupCount ?? 0}/4',
                          ),
                        ],
                      ),
                      const SizedBox(height: GuardianSpace.md),
                      Text(_feedback ?? ''),
                      const SizedBox(height: GuardianSpace.sm),
                      Text(
                        strings.heuristicDisclosure,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: GuardianSpace.lg),
              SurfaceCard(
                padding: const EdgeInsets.all(GuardianSpace.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: GuardianColors.success,
                    ),
                    const SizedBox(width: GuardianSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.localOnly,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: GuardianSpace.xs),
                          Text(strings.passwordPrivacy),
                        ],
                      ),
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

class _PasswordFact extends StatelessWidget {
  const _PasswordFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: GuardianColors.violet.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(GuardianRadius.small),
    ),
    child: Text('$label: $value'),
  );
}
