import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Khởi tạo notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    // Android settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  // Xử lý khi user tap vào notification
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
  }

  // Request permissions (iOS)
  Future<bool> requestPermissions() async {
    final bool? result = await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return result ?? false;
  }

  // 1. THÔNG BÁO THỜI TIẾT HIỆN TẠI
  Future<void> showWeatherNotification({
    required String cityName,
    required double temperature,
    required String description,
    required String icon,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'weather_channel',
      'Weather Updates',
      channelDescription: 'Notifications about current weather',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      '🌤️ Thời tiết tại $cityName',
      '${temperature.round()}° - $description',
      details,
      payload: 'weather_update',
    );
  }

  // 2. THÔNG BÁO CẢNH BÁO THỜI TIẾT XẤU
  Future<void> showWeatherAlert({
    required String cityName,
    required String alertMessage,
    required String severity,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'weather_alerts',
      'Weather Alerts',
      channelDescription: 'Important weather warnings',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    String emoji = severity == 'danger' ? '⚠️' : '⚡';

    await _notifications.show(
      1,
      '$emoji Cảnh báo thời tiết - $cityName',
      alertMessage,
      details,
      payload: 'weather_alert',
    );
  }

  // 3. THÔNG BÁO THỜI TIẾT BUỔI SÁNG (Scheduled)
  Future<void> scheduleMorningWeather({
    required String cityName,
    required int hour,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'morning_weather',
      'Morning Weather',
      channelDescription: 'Daily morning weather forecast',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule cho ngày mai
    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      0,
    );

    // Nếu giờ đã qua, schedule cho ngày mai
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      2,
      '☀️ Chào buổi sáng!',
      'Xem thời tiết hôm nay tại $cityName',
      scheduledTime,
      details,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'morning_weather',
    );
  }

  // 4. THÔNG BÁO NHIỆT ĐỘ QUÁC
  Future<void> showTemperatureAlert({
    required String cityName,
    required double temperature,
    required String type,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'temperature_alerts',
      'Temperature Alerts',
      channelDescription: 'Alerts for extreme temperatures',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    String emoji = type == 'hot' ? '🔥' : '❄️';
    String message = type == 'hot'
        ? 'Trời rất nóng ${temperature.round()}°! Nhớ uống nhiều nước!'
        : 'Trời rất lạnh ${temperature.round()}°! Nhớ giữ ấm!';

    await _notifications.show(
      3,
      '$emoji Cảnh báo nhiệt độ - $cityName',
      message,
      details,
      payload: 'temperature_alert',
    );
  }

  // 5. THÔNG BÁO MƯA
  Future<void> showRainAlert({
    required String cityName,
    required String description,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'rain_alerts',
      'Rain Alerts',
      channelDescription: 'Notifications about rain',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      4,
      '☔ Cảnh báo mưa - $cityName',
      'Sắp có mưa! $description. Nhớ mang ô!',
      details,
      payload: 'rain_alert',
    );
  }

  // 6. THÔNG BÁO KHI ĐỔI THÀNH PHỐ
  Future<void> showCityChangedNotification({
    required String cityName,
    required double temperature,
    required String description,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'city_weather',
      'City Weather',
      channelDescription: 'Weather for selected city',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      5,
      '📍 Thời tiết tại $cityName',
      '${temperature.round()}° - $description',
      details,
      payload: 'city_changed',
    );
  }

  // HỦY TẤT CẢ NOTIFICATIONS
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  // HỦY NOTIFICATION CỤ THỂ
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  // KIỂM TRA PERMISSIONS
  Future<bool> checkPermissions() async {
    if (_isInitialized) {
      final granted = await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      return granted ?? false;
    }
    return false;
  }
}