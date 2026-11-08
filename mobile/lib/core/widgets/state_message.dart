import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/settings_provider.dart';
import '../theme/app_tokens.dart';

class StateMessage extends ConsumerWidget {
  const StateMessage.error({super.key, this.onRetry})
      : title = null, body = null, actionLabel = null, onAction = null, _error = true;
  const StateMessage.empty({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  }) : onRetry = null, _error = false;

  final String? title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onRetry;
  final bool _error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final theme = Theme.of(context);
    final action = _error ? onRetry : onAction;
    final label = _error ? strings.retry : actionLabel;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSpace.navHeight,
              height: AppSpace.navHeight,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(_error ? Icons.wifi_off_rounded : Icons.inbox_rounded,
                  color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(_error ? strings.errorTitle : title!,
                textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpace.sm),
            Text(_error ? strings.errorBody : body!,
                textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            if (action != null && label != null) ...[
              const SizedBox(height: AppSpace.lg),
              FilledButton.tonal(onPressed: action, child: Text(label)),
            ],
          ],
        ),
      ),
    );
  }
}
