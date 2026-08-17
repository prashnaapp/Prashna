import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Thin callable client for server-authoritative test attempts (asia-south1).
class TestAttemptApi {
  TestAttemptApi({
    this.functions,
    this.callOverride,
  });

  /// Optional; lazily defaults to asia-south1 when [callOverride] is null.
  FirebaseFunctions? functions;

  /// Test hook — when set, no Firebase initialization occurs.
  final Future<Map<String, dynamic>> Function(
    String name,
    Map<String, dynamic> data,
  )? callOverride;

  Future<Map<String, dynamic>> startTestAttempt({
    required String testId,
    required String startRequestId,
  }) {
    return _call('startTestAttempt', <String, dynamic>{
      'testId': testId,
      'startRequestId': startRequestId,
    });
  }

  Future<Map<String, dynamic>> submitTestAttempt({
    required String attemptId,
    required List<Map<String, String>> selectedAnswers,
  }) {
    return _call('submitTestAttempt', <String, dynamic>{
      'attemptId': attemptId,
      'selectedAnswers': selectedAnswers,
    });
  }

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    final override = callOverride;
    if (override != null) {
      return override(name, data);
    }
    try {
      final resolved = functions ??=
          FirebaseFunctions.instanceFor(region: 'asia-south1');
      final callable = resolved.httpsCallable(name);
      final result = await callable.call(data);
      final payload = result.data;
      if (payload is Map) {
        return Map<String, dynamic>.from(payload);
      }
      throw StateError('Invalid $name response');
    } on FirebaseFunctionsException catch (error) {
      debugPrint('TestAttemptApi.$name failed: ${error.code} ${error.message}');
      rethrow;
    }
  }
}
