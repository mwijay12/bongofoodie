import 'package:flutter/material.dart';
import '../../data/models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../utils/emoji_sanitizer.dart';
import 'promo_dish_image.dart';
import 'app_icon.dart';
import '../icons/app_icon_key.dart';

/// Food leads the offer; text never shares the artwork's paint bounds.
class PromoOfferCard extends StatelessWidget {
  const PromoOfferCard(
      {super.key,
      required this.promotion,
      required this.actionLabel,
      required this.onTap});
  final PromotionModel promotion;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Remote color only chooses a curated campaign, never arbitrary text contrast.
    final hex =
        int.tryParse(promotion.bgColorHex.replaceAll('#', ''), radix: 16);
    final green = hex != null && ((hex >> 8) & 255) > ((hex >> 16) & 255);
    final foreground = green ? AppColors.surface : AppColors.ink;
    final title = stripEmoji(promotion.title);
    final subtitle = stripEmoji(promotion.subtitle);
    final badge = stripEmoji(promotion.badgeText);
    return Semantics(
      container: true,
      button: true,
      label: [title, badge, subtitle, actionLabel]
          .where((s) => s.isNotEmpty)
          .join('. '),
      onTap: onTap,
      // Compact carousel tile: clamp copy scaling so the card never balloons.
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: PromoCardMetrics.maxTextScale,
        child: ExcludeSemantics(
          child: InkWell(
            borderRadius: BorderRadius.circular(PromoCardMetrics.borderRadius),
            onTap: onTap,
            child: Ink(
              width: PromoCardMetrics.width,
              height: PromoCardMetrics.heightFor(context),
              padding: const EdgeInsets.all(PromoCardMetrics.padding),
              decoration: BoxDecoration(
                  gradient: green ? AppColors.promoGreen : AppColors.promoOrange,
                  borderRadius:
                      BorderRadius.circular(PromoCardMetrics.borderRadius)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      if (badge.isNotEmpty) ...[
                        AppIcon(
                            iconKey: promotion.iconKey ??
                                appIconKeyForText(
                                    '${promotion.title} ${promotion.badgeText}',
                                    fallback: AppIconKey.fire),
                            color: foreground,
                            size: AppSpace.v16),
                        const SizedBox(width: AppSpace.v6),
                        Expanded(
                            child: Text(badge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: foreground,
                                    fontSize: 11,
                                    height: 1.2,
                                    fontWeight: FontWeight.w800))),
                      ],
                    ]),
                    if (badge.isNotEmpty) const SizedBox(height: AppSpace.v4),
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: foreground,
                            fontSize: 14,
                            height: 1.15,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: AppSpace.v4),
                    Expanded(
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                          Expanded(
                              child: Text(subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: foreground,
                                      fontSize: 12,
                                      height: 1.25,
                                      fontWeight: FontWeight.w600))),
                          const SizedBox(width: PromoCardMetrics.imageGap),
                          PromoDishImage(imageRef: promotion.imageKey),
                        ])),
                    Row(children: [
                      Expanded(
                          child: Text(actionLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: foreground,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800))),
                      Icon(Icons.arrow_forward_rounded,
                          color: foreground, size: AppSpace.lg),
                    ]),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}
