/// Route paths used across the app.
abstract final class Routes {
  static const String home = '/';
  static const String lesson = '/lesson';
  static const String review = '/review';
  static const String kanaGrid = '/kana';
  static const String goal = '/goal';
  static const String settings = '/settings';

  static String kanaDetail(int itemId) => '/kana/$itemId';
}
