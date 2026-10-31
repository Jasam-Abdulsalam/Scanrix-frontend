import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Base URL and endpoint paths for the Scanrix backend (`app/api/v1/api.py`).
///
/// [baseUrl] comes from `.env` (`BASE_URL`, gitignored — copy `.env.example`
/// and point it at your running backend; see the backend's own `.env` /
/// uvicorn host:port). `dotenv.load()` must run before this is read — done
/// in `main()`.
class ApiConstants {
  ApiConstants._();

  static String get baseUrl => dotenv.get('BASE_URL');

  // auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String googleLogin = '/auth/google';
  static const String googleSignup = '/auth/google/signup';
  static const String me = '/auth/me';
  static const String mePhoto = '/auth/me/photo';

  // products
  static String productByBarcode(String barcode) => '/products/$barcode';

  // scan
  static const String scan = '/scan/';
  static const String analyzeText = '/scan/analyze-text';

  // ai (opt-in "Get AI verdict", see the backend's API_CONTRACT.md section 11)
  static const String aiAnalyzeProduct = '/ai/analyze-product';
  static const String aiCredits = '/ai/credits';

  // history
  static const String history = '/history/';
  static const String historyCount = '/history/count';
  static String historyEntry(String id) => '/history/$id';

  // favorites (saved products)
  static const String favorites = '/favorites/';
  static const String favoriteBarcodes = '/favorites/barcodes';
  static String favorite(String barcode) => '/favorites/${Uri.encodeComponent(barcode)}';

  /// The backend returns `photo_url` either as an absolute URL (e.g. a
  /// Google profile photo) or, for an uploaded photo, a path relative to
  /// the backend's own host (`/static/...`) — kept host-agnostic
  /// server-side since that host is a LAN IP that changes per network,
  /// same reason [baseUrl] lives in `.env` rather than being hardcoded.
  /// Resolves the relative case against [baseUrl]'s host; passes an
  /// already-absolute URL through unchanged.
  static String? resolveMediaUrl(String? path) {
    if (path == null) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final base = Uri.parse(baseUrl);
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.port,
      path: path,
    ).toString();
  }
}
