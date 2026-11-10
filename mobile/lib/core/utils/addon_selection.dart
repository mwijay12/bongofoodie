import '../../data/models/models.dart';

/// Optional binary choices: each linked addon is charged once per product unit.
/// Conflicting IDs or invalid prices are catalog errors, never free substitutions.
List<CustomizationOption> validatedAddons(
    Iterable<CustomizationOption> source) {
  final byId = <String, CustomizationOption>{};
  for (final option in source) {
    if (option.id.trim().isEmpty ||
        option.name.trim().isEmpty ||
        !option.price.isFinite ||
        option.price < 0) {
      throw const FormatException('Invalid addon');
    }
    final previous = byId[option.id];
    if (previous != null &&
        (previous.price != option.price ||
            previous.name != option.name ||
            previous.type != option.type)) {
      throw const FormatException('Conflicting addon ID');
    }
    byId[option.id] = option;
  }
  return List.unmodifiable(byId.values);
}

/// Supabase join rows. Empty is valid; missing/malformed joins are not.
List<CustomizationOption> linkedAddonsFromRows(dynamic rows) {
  if (rows is! List) throw const FormatException('Missing addon links');
  return validatedAddons(rows.map((row) {
    if (row is! Map || row['customizations'] is! Map) {
      throw const FormatException('Invalid addon link');
    }
    final nested = Map<String, dynamic>.from(row['customizations'] as Map);
    if (nested['price'] is! num) {
      throw const FormatException('Missing addon price');
    }
    return CustomizationOption.fromJson(nested);
  }));
}
