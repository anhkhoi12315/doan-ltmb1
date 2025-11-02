

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import 'weather_model.dart';

class WeatherCard extends StatelessWidget {
  final Weather weather;
  final String temperatureUnit;
  final VoidCallback? onTap;

  const WeatherCard({
    Key? key,
    required this.weather,
    this.temperatureUnit = '°C',
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final temp = temperatureUnit == '°C' ? weather.temperature : weather.temperatureF;
    final feelsLike = temperatureUnit == '°C' ? weather.feelsLike : weather.feelsLikeF;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: screenWidth - 40,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _getGradientColors(),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // City + Date
                Text(
                  weather.cityName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  weather.formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 16),

                // Temperature + Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Main temperature
                          Text(
                            '${temp.toStringAsFixed(1)}$temperatureUnit',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Weather description
                          Text(
                            weather.weatherStatusVN,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Feels like description (FIXED!)
                          Text(
                            'Cảm giác: ${_getFeelsLikeDescription(feelsLike)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Weather icon
                    CachedNetworkImage(
                      imageUrl: weather.iconUrl,
                      width: 100,
                      height: 100,
                      placeholder: (context, url) => const SizedBox(
                        width: 100,
                        height: 100,
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.cloud_off,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Weather Details
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDetailItem(
                        Icons.water_drop,
                        '${weather.humidity}%',
                        'Độ ẩm',
                      ),
                      _buildDetailItem(
                        Icons.air,
                        '${weather.windSpeed.toStringAsFixed(1)} m/s',
                        'Gió',
                      ),
                      _buildDetailItem(
                        Icons.compress,
                        '${weather.pressure} hPa',
                        'Áp suất',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  /// Get feels like description based on temperature
  String _getFeelsLikeDescription(double feelsLike) {
    if (feelsLike < 0) return 'Rất lạnh 🥶';
    if (feelsLike < 10) return 'Lạnh ❄️';
    if (feelsLike < 15) return 'Mát lạnh 🌬️';
    if (feelsLike < 20) return 'Mát mẻ 😌';
    if (feelsLike < 25) return 'Dễ chịu 😊';
    if (feelsLike < 28) return 'Ấm áp ☀️';
    if (feelsLike < 32) return 'Hơi nóng 🌡️';
    if (feelsLike < 35) return 'Nóng 🔥';
    return 'Rất nóng 🥵';
  }

  List<Color> _getGradientColors() {
    final temp = weather.temperature;
    final desc = weather.description.toLowerCase();

    if (desc.contains('rain') || desc.contains('drizzle') || desc.contains('mưa')) {
      return [const Color(0xFF4A90E2), const Color(0xFF5BA3F5)];
    }
    if (desc.contains('cloud') || desc.contains('mây')) {
      return [const Color(0xFF6BA5D7), const Color(0xFF8CBCE8)];
    }
    if (temp < 15) {
      return [const Color(0xFF4A90E2), const Color(0xFF5BA3F5)];
    } else if (temp < 28) {
      return [const Color(0xFF6BA5D7), const Color(0xFF8CBCE8)];
    } else {
      return [const Color(0xFFFF9A56), const Color(0xFFFFAA71)];
    }
  }
}
