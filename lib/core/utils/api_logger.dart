import 'package:flutter/foundation.dart';

class ApiLogEntry {
  final String id;
  final String title;
  final String url;
  final String method;
  final String requestBody;
  final int? statusCode;
  final String? responseBody;
  final String? error;
  final DateTime timestamp;

  ApiLogEntry({
    required this.title,
    required this.url,
    required this.method,
    required this.requestBody,
    this.statusCode,
    this.responseBody,
    this.error,
    DateTime? timestamp,
  })  : id = DateTime.now().microsecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now();

  bool get isSuccess =>
      statusCode != null && (statusCode == 200 || statusCode == 201);
  bool get isError => error != null || (statusCode != null && statusCode! >= 400);
  bool get isPending => statusCode == null && error == null;

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class ApiLogger {
  ApiLogger._();

  static final ValueNotifier<List<ApiLogEntry>> logsNotifier =
      ValueNotifier<List<ApiLogEntry>>([]);

  static void logRequest({
    required String title,
    required String url,
    required String method,
    required String body,
  }) {
    // 1. Console / Terminal Print (100% visible in flutter run, logcat, devtools)
    print('\n==================== [API REQUEST: $title] ====================');
    print('API_URL: $url');
    print('API_METHOD: $method');
    print('API_HEADERS: {Content-Type: application/json, Accept: application/json}');
    print('API_BODY: $body');
    print('===============================================================\n');

    debugPrint('[$title REQUEST] $method $url\nBody: $body');

    // 2. Add to in-app reactive log list
    final newEntry = ApiLogEntry(
      title: title,
      url: url,
      method: method,
      requestBody: body,
    );

    logsNotifier.value = [newEntry, ...logsNotifier.value.take(19)];
  }

  static void logResponse({
    required String title,
    required String url,
    required int statusCode,
    required String responseBody,
  }) {
    print('\n==================== [API RESPONSE: $title] ====================');
    print('API_URL: $url');
    print('STATUS_CODE: $statusCode');
    print('API_RESPONSE: $responseBody');
    print('================================================================\n');

    debugPrint('[$title RESPONSE] $url -> Status: $statusCode\nResponse: $responseBody');

    // Update the matching request entry
    final currentLogs = List<ApiLogEntry>.from(logsNotifier.value);
    final index = currentLogs.indexWhere(
      (e) => e.title == title && e.url == url && e.isPending,
    );

    if (index != -1) {
      final existing = currentLogs[index];
      currentLogs[index] = ApiLogEntry(
        title: existing.title,
        url: existing.url,
        method: existing.method,
        requestBody: existing.requestBody,
        statusCode: statusCode,
        responseBody: responseBody,
        timestamp: existing.timestamp,
      );
      logsNotifier.value = currentLogs;
    } else {
      currentLogs.insert(
        0,
        ApiLogEntry(
          title: title,
          url: url,
          method: 'RESPONSE',
          requestBody: '',
          statusCode: statusCode,
          responseBody: responseBody,
        ),
      );
      logsNotifier.value = currentLogs.take(20).toList();
    }
  }

  static void logError({
    required String title,
    required String url,
    required dynamic error,
  }) {
    print('\n==================== [API ERROR: $title] ====================');
    print('API_URL: $url');
    print('API_ERROR: $error');
    print('=============================================================\n');

    debugPrint('[$title ERROR] $url -> $error');

    final currentLogs = List<ApiLogEntry>.from(logsNotifier.value);
    final index = currentLogs.indexWhere(
      (e) => e.title == title && e.url == url && e.isPending,
    );

    if (index != -1) {
      final existing = currentLogs[index];
      currentLogs[index] = ApiLogEntry(
        title: existing.title,
        url: existing.url,
        method: existing.method,
        requestBody: existing.requestBody,
        error: error.toString(),
        timestamp: existing.timestamp,
      );
      logsNotifier.value = currentLogs;
    } else {
      currentLogs.insert(
        0,
        ApiLogEntry(
          title: title,
          url: url,
          method: 'ERROR',
          requestBody: '',
          error: error.toString(),
        ),
      );
      logsNotifier.value = currentLogs.take(20).toList();
    }
  }

  static void clearLogs() {
    logsNotifier.value = [];
  }
}
