// lib/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'weather_model.dart';
import 'weather_provider.dart';
import 'settings_provider.dart';
import 'favorites_provider.dart';
import 'forecast_screen.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import 'weather_card.dart';
import 'notification_service.dart';
import 'constants.dart';

/// Home Screen với Riverpod
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {

  final NotificationService _notificationService = NotificationService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _rotationController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _refreshWeather() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    _rotationController.repeat();

    try {
      // Force refresh bằng cách invalidate provider
      ref.invalidate(currentWeatherProvider);
      await ref.read(currentWeatherProvider.future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Đã cập nhật thành công!'),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Không thể cập nhật'),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      _rotationController.stop();
      _rotationController.reset();
      setState(() => _isRefreshing = false);
    }
  }

  Color _getGradientColor(Weather? weather) {
    if (weather == null) return const Color(0xFF4A90E2);

    final hour = DateTime.now().hour;
    final weatherMain = weather.description.toLowerCase();

    if (hour >= 18 || hour < 6) {
      return const Color(0xFF1a237e);
    }

    if (weatherMain.contains('mưa') || weatherMain.contains('rain')) {
      return const Color(0xFF546e7a);
    }

    if (weatherMain.contains('mây') || weatherMain.contains('cloud')) {
      return const Color(0xFF607d8b);
    }

    return const Color(0xFF4A90E2);
  }

  @override
  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(currentWeatherProvider);
    final currentCity = ref.watch(selectedCityProvider);
    final temperatureUnit = ref.watch(temperatureUnitProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getGradientColor(weatherAsync.value),
              _getGradientColor(weatherAsync.value)
                  .withBlue((_getGradientColor(weatherAsync.value).blue + 50).clamp(0, 255)),
              const Color(0xFF9B59B6),
            ],
          ),
        ),
        child: SafeArea(
          child: weatherAsync.when(
            data: (weather) {
              // ← FIX: Watch isFavorite INSIDE data callback
              final isFavorite = ref.watch(isFavoriteCityProvider(weather.cityName));
              return _buildWeatherContent(weather, temperatureUnit, isFavorite);
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (error, stack) => _buildErrorWidget(error.toString()),
          ),
        ),
      ),
    );
  }


  Widget _buildDrawer() {
    final temperatureUnit = ref.watch(temperatureUnitProvider);
    final notificationsEnabled = ref.watch(notificationsProvider);
    final favoritesCount = ref.watch(favoritesCountProvider);

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4A90E2),
              Color(0xFF5B4FE3),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                child: const Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white30,
                      child: Icon(
                        Icons.wb_sunny,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Weather App',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'with Riverpod',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white30),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildDrawerItem(
                      icon: Icons.home,
                      title: 'Trang chủ',
                      onTap: () => Navigator.pop(context),
                    ),
                    _buildDrawerItem(
                      icon: Icons.search,
                      title: 'Tìm kiếm thành phố',
                      onTap: () async {
                        Navigator.pop(context);
                        final selectedCity = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SearchScreen()),
                        );
                        if (selectedCity != null && selectedCity is String) {
                          ref.read(selectedCityProvider.notifier).state = selectedCity;
                        }
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.favorite,
                      title: 'Yêu thích',
                      subtitle: '$favoritesCount thành phố',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                        );
                      },
                    ),
                    const Divider(color: Colors.white30),
                    _buildDrawerItem(
                      icon: Icons.settings,
                      title: 'Cài đặt',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.thermostat,
                      title: 'Đơn vị nhiệt độ',
                      subtitle: temperatureUnit,
                      trailing: Switch(
                        value: temperatureUnit == '°C',
                        activeColor: Colors.white,
                        onChanged: (value) {
                          ref.read(temperatureUnitProvider.notifier).toggle();
                        },
                      ),
                    ),
                    _buildDrawerItem(
                      icon: Icons.notifications,
                      title: 'Thông báo',
                      subtitle: notificationsEnabled ? 'Bật' : 'Tắt',
                      trailing: Switch(
                        value: notificationsEnabled,
                        activeColor: Colors.white,
                        onChanged: (value) {
                          ref.read(notificationsProvider.notifier).toggle();
                        },
                      ),
                    ),
                    const Divider(color: Colors.white30),
                    _buildDrawerItem(
                      icon: Icons.info,
                      title: 'Giới thiệu',
                      onTap: () {
                        Navigator.pop(context);
                        _showAboutDialog();
                      },
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12))
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.white60),
      onTap: onTap,
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Giới thiệu'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weather App v1.0.0'),
            SizedBox(height: 8),
            Text('Ứng dụng xem thời tiết với Riverpod'),
            SizedBox(height: 8),
            Text('Powered by OpenWeatherMap API'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.white70),
          const SizedBox(height: 16),
          const Text(
            'Không thể tải dữ liệu',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.invalidate(currentWeatherProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherContent(Weather weather, String temperatureUnit, bool isFavorite) {
    return RefreshIndicator(
      onRefresh: _refreshWeather,
      color: Colors.blue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(weather, isFavorite),
                const SizedBox(height: 20),
                WeatherCard(
                  weather: weather,
                  temperatureUnit: temperatureUnit,
                ),
                const SizedBox(height: 16),
                _buildForecastButton(weather),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildHeader(Weather weather, bool isFavorite) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Menu button
        GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.menu, color: Colors.white, size: 24),
          ),
        ),

        // City selector
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final selectedCity = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
              if (selectedCity != null && selectedCity is String) {
                ref.read(selectedCityProvider.notifier).state = selectedCity;
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    weather.cityName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),

        // Right buttons: Test Notification + Favorite + Refresh
        Row(
          children: [
            // TEST NOTIFICATION BUTTON (NEW!)
            // TEST NOTIFICATION BUTTON with debug
            GestureDetector(
              onTap: () async {
                print('🔔 Testing notification...');

                try {
                  // Request permission first
                  await _notificationService.requestPermissions();

                  // Show notification
                  await _notificationService.showWeatherNotification(
                    cityName: weather.cityName,
                    temperature: weather.temperature,
                    description: weather.description,
                    icon: weather.icon,
                  );

                  print('✅ Notification sent successfully!');

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 12),
                            Text('Đã gửi thông báo! Kiểm tra notification drawer'),
                          ],
                        ),
                        duration: Duration(seconds: 3),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  print('❌ Notification error: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),

            // Favorite button
            GestureDetector(
              onTap: () async {
                await ref.read(favoritesProvider.notifier).toggleFavorite(weather.cityName);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFavorite
                            ? 'Đã xóa khỏi yêu thích'
                            : 'Đã thêm vào yêu thích',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Refresh button
            GestureDetector(
              onTap: _isRefreshing ? null : _refreshWeather,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isRefreshing
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: RotationTransition(
                  turns: _rotationController,
                  child: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildForecastButton(Weather weather) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ForecastScreen(cityName: weather.cityName),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Xem dự báo 7 ngày',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
