import 'package:flutter/material.dart';

/// Present sheets above the shell and its floating navigation.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool? showDragHandle,
  Color? backgroundColor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    barrierColor: Theme.of(context).colorScheme.scrim.withOpacity(.45),
    showDragHandle: showDragHandle,
    backgroundColor: backgroundColor,
    builder: builder,
  );
}
