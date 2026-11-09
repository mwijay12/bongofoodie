import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/settings_provider.dart';
import '../theme/app_tokens.dart';
import 'skeleton/shimmer.dart';
import 'state_message.dart';

class AsyncSkeleton<T> extends ConsumerWidget {
  const AsyncSkeleton({
    super.key,
    required this.value,
    required this.data,
    required this.skeleton,
    this.onRetry,
    this.isEmpty,
    this.empty,
    this.errorWidget,
  });
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget skeleton;
  final VoidCallback? onRetry;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.base,
      switchInCurve: AppMotion.enter,
      child: value.when(
        skipLoadingOnRefresh: true,
        loading: () => KeyedSubtree(
          key: const ValueKey('loading'),
          child: Semantics(
            label: strings.loading,
            child: ExcludeSemantics(child: Shimmer(child: skeleton)),
          ),
        ),
        error: (_, __) => KeyedSubtree(
          key: const ValueKey('error'),
          child: errorWidget ?? StateMessage.error(onRetry: onRetry),
        ),
        data: (d) => KeyedSubtree(
          key: const ValueKey('data'),
          child: (isEmpty?.call(d) ?? false) ? (empty ?? const SizedBox.shrink()) : data(d),
        ),
      ),
    );
  }
}
