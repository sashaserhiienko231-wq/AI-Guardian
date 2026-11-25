import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/design_system.dart';
import '../app/providers.dart';
import '../app/strings.dart';

class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});

  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send({String? retryText}) async {
    if (_sending) return;
    final message = (retryText ?? _controller.text).trim();
    if (message.isEmpty) return;

    setState(() {
      if (retryText == null) {
        _messages.add(_ChatMessage(role: 'user', text: message));
        _controller.clear();
      } else {
        _messages.removeWhere((item) => item.failedPrompt == retryText);
      }
      _sending = true;
    });
    _scrollToLatest();

    try {
      final response = await ref.read(apiProvider).post(
        '/api/v1/assistant/chat',
        {'message': message},
      );
      final answer = response['answer'];
      if (answer is! String || answer.trim().isEmpty) {
        throw const FormatException('The assistant returned no answer.');
      }
      if (mounted) {
        setState(
          () => _messages.add(_ChatMessage(role: 'assistant', text: answer)),
        );
      }
    } catch (error) {
      if (mounted) {
        final strings = AppStrings(ref.read(localeProvider));
        setState(
          () => _messages.add(
            _ChatMessage(
              role: 'error',
              text: friendlyApiError(
                error,
                ukrainian: ref.read(localeProvider),
              ),
              failedPrompt: message,
              retryLabel: strings.retryMessage,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToLatest();
      }
    }
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(ref.watch(localeProvider));
    final chatHeight = (MediaQuery.sizeOf(context).height - 350)
        .clamp(280.0, 620.0)
        .toDouble();

    return PageScaffold(
      title: strings.assistant,
      subtitle: strings.assistantSubtitle,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            children: [
              _DisclosureBanner(strings: strings),
              const SizedBox(height: GuardianSpace.md),
              SizedBox(
                height: chatHeight,
                child: SurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      Expanded(
                        child: _messages.isEmpty && !_sending
                            ? _ChatEmptyState(strings: strings)
                            : ListView.builder(
                                key: const Key('assistant-messages'),
                                controller: _scrollController,
                                reverse: true,
                                padding: const EdgeInsets.all(GuardianSpace.lg),
                                itemCount:
                                    _messages.length + (_sending ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (_sending && index == 0) {
                                    return _ThinkingBubble(
                                      label: strings.assistantThinking,
                                    );
                                  }
                                  final messageIndex =
                                      _messages.length -
                                      1 -
                                      index +
                                      (_sending ? 1 : 0);
                                  if (messageIndex < 0 ||
                                      messageIndex >= _messages.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return _MessageBubble(
                                    message: _messages[messageIndex],
                                    onRetry: (text) => _send(retryText: text),
                                  );
                                },
                              ),
                      ),
                      Divider(height: 1, color: Theme.of(context).dividerColor),
                      Padding(
                        padding: const EdgeInsets.all(GuardianSpace.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                key: const Key('assistant-input'),
                                minLines: 1,
                                maxLines: 4,
                                maxLength: 5000,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _send(),
                                decoration: InputDecoration(
                                  hintText: strings.assistantHint,
                                  counterText: '',
                                  prefixIcon: const Icon(
                                    Icons.chat_bubble_outline,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: GuardianSpace.sm),
                            IconButton.filled(
                              tooltip: strings.send,
                              onPressed: _sending ? null : () => _send(),
                              icon: _sending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.arrow_upward_rounded),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: GuardianSpace.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  strings.localConversation,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.role,
    required this.text,
    this.failedPrompt,
    this.retryLabel,
  });

  final String role;
  final String text;
  final String? failedPrompt;
  final String? retryLabel;
}

class _DisclosureBanner extends StatelessWidget {
  const _DisclosureBanner({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(GuardianSpace.md),
    accent: GuardianColors.violet,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_awesome_outlined, color: GuardianColors.violet),
        const SizedBox(width: GuardianSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.aiDisclosureTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: GuardianSpace.xs),
              Text(
                strings.aiDisclosure,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(GuardianSpace.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.forum_outlined,
            color: GuardianColors.violet,
            size: 40,
          ),
          const SizedBox(height: GuardianSpace.md),
          Text(
            strings.assistantEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: GuardianSpace.md),
      padding: const EdgeInsets.all(GuardianSpace.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(GuardianRadius.medium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: GuardianSpace.sm),
          Text(label),
        ],
      ),
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.onRetry});

  final _ChatMessage message;
  final ValueChanged<String> onRetry;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final isError = message.role == 'error';
    final theme = Theme.of(context);
    final background = isUser
        ? GuardianColors.violet.withValues(alpha: 0.18)
        : isError
        ? GuardianColors.danger.withValues(alpha: 0.08)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.75);
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width < 700 ? 360 : 680,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: GuardianSpace.md),
          padding: const EdgeInsets.symmetric(
            horizontal: GuardianSpace.lg,
            vertical: GuardianSpace.md,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(GuardianRadius.medium),
              topRight: const Radius.circular(GuardianRadius.medium),
              bottomLeft: Radius.circular(isUser ? GuardianRadius.medium : 5),
              bottomRight: Radius.circular(isUser ? 5 : GuardianRadius.medium),
            ),
            border: isError
                ? Border.all(
                    color: GuardianColors.danger.withValues(alpha: 0.3),
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isUser)
                SelectableText(message.text)
              else if (isError)
                Text(
                  message.text,
                  style: TextStyle(color: theme.colorScheme.error),
                )
              else
                MarkdownBody(
                  data: message.text,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                    p: theme.textTheme.bodyMedium,
                    h1: theme.textTheme.headlineSmall,
                    h2: theme.textTheme.titleLarge,
                    h3: theme.textTheme.titleMedium,
                    code: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'Consolas',
                      backgroundColor: theme.colorScheme.onSurface.withValues(
                        alpha: 0.08,
                      ),
                    ),
                  ),
                ),
              if (message.failedPrompt != null) ...[
                const SizedBox(height: GuardianSpace.sm),
                TextButton.icon(
                  onPressed: () => onRetry(message.failedPrompt!),
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: Text(message.retryLabel ?? ''),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
