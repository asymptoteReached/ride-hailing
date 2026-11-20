// Keys are injected at build time and are never committed:
//   flutter run --dart-define-from-file=secrets.json
// Copy secrets.example.json to secrets.json (gitignored) and fill in your own sandbox keys.
var collectionPrimaryKey = const String.fromEnvironment('MOMO_COLLECTION_PRIMARY_KEY');
var collectionSecondaryKey = const String.fromEnvironment('MOMO_COLLECTION_SECONDARY_KEY');

var disbursementsPrimaryKey = const String.fromEnvironment('MOMO_DISBURSEMENTS_PRIMARY_KEY');
var disbursementsSecondaryKey = const String.fromEnvironment('MOMO_DISBURSEMENTS_SECONDARY_KEY');

var sandBoxUrl =
    "https://sandbox.momodeveloper.mtn.com"; //(you pass X-Target-Environment: sandbox)
var productionUrl =
    "https://momoapi.mtn.com"; // (you pass X-Target-Environment: production)

var UUID = const String.fromEnvironment('MOMO_API_USER_UUID');
var apiKey = const String.fromEnvironment('MOMO_API_KEY');
var accessToken =
    const String.fromEnvironment('MOMO_ACCESS_TOKEN');
