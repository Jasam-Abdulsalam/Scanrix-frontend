/// Google Sign-In OAuth configuration.
///
/// TODO: replace [webClientId] with the real **Web** OAuth client ID from
/// Google Cloud Console (APIs & Services > Credentials > OAuth 2.0 Client
/// IDs > Web client). This is used as `serverClientId` when initializing
/// `google_sign_in` on every platform — it's what makes the resulting ID
/// token's `aud` claim match what the backend verifies against
/// (`settings.GOOGLE_CLIENT_ID`; see scanrix-backend's CLAUDE.md
/// "Google Sign-In" section). The two must be the exact same client ID.
///
/// Getting real credentials also requires registering separate OAuth
/// clients for Android (package name `com.scanrix.scanrix_frontend` + your
/// debug/release SHA-1 signing fingerprint) and iOS (bundle ID), and adding
/// the iOS reversed-client-id URL scheme to `ios/Runner/Info.plist` — see
/// "Google Sign-In setup" in this repo's CLAUDE.md for the exact steps.
class GoogleAuthConfig {
  GoogleAuthConfig._();

  static const String webClientId =
      'REPLACE_WITH_GOOGLE_WEB_CLIENT_ID.apps.googleusercontent.com';
}
