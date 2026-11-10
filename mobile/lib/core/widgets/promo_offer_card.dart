import 'package:flutter/material.dart';
import '../../data/models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../utils/emoji_sanitizer.dart';
import 'promo_dish_image.dart';

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
      button: true,
      label: [title, badge, subtitle, actionLabel]
          .where((s) => s.isNotEmpty)
          .join('. '),
      onTap: onTap,
      child: ExcludeSemantics(
          child: InkWell(
        borderRadius: BorderRadius.circular(PromoCardMetrics.borderRadius),
        onTap: onTap,
        child: Ink(
          width: PromoCardMetrics.width,
          height: PromoCardMetrics.height,
          padding: const EdgeInsets.all(PromoCardMetrics.padding),
          decoration: BoxDecoration(
              gradient: green ? AppColors.promoGreen : AppColors.promoOrange,
              borderRadius:
                  BorderRadius.circular(PromoCardMetrics.borderRadius)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
                height: PromoCardMetrics.imageSize,
                child: Row(children: [
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (badge.isNotEmpty) ...[
                        Text(badge,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: foreground,
                                fontSize: 12,
                                height: 1.2,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: AppSpace.sm),
                      ],
                      Text(title,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: foreground,
                              fontSize: 15,
                              height: 1.15,
                              fontWeight: FontWeight.w800)),
                    ],
                  )),
                  const SizedBox(width: PromoCardMetrics.imageGap),
                  PromoDishImage(imageRef: promotion.imageKey),
                ])),
            const SizedBox(height: AppSpace.v10),
            Text(subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: foreground,
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Row(children: [
              Expanded(
                  child: Text(actionLabel,
                      maxLines: 2,
                      style: TextStyle(
                          color: foreground,
                          fontSize: 13,
                          fontWeight: FontWeight.w800))),
              Icon(Icons.arrow_forward_rounded,
                  color: foreground, size: AppSpace.lg),
            ]),
          ]),
        ),
      )),
    );
  }
}
