import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/design_system.dart';
import '../app/providers.dart';
import '../app/strings.dart';

class LearningPage extends ConsumerStatefulWidget {
  const LearningPage({super.key});

  @override
  ConsumerState<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends ConsumerState<LearningPage> {
  List<dynamic>? _lessons;
  final _searchController = TextEditingController();
  Set<String> _completed = {};
  List<dynamic> _quizResults = const [];
  String _level = 'all';
  String? _error;
  String? _progressError;
  bool _progressAvailable = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _progressError = null;
    });
    List<dynamic>? lessons;
    Map<String, dynamic>? progress;
    String? lessonsError;
    String? progressError;
    await Future.wait([
      () async {
        try {
          lessons = await ref
              .read(apiProvider)
              .getList('/api/v1/learning/lessons');
        } catch (error) {
          lessonsError = friendlyApiError(
            error,
            ukrainian: ref.read(localeProvider),
          );
        }
      }(),
      () async {
        try {
          progress = await ref
              .read(apiProvider)
              .getMap('/api/v1/learning/progress');
        } catch (error) {
          progressError = friendlyApiError(
            error,
            ukrainian: ref.read(localeProvider),
          );
        }
      }(),
    ]);
    if (mounted) {
      setState(() {
        if (lessons != null) _lessons = lessons;
        if (progress != null) {
          _completed = (progress!['completed_lessons'] as List<dynamic>? ?? [])
              .whereType<String>()
              .toSet();
          _quizResults =
              progress!['quiz_results'] as List<dynamic>? ?? const [];
          _progressAvailable = true;
        } else {
          _progressAvailable = false;
        }
        _error = lessonsError;
        _progressError = progressError;
        _loading = false;
      });
    }
  }

  String _titleFor(Map lesson, bool ukrainian) {
    final localized = lesson['localized_title'];
    if (localized is Map) {
      final candidate = localized[ukrainian ? 'uk' : 'en'];
      if (candidate is String && candidate.isNotEmpty) return candidate;
    }
    return lesson['title']?.toString() ?? '';
  }

  Future<void> _completeLesson(String id, BuildContext dialogContext) async {
    final nextCompleted = {..._completed, id};
    setState(() => _progressError = null);
    try {
      await ref.read(apiProvider).post('/api/v1/learning/progress', {
        'completed_lessons': nextCompleted.toList(),
        'quiz_results': _quizResults,
      });
      if (!mounted) return;
      setState(() => _completed = nextCompleted);
      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
    } catch (error) {
      if (mounted) {
        setState(
          () => _progressError = friendlyApiError(
            error,
            ukrainian: ref.read(localeProvider),
          ),
        );
      }
    }
  }

  void _openLesson(Map lesson, AppStrings strings) {
    final id = lesson['id']?.toString() ?? '';
    final title = _titleFor(lesson, strings.uk);
    final level = lesson['level']?.toString() ?? strings.unknownType;
    final body = switch (id) {
      'phishing' => strings.lessonPhishing,
      'passwords' => strings.lessonPasswords,
      'safe-browsing' => strings.lessonBrowsing,
      'qr-safety' => strings.lessonQr,
      _ => strings.articleNotProvided,
    };

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.menu_book_outlined, color: GuardianColors.cyan),
        title: Text(title),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusBadge(
                  label:
                      '${strings.lessonLevel}: ${_levelLabel(level, strings)}',
                  color: GuardianColors.cyan,
                ),
                const SizedBox(height: GuardianSpace.lg),
                SectionHeading(strings.lessonIntro),
                const SizedBox(height: GuardianSpace.sm),
                SelectableText(body),
                if (_progressError != null) ...[
                  const SizedBox(height: GuardianSpace.lg),
                  Text(
                    _progressError!,
                    style: const TextStyle(color: GuardianColors.danger),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: _completed.contains(id) || !_progressAvailable
                ? null
                : () => _completeLesson(id, dialogContext),
            child: Text(
              !_progressAvailable
                  ? strings.progressUnavailable
                  : _completed.contains(id)
                  ? strings.lessonCompleted
                  : strings.completeLesson,
            ),
          ),
        ],
      ),
    );
  }

  String _levelLabel(String level, AppStrings strings) => switch (level) {
    'beginner' => strings.beginner,
    'intermediate' => strings.intermediate,
    _ => level,
  };

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(ref.watch(localeProvider));
    final search = _searchController.text.trim().toLowerCase();
    final lessons = (_lessons ?? [])
        .whereType<Map>()
        .where((lesson) {
          final level = lesson['level']?.toString() ?? '';
          if (_level != 'all' && level != _level) return false;
          if (search.isEmpty) return true;
          return '${_titleFor(lesson, strings.uk)} ${lesson['title'] ?? ''}'
              .toLowerCase()
              .contains(search);
        })
        .toList(growable: false);

    return PageScaffold(
      title: strings.learningCenter,
      subtitle: strings.learningSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SurfaceCard(
            padding: const EdgeInsets.all(GuardianSpace.lg),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final searchField = TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    hintText: strings.searchHistory,
                  ),
                );
                final levelFilter = DropdownButtonFormField<String>(
                  initialValue: _level,
                  decoration: InputDecoration(labelText: strings.lessonLevel),
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text(strings.allCategories),
                    ),
                    DropdownMenuItem(
                      value: 'beginner',
                      child: Text(strings.beginner),
                    ),
                    DropdownMenuItem(
                      value: 'intermediate',
                      child: Text(strings.intermediate),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _level = value);
                  },
                );
                if (constraints.maxWidth < 640) {
                  return Column(
                    children: [
                      searchField,
                      const SizedBox(height: GuardianSpace.md),
                      levelFilter,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(flex: 2, child: searchField),
                    const SizedBox(width: GuardianSpace.md),
                    Expanded(child: levelFilter),
                  ],
                );
              },
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: GuardianSpace.lg),
            _LearningError(message: _error!, onRetry: _load, strings: strings),
          ],
          if (_progressError != null) ...[
            const SizedBox(height: GuardianSpace.md),
            Text(
              _progressError!,
              style: const TextStyle(color: GuardianColors.danger),
            ),
          ],
          const SizedBox(height: GuardianSpace.lg),
          if (_loading && _lessons == null)
            LoadingState(message: strings.loading)
          else if (!_loading && _error == null && _lessons!.isEmpty)
            EmptyState(
              icon: Icons.menu_book_outlined,
              title: strings.noLessons,
              message: strings.noLearningContent,
            )
          else if (!_loading && _error == null && lessons.isEmpty)
            EmptyState(
              icon: Icons.search_off_rounded,
              title: strings.noLessons,
              message: strings.noLessonsMatching,
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1080
                    ? 3
                    : constraints.maxWidth >= 680
                    ? 2
                    : 1;
                final gap = GuardianSpace.md;
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final lesson in lessons)
                      SizedBox(
                        width: width,
                        child: _LessonCard(
                          lesson: lesson,
                          title: _titleFor(lesson, strings.uk),
                          level: _levelLabel(
                            lesson['level']?.toString() ?? '',
                            strings,
                          ),
                          completed:
                              _progressAvailable &&
                              _completed.contains(lesson['id']?.toString()),
                          strings: strings,
                          onOpen: () => _openLesson(lesson, strings),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.title,
    required this.level,
    required this.completed,
    required this.strings,
    required this.onOpen,
  });

  final Map lesson;
  final String title;
  final String level;
  final bool completed;
  final AppStrings strings;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(GuardianSpace.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: GuardianColors.cyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(GuardianRadius.small),
              ),
              child: const Icon(
                Icons.menu_book_outlined,
                color: GuardianColors.cyan,
              ),
            ),
            const Spacer(),
            if (completed)
              StatusBadge(
                label: strings.lessonCompleted,
                color: GuardianColors.success,
                icon: Icons.check_circle_outline,
              ),
          ],
        ),
        const SizedBox(height: GuardianSpace.lg),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: GuardianSpace.sm),
        Text(
          '${strings.lessonLevel}: $level',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: GuardianSpace.lg),
        OutlinedButton.icon(
          onPressed: onOpen,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: Text(strings.openLesson),
        ),
      ],
    ),
  );
}

class _LearningError extends StatelessWidget {
  const _LearningError({
    required this.message,
    required this.onRetry,
    required this.strings,
  });

  final String message;
  final VoidCallback onRetry;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) =>
      ErrorPanel(message: message, retryLabel: strings.retry, onRetry: onRetry);
}
