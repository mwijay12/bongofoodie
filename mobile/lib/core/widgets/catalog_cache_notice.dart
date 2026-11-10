import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/menu_repository.dart';
import '../../state/menu_provider.dart';
import '../../state/settings_provider.dart';
import '../theme/app_tokens.dart';

class CatalogCacheNotice extends ConsumerWidget {
  const CatalogCacheNotice({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(catalogSourcesProvider);
    if (!sources.values.any((s) => s != CatalogSource.live))
      return const SizedBox.shrink();
    final sw = ref.watch(appStringsProvider).isSw;
    final stale = sources.values.contains(CatalogSource.stale);
    return Padding(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(sw
            ? (stale
                ? 'Taarifa zilizohifadhiwa zimepitwa na wakati. Bei zinaweza kubadilika.'
                : 'Unaona taarifa zilizohifadhiwa. Si uthibitisho wa upatikanaji.')
            : (stale
                ? 'Saved data is out of date. Prices may have changed.'
                : 'Showing saved data, not confirmed availability.')),
        TextButton(
            onPressed: () {
              ref.invalidate(allMenuItemsProvider);
              ref.invalidate(categoriesProvider);
              ref.invalidate(promotionsProvider);
              ref.read(dailyDiscoveriesProvider.notifier).refresh();
            },
            child: Text(sw ? 'Jaribu kupakia upya' : 'Retry refresh')),
      ]),
    );
  }
}
