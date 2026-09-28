import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Encodes Flutter mapper payloads for HTTPS callables.
///
/// [FieldValue.delete] cannot cross the callable JSON boundary, so P1-A
/// clears are sent as `{_fieldDelete: true}`. Server timestamps are omitted
/// and applied by the trusted function.
Map<String, dynamic> encodeCallableWriteData(Map<String, dynamic> data) {
  final encoded = <String, dynamic>{};
  data.forEach((key, value) {
    if (value is FieldValue) {
      if (value == FieldValue.delete()) {
        encoded[key] = const {'_fieldDelete': true};
      }
      return;
    }
    encoded[key] = value;
  });
  return encoded;
}

class AdminQuestionAssignmentState {
  const AdminQuestionAssignmentState({
    required this.owners,
    required this.legacyTestIds,
  });

  final Map<String, String> owners;
  final Map<String, List<String>> legacyTestIds;
}

/// Thin asia-south1 callable client for trusted admin catalog writes.
class AdminContentCallableClient {
  AdminContentCallableClient({this.functions, this.callOverride});

  static const _region = 'asia-south1';
  static const _projectId = 'prashna-67689';

  FirebaseFunctions? functions;

  @visibleForTesting
  final Future<Map<String, dynamic>> Function(
    String name,
    Map<String, dynamic> data,
  )?
  callOverride;

  Future<String> createQuestion({
    required String questionId,
    required Map<String, dynamic> data,
  }) async {
    final result = await _call('adminCreateQuestion', {
      'questionId': questionId,
      'data': encodeCallableWriteData(data),
    });
    return (result['questionId'] as String?) ?? questionId;
  }

  Future<void> updateQuestion({
    required String questionId,
    required Map<String, dynamic> data,
  }) {
    return _call('adminUpdateQuestion', {
      'questionId': questionId,
      'data': encodeCallableWriteData(data),
    }).then((_) {});
  }

  Future<List<String>> createQuestionsBatch({
    required List<({String questionId, Map<String, dynamic> data})> items,
  }) async {
    final result = await _call('adminCreateQuestionsBatch', {
      'items': [
        for (final item in items)
          {
            'questionId': item.questionId,
            'data': encodeCallableWriteData(item.data),
          },
      ],
    });
    final ids = result['questionIds'];
    if (ids is List) {
      return [for (final id in ids) id.toString()];
    }
    return [for (final item in items) item.questionId];
  }

  Future<void> setQuestionStatus({
    required String questionId,
    required String status,
  }) {
    return _call('adminSetQuestionStatus', {
      'questionId': questionId,
      'status': status,
    }).then((_) {});
  }

  Future<void> setQuestionActive({
    required String questionId,
    required bool isActive,
  }) {
    return _call('adminSetQuestionActive', {
      'questionId': questionId,
      'isActive': isActive,
    }).then((_) {});
  }

  Future<Map<String, String>> getQuestionAssignments({
    required List<String> questionIds,
  }) async {
    return (await getQuestionAssignmentState(questionIds: questionIds)).owners;
  }

  Future<AdminQuestionAssignmentState> getQuestionAssignmentState({
    required List<String> questionIds,
  }) async {
    final result = await _call('adminGetQuestionAssignments', {
      'questionIds': questionIds,
    });
    final assignments = <String, String>{};
    final rawAssignments = result['assignments'];
    if (rawAssignments is List) {
      for (final item in rawAssignments) {
        if (item is! Map) continue;
        final questionId = item['questionId'];
        final testId = item['testId'];
        if (questionId is String &&
            testId is String &&
            testId.trim().isNotEmpty) {
          assignments[questionId] = testId;
        }
      }
    }
    final legacyTestIds = <String, List<String>>{};
    final rawLegacy = result['legacyReferences'];
    if (rawLegacy is List) {
      for (final item in rawLegacy) {
        if (item is! Map || item['questionId'] is! String) continue;
        final ids = item['testIds'];
        if (ids is List) {
          legacyTestIds[item['questionId'] as String] = [
            for (final id in ids)
              if (id is String && id.trim().isNotEmpty) id,
          ];
        }
      }
    }
    return AdminQuestionAssignmentState(
      owners: assignments,
      legacyTestIds: legacyTestIds,
    );
  }

  Future<String> createTest({
    required String testId,
    required Map<String, dynamic> data,
  }) async {
    final result = await _call('adminCreateTest', {
      'testId': testId,
      'data': encodeCallableWriteData(data),
    });
    return (result['testId'] as String?) ?? testId;
  }

  Future<void> updateTest({
    required String testId,
    required Map<String, dynamic> data,
  }) {
    return _call('adminUpdateTest', {
      'testId': testId,
      'data': encodeCallableWriteData(data),
    }).then((_) {});
  }

  Future<void> publishTest({required String testId}) {
    return _call('adminPublishTest', {'testId': testId}).then((_) {});
  }

  Future<void> setTestStatus({required String testId, required String status}) {
    return _call('adminSetTestStatus', {
      'testId': testId,
      'status': status,
    }).then((_) {});
  }

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    final override = callOverride;
    if (override != null) return override(name, data);
    try {
      if (kIsWeb) {
        return await _callViaHttp(name, data);
      }
      final resolved = functions ??= FirebaseFunctions.instanceFor(
        region: _region,
      );
      final result = await resolved.httpsCallable(name).call(data);
      final payload = result.data;
      if (payload is Map) return Map<String, dynamic>.from(payload);
      return const {};
    } on FirebaseFunctionsException catch (error) {
      debugPrint(
        'AdminContentCallableClient.$name failed: ${error.code} ${error.message}',
      );
      throw FormatException(error.message ?? error.code);
    }
  }

  /// Flutter Web dart2js cannot serialize Int64 used by the Functions plugin.
  /// Direct callable HTTP keeps Auth + assertAdmin and avoids that path.
  Future<Map<String, dynamic>> _callViaHttp(
    String name,
    Map<String, dynamic> data,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const FormatException('Authentication required.');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw const FormatException('Authentication required.');
    }

    final uri = Uri.https('$_region-$_projectId.cloudfunctions.net', '/$name');
    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'data': data}),
        )
        .timeout(const Duration(seconds: 70));

    final decoded = _decodeJsonMap(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final result = decoded['result'];
      if (result is Map) return Map<String, dynamic>.from(result);
      return const {};
    }

    final error = decoded['error'];
    final message =
        _callableErrorMessage(error) ??
        'Callable $name failed (${response.statusCode}).';
    debugPrint(
      'AdminContentCallableClient.$name failed: HTTP ${response.statusCode} $message',
    );
    throw FormatException(message);
  }

  Map<String, dynamic> _decodeJsonMap(String body) {
    if (body.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // Non-JSON gateway bodies fall through to a generic HTTP error.
    }
    return const {};
  }

  String? _callableErrorMessage(Object? error) {
    if (error is! Map) return null;
    final message = error['message'];
    if (message is String && message.trim().isNotEmpty) return message;
    final status = error['status'];
    if (status is String && status.trim().isNotEmpty) return status;
    return null;
  }
}
