import '../../domain/entities/user_profile.dart';

/// Model representing authentication response from /api/auth/login
class AuthResponseModel {
  final UserProfile user;
  final String? token;
  final String? accessToken;
  final String? refreshToken;
  final String? expiresIn;
  final String? refreshExpiresAt;
  final Map<String, dynamic> rawData;

  const AuthResponseModel({
    required this.user,
    required this.rawData,
    this.token,
    this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.refreshExpiresAt,
  });

  factory AuthResponseModel.fromJson(
    Map<String, dynamic> json, {
    String? fallbackPhone,
  }) {
    // Check if payload is wrapped in { "status": "success", "data": { ... } }
    Map<String, dynamic> data = json;
    if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      data = json['data'] as Map<String, dynamic>;
    }

    final token = data['token']?.toString();
    final accessToken = data['accessToken']?.toString() ?? token;
    final refreshToken = data['refreshToken']?.toString();
    final expiresIn = data['expiresIn']?.toString();
    final refreshExpiresAt = data['refreshExpiresAt']?.toString();

    Map<String, dynamic> userMap = {};
    if (data.containsKey('user') && data['user'] is Map<String, dynamic>) {
      userMap = data['user'] as Map<String, dynamic>;
    } else {
      userMap = data;
    }

    final String fullName = (userMap['name'] as String? ?? 'User').trim();
    final parts = fullName.split(' ');
    final firstName = parts.isNotEmpty ? parts.first : fullName;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final id = userMap['id']?.toString() ??
        userMap['_id']?.toString() ??
        'usr_${DateTime.now().millisecondsSinceEpoch}';
    final email = userMap['email']?.toString() ?? '';
    final phone = (userMap['phone'] as String? ??
            userMap['phoneNumber'] as String? ??
            fallbackPhone ??
            '')
        .trim();
    final role = userMap['role']?.toString() ?? 'user';

    final user = UserProfile(
      id: id,
      firstName: firstName.isNotEmpty ? firstName : 'User',
      lastName: lastName,
      email: email,
      phoneNumber: phone,
      role: role,
      authProvider: 'phone',
    );

    return AuthResponseModel(
      user: user,
      rawData: data,
      token: token,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
      refreshExpiresAt: refreshExpiresAt,
    );
  }
}

