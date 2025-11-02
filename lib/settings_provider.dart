
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cache_service.dart';

/// Provider cho CacheService
final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

// ==================== DARK MODE ====================

/// Provider cho dark mode
final darkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  return DarkModeNotifier(ref);
});

class DarkModeNotifier extends StateNotifier<bool> {
  final Ref ref;

  DarkModeNotifier(this.ref) : super(false) {
    _loadDarkMode();
  }

  Future<void> _loadDarkMode() async {
    final cacheService = ref.read(cacheServiceProvider);
    final isDark = await cacheService.getDarkMode();
    state = isDark;
  }

  Future<void> toggle() async {
    state = !state;
    final cacheService = ref.read(cacheServiceProvider);
    await cacheService.setDarkMode(state);
    print('🌓 Dark mode: ${state ? "ON" : "OFF"}');
  }

  Future<void> setDarkMode(bool enabled) async {
    state = enabled;
    final cacheService = ref.read(cacheServiceProvider);
    await cacheService.setDarkMode(enabled);
  }
}

// ==================== TEMPERATURE UNIT ====================

/// Provider cho temperature unit (°C hoặc °F)
final temperatureUnitProvider = StateNotifierProvider<TempUnitNotifier, String>((ref) {
  return TempUnitNotifier(ref);
});

class TempUnitNotifier extends StateNotifier<String> {
  final Ref ref;

  TempUnitNotifier(this.ref) : super('°C') {
    _loadUnit();
  }

  Future<void> _loadUnit() async {
    final cacheService = ref.read(cacheServiceProvider);
    final unit = await cacheService.getTemperatureUnit();
    state = unit;
  }

  Future<void> setUnit(String unit) async {
    state = unit;
    final cacheService = ref.read(cacheServiceProvider);
    await cacheService.setTemperatureUnit(unit);
    print('🌡️ Temperature unit: $unit');
  }

  void toggle() {
    setUnit(state == '°C' ? '°F' : '°C');
  }
}

// ==================== NOTIFICATIONS ====================

/// Provider cho notifications enabled
final notificationsProvider = StateNotifierProvider<NotificationsNotifier, bool>((ref) {
  return NotificationsNotifier(ref);
});

class NotificationsNotifier extends StateNotifier<bool> {
  final Ref ref;

  NotificationsNotifier(this.ref) : super(true) {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final cacheService = ref.read(cacheServiceProvider);
    final enabled = await cacheService.getNotificationsEnabled();
    state = enabled;
  }

  Future<void> toggle() async {
    state = !state;
    final cacheService = ref.read(cacheServiceProvider);
    await cacheService.setNotificationsEnabled(state);
    print('🔔 Notifications: ${state ? "ON" : "OFF"}');
  }
}
