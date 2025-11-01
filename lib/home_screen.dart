import 'package:flutter/material.dart';
import 'dart:ui';
import 'weather_service.dart';
import 'weather_model.dart';
import 'forecast_screen.dart';
import 'search_screen.dart';
import 'notification_service.dart';

class HomeScreen extends StatefulWidget {
  final String? cityName;

  const HomeScreen({Key? key, this.cityName}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  final NotificationService _notificationService = NotificationService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Weather? _weather;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _errorMessage = '';
  late String _currentCity;
  DateTime? _lastUpdateTime;
  late AnimationController _rotationController;

  // Settings
  String _temperatureUnit = '°C';
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _currentCity = widget.cityName ?? 'Ho Chi Minh';
    _rotationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _initializeNotifications();
    _fetchWeather();
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

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final weatherData = await _weatherService.getCurrentWeather(_currentCity);
      setState(() {
        _weather = Weather.fromJson(weatherData);
        _isLoading = false;
        _lastUpdateTime = DateTime.now();
      });

      if (_notificationsEnabled && _weather != null) {
        _sendWeatherNotifications();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendWeatherNotifications() async {
    if (_weather == null) return;

    await _notificationService.showWeatherNotification(
      cityName: _weather!.cityName,
      temperature: _weather!.temperature,
      description: _weather!.description,
      icon: _weather!.icon,
    );

    if (_weather!.temperature > 35) {
      await _notificationService.showTemperatureAlert(
        cityName: _weather!.cityName,
        temperature: _weather!.temperature,
        type: 'hot',
      );
    }

    if (_weather!.temperature < 15) {
      await _notificationService.showTemperatureAlert(
        cityName: _weather!.cityName,
        temperature: _weather!.temperature,
        type: 'cold',
      );
    }

    final description = _weather!.description.toLowerCase();
    if (description.contains('mưa') || description.contains('rain')) {
      await _notificationService.showRainAlert(
        cityName: _weather!.cityName,
        description: _weather!.description,
      );
    }

    if (description.contains('bão') || description.contains('storm') ||
        description.contains('giông') || description.contains('thunder')) {
      await _notificationService.showWeatherAlert(
        cityName: _weather!.cityName,
        alertMessage: 'Cảnh báo: ${_weather!.description}. Hãy cẩn thận!',
        severity: 'danger',
      );
    }
  }

  Future<void> _refreshWeather() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    _rotationController.repeat();

    try {
      final weatherData = await _weatherService.getCurrentWeather(_currentCity);
      setState(() {
        _weather = Weather.fromJson(weatherData);
        _lastUpdateTime = DateTime.now();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Đã cập nhật thành công!'),
              ],
            ),
            duration: Duration(seconds: 2),
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
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Không thể cập nhật'),
              ],
            ),
            duration: Duration(seconds: 2),
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

      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Color _getGradientColor() {
    if (_weather == null) {
      return Color(0xFF4A90E2);
    }

    final hour = DateTime.now().hour;
    final weatherMain = _weather!.description.toLowerCase();

    if (hour >= 18 || hour < 6) {
      return Color(0xFF1a237e);
    }

    if (weatherMain.contains('mưa') || weatherMain.contains('rain')) {
      return Color(0xFF546e7a);
    }

    if (weatherMain.contains('mây') || weatherMain.contains('cloud')) {
      return Color(0xFF607d8b);
    }

    return Color(0xFF4A90E2);
  }

  String _formatLastUpdate() {
    if (_lastUpdateTime == null) return 'Chưa có dữ liệu';

    final now = DateTime.now();
    final diff = now.difference(_lastUpdateTime!);

    if (diff.inSeconds < 60) {
      return 'Cập nhật ${diff.inSeconds}s trước';
    } else if (diff.inMinutes < 60) {
      return 'Cập nhật ${diff.inMinutes}m trước';
    } else {
      return 'Cập nhật ${diff.inHours}h trước';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getGradientColor(),
              _getGradientColor().withBlue((_getGradientColor().blue + 50).clamp(0, 255)),
              Color(0xFF9B59B6),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading && _weather == null
              ? Center(child: CircularProgressIndicator(color: Colors.white))
              : _errorMessage.isNotEmpty && _weather == null
              ? _buildErrorWidget()
              : _buildWeatherContent(),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
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
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withOpacity(0.3),
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
                      'by Nguyễn Khôi',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white30),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildDrawerItem(
                      icon: Icons.home,
                      title: 'Trang chủ',
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.search,
                      title: 'Tìm kiếm thành phố',
                      onTap: () async {
                        Navigator.pop(context);
                        final selectedCity = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SearchScreen()),
                        );

                        if (selectedCity != null && selectedCity is String) {
                          print('🏠 Drawer received: $selectedCity');
                          setState(() {
                            _currentCity = selectedCity;
                            _isLoading = true;
                          });
                          _fetchWeather();
                        }
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.calendar_today,
                      title: 'Dự báo 7 ngày',
                      onTap: () {
                        Navigator.pop(context);
                        if (_weather != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ForecastScreen(
                                cityName: _weather!.cityName,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.favorite,
                      title: 'Yêu thích',
                      subtitle: 'Đang phát triển',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Tính năng đang được phát triển!'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                    ),
                    Divider(color: Colors.white30),
                    _buildDrawerItem(
                      icon: Icons.thermostat,
                      title: 'Đơn vị nhiệt độ',
                      subtitle: _temperatureUnit,
                      trailing: Switch(
                        value: _temperatureUnit == '°C',
                        activeColor: Colors.white,
                        onChanged: (value) {
                          setState(() {
                            _temperatureUnit = value ? '°C' : '°F';
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    _buildDrawerItem(
                      icon: Icons.notifications,
                      title: 'Thông báo',
                      subtitle: _notificationsEnabled ? 'Bật' : 'Tắt',
                      trailing: Switch(
                        value: _notificationsEnabled,
                        activeColor: Colors.white,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });

                          if (value) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ Đã bật thông báo thời tiết'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            if (_weather != null) {
                              _notificationService.showWeatherNotification(
                                cityName: _weather!.cityName,
                                temperature: _weather!.temperature,
                                description: _weather!.description,
                                icon: _weather!.icon,
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Đã tắt thông báo thời tiết'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            _notificationService.cancelAll();
                          }
                        },
                      ),
                    ),
                    _buildDrawerItem(
                      icon: Icons.dark_mode,
                      title: 'Chế độ tối',
                      subtitle: 'Đang phát triển',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Tính năng đang được phát triển!'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                    ),
                    Divider(color: Colors.white30),
                    _buildDrawerItem(
                      icon: Icons.info,
                      title: 'Giới thiệu',
                      onTap: () {
                        Navigator.pop(context);
                        _showAboutDialog();
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.help,
                      title: 'Trợ giúp',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Liên hệ: support@weatherapp.com'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              Padding(
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
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: TextStyle(color: Colors.white60, fontSize: 12),
      )
          : null,
      trailing: trailing ?? Icon(Icons.chevron_right, color: Colors.white60),
      onTap: onTap,
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Giới thiệu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weather App v1.0.0'),
            SizedBox(height: 8),
            Text('Ứng dụng xem thời tiết'),
            SizedBox(height: 8),
            Text('Phát triển bởi: Your Name'),
            SizedBox(height: 8),
            Text('Powered by OpenWeatherMap API'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.white70),
          SizedBox(height: 16),
          Text(
            'Không thể tải dữ liệu',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchWeather,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text('Thử lại', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherContent() {
    if (_weather == null) return SizedBox();

    return RefreshIndicator(
      onRefresh: _refreshWeather,
      color: Colors.blue,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(height: 30),
              _buildMainWeather(),
              SizedBox(height: 30),
              _buildWeatherDetails(),
              SizedBox(height: 20),
              _buildForecastButton(),
              SizedBox(height: 12),
              _buildRefreshInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.menu, color: Colors.white, size: 24),
          ),
        ),
        GestureDetector(
          onTap: () async {
            // ← FIX: Nhận city name từ search screen
            final selectedCity = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SearchScreen()),
            );

            if (selectedCity != null && selectedCity is String) {
              print('🏠 Header received city: $selectedCity');
              setState(() {
                _currentCity = selectedCity;
                _isLoading = true;
              });
              _fetchWeather();
            }
          },
          child: Row(
            children: [
              Icon(Icons.location_on, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                _weather!.cityName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
            ],
          ),
        ),
        GestureDetector(
          onTap: _isRefreshing ? null : _refreshWeather,
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isRefreshing
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: RotationTransition(
              turns: _rotationController,
              child: Icon(
                Icons.refresh,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainWeather() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Image.network(
            _weatherService.getWeatherIconUrl(_weather!.icon),
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: 20),
        Text(
          '${_weather!.temperature.round()}°',
          style: TextStyle(
            color: Colors.white,
            fontSize: 72,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
        SizedBox(height: 8),
        Text(
          _weather!.description,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Cảm giác như ${_weather!.feelsLike.round()}°',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        SizedBox(height: 6),
        Text(
          _formatDate(_weather!.dateTime),
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherDetails() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildDetailCard(
          icon: Icons.air,
          label: 'Tốc độ gió',
          value: '${_weather!.windSpeed.toStringAsFixed(1)} km/h',
        ),
        _buildDetailCard(
          icon: Icons.water_drop,
          label: 'Độ ẩm',
          value: '${_weather!.humidity}%',
        ),
        _buildDetailCard(
          icon: Icons.visibility,
          label: 'Tầm nhìn',
          value: '${(_weather!.visibility / 1000).toStringAsFixed(1)} km',
        ),
        _buildDetailCard(
          icon: Icons.compress,
          label: 'Áp suất',
          value: '${_weather!.pressure} hPa',
        ),
      ],
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForecastButton() {
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
                    builder: (context) => ForecastScreen(cityName: _weather!.cityName),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: Padding(
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

  Widget _buildRefreshInfo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time,
                color: Colors.white70,
                size: 14,
              ),
              SizedBox(width: 6),
              Text(
                _formatLastUpdate(),
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final days = ['Chủ Nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'];
    final months = [
      'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
      'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'
    ];

    return '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]}';
  }
}