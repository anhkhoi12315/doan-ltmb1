

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

/// Service quản lý cache và local storage
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;

  /// Khởi tạo SharedPreferences
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ==================== WEATHER CACHE ====================

  /// Lưu cache thời tiết
  Future<void> saveWeatherCache(String cityName, Map<String, dynamic> data) async {
    await initialize();
    final cacheKey = 'weather_cache_$cityName';
    final cacheData = {
      'data': data,
      'cached_at': DateTime.now().toIso8601String(),
    };
    await _prefs!.setString(cacheKey, jsonEncode(cacheData));
    print('💾 Cached weather for: $cityName');
  }

  /// Lấy cache thời tiết (null nếu expired hoặc không có)
  Future<Map<String, dynamic>?> getWeatherCache(String cityName) async {
    await initialize();
    final cacheKey = 'weather_cache_$cityName';
    final cached = _prefs!.getString(cacheKey);

    if (cached == null) return null;

    try {
      final cacheData = jsonDecode(cached) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(cacheData['cached_at']);
      final now = DateTime.now();

      // Kiểm tra expired (30 phút)
      if (now.difference(cachedAt) > CACHE_DURATION) {
        await _prefs!.remove(cacheKey);
        return null;
      }

      print('✅ Cache hit for: $cityName');
      return cacheData['data'] as Map<String, dynamic>;
    } catch (e) {
      print('❌ Cache error: $e');
      return null;
    }
  }

  /// Xóa cache của một thành phố
  Future<void> clearWeatherCache(String cityName) async {
    await initialize();
    await _prefs!.remove('weather_cache_$cityName');
  }

  // ==================== FAVORITES ====================

  /// Lưu danh sách yêu thích
  Future<void> saveFavorites(List<String> cities) async {
    await initialize();
    await _prefs!.setStringList(KEY_FAVORITES, cities);
    print('💾 Saved ${cities.length} favorite cities');
  }

  /// Lấy danh sách yêu thích
  Future<List<String>> getFavorites() async {
    await initialize();
    return _prefs!.getStringList(KEY_FAVORITES) ?? [];
  }

  /// Thêm thành phố vào yêu thích
  Future<void> addFavorite(String cityName) async {
    final favorites = await getFavorites();
    if (!favorites.contains(cityName)) {
      favorites.add(cityName);
      await saveFavorites(favorites);
    }
  }

  /// Xóa thành phố khỏi yêu thích
  Future<void> removeFavorite(String cityName) async {
    final favorites = await getFavorites();
    favorites.remove(cityName);
    await saveFavorites(favorites);
  }

  /// Kiểm tra thành phố có trong yêu thích không
  Future<bool> isFavorite(String cityName) async {
    final favorites = await getFavorites();
    return favorites.contains(cityName);
  }

  // ==================== SETTINGS ====================

  /// Lưu dark mode
  Future<void> setDarkMode(bool enabled) async {
    await initialize();
    await _prefs!.setBool(KEY_DARK_MODE, enabled);
  }

  /// Lấy dark mode
  Future<bool> getDarkMode() async {
    await initialize();
    return _prefs!.getBool(KEY_DARK_MODE) ?? false;
  }

  /// Lưu temperature unit
  Future<void> setTemperatureUnit(String unit) async {
    await initialize();
    await _prefs!.setString(KEY_TEMP_UNIT, unit);
  }

  /// Lấy temperature unit
  Future<String> getTemperatureUnit() async {
    await initialize();
    return _prefs!.getString(KEY_TEMP_UNIT) ?? '°C';
  }

  /// Lưu notifications enabled
  Future<void> setNotificationsEnabled(bool enabled) async {
    await initialize();
    await _prefs!.setBool(KEY_NOTIFICATIONS, enabled);
  }

  /// Lấy notifications enabled
  Future<bool> getNotificationsEnabled() async {
    await initialize();
    return _prefs!.getBool(KEY_NOTIFICATIONS) ?? true;
  }

  /// Lưu last selected city
  Future<void> setLastCity(String cityName) async {
    await initialize();
    await _prefs!.setString(KEY_LAST_CITY, cityName);
  }

  /// Lấy last selected city
  Future<String?> getLastCity() async {
    await initialize();
    return _prefs!.getString(KEY_LAST_CITY);
  }

  // ==================== UTILITIES ====================

  /// Xóa toàn bộ cache
  Future<void> clearAll() async {
    await initialize();
    await _prefs!.clear();
    print('🗑️ Cleared all cache');
  }

  /// Lấy kích thước cache (bytes)
  Future<int> getCacheSize() async {
    await initialize();
    int size = 0;
    final keys = _prefs!.getKeys();
    for (var key in keys) {
      final value = _prefs!.get(key);
      size += value.toString().length;
    }
    return size;
  }
}
