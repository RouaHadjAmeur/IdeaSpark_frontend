/// Backend API base URL. Change for production or use env.
/// For iOS Simulator use http://localhost:3000
/// For Android Emulator use http://10.0.2.2:3000
/// For physical device use your machine's LAN IP, e.g. http://192.168.1.10:3000
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static String get authBase => '$baseUrl/auth';
}
