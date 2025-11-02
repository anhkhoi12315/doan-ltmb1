// lib/weather_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'weather_model.dart';
import 'weather_service.dart';

/// Provider cho WeatherService
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

/// Provider cho city hiện tại được chọn
final selectedCityProvider = StateProvider<String>((ref) {
  return 'Ho Chi Minh'; // Default city
});

/// Provider cho current weather (auto-fetch khi city thay đổi)
final currentWeatherProvider = FutureProvider.autoDispose<Weather>((ref) async {
  final cityName = ref.watch(selectedCityProvider);
  final weatherService = ref.watch(weatherServiceProvider);

  final weatherData = await weatherService.getCurrentWeather(cityName);
  return Weather.fromJson(weatherData);
});

/// Provider cho forecast data
final forecastProvider = FutureProvider.autoDispose<List<Weather>>((ref) async {
  final cityName = ref.watch(selectedCityProvider);
  final weatherService = ref.watch(weatherServiceProvider);

  final forecastData = await weatherService.get5DayForecast(cityName);
  final list = forecastData['list'] as List;

  return list.map((item) {
    return Weather.fromJson({
      'name': cityName,
      'main': item['main'],
      'weather': item['weather'],
      'wind': item['wind'],
      'visibility': item['visibility'] ?? 10000,
      'dt': item['dt'],
    });
  }).toList();
});

/// Provider để refresh weather (force refresh)
final refreshWeatherProvider = FutureProvider.autoDispose((ref) async {
  // Invalidate current weather để force refresh
  ref.invalidate(currentWeatherProvider);
  return ref.watch(currentWeatherProvider.future);
});

/// Provider cho last update time
final lastUpdateTimeProvider = StateProvider<DateTime?>((ref) => null);
