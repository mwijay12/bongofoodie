import 'dart:math';

abstract final class CheckoutValidation {
  static String? normalizeTzPhone(String input) {
    final digits = input.replaceAll(RegExp(r'[\s()\-]'), '');
    final normalized = digits.startsWith('0')
        ? '+255${digits.substring(1)}'
        : digits.startsWith('255')
            ? '+$digits'
            : digits;
    return RegExp(r'^\+255[67][0-9]{8}$').hasMatch(normalized)
        ? normalized
        : null;
  }

  // Input quality only: cannot prove a real person's identity or a reachable phone.
  static bool validName(String input) =>
      input.trim().length >= 2 &&
      input.trim().length <= 100 &&
      RegExp(r'[A-Za-z\u00C0-\u024F]').hasMatch(input) &&
      !RegExp(r'[\x00-\x1F]').hasMatch(input);
  static bool validAddress(String input) =>
      input.trim().length >= 10 && input.trim().length <= 500;
  static String newOrderId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return 'BF-${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
