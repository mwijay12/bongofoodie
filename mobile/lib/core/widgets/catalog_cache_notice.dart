import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/menu_repository.dart';
import '../../state/menu_provider.dart';
import '../../state/settings_provider.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Tells the truth about where the catalog came from.
///
/// Previously any failure collapsed into "check your connection", which was
/// wrong when the real cause was a paused Supabase project or missing keys.
class CatalogCacheNotice extends ConsumerWidget {
  const CatalogCacheNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final sw = strings.isSw;
    final status = SupabaseService.status;

    // Credentials were compiled in but the client could not start.
    // This is the case that used to masquerade as a network problem.
    if (status == SupabaseStatus.failed) {
      return _Notice(
        icon: Icons.cloud_off_rounded,
        color: AppColors.danger,
        title: sw ? 'Seva haipatikani' : 'Server unavailable',
        body: sw
            ? 'Programu imeshindwa kuunganisha data halisi. Inaonyesha data ya maonyesho kwa sasa.'
            : 'The app could not connect to the live catalog, so showcase data is shown instead.',
        detail: SupabaseService.failureReason,
        actionLabel: strings.retry,
        onAction: () => ref.invalidate(menuRepositoryProvider),
      );
    }

    // No credentials at all: intentional demo mode, not an error.
    if (status == SupabaseStatus.showcase) {
      return _Notice(
        icon: Icons.storefront_rounded,
        color: AppColors.primary,
        title: strings.showcaseNoticeTitle,
        body: strings.showcaseNoticeBody,
      );
    }

    // Live client, but some reads fell back to a saved snapshot.
    final sources = ref.watch(catalogSourcesProvider);
    final stale = sources.values.contains(CatalogSource.stale);
    final hasFallback =
        sources.values.any((s) => s != CatalogSource.live);
    if (!hasFallback) return const SizedBox.shrink();

    return _Notice(
      icon: Icons.sync_problem_rounded,
      color: AppColors.primary,
      title: sw
          ? (stale ? 'Taarifa zimepitwa na wakati' : 'Taarifa zilizohifadhiwa')
          : (stale ? 'Saved data is out of date' : 'Showing saved data'),
      body: sw
          ? (stale
              ? 'Bei zinaweza kubadilika. Hii si uthibitisho wa upatikanaji.'
              : 'Hii si uthibitisho wa upatikanaji.')
          : (stale
              ? 'Prices may have changed. This is not confirmed availability.'
              : 'This is not confirmed availability.'),
      actionLabel: sw ? 'Jaribu kupakia upya' : 'Retry refresh',
      onAction: () {
        ref.invalidate(allMenuItemsProvider);
        ref.invalidate(categoriesProvider);
        ref.invalidate(promotionsProvider);
        ref.read(dailyDiscoveriesProvider.notifier).refresh();
      },
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.detail,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.screenH, AppSpace.sm, AppSpace.screenH, AppSpace.sm),
        child: Container(
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(AppRadius.v14),
            border: Border.all(color: color.withOpacity(0.28)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: AppSpace.v20, color: color),
            const SizedBox(width: AppSpace.v10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: color)),
                    const SizedBox(height: AppSpace.v2),
                    Text(body,
                        style: const TextStyle(
                            fontSize: 11.5,
                            height: 1.3,
                            color: AppColors.inkMuted)),
                    if (detail != null && detail!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpace.v4),
                        child: Text(
                          detail!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 10.5,
                              height: 1.25,
                              color: AppColors.inkMuted,
                              fontFeatures: [FontFeature.tabularFigures()]),
                        ),
                      ),
                    if (actionLabel != null && onAction != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: onAction,
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, AppSpace.v32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: Text(actionLabel!,
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w800)),
                        ),
                      ),
                  ]),
            ),
          ]),
        ),
      );
}
