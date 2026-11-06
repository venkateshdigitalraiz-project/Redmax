import 'dart:convert';
import 'dart:io';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/api_logger.dart';
import '../../domain/entities/user_profile.dart';
import '../models/auth_response_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserProfile> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'user',
  });

  Future<void> sendOtp(String phone);
  Future<void> resendOtp(String phone);
  Future<AuthResponseModel> verifyOtp({
    required String phone,
    required String otp,
  });
  Future<UserProfile> getUserProfile({
    required String accessToken,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final String registerUrl;
  final String loginUrl;
  final HttpClient _client;

  AuthRemoteDataSourceImpl({
    String? registerUrl,
    String? loginUrl,
    String? verifyOtpUrl,
    HttpClient? client,
  }) : registerUrl = registerUrl ?? ApiEndpoints.register,
       loginUrl = loginUrl ?? verifyOtpUrl ?? ApiEndpoints.login,
       _client = client ?? HttpClient();

  String get verifyOtpUrl => loginUrl;

  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'user',
  }) async {
    final uri = Uri.parse(registerUrl);
    final payload = {
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'password': password,
      'role': role.trim().isNotEmpty ? role.trim() : 'user',
    };
    final payloadJson = jsonEncode(payload);

    ApiLogger.logRequest(
      title: 'REGISTER',
      url: registerUrl,
      method: 'POST',
      body: payloadJson,
    );

    try {
      _client.connectionTimeout = const Duration(seconds: 10);
      final request = await _client
          .postUrl(uri)
          .timeout(const Duration(seconds: 10));

      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.write(payloadJson);

      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );

      final responseBody = await response.transform(utf8.decoder).join();

      ApiLogger.logResponse(
        title: 'REGISTER',
        url: registerUrl,
        statusCode: response.statusCode,
        responseBody: responseBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _mapResponseToUserProfile(
          body: responseBody,
          fallbackName: name,
          fallbackEmail: email,
          fallbackPhone: phone,
        );
      } else {
        String errorMessage = 'Registration failed (${response.statusCode})';
        try {
          if (responseBody.isNotEmpty) {
            final decoded = jsonDecode(responseBody);
            if (decoded is Map<String, dynamic>) {
              errorMessage =
                  decoded['message']?.toString() ??
                  decoded['error']?.toString() ??
                  decoded['msg']?.toString() ??
                  errorMessage;
            }
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      ApiLogger.logError(title: 'REGISTER', url: registerUrl, error: e);
      if (e is SocketException) {
        throw Exception(
          'Unable to connect to server at $registerUrl. Please verify network and server status.',
        );
      }
      if (e is HttpException) {
        throw Exception('HTTP error during registration: ${e.message}');
      }
      if (e is Exception) rethrow;
      throw Exception('Unexpected error during registration: $e');
    }
  }

  @override
  Future<void> sendOtp(String phone) async {
    final payload = {
      'loginType': 'phone',
      'phone': phone.trim(),
    };
    final payloadJson = jsonEncode(payload);

    final candidateUrls = [
      loginUrl,
      if (loginUrl != 'http://192.168.0.161:5001/api/auth/login')
        'http://192.168.0.161:5001/api/auth/login',
      if (loginUrl != 'http://localhost:5000/api/auth/login')
        'http://localhost:5000/api/auth/login',
    ];

    Object? lastError;

    for (int i = 0; i < candidateUrls.length; i++) {
      final targetUrl = candidateUrls[i];
      final uri = Uri.parse(targetUrl);

      ApiLogger.logRequest(
        title: 'SEND_OTP',
        url: targetUrl,
        method: 'POST',
        body: payloadJson,
      );

      try {
        _client.connectionTimeout = const Duration(seconds: 10);
        final request = await _client
            .postUrl(uri)
            .timeout(const Duration(seconds: 10));

        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        request.write(payloadJson);

        final response = await request.close().timeout(
          const Duration(seconds: 10),
        );

        final responseBody = await response.transform(utf8.decoder).join();

        ApiLogger.logResponse(
          title: 'SEND_OTP',
          url: targetUrl,
          statusCode: response.statusCode,
          responseBody: responseBody,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return;
        } else {
          String errorMessage = 'Failed to send OTP (${response.statusCode})';
          try {
            if (responseBody.isNotEmpty) {
              final decoded = jsonDecode(responseBody);
              if (decoded is Map<String, dynamic>) {
                errorMessage =
                    decoded['message']?.toString() ??
                    decoded['error']?.toString() ??
                    decoded['msg']?.toString() ??
                    errorMessage;
              }
            }
          } catch (_) {}
          throw Exception(errorMessage);
        }
      } catch (e) {
        lastError = e;
        ApiLogger.logError(title: 'SEND_OTP', url: targetUrl, error: e);

        if ((e is SocketException || e is HttpException) &&
            i < candidateUrls.length - 1) {
          continue;
        }

        if (e is Exception && !e.toString().contains('SocketException')) {
          rethrow;
        }
      }
    }

    if (lastError is SocketException) {
      throw Exception(
        'Unable to connect to server at $loginUrl. Please verify network and server status.',
      );
    }
    if (lastError is HttpException) {
      throw Exception('HTTP error sending OTP: ${lastError.message}');
    }
    if (lastError is Exception) throw lastError;
    throw Exception('Unexpected error sending OTP: $lastError');
  }

  @override
  Future<void> resendOtp(String phone) => sendOtp(phone);

  @override
  Future<AuthResponseModel> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final payload = {
      'loginType': 'phone',
      'phone': phone.trim(),
      'otp': otp.trim(),
    };
    final payloadJson = jsonEncode(payload);

    // List candidate URLs: primary user endpoint (http://localhost:5000/api/auth/login),
    // and fallback to LAN/base URL if localhost is unreachable.
    final candidateUrls = [
      verifyOtpUrl,
      if (verifyOtpUrl != 'http://192.168.0.161:5001/api/auth/login')
        'http://192.168.0.161:5001/api/auth/login',
      if (verifyOtpUrl != 'http://localhost:5000/api/auth/login')
        'http://localhost:5000/api/auth/login',
    ];

    Object? lastError;

    for (int i = 0; i < candidateUrls.length; i++) {
      final targetUrl = candidateUrls[i];
      final uri = Uri.parse(targetUrl);

      ApiLogger.logRequest(
        title: 'LOGIN_OTP',
        url: targetUrl,
        method: 'POST',
        body: payloadJson,
      );

      try {
        _client.connectionTimeout = const Duration(seconds: 10);
        final request = await _client
            .postUrl(uri)
            .timeout(const Duration(seconds: 10));

        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        request.write(payloadJson);

        final response = await request.close().timeout(
          const Duration(seconds: 10),
        );

        final responseBody = await response.transform(utf8.decoder).join();

        ApiLogger.logResponse(
          title: 'LOGIN_OTP',
          url: targetUrl,
          statusCode: response.statusCode,
          responseBody: responseBody,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final decoded = jsonDecode(responseBody);
          if (decoded is Map<String, dynamic>) {
            // Check API-level failure inside HTTP 200/201 response
            final status = decoded['status']?.toString().toLowerCase();
            final success = decoded['success'];
            final isFail =
                status == 'fail' || status == 'error' || success == false;

            if (isFail) {
              final errorMessage = decoded['message']?.toString() ??
                  decoded['error']?.toString() ??
                  decoded['msg']?.toString() ??
                  'Invalid OTP. Please check and try again.';
              throw Exception(errorMessage);
            }

            // Ensure data object or tokens exist
            if (decoded.containsKey('data') && decoded['data'] == null) {
              final errorMessage = decoded['message']?.toString() ??
                  'Invalid OTP or authentication failed. Please try again.';
              throw Exception(errorMessage);
            }

            return AuthResponseModel.fromJson(decoded, fallbackPhone: phone);
          }
          throw Exception('Invalid server response format.');
        } else {
          String errorMessage = 'Failed to verify OTP (${response.statusCode})';
          try {
            if (responseBody.isNotEmpty) {
              final decoded = jsonDecode(responseBody);
              if (decoded is Map<String, dynamic>) {
                errorMessage =
                    decoded['message']?.toString() ??
                    decoded['error']?.toString() ??
                    decoded['msg']?.toString() ??
                    errorMessage;
              }
            }
          } catch (_) {}
          throw Exception(errorMessage);
        }
      } catch (e) {
        lastError = e;
        ApiLogger.logError(title: 'LOGIN_OTP', url: targetUrl, error: e);

        // If connection error and we have another candidate URL, try next candidate
        if ((e is SocketException || e is HttpException) &&
            i < candidateUrls.length - 1) {
          continue;
        }

        if (e is Exception && !e.toString().contains('SocketException')) {
          rethrow;
        }
      }
    }

    if (lastError is SocketException) {
      throw Exception(
        'Unable to connect to server at $verifyOtpUrl. Please verify network and server status.',
      );
    }
    if (lastError is HttpException) {
      throw Exception('HTTP error verifying OTP: ${lastError.message}');
    }
    if (lastError is Exception) throw lastError;
    throw Exception('Unexpected error verifying OTP: $lastError');
  }

  @override
  Future<UserProfile> getUserProfile({required String accessToken}) async {
    final targetUrl = ApiEndpoints.userProfile;
    final uri = Uri.parse(targetUrl);

    ApiLogger.logRequest(
      title: 'GET_USER_PROFILE',
      url: targetUrl,
      method: 'GET',
      body:
          'Headers: {Authorization: Bearer ${accessToken.length > 20 ? "${accessToken.substring(0, 20)}..." : accessToken}}',
    );

    try {
      _client.connectionTimeout = const Duration(seconds: 10);
      final request =
          await _client.getUrl(uri).timeout(const Duration(seconds: 10));

      request.headers
          .set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response =
          await request.close().timeout(const Duration(seconds: 10));
      final responseBody = await response.transform(utf8.decoder).join();

      ApiLogger.logResponse(
        title: 'GET_USER_PROFILE',
        url: targetUrl,
        statusCode: response.statusCode,
        responseBody: responseBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(responseBody);
        if (decoded is Map<String, dynamic>) {
          final status = decoded['status']?.toString().toLowerCase();
          if (status == 'fail' || status == 'error') {
            throw Exception(
              decoded['message'] ?? 'Failed to load user profile',
            );
          }

          Map<String, dynamic> userMap = {};
          if (decoded['data'] is Map<String, dynamic> &&
              decoded['data']['user'] is Map<String, dynamic>) {
            userMap = decoded['data']['user'] as Map<String, dynamic>;
          } else if (decoded['user'] is Map<String, dynamic>) {
            userMap = decoded['user'] as Map<String, dynamic>;
          } else if (decoded['data'] is Map<String, dynamic>) {
            userMap = decoded['data'] as Map<String, dynamic>;
          } else {
            userMap = decoded;
          }

          final fullName = (userMap['name'] as String? ?? 'User').trim();
          final parts = fullName.split(' ');
          final firstName = parts.isNotEmpty ? parts.first : fullName;
          final lastName =
              parts.length > 1 ? parts.sublist(1).join(' ') : '';
          final id = userMap['id']?.toString() ??
              userMap['_id']?.toString() ??
              'usr_${DateTime.now().millisecondsSinceEpoch}';
          final email = (userMap['email'] as String? ?? '').trim();
          final phone = (userMap['phone'] as String? ??
                  userMap['phoneNumber'] as String? ??
                  '')
              .trim();
          final role = (userMap['role'] as String? ?? 'user').trim();

          return UserProfile(
            id: id,
            firstName: firstName.isNotEmpty ? firstName : 'User',
            lastName: lastName,
            email: email,
            phoneNumber: phone,
            role: role.isNotEmpty ? role : 'user',
            authProvider: 'phone',
          );
        }
        throw Exception('Invalid profile response format');
      } else {
        String errorMessage =
            'Failed to fetch user profile (${response.statusCode})';
        try {
          if (responseBody.isNotEmpty) {
            final decoded = jsonDecode(responseBody);
            if (decoded is Map<String, dynamic>) {
              errorMessage = decoded['message']?.toString() ??
                  decoded['error']?.toString() ??
                  decoded['msg']?.toString() ??
                  errorMessage;
            }
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      ApiLogger.logError(title: 'GET_USER_PROFILE', url: targetUrl, error: e);
      if (e is SocketException) {
        throw Exception('Unable to connect to server at $targetUrl');
      }
      if (e is HttpException) {
        throw Exception('HTTP error fetching profile: ${e.message}');
      }
      if (e is Exception) rethrow;
      throw Exception('Unexpected error fetching profile: $e');
    }
  }

  UserProfile _mapResponseToUserProfile({
    required String body,
    required String fallbackName,
    required String fallbackEmail,
    required String fallbackPhone,
  }) {
    Map<String, dynamic> data = {};
    if (body.isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          if (decoded['user'] is Map<String, dynamic>) {
            data = decoded['user'] as Map<String, dynamic>;
          } else if (decoded['data'] is Map<String, dynamic>) {
            data = decoded['data'] as Map<String, dynamic>;
          } else {
            data = decoded;
          }
        }
      } catch (_) {}
    }

    final String fullName = (data['name'] as String? ?? fallbackName).trim();
    final nameParts = fullName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : fullName;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final id =
        data['id']?.toString() ??
        data['_id']?.toString() ??
        'usr_${DateTime.now().millisecondsSinceEpoch}';
    final email = (data['email'] as String? ?? fallbackEmail).trim();
    final phone =
        (data['phone'] as String? ??
                data['phoneNumber'] as String? ??
                fallbackPhone)
            .trim();
    final role = data['role']?.toString() ?? 'user';

    return UserProfile(
      id: id,
      firstName: firstName.isNotEmpty ? firstName : 'User',
      lastName: lastName,
      email: email,
      phoneNumber: phone,
      role: role,
      authProvider: 'email',
      optOutMarketing: false,
    );
  }
}
