import 'package:flutter/material.dart';

/// Semantic icon keys that replace emoji in widget labels and in remote seed
/// copy. No database column backs these keys: the UI resolves them from
/// existing fields or from title keywords, always with a safe default.
enum AppIconKey {
  fire(Icons.local_fire_department, 'Fire and grill'),
  rice(Icons.rice_bowl, 'Rice and pilau'),
  restaurant(Icons.restaurant, 'Restaurant'),
  idea(Icons.tips_and_updates, 'Daily tip'),
  trophy(Icons.emoji_events, 'Trivia award'),
  delivery(Icons.delivery_dining, 'Delivery rider'),
  location(Icons.location_on, 'Delivery address'),
  phone(Icons.call, 'Customer phone'),
  chat(Icons.chat_bubble_outline, 'Chef notes'),
  soup(Icons.soup_kitchen, 'Dish creator'),
  star(Icons.star_rounded, 'Top rated'),
  receipt(Icons.receipt_long, 'Receipt'),
  celebration(Icons.celebration, 'Celebration'),
  flag(Icons.flag, 'Language'),
  savings(Icons.savings, 'Savings'),
  fastfood(Icons.fastfood, 'Street food'),
  pizza(Icons.local_pizza, 'Pizza'),
  eco(Icons.eco, 'Coastal sourcing'),
  wave(Icons.waving_hand, 'Welcome'),
  gem(Icons.diamond_outlined, 'VIP'),
  sparkles(Icons.auto_awesome_rounded, 'Chef bespoke'),
  farm(Icons.agriculture, 'Farm sourcing'),
  bolt(Icons.bolt, 'Fast preparation');

  const AppIconKey(this.icon, this.label);

  /// The Material Icon mapped to this key.
  final IconData icon;

  /// A meaningful semantics label used by the AppIcon widget.
  final String label;
}

/// Resolves an icon from text that used to carry an emoji (promo title/badge
/// or discovery title). The database has no icon column, so this keyword map
/// over existing fields is the only source; [fallback] keeps it safe.
AppIconKey appIconKeyForText(
  String source, {
  AppIconKey fallback = AppIconKey.idea,
}) {
  final text = source.toLowerCase();
  bool matches(List<String> words) =>
      words.any((word) => text.contains(word));

  if (matches(const ['pilau', 'rice', 'wali', 'biriani', 'curry'])) {
    return AppIconKey.rice;
  }
  if (matches(const ['pizza', 'burger', 'smash'])) return AppIconKey.pizza;
  if (matches(const ['chips', 'fries', 'mayai', 'street icon'])) {
    return AppIconKey.fastfood;
  }
  if (matches(const [
    'zanzibar',
    'pwani',
    'coconut',
    'nazi',
    'karafuu',
    'clove',
    'palm',
    'sourcing',
    'organic',
    'farm',
    'coastal',
  ])) {
    return AppIconKey.eco;
  }
  if (matches(const [
    'mkaa',
    'grill',
    'choma',
    'feast',
    'spice',
    'pili',
    'fire',
    'hot',
  ])) {
    return AppIconKey.fire;
  }
  if (matches(const ['mishkaki', 'skewer', 'nyama', 'kitchen', 'dish'])) {
    return AppIconKey.restaurant;
  }
  if (matches(const ['boda', 'rider', 'delivery', 'live orders', 'queue'])) {
    return AppIconKey.delivery;
  }
  if (matches(const [
    'kijitonyama',
    'flagship',
    'address',
    'location',
    'pin',
  ])) {
    return AppIconKey.location;
  }
  if (matches(const ['phone', 'call', 'simu'])) return AppIconKey.phone;
  if (matches(const ['ongea', 'chef notes', 'chat', 'ask me'])) {
    return AppIconKey.chat;
  }
  if (matches(const ['buni', 'dish creator', 'pot', 'soup'])) {
    return AppIconKey.soup;
  }
  if (matches(const ['trivia', 'trophy', 'scholar', 'award', 'winner'])) {
    return AppIconKey.trophy;
  }
  if (matches(const ['top rated', 'rating', 'star'])) {
    return AppIconKey.star;
  }
  if (matches(const [
    'saving',
    'money',
    'lowest price',
    'discount',
    ' off',
    'tsh',
    '% off',
  ])) {
    return AppIconKey.savings;
  }
  if (matches(const ['receipt'])) return AppIconKey.receipt;
  if (matches(const ['bespoke', 'atelier', 'sparkle', 'chef ai'])) {
    return AppIconKey.sparkles;
  }
  if (matches(const ['vip', 'diamond', 'gem'])) return AppIconKey.gem;
  if (matches(const ['celebration', 'party', 'hongera', 'unlocked'])) {
    return AppIconKey.celebration;
  }
  if (matches(const ['fastest', 'prep', 'quick', 'voltage'])) {
    return AppIconKey.bolt;
  }
  if (matches(const ['flag', 'lugha', 'language'])) return AppIconKey.flag;
  if (matches(const ['welcome', 'karibu', 'wave'])) return AppIconKey.wave;
  return fallback;
}

/// Optional fromJson helper: accepts a nullable icon-key name and returns null
/// for missing or unknown values. No schema column is required.
AppIconKey? appIconKeyFromJson(Object? raw) {
  if (raw == null) return null;
  final name = raw.toString().trim();
  for (final key in AppIconKey.values) {
    if (key.name == name) return key;
  }
  return null;
}
