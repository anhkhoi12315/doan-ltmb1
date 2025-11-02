

/// App constants và configuration
const String APP_NAME = 'Weather App';
const String APP_VERSION = '1.0.0';

// API Configuration
const String WEATHER_API_KEY = '80f5f42bf5f89426d4840790a2e8cc7d';
const String WEATHER_API_BASE = 'https://api.openweathermap.org/data/2.5';
const Duration API_TIMEOUT = Duration(seconds: 15);

// Cache Configuration
const Duration CACHE_DURATION = Duration(minutes: 30);
const int MAX_CACHED_CITIES = 10;

// UI Configuration
const double CARD_BORDER_RADIUS = 16.0;
const Duration ANIMATION_DURATION = Duration(milliseconds: 300);

// Temperature thresholds
const double TEMP_VERY_COLD = 0.0;
const double TEMP_COLD = 10.0;
const double TEMP_COOL = 15.0;
const double TEMP_WARM = 25.0;
const double TEMP_HOT = 30.0;
const double TEMP_VERY_HOT = 35.0;

// Popular Vietnamese cities
const List<String> POPULAR_CITIES_VN = [
  'Ho Chi Minh',
  'Hanoi',
  'Da Nang',
  'Hai Phong',
  'Can Tho',
  'Nha Trang',
  'Hue',
  'Da Lat',
];

// SharedPreferences keys
const String KEY_FAVORITES = 'favorite_cities';
const String KEY_DARK_MODE = 'dark_mode';
const String KEY_TEMP_UNIT = 'temperature_unit';
const String KEY_NOTIFICATIONS = 'notifications_enabled';
const String KEY_LAST_CITY = 'last_selected_city';
