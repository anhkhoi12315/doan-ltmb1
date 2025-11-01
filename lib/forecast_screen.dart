import 'package:flutter/material.dart';
import 'dart:ui';
import 'weather_service.dart';
import 'weather_model.dart';

class ForecastScreen extends StatefulWidget {
  final String cityName;

  const ForecastScreen({super.key, required this.cityName});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  final WeatherService _weatherService = WeatherService();
  List<Weather> _forecasts = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchForecast();
  }

  Future<void> _fetchForecast() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final forecastData = await _weatherService.get5DayForecast(widget.cityName);

      // Parse forecast data
      List<Weather> forecasts = [];
      final list = forecastData['list'] as List;

      for (var item in list) {
        forecasts.add(Weather.fromJson({
          'name': widget.cityName,
          'main': item['main'],
          'weather': item['weather'],
          'wind': item['wind'],
          'visibility': item['visibility'],
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

  // Format date without intl package
  String _formatDate(DateTime date) {
    final days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final day = days[date.weekday % 7];
    return '$day ${date.day}/${date.month}';
  }

  // Format time without intl package
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Get daily forecast (one per day)
  List<Weather> _getDailyForecasts() {
    Map<String, Weather> dailyMap = {};

    for (var forecast in _forecasts) {
      final dateKey = '${forecast.dateTime.year}-${forecast.dateTime.month.toString().padLeft(2, '0')}-${forecast.dateTime.day.toString().padLeft(2, '0')}';

      // Take the noon forecast (12:00) or first of the day
      if (!dailyMap.containsKey(dateKey)) {
        dailyMap[dateKey] = forecast;
      } else if (forecast.dateTime.hour == 12) {
        dailyMap[dateKey] = forecast;
      }
    }

    return dailyMap.values.toList();
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
              const Color(0xFF5B8FE3),
              const Color(0xFF9B59B6),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _errorMessage.isNotEmpty
              ? _buildErrorWidget()
              : _buildForecastContent(),
        ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastContent() {
    final dailyForecasts = _getDailyForecasts();

    return RefreshIndicator(
      onRefresh: _fetchForecast,
      color: Colors.blue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildTitle(),
              const SizedBox(height: 20),
              _buildDailyForecasts(dailyForecasts),
              const SizedBox(height: 24),
              _buildHourlyTitle(),
              const SizedBox(height: 16),
              _buildHourlyForecasts(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dự báo thời tiết',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.cityName,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      '7 ngày tới',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.9),
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDailyForecasts(List<Weather> forecasts) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: forecasts.length > 7 ? 7 : forecasts.length,
        itemBuilder: (context, index) {
          return _buildDailyCard(forecasts[index]);
        },
      ),
    );
  }

  Widget _buildDailyCard(Weather forecast) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  _formatDate(forecast.dateTime),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Image.network(
                  _weatherService.getWeatherIconUrl(forecast.icon),
                  width: 32,
                  height: 32,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.cloud, color: Colors.white, size: 32);
                  },
                ),
                Text(
                  '${forecast.temperature.round()}°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyTitle() {
    return Text(
      'Theo giờ',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.9),
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildHourlyForecasts() {
    // Get next 24 hours
    final hourlyForecasts = _forecasts.length > 8
        ? _forecasts.sublist(0, 8)
        : _forecasts;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: hourlyForecasts.map((forecast) {
              return _buildHourlyItem(forecast);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyItem(Weather forecast) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              _formatTime(forecast.dateTime),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Row(
            children: [
              Image.network(
                _weatherService.getWeatherIconUrl(forecast.icon),
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.cloud, color: Colors.white, size: 32);
                },
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: Text(
                  forecast.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            '${forecast.temperature.round()}°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}