/// App 版本字串。
///
/// CI 每次建置都會把這個檔案覆寫成 `1.0.<run number>`，
/// 所以每個 APK 的版本都不同、Android 也認得是新版；
/// 本地直接開發時就維持 'dev'。
const String kAppVersion = 'dev';
