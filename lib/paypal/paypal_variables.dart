// Keys are injected at build time and are never committed:
//   flutter run --dart-define-from-file=secrets.json
// Copy secrets.example.json to secrets.json (gitignored) and fill in your own sandbox keys.
var clientID =
    const String.fromEnvironment('PAYPAL_CLIENT_ID');
var secretKey =
    const String.fromEnvironment('PAYPAL_SECRET_KEY');
