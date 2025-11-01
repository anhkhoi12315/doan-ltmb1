import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String apiKey = '80f5f42bf5f89426d4840790a2e8cc7d';
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Lấy thời tiết hiện tại
  Future<Map<String, dynamic>> getCurrentWeather(String cityName) async {
    final url = Uri.parse('$baseUrl/weather?q=$cityName&appid=$apiKey&units=metric&lang=vi');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Lỗi kết nối: Không thể tải dữ liệu thời tiết. Vui lòng kiểm tra tên thành phố.');
    }
  }

  // Lấy dự báo 5 ngày (3 giờ/lần)
  Future<Map<String, dynamic>> get5DayForecast(String cityName) async {
    final url = Uri.parse('$baseUrl/forecast?q=$cityName&appid=$apiKey&units=metric&lang=vi');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Lỗi kết nối: Không thể tải dự báo thời tiết.');
    }
  }

  // Lấy URL icon thời tiết
  String getWeatherIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }
}