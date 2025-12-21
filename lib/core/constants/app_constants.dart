class AppConstants {
  // App Info
  static const String appName = 'Koji';
  static const String appVersion = '1.0.0';

  // Routes
  static const String splashRoute = '/splash';
  static const String accountTypeRoute = '/account-type';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String dashboardRoute = '/dashboard';
  static const String estimatesRoute = '/estimates';
  static const String clientsRoute = '/clients';
  static const String profileRoute = '/profile';

  // Default Values
  static const String defaultCurrency = '€';
  static const String defaultLocale = 'fr_FR';
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
  static const int siretLength = 14;
  
  // UI
  static const double defaultPadding = 24.0;
  static const double defaultRadius = 12.0;
  static const double cardRadius = 16.0;
  static const double buttonHeight = 56.0;
  
  // Animation
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 2);
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userIdKey = 'user_id';
  static const String accountTypeKey = 'account_type';
  static const String profileKey = 'profile';
}
