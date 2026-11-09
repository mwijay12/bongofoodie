import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/emoji_sanitizer.dart';
import '../../core/config/env_config.dart';
import '../mock/showcase_seed_data.dart';
import '../models/models.dart';

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value.map((entry) => entry.toString()).toList();
  }
  if (value is String && value.trim().isNotEmpty) {
    final trimmed = value.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      final inner = trimmed.substring(1, trimmed.length - 1);
      if (inner.isEmpty) return const <String>[];
      return inner
          .split(',')
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList();
    }
    return <String>[trimmed];
  }
  return const <String>[];
}

final showcaseLatencyProvider = Provider<Duration>((ref) {
  if (SupabaseService.isLive) return Duration.zero;
  const configuredMs = int.fromEnvironment('SHOWCASE_LATENCY_MS', defaultValue: 700);
  return Duration(milliseconds: configuredMs < 0 ? 0 : configuredMs);
});

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepository(showcaseLatency: ref.watch(showcaseLatencyProvider));
});

class MenuRepository {
  MenuRepository({Duration? showcaseLatency})
      : _showcaseLatency = showcaseLatency ?? EnvConfig.showcaseLatency;
  final Duration _showcaseLatency;

  static const _dishReadTimeout = Duration(seconds: 10);
  static const _favPrefKey = 'bongo_favorites_v2';
  static const _discoveriesPrefKey = 'bongo_discoveries_v2';
  static const _quizDatePrefKey = 'bongo_quiz_date_v2';
  static const _quizWinsPrefKey = 'bongo_quiz_wins_v2';

  Future<List<CategoryModel>> getCategories() async {
    final sb = SupabaseService.client;
    if (sb == null && _showcaseLatency > Duration.zero) {
      await Future<void>.delayed(_showcaseLatency);
    }
    if (sb != null) {
      try {
        final rows = await sb
            .from('categories')
            .select('id, name, description')
            .order('sort_order', ascending: true);
        if (rows.isNotEmpty) {
          return rows
              .map<CategoryModel>(
                  (r) => CategoryModel.fromJson(Map<String, dynamic>.from(r)))
              .toList();
        }
      } catch (_) {}
    }
    return ShowcaseSeedData.categories;
  }

  Future<List<MenuItemModel>> getMenu({
    String category = '',
    String query = '',
  }) async {
    List<MenuItemModel> items = [];
    final sb = SupabaseService.client;
    if (sb == null && _showcaseLatency > Duration.zero) {
      await Future<void>.delayed(_showcaseLatency);
    }

    if (sb != null) {
      try {
        var req = sb.from('menu').select('''
          id,
          name,
          description,
          image_url,
          price,
          rating,
          rating_count,
          calories,
          protein,
          prep_time_mins,
          spice_level,
          ingredients,
          allergens,
          fun_fact_en,
          fun_fact_sw,
          category_id,
          categories ( id, name ),
          menu_customizations (
            customizations ( id, name, price, type )
          )
        ''');

        if (query.trim().isNotEmpty) {
          req = req.ilike('name', '%${query.trim()}%');
        }

        final rows = await req;
        if (rows.isNotEmpty) {
          items = rows.map<MenuItemModel>((raw) {
            final r = Map<String, dynamic>.from(raw);
            final catObj = r['categories'];
            final catMap = catObj is Map ? Map<String, dynamic>.from(catObj) : null;
            final rawLinks = r['menu_customizations'];
            final custList = <CustomizationOption>[];
            if (rawLinks is List) {
              for (final link in rawLinks) {
                if (link is Map && link['customizations'] is Map) {
                  custList.add(
                    CustomizationOption.fromJson(
                      Map<String, dynamic>.from(link['customizations'] as Map),
                    ),
                  );
                }
              }
            }

            return MenuItemModel(
              id: (r['id'] ?? '').toString(),
              name: stripEmoji((r['name'] ?? '').toString()),
              description: stripEmoji((r['description'] ?? '').toString()),
              imageUrl: (r['image_url'] ?? 'salad').toString(),
              price: (r['price'] as num?)?.toDouble() ?? 0,
              rating: (r['rating'] as num?)?.toDouble() ?? 4.8,
              ratingCount: (r['rating_count'] as num?)?.toInt() ?? 10,
              calories: (r['calories'] as num?)?.toInt() ?? 520,
              protein: (r['protein'] as num?)?.toInt() ?? 24,
              prepTimeMins: (r['prep_time_mins'] as num?)?.toInt() ?? 20,
              categoryId: (catMap?['id'] ?? r['category_id'] ?? '').toString(),
              categoryName: (catMap?['name'] ?? 'Swahili Bites').toString(),
              availableCustomizations: custList.isNotEmpty
                  ? custList
                  : ShowcaseSeedData.defaultSwahiliSides,
              spiceLevel: (r['spice_level'] as num?)?.toInt(),
              ingredients: _asStringList(r['ingredients']),
              allergens: _asStringList(r['allergens']),
              funFactEn: r['fun_fact_en']?.toString(),
              funFactSw: r['fun_fact_sw']?.toString(),
            );
          }).toList();
        }
      } catch (_) {}
    }

    if (items.isEmpty) {
      items = List<MenuItemModel>.from(ShowcaseSeedData.menuItems);
      if (query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        items = items
            .where((m) =>
                m.name.toLowerCase().contains(q) ||
                m.description.toLowerCase().contains(q))
            .toList();
      }
    }

    if (category.trim().isNotEmpty && category.toLowerCase() != 'all') {
      final target = category.trim().toLowerCase();
      items = items
          .where((m) =>
              m.categoryId.toLowerCase() == target ||
              m.categoryName.toLowerCase() == target)
          .toList();
    }

    return items;
  }

  Future<List<CustomizationOption>> getDishCustomizations(String dishId) async {
    final sb = SupabaseService.client;
    if (sb == null && _showcaseLatency > Duration.zero) {
      await Future<void>.delayed(_showcaseLatency);
    }
    if (sb != null && !dishId.startsWith('menu-')) {
      try {
        final rows = await sb
            .from('menu_customizations')
            .select('customizations ( id, name, price, type )')
            .eq('menu_id', dishId)
            .order('created_at', ascending: true)
            .timeout(_dishReadTimeout);
        final options = <CustomizationOption>[];
        for (final row in rows) {
          final customization = row['customizations'];
          if (customization is Map) {
            options.add(CustomizationOption.fromJson(
              Map<String, dynamic>.from(customization),
            ));
          }
        }
        if (options.isNotEmpty) return options;
      } catch (_) {}
    }

    final matches = ShowcaseSeedData.menuItems
        .where((item) => item.id == dishId)
        .toList();
    if (matches.isNotEmpty &&
        matches.first.availableCustomizations.isNotEmpty) {
      return matches.first.availableCustomizations;
    }
    return ShowcaseSeedData.defaultSwahiliSides;
  }

  Future<List<MenuReviewModel>> getDishReviews(String dishId) async {
    final sb = SupabaseService.client;
    if (sb == null && _showcaseLatency > Duration.zero) {
      await Future<void>.delayed(_showcaseLatency);
    }
    if (sb != null && !dishId.startsWith('menu-')) {
      try {
        final rows = await sb
            .from('menu_reviews')
            .select(
                'id, menu_id, profile_id, rating, comment, created_at, updated_at')
            .eq('menu_id', dishId)
            .order('created_at', ascending: false)
            .timeout(_dishReadTimeout);
        if (rows.isNotEmpty) {
          return rows
              .map<MenuReviewModel>((r) => MenuReviewModel.fromJson(
                    Map<String, dynamic>.from(r),
                  ))
              .toList();
        }
      } catch (_) {}
    }
    return ShowcaseSeedData.menuReviews
        .where((review) => review.menuId == dishId)
        .toList();
  }

  Future<List<PromotionModel>> getPromotions() async {
    final sb = SupabaseService.client;
    if (sb == null && _showcaseLatency > Duration.zero) {
      await Future<void>.delayed(_showcaseLatency);
    }
    if (sb != null) {
      try {
        final rows = await sb
            .from('promotions')
            .select('*')
            .eq('is_active', true)
            .order('sort_order', ascending: true);
        if (rows.isNotEmpty) {
          return rows.map<PromotionModel>((r) {
            final json = Map<String, dynamic>.from(r);
            // Remote-only safety net: legacy live rows may still carry emoji.
            for (final column in const [
              'title',
              'subtitle',
              'discount_badge',
            ]) {
              json[column] = stripEmoji((json[column] ?? '').toString());
            }
            return PromotionModel.fromJson(json);
          }).toList();
        }
      } catch (_) {}
    }
    return ShowcaseSeedData.promotions;
  }

  Future<BranchSettingsModel> getBranchSettings() async {
    final sb = SupabaseService.client;
    if (sb == null && _showcaseLatency > Duration.zero) {
      await Future<void>.delayed(_showcaseLatency);
    }
    if (sb != null) {
      try {
        final row = await sb
            .from('settings')
            .select('*')
            .eq('id', 'branch_settings')
            .maybeSingle();
        if (row != null) {
          return BranchSettingsModel.fromJson(Map<String, dynamic>.from(row));
        }
      } catch (_) {}
    }
    return const BranchSettingsModel();
  }

  Future<Set<String>> getFavoriteIds(String? userId) async {
    final sb = SupabaseService.client;
    if (sb == null && _showcaseLatency > Duration.zero) {
      await Future<void>.delayed(_showcaseLatency);
    }
    if (sb != null && userId != null && !userId.startsWith('demo-')) {
      try {
        final rows = await sb
            .from('favorites')
            .select('menu_id')
            .eq('profile_id', userId);
        return rows.map<String>((r) => r['menu_id'].toString()).toSet();
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_favPrefKey);
    return (saved ?? ['menu-nyama-choma', 'menu-pilau-kuku']).toSet();
  }

  Future<bool> toggleFavorite(String? userId, String menuId) async {
    final sb = SupabaseService.client;
    if (sb != null && userId != null && !userId.startsWith('demo-')) {
      try {
        final existing = await sb
            .from('favorites')
            .select('id')
            .eq('profile_id', userId)
            .eq('menu_id', menuId)
            .maybeSingle();
        if (existing != null) {
          await sb.from('favorites').delete().eq('id', existing['id']);
          return false;
        } else {
          await sb.from('favorites').insert({
            'profile_id': userId,
            'menu_id': menuId,
          });
          return true;
        }
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    final current =
        (prefs.getStringList(_favPrefKey) ?? ['menu-nyama-choma', 'menu-pilau-kuku'])
            .toSet();
    final added = !current.contains(menuId);
    if (added) {
      current.add(menuId);
    } else {
      current.remove(menuId);
    }
    await prefs.setStringList(_favPrefKey, current.toList());
    return added;
  }

  Future<double> rateDish({
    required String menuId,
    required int stars,
    String comment = '',
    double currentRating = 4.8,
  }) async {
    final sb = SupabaseService.client;
    if (sb != null && !menuId.startsWith('menu-')) {
      try {
        final res = await sb.rpc('rate_menu_item', params: {
          'p_menu_id': menuId,
          'p_rating': stars,
          'p_comment': comment,
        });
        if (res is Map && res['rating'] != null) {
          return (res['rating'] as num).toDouble();
        }
      } catch (_) {}
    }
    return double.parse((((currentRating * 8) + stars) / 9).toStringAsFixed(1));
  }

  Future<List<DiscoveryModel>> getDailyDiscoveries() async {
    final sb = SupabaseService.client;
    if (sb == null && _showcaseLatency > Duration.zero) {
      await Future<void>.delayed(_showcaseLatency);
    }
    if (sb != null) {
      try {
        final rows = await sb
            .from('daily_discoveries')
            .select('id, title, description')
            .eq('is_active', true)
            .order('created_at', ascending: false);
        if (rows.isNotEmpty) {
          return rows.map<DiscoveryModel>((r) {
            final json = Map<String, dynamic>.from(r);
            // Remote-only safety net; staff-authored local discoveries are
            // user-typed text and are not passed through stripEmoji.
            for (final column in const ['title', 'description']) {
              json[column] = stripEmoji((json[column] ?? '').toString());
            }
            return DiscoveryModel.fromJson(json);
          }).toList();
        }
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    final customRaw = prefs.getString(_discoveriesPrefKey);
    if (customRaw != null) {
      try {
        final list = jsonDecode(customRaw) as List;
        return list
            .whereType<Map>()
            .map((e) => DiscoveryModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {}
    }
    return ShowcaseSeedData.discoveries;
  }

  Future<void> addDailyDiscovery(String title, String description) async {
    final sb = SupabaseService.client;
    if (sb != null) {
      try {
        await sb.from('daily_discoveries').insert({
          'title': title,
          'description': description,
        });
        return;
      } catch (_) {}
    }

    final current = await getDailyDiscoveries();
    final updated = [
      DiscoveryModel(
        id: 'disc-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        description: description,
      ),
      ...current,
    ];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _discoveriesPrefKey,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> deleteDailyDiscovery(String id) async {
    final sb = SupabaseService.client;
    if (sb != null && !id.startsWith('disc-')) {
      try {
        await sb.from('daily_discoveries').delete().eq('id', id);
        return;
      } catch (_) {}
    }

    final current = await getDailyDiscoveries();
    final updated = current.where((d) => d.id != id).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _discoveriesPrefKey,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }

  Future<bool> hasAttemptedTriviaToday(String? userId) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final sb = SupabaseService.client;
    if (sb != null && userId != null && !userId.startsWith('demo-')) {
      try {
        final row = await sb
            .from('quiz_attempts')
            .select('id')
            .eq('profile_id', userId)
            .eq('quiz_date', today)
            .maybeSingle();
        if (row != null) return true;
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_quizDatePrefKey) == today;
  }

  Future<void> recordTriviaAttempt(String? userId, bool isCorrect) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final sb = SupabaseService.client;
    if (sb != null && userId != null && !userId.startsWith('demo-')) {
      try {
        await sb.from('quiz_attempts').insert({
          'profile_id': userId,
          'quiz_date': today,
          'is_correct': isCorrect,
        });
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_quizDatePrefKey, today);
    if (isCorrect) {
      final wins = prefs.getInt(_quizWinsPrefKey) ?? 1;
      await prefs.setInt(_quizWinsPrefKey, wins + 1);
    }
  }

  Future<int> getTriviaWinsCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_quizWinsPrefKey) ?? 1;
  }
}
