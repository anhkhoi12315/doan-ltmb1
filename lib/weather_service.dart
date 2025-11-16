

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'cache_service.dart';

/// Service để gọi OpenWeatherMap API
class WeatherService {
  final CacheService _cacheService = CacheService();
  final http.Client _httpClient = http.Client();

  Future<Map<String, dynamic>> getCurrentWeather(String cityName) async {
    // Thử lấy từ cache trước
    final cached = await _cacheService.getWeatherCache(cityName);
    if (cached != null) {
      print('✅ Using cached data for: $cityName');
      return cached;
    }

    // Nếu không có cache, gọi API
    final url = Uri.parse(
      '$WEATHER_API_BASE/weather?q=$cityName&appid=$WEATHER_API_KEY&units=metric&lang=vi',
    );

    try {
      print('🌐 Fetching weather from API for: $cityName');
      final response = await _httpClient.get(url).timeout(API_TIMEOUT);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        // Lưu vào cache
        await _cacheService.saveWeatherCache(cityName, data);

        return data;
      } else if (response.statusCode == 404) {
        throw Exception('Không tìm thấy thành phố: $cityName');
      } else {
        throw Exception('Lỗi server: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Hết thời gian kết nối. Vui lòng thử lại.');
    } catch (e) {
      print('❌ Error fetching weather: $e');
      rethrow;
    }
  }

  /// Lấy dự báo 5 ngày (3 giờ/lần)
  Future<Map<String, dynamic>> get5DayForecast(String cityName) async {
    final url = Uri.parse(
      '$WEATHER_API_BASE/forecast?q=$cityName&appid=$WEATHER_API_KEY&units=metric&lang=vi',
    );

    try {
      print('📅 Fetching 5-day forecast for: $cityName');
      final response = await _httpClient.get(url).timeout(API_TIMEOUT);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Lỗi khi lấy dự báo thời tiết');
      }
    } on TimeoutException {
      throw Exception('Hết thời gian kết nối');
    } catch (e) {
      print('❌ Error fetching forecast: $e');
      rethrow;
    }
  }

  /// Lấy URL của weather icon
  String getWeatherIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@4x.png';
  }

  /// Xóa cache của một thành phố
  Future<void> clearCacheForCity(String cityName) async {
    await _cacheService.clearWeatherCache(cityName);
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }
}
