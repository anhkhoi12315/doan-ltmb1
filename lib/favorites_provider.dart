

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cache_service.dart';
import 'settings_provider.dart';

/// Provider cho danh sách yêu thích
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, AsyncValue<List<String>>>((ref) {
  return FavoritesNotifier(ref);
});

class FavoritesNotifier extends StateNotifier<AsyncValue<List<String>>> {
  final Ref ref;

  FavoritesNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadFavorites();
  }

  /// Load favorites từ cache
  Future<void> _loadFavorites() async {
    try {
      final cacheService = ref.read(cacheServiceProvider);
      final favorites = await cacheService.getFavorites();
      state = AsyncValue.data(favorites);
      print('✅ Loaded ${favorites.length} favorites');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      print('❌ Error loading favorites: $e');
    }
  }

  /// Thêm thành phố vào yêu thích
  Future<void> addFavorite(String cityName) async {
    state.whenData((favorites) async {
      if (!favorites.contains(cityName)) {
        final updated = [...favorites, cityName];
        state = AsyncValue.data(updated);

        final cacheService = ref.read(cacheServiceProvider);
        await cacheService.saveFavorites(updated);

        print('⭐ Added to favorites: $cityName');
      }
    });
  }

  /// Xóa thành phố khỏi yêu thích
  Future<void> removeFavorite(String cityName) async {
    state.whenData((favorites) async {
      final updated = favorites.where((city) => city != cityName).toList();
      state = AsyncValue.data(updated);

      final cacheService = ref.read(cacheServiceProvider);
      await cacheService.saveFavorites(updated);

      print('🗑️ Removed from favorites: $cityName');
    });
  }

  /// Toggle favorite (add nếu chưa có, remove nếu đã có)
  Future<void> toggleFavorite(String cityName) async {
    state.whenData((favorites) async {
      if (favorites.contains(cityName)) {
        await removeFavorite(cityName);
      } else {
        await addFavorite(cityName);
      }
    });
  }

  /// Xóa tất cả favorites
  Future<void> clearAll() async {
    state = const AsyncValue.data([]);
    final cacheService = ref.read(cacheServiceProvider);
    await cacheService.saveFavorites([]);
    print('🗑️ Cleared all favorites');
  }

  /// Refresh favorites
  Future<void> refresh() async {
    await _loadFavorites();
  }
}

/// Provider kiểm tra một city có trong favorites không
final isFavoriteCityProvider = Provider.family<bool, String>((ref, cityName) {
  final favoritesAsync = ref.watch(favoritesProvider);
  return favoritesAsync.maybeWhen(
    data: (favorites) => favorites.contains(cityName),
    orElse: () => false,
  );
});

/// Provider lấy số lượng favorites
final favoritesCountProvider = Provider<int>((ref) {
  final favoritesAsync = ref.watch(favoritesProvider);
  return favoritesAsync.maybeWhen(
    data: (favorites) => favorites.length,
    orElse: () => 0,
  );
});
