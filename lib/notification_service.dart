
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // ==================== INITIALIZATION ====================

  /// Khởi tạo notification service
  Future<bool> initialize() async {
    if (_isInitialized) {
      print('✅ Notification service already initialized');
      return true;
    }

    try {
      print('🔔 Initializing notification service...');

      // Initialize timezone
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
      print('✅ Timezone initialized: Asia/Ho_Chi_Minh');

      // Android settings
      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

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

      // Initialize plugin
      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        _isInitialized = true;
        print('✅ Notification service initialized successfully');
        return true;
      } else {
        print('⚠️ Notification initialization returned null/false');
        _isInitialized = true; // Still mark as initialized
        return true;
      }
    } catch (e, stackTrace) {
      print('❌ Failed to initialize notifications: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Xử lý khi user tap notification
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
  }

  // ==================== PERMISSIONS ====================

  /// Request notification permissions (Android 13+ & iOS)
  Future<bool> requestPermissions() async {
    try {
      print('🔔 Requesting notification permissions...');

      // Android 13+ permission
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        print('Android permission granted: $granted');
        if (granted == true) return true;
      }

      // iOS permission
      final iosImpl = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosImpl != null) {
        final granted = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        print('iOS permission granted: $granted');
        return granted ?? false;
      }

      // Default: assume granted for older Android versions
      print('⚠️ Using default permission (Android < 13)');
      return true;
    } catch (e) {
      print('❌ Error requesting permissions: $e');
      return false;
    }
  }

  /// Check if notifications are enabled
  Future<bool> checkPermissions() async {
    try {
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        final enabled = await androidImpl.areNotificationsEnabled();
        print('Notifications enabled: ${enabled ?? false}');
        return enabled ?? false;
      }

      return true; // Assume enabled on iOS
    } catch (e) {
      print('❌ Error checking permissions: $e');
      return false;
    }
  }

  // ==================== SHOW NOTIFICATIONS ====================

  /// 1. Thông báo thời tiết hiện tại (ĐƠN GIẢN NHẤT)
  Future<void> showWeatherNotification({
    required String cityName,
    required double temperature,
    required String description,
    required String icon,
  }) async {
    try {
      print('🔔 Showing weather notification...');
      print('City: $cityName, Temp: $temperature, Desc: $description');

      // Ensure initialized
      if (!_isInitialized) {
        await initialize();
      }

      // Android details
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'weather_basic', // Channel ID
        'Weather Updates', // Channel name
        channelDescription: 'Current weather notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        showWhen: true,
      );

      // iOS details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        0, // Notification ID
        '🌤️ $cityName',
        '${temperature.toStringAsFixed(1)}°C - $description',
        details,
        payload: 'weather_$cityName',
      );

      print('✅ Notification shown successfully!');
    } catch (e, stackTrace) {
      print('❌ Error showing notification: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// 2. Cảnh báo thời tiết xấu
  Future<void> showWeatherAlert({
    required String cityName,
    required String alertMessage,
    required String severity,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'weather_alerts',
        'Weather Alerts',
        channelDescription: 'Important weather warnings',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      String emoji = severity == 'danger' ? '⚠️' : '⚡';

      await _notifications.show(
        1,
        '$emoji Cảnh báo - $cityName',
        alertMessage,
        details,
        payload: 'alert_$cityName',
      );

      print('✅ Weather alert sent');
    } catch (e) {
      print('❌ Error showing alert: $e');
    }
  }

  /// 3. Cảnh báo nhiệt độ cực đoan
  Future<void> showTemperatureAlert({
    required String cityName,
    required double temperature,
    required String type,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'temp_alerts',
        'Temperature Alerts',
        channelDescription: 'Extreme temperature warnings',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      String emoji = type == 'hot' ? '🔥' : '❄️';
      String message = type == 'hot'
          ? 'Nhiệt độ cao ${temperature.round()}°C! Nhớ uống đủ nước'
          : 'Nhiệt độ thấp ${temperature.round()}°C! Giữ ấm cơ thể';

      await _notifications.show(
        3,
        '$emoji $cityName',
        message,
        details,
        payload: 'temp_$type',
      );

      print('✅ Temperature alert sent');
    } catch (e) {
      print('❌ Error showing temp alert: $e');
    }
  }

  /// 4. Cảnh báo mưa
  Future<void> showRainAlert({
    required String cityName,
    required String description,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'rain_alerts',
        'Rain Alerts',
        channelDescription: 'Rain notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        4,
        '☔ $cityName',
        'Sắp có mưa! $description. Nhớ mang ô!',
        details,
        payload: 'rain',
      );

      print('✅ Rain alert sent');
    } catch (e) {
      print('❌ Error showing rain alert: $e');
    }
  }

  /// 5. Thông báo thời tiết buổi sáng (Scheduled)
  Future<void> scheduleMorningWeather({
    required String cityName,
    required int hour,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'morning_weather',
        'Morning Weather',
        channelDescription: 'Daily morning weather',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final now = tz.TZDateTime.now(tz.local);
      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        0,
      );

      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      await _notifications.zonedSchedule(
        2,
        '☀️ Chào buổi sáng!',
        'Xem thời tiết hôm nay tại $cityName',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'morning',
      );

      print('✅ Morning weather scheduled for ${scheduledTime.hour}:00');
    } catch (e) {
      print('❌ Error scheduling morning weather: $e');
    }
  }

  // ==================== MANAGEMENT ====================

  /// Hủy tất cả notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    print('🗑️ All notifications cancelled');
  }

  /// Hủy notification cụ thể
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
    print('🗑️ Notification $id cancelled');
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
