

import 'package:intl/intl.dart';

/// Model cho dữ liệu thời tiết
class Weather {
  final String cityName;
  final double temperature;
  final String description;
  final String icon;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final int pressure;
  final int visibility;
  final DateTime dateTime;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.description,
    required this.icon,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.visibility,
    required this.dateTime,
  });

  /// Tạo Weather object từ JSON (OpenWeatherMap API)
  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      cityName: json['name'] ?? '',
      temperature: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'] ?? '',
      icon: json['weather'][0]['icon'] ?? '',
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      humidity: json['main']['humidity'] ?? 0,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      pressure: json['main']['pressure'] ?? 0,
      visibility: json['visibility'] ?? 10000,
      dateTime: DateTime.fromMillisecondsSinceEpoch((json['dt'] as int) * 1000),
    );
  }

  /// Chuyển Weather object thành JSON để cache
  Map<String, dynamic> toJson() {
    return {
      'name': cityName,
      'main': {
        'temp': temperature,
        'feels_like': feelsLike,
        'humidity': humidity,
        'pressure': pressure,
      },
      'weather': [
        {
          'description': description,
          'icon': icon,
        }
      ],
      'wind': {
        'speed': windSpeed,
      },
      'visibility': visibility,
      'dt': dateTime.millisecondsSinceEpoch ~/ 1000,
    };
  }

  // ==================== HELPER METHODS ====================

  /// Chuyển đổi nhiệt độ sang Fahrenheit
  double get temperatureF => (temperature * 9 / 5) + 32;
  double get feelsLikeF => (feelsLike * 9 / 5) + 32;

  /// Lấy mô tả thời tiết bằng tiếng Việt
  String get weatherStatusVN {
    final desc = description.toLowerCase();
    if (desc.contains('rain')) return 'Mưa';
    if (desc.contains('drizzle')) return 'Mưa phùn';
    if (desc.contains('cloud')) return 'Nhiều mây';
    if (desc.contains('clear')) return 'Trời quang';
    if (desc.contains('snow')) return 'Tuyết';
    if (desc.contains('thunder')) return 'Sấm sét';
    if (desc.contains('fog') || desc.contains('mist')) return 'Sương mù';
    return description;
  }

  /// Lấy icon thời tiết từ OpenWeatherMap
  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@4x.png';

  /// Định dạng thời gian
  String get formattedTime => DateFormat('HH:mm').format(dateTime);
  String get formattedDate => DateFormat('dd/MM/yyyy').format(dateTime);
  String get formattedDateTime => DateFormat('dd/MM/yyyy HH:mm').format(dateTime);

  /// Lấy mô tả cảm giác nhiệt độ
  String getTempFeeling() {
    if (feelsLike < 0) return 'Rất lạnh';
    if (feelsLike < 10) return 'Lạnh';
    if (feelsLike < 20) return 'Mát mẻ';
    if (feelsLike < 25) return 'Dễ chịu';
    if (feelsLike < 30) return 'Ấm';
    if (feelsLike < 35) return 'Nóng';
    return 'Rất nóng';
  }

  /// Lấy mô tả độ ẩm
  String getHumidityStatus() {
    if (humidity < 30) return 'Khô';
    if (humidity < 60) return 'Bình thường';
    if (humidity < 80) return 'Ẩm';
    return 'Rất ẩm';
  }

  /// Copy with (để update một số field)
  Weather copyWith({
    String? cityName,
    double? temperature,
    String? description,
    String? icon,
    double? feelsLike,
    int? humidity,
    double? windSpeed,
    int? pressure,
    int? visibility,
    DateTime? dateTime,
  }) {
    return Weather(
      cityName: cityName ?? this.cityName,
      temperature: temperature ?? this.temperature,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      feelsLike: feelsLike ?? this.feelsLike,
      humidity: humidity ?? this.humidity,
      windSpeed: windSpeed ?? this.windSpeed,
      pressure: pressure ?? this.pressure,
      visibility: visibility ?? this.visibility,
      dateTime: dateTime ?? this.dateTime,
    );
  }

  @override
  String toString() {
    return 'Weather(city: $cityName, temp: $temperature°C, desc: $description)';
  }
}
