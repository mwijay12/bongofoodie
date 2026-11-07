import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/models.dart';
import '../data/repositories/menu_repository.dart';
import 'auth_provider.dart';

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  return ref.watch(menuRepositoryProvider).getCategories();
});

final promotionsProvider = FutureProvider<List<PromotionModel>>((ref) async {
  return ref.watch(menuRepositoryProvider).getPromotions();
});

final branchSettingsProvider = FutureProvider<BranchSettingsModel>((ref) async {
  return ref.watch(menuRepositoryProvider).getBranchSettings();
});

final allMenuItemsProvider = FutureProvider<List<MenuItemModel>>((ref) async {
  return ref.watch(menuRepositoryProvider).getMenu();
});

final dailyDiscoveriesProvider =
    StateNotifierProvider<DailyDiscoveriesNotifier, AsyncValue<List<DiscoveryModel>>>(
        (ref) {
  return DailyDiscoveriesNotifier(ref.watch(menuRepositoryProvider));
});

class DailyDiscoveriesNotifier
    extends StateNotifier<AsyncValue<List<DiscoveryModel>>> {
  final MenuRepository _repo;

  DailyDiscoveriesNotifier(this._repo) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.getDailyDiscoveries();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addDiscovery(String title, String description) async {
    await _repo.addDailyDiscovery(title, description);
    await refresh();
  }

  Future<void> removeDiscovery(String id) async {
    await _repo.deleteDailyDiscovery(id);
    await refresh();
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  final repo = ref.watch(menuRepositoryProvider);
  final userId = ref.watch(authProvider.select((s) => s.user?.id));
  return FavoritesNotifier(repo, userId);
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  final MenuRepository _repo;
  final String? _userId;

  FavoritesNotifier(this._repo, this._userId) : super(<String>{}) {
    _load();
  }

  Future<void> _load() async {
    state = await _repo.getFavoriteIds(_userId);
  }

  Future<bool> toggle(String menuId) async {
    final added = await _repo.toggleFavorite(_userId, menuId);
    final updated = Set<String>.from(state);
    if (added) {
      updated.add(menuId);
    } else {
      updated.remove(menuId);
    }
    state = updated;
    return added;
  }
}
