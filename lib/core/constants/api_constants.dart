/// Base URL and endpoint paths for the Scanrix backend (`app/api/v1/api.py`).
///
/// Update [baseUrl] to point at your running backend (see the backend's
/// `.env` / uvicorn host:port).
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://192.168.1.9:8000/api/v1';

  // auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String googleLogin = '/auth/google';

  // products
  static String productByBarcode(String barcode) => '/products/$barcode';

  // scan
  static const String scan = '/scan/';
  static const String analyzeText = '/scan/analyze-text';

  // history
  static const String history = '/history/';
}
