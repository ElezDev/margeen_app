class AppConfig {
  AppConfig._();

  /// Emulador Android → 10.0.2.2 apunta al localhost de tu Mac.
  /// Dispositivo físico → usa la IP de tu PC, ej: http://192.168.1.10:8000/api
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://margeen-api-production.up.railway.app/api',
  );

  static const appName = 'Margeen';
}
