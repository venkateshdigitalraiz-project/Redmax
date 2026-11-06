class ApiEndpoints {
  ApiEndpoints._();

  /// Base URL of the backend API
  static const String baseUrl = 'http://192.168.0.161:5001';

  /// Auth endpoints
  static const String login = '$baseUrl/api/auth/login';
  static const String register = '$baseUrl/api/auth/register';
  static const String sendOtp = login;
  static const String verifyOtp = login;

  /// User profile endpoint
  static const String userProfile = '$baseUrl/api/users/profile';
}
