
import 'package:flutter/material.dart';
import 'dart:ui';
import 'weather_service.dart';
import 'weather_model.dart';
import 'package:intl/intl.dart';

class ForecastScreen extends StatefulWidget {
  final String cityName;

  const ForecastScreen({super.key, required this.cityName});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen>
    with SingleTickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  List<Weather> _forecasts = [];
  bool _isLoading = true;
  String _errorMessage = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // ← FIX: Initialize here
    _fetchForecast();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchForecast() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final forecastData = await _weatherService.get5DayForecast(widget.cityName);
      List<Weather> forecasts = [];
      final list = forecastData['list'] as List;

      for (var item in list) {
        forecasts.add(Weather.fromJson({
          'name': widget.cityName,
          'main': item['main'],
          'weather': item['weather'],
          'wind': item['wind'],
          'visibility': item['visibility'] ?? 10000,
          'dt': item['dt'],
        }));
      }

      setState(() {
        _forecasts = forecasts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getGradientColor() {
    final hour = DateTime.now().hour;
    if (hour >= 18 || hour < 6) {
      return const Color(0xFF1a237e);
    }
    return const Color(0xFF4A90E2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getGradientColor(),
              _getGradientColor().withBlue((_getGradientColor().blue + 50).clamp(0, 255)),
              const Color(0xFF9B59B6),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (!_isLoading && _errorMessage.isEmpty) _buildTabBar(), // ← FIX: Only show when loaded
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _errorMessage.isNotEmpty
                    ? _buildErrorWidget()
                    : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDailyForecast(),
                    _buildHourlyForecast(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.cityName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Dự báo thời tiết',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: '📅 Theo ngày'),
          Tab(text: '⏰ Theo giờ'),
        ],
      ),
    );
  }

  Widget _buildDailyForecast() {
    // Group forecasts by day
    final dailyForecasts = <String, List<Weather>>{};
    for (var forecast in _forecasts) {
      final dateKey = DateFormat('yyyy-MM-dd').format(forecast.dateTime);
      dailyForecasts.putIfAbsent(dateKey, () => []).add(forecast);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: dailyForecasts.length,
      itemBuilder: (context, index) {
        final dateKey = dailyForecasts.keys.elementAt(index);
        final dayForecasts = dailyForecasts[dateKey]!;

        // Calculate stats
        final temps = dayForecasts.map((f) => f.temperature).toList();
        final maxTemp = temps.reduce((a, b) => a > b ? a : b);
        final minTemp = temps.reduce((a, b) => a < b ? a : b);

        // Get midday forecast for representative icon
        final mainForecast = dayForecasts[dayForecasts.length ~/ 2];

        return _buildDailyCard(
          date: DateFormat('dd/MM/yyyy').format(mainForecast.dateTime),
          dayName: _getDayName(mainForecast.dateTime),
          icon: mainForecast.icon,
          description: mainForecast.weatherStatusVN,
          maxTemp: maxTemp,
          minTemp: minTemp,
        );
      },
    );
  }

  Widget _buildHourlyForecast() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _forecasts.length,
      itemBuilder: (context, index) {
        final forecast = _forecasts[index];
        return _buildHourlyCard(forecast);
      },
    );
  }

  Widget _buildDailyCard({
    required String date,
    required String dayName,
    required String icon,
    required String description,
    required double maxTemp,
    required double minTemp,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Date
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Icon & Description
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Image.network(
                  _weatherService.getWeatherIconUrl(icon),
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.cloud,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Temperature
          Text(
            '${maxTemp.round()}° / ${minTemp.round()}°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyCard(Weather forecast) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Time
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('HH:mm').format(forecast.dateTime),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('dd/MM').format(forecast.dateTime),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Icon
          Image.network(
            _weatherService.getWeatherIconUrl(forecast.icon),
            width: 50,
            height: 50,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.cloud,
              color: Colors.white,
              size: 50,
            ),
          ),
          const SizedBox(width: 12),
          // Description
          Expanded(
            child: Text(
              forecast.weatherStatusVN,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          // Temperature
          Text(
            '${forecast.temperature.round()}°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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
          const Icon(Icons.error_outline, size: 64, color: Colors.white70),
          const SizedBox(height: 16),
          const Text(
            'Không thể tải dự báo',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchForecast,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  String _getDayName(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return 'Hôm nay';
    if (checkDate == today.add(const Duration(days: 1))) return 'Ngày mai';

    const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return days[date.weekday % 7];
  }
}
