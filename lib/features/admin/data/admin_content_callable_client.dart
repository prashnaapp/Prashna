import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

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

/// Thin asia-south1 callable client for trusted admin catalog writes.
class AdminContentCallableClient {
  AdminContentCallableClient({this.functions, this.callOverride});

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
      final resolved = functions ??= FirebaseFunctions.instanceFor(
        region: 'asia-south1',
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
}
