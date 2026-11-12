import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/settings_provider.dart';
import '../services/supabase_service.dart';
import '../theme/app_tokens.dart';

/// What actually went wrong. The old widget used a wifi-off icon and
/// "check your connection" for every failure, including a paused server or an
/// empty database, which sent people looking in the wrong place.
enum ErrorKind {
  /// The device cannot reach the network at all.
  network,

  /// The server answered but rejected or failed the request (missing table,
  /// paused project, bad key). The connection is fine.
  server,

  /// Credentials were never configured; this is showcase mode, not a fault.
  configuration,
}

class StateMessage extends ConsumerWidget {
  const StateMessage.error({
    super.key,
    this.onRetry,
    this.compact = false,
    this.kind,
  })  : title = null,
        body = null,
        actionLabel = null,
        onAction = null,
        _error = true,
        _explicitKind = kind;

  const StateMessage.empty({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  })  : onRetry = null,
        _error = false,
        _explicitKind = null;

  final String? title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onRetry;
  final bool _error;
  final ErrorKind? _explicitKind;
  final bool compact;

  /// Inferred when the caller does not say. A configured-but-dead client is a
  /// server problem, not the user's network; missing keys are configuration.
  ErrorKind get _kind {
    if (_explicitKind != null) return _explicitKind!;
    return switch (SupabaseService.status) {
      SupabaseStatus.failed => ErrorKind.server,
      SupabaseStatus.showcase => ErrorKind.configuration,
      SupabaseStatus.live => ErrorKind.server,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final theme = Theme.of(context);
    final action = _error ? onRetry : onAction;
    final label = _error ? strings.retry : actionLabel;
    final pad = compact ? AppSpace.md : AppSpace.xl;
    final gap = compact ? AppSpace.sm : AppSpace.lg;
    final iconSize = compact ? AppSpace.navHeight - 24 : AppSpace.navHeight;

    final kind = _kind;
    final (titleText, bodyText, icon) = switch (kind) {
      ErrorKind.network => (
          strings.offlineTitle,
          strings.offlineBody,
          Icons.wifi_off_rounded
        ),
      ErrorKind.server => (
          strings.serverTitle,
          strings.serverBody,
          Icons.cloud_off_rounded
        ),
      ErrorKind.configuration => (
          strings.showcaseNoticeTitle,
          strings.showcaseNoticeBody,
          Icons.storefront_rounded
        ),
    };

    final resolvedTitle = _error ? titleText : title!;
    final resolvedBody = _error ? bodyText : body!;
    final resolvedIcon = _error ? icon : Icons.inbox_rounded;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(resolvedIcon,
                  color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(resolvedTitle,
                textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpace.sm),
            Text(resolvedBody,
                textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            // Only surface the technical reason when it is a server fault;
            // showing a raw exception for demo mode would be noise.
            if (_error && kind == ErrorKind.server) ...[
              if (SupabaseService.failureReason.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpace.xs),
                Text(
                  SupabaseService.failureReason,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ],
            if (action != null && label != null) ...[
              SizedBox(height: gap),
              FilledButton.tonal(onPressed: action, child: Text(label)),
            ],
          ],
        ),
      ),
    );
  }
}
