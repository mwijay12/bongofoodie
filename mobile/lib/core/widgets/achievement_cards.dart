import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import '../../state/achievements_provider.dart';

/// Recognition only, never a coupon, rank, payment or delivery certification.
class AchievementCards extends StatelessWidget {
  const AchievementCards(
      {super.key, required this.progress, required this.isSw});
  final AchievementProgress progress;
  final bool isSw;

  @override
  Widget build(BuildContext context) {
    final badges = [
      (
        id: 'first-order',
        title: isSw ? 'Oda ya kwanza' : 'First order',
        criterion: isSw
            ? 'Tuma oda moja ukiwa umeingia.'
            : 'Submit one order while signed in.',
        count: progress.ordersSubmitted,
        target: 1
      ),
      (
        id: 'three-orders',
        title: isSw ? 'Oda tatu' : 'Three orders',
        criterion: isSw
            ? 'Tuma oda tatu ukiwa umeingia.'
            : 'Submit three orders while signed in.',
        count: progress.ordersSubmitted,
        target: 3
      ),
      (
        id: 'spice-quiz',
        title: isSw ? 'Mjuzi wa viungo' : 'Spice knowledge',
        criterion: isSw
            ? 'Jibu swali la siku kwa usahihi ukiwa umeingia.'
            : 'Answer a daily quiz correctly while signed in.',
        count: progress.correctQuizzes,
        target: 1
      ),
    ];
    final theme = Theme.of(context);
    return Column(children: [
      for (final badge in badges)
        Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: Semantics(
                container: true,
                label:
                    '${badge.title}. ${badge.criterion}. ${badge.count >= badge.target ? (isSw ? "Imepatikana" : "Earned") : (isSw ? "Bado haijapatikana" : "Not yet earned")}. ${badge.count.clamp(0, badge.target)}/${badge.target}',
                child: ExcludeSemantics(
                    child: Container(
                  padding: const EdgeInsets.all(AppSpace.md),
                  decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: Image.asset('assets/badges/${badge.id}.png',
                                width: AppSpace.xxl * 2,
                                height: AppSpace.xxl * 2,
                                cacheWidth: (AppSpace.xxl *
                                        2 *
                                        MediaQuery.devicePixelRatioOf(context))
                                    .round(),
                                errorBuilder: (_, __, ___) => const SizedBox(
                                    width: AppSpace.xxl * 2,
                                    height: AppSpace.xxl * 2,
                                    child: Icon(
                                        Icons.workspace_premium_outlined)))),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(badge.title,
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: AppSpace.xs),
                              Text(badge.criterion,
                                  style: theme.textTheme.bodyMedium),
                              const SizedBox(height: AppSpace.sm),
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                        badge.count >= badge.target
                                            ? Icons.check_circle_outline
                                            : Icons.lock_outline,
                                        size: AppSpace.lg,
                                        color: theme.colorScheme.onSurface),
                                    const SizedBox(width: AppSpace.xs),
                                    Expanded(
                                        child: Text(
                                            '${badge.count >= badge.target ? (isSw ? "Imepatikana" : "Earned") : (isSw ? "Bado haijapatikana" : "Not yet earned")} · ${badge.count.clamp(0, badge.target)}/${badge.target}',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w700))),
                                  ]),
                            ])),
                      ]),
                )))),
    ]);
  }
}
