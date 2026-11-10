/// Lightweight input checks, not proof of account ownership or deliverability.
bool isValidAuthEmail(String value) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());

bool isValidTzPhone(String value) {
  final compact = value.replaceAll(RegExp(r'[\s()-]'), '');
  return RegExp(r'^(?:\+255|255|0)[67]\d{8}$').hasMatch(compact);
}
