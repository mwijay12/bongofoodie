/// Render-time safety net for text that comes from remote data: Supabase rows
/// (promotions, daily discoveries, menu) and Chef AI replies. Legacy live rows
/// can still contain emoji until the strip migration is run.
///
/// NEVER call this on user-typed text (chat input, staff-authored discoveries,
/// search queries): it would delete characters a person deliberately entered.
///
/// Documented emoji ranges (Unicode scalar values):
///   U+1F000..U+1FAFF  pictographs, emoticons, transport, food, awards
///   U+1F1E6..U+1F1FF  regional indicators (flag pairs such as TZ / GB)
///   U+1F3FB..U+1F3FF  skin-tone modifiers
///   U+2600..U+27BF    miscellaneous symbols and dingbats (U+2728 sparkles)
///   U+2B00..U+2BFF    emoji-style stars / arrows (U+2B50 star)
///   U+FE0F            variation selector-16
///   U+200D            zero width joiner (ZWJ sequences, e.g. chef = man + ZWJ + pot)
///   U+20E3            combining enclosing keycap
///
/// Dart RegExp works on UTF-16 code units, so supplementary-plane ranges are
/// applied to runes. The BMP ranges and the ZWJ/variation/keycap joiners are
/// expressed as regex character classes built from numeric code points; this
/// file therefore contains no literal emoji characters. Swahili diacritics,
/// combining accents and ordinary punctuation are outside every range.
library;

/// BMP emoji ranges. Built from code points so the source stays emoji-free.
final RegExp _emojiRanges = RegExp(
  '[${String.fromCharCode(0x2600)}-${String.fromCharCode(0x27BF)}'
  '${String.fromCharCode(0x2B00)}-${String.fromCharCode(0x2BFF)}]',
);

/// Joiners that glue emoji into ZWJ sequences, flags and keycaps. Removing the
/// joiner first breaks the sequence; the rune pass then removes each pictograph.
final RegExp _zwjJoiners = RegExp(
  '[${String.fromCharCode(0x200D)}'
  '${String.fromCharCode(0xFE0F)}'
  '${String.fromCharCode(0x20E3)}]',
);

/// Gaps left behind when a pictograph (or a whole ZWJ sequence) disappears.
final RegExp _leftoverSpaces = RegExp(r' {2,}');

bool _isSupplementaryEmoji(int rune) =>
    (rune >= 0x1F000 && rune <= 0x1FAFF) ||
    (rune >= 0x1F1E6 && rune <= 0x1F1FF) ||
    (rune >= 0x1F3FB && rune <= 0x1F3FF);

/// Removes emoji code points and ZWJ / flag / keycap sequences from [input],
/// collapses leftover double spaces and trims the edges.
String stripEmoji(String input) {
  if (input.isEmpty) return input;
  // 1. Break ZWJ sequences by dropping joiners and variation selectors.
  final withoutJoiners = input.replaceAll(_zwjJoiners, '');
  // 2. Remove BMP dingbat / star ranges.
  final withoutRanges = withoutJoiners.replaceAll(_emojiRanges, '');
  // 3. Remove supplementary-plane pictographs, flags and skin tones.
  final buffer = StringBuffer();
  for (final rune in withoutRanges.runes) {
    if (!_isSupplementaryEmoji(rune)) {
      buffer.write(String.fromCharCode(rune));
    }
  }
  // 4. Collapse the spaces left behind, then trim leading/trailing space.
  return buffer.toString().replaceAll(_leftoverSpaces, ' ').trim();
}
