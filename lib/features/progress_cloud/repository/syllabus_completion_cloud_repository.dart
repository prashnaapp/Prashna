import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../../authentication/services/auth_service.dart';
import '../../progress/data/models/syllabus_completion.dart';
import '../../syllabus/data/models/canonical_scope.dart';

/// Read seam for `user_progress/{uid}/syllabus_completion/{scopeKey}`.
abstract class SyllabusCompletionDocumentStore {
  Future<Map<String, dynamic>?> getCompletion(String uid, String scopeKey);
}

/// Firestore implementation — read only.
class FirestoreSyllabusCompletionDocumentStore
    implements SyllabusCompletionDocumentStore {
  FirestoreSyllabusCompletionDocumentStore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'user_progress';
  static const String syllabusCompletionSubcollectionName =
      'syllabus_completion';

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> docRef(String uid, String scopeKey) {
    return _firestore
        .collection(collectionName)
        .doc(uid)
        .collection(syllabusCompletionSubcollectionName)
        .doc(scopeKey);
  }

  @override
  Future<Map<String, dynamic>?> getCompletion(
    String uid,
    String scopeKey,
  ) async {
    final snapshot = await docRef(uid, scopeKey).get();
    if (!snapshot.exists) return null;
    return snapshot.data();
  }
}

/// In-memory store for unit tests.
class InMemorySyllabusCompletionDocumentStore
    implements SyllabusCompletionDocumentStore {
  final Map<String, Map<String, Map<String, dynamic>>> _byUid = {};

  void seed(String uid, String scopeKey, Map<String, dynamic> data) {
    _byUid.putIfAbsent(uid, () => {})[scopeKey] = Map<String, dynamic>.from(
      data,
    );
  }

  void remove(String uid, String scopeKey) {
    _byUid[uid]?.remove(scopeKey);
  }

  String? lastUid;
  String? lastScopeKey;

  @override
  Future<Map<String, dynamic>?> getCompletion(
    String uid,
    String scopeKey,
  ) async {
    lastUid = uid;
    lastScopeKey = scopeKey;
    final data = _byUid[uid]?[scopeKey];
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }
}

/// Trusted mutation seam — never writes Firestore from the client.
abstract class SyllabusCompletionMutationClient {
  Future<Map<String, dynamic>> setCompletionStatus({
    required String courseId,
    required String paperId,
    String? partId,
    required String syllabusUnitId,
    required String status,
  });
}

/// HTTPS callable client for `setSyllabusCompletion`.
class CallableSyllabusCompletionMutationClient
    implements SyllabusCompletionMutationClient {
  CallableSyllabusCompletionMutationClient({
    this._functions,
    this.callOverride,
  });

  FirebaseFunctions? _functions;

  /// Test hook — when set, no Firebase initialization occurs.
  final Future<Map<String, dynamic>> Function(
    String name,
    Map<String, dynamic> data,
  )?
  callOverride;

  @override
  Future<Map<String, dynamic>> setCompletionStatus({
    required String courseId,
    required String paperId,
    String? partId,
    required String syllabusUnitId,
    required String status,
  }) async {
    final payload = <String, dynamic>{
      'courseId': courseId,
      'paperId': paperId,
      'partId': ?partId,
      'syllabusUnitId': syllabusUnitId,
      'status': status,
    };

    final override = callOverride;
    if (override != null) {
      return override('setSyllabusCompletion', payload);
    }

    try {
      final resolved = _functions ??= FirebaseFunctions.instanceFor(
        region: 'asia-south1',
      );
      final callable = resolved.httpsCallable('setSyllabusCompletion');
      final result = await callable.call(payload);
      final data = result.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      throw StateError('Invalid setSyllabusCompletion response');
    } on FirebaseFunctionsException catch (error) {
      debugPrint(
        'SyllabusCompletionMutationClient failed: '
        '${error.code} ${error.message}',
      );
      rethrow;
    }
  }
}

/// Student read + trusted mutation path for canonical syllabus completion.
///
/// Never exposes arbitrary Firestore write methods.
class SyllabusCompletionCloudRepository {
  SyllabusCompletionCloudRepository({
    SyllabusCompletionDocumentStore? store,
    SyllabusCompletionMutationClient? mutationClient,
    FirebaseFirestore? firestore,
    String? Function()? currentUid,
  }) : _store =
           store ??
           FirestoreSyllabusCompletionDocumentStore(firestore: firestore),
       _mutationClient =
           mutationClient ?? CallableSyllabusCompletionMutationClient(),
       _currentUid = currentUid ?? _defaultUid;

  static const String collectionName =
      FirestoreSyllabusCompletionDocumentStore.collectionName;
  static const String syllabusCompletionSubcollectionName =
      FirestoreSyllabusCompletionDocumentStore
          .syllabusCompletionSubcollectionName;

  final SyllabusCompletionDocumentStore _store;
  final SyllabusCompletionMutationClient _mutationClient;
  final String? Function() _currentUid;

  static String? _defaultUid() => AuthService.instance.currentUser?.uid;

  /// Loads completion for the current authenticated user.
  ///
  /// Returns [SyllabusCompletion.notStarted] when the document is missing.
  /// Throws [StateError] when signed out.
  /// Rethrows Firestore / parse failures so UI can show Retry.
  Future<SyllabusCompletion> getCompletion({
    required CanonicalScope scope,
  }) async {
    final uid = _requireUid();
    final scopeKey = scope.scopeKey;

    try {
      final data = await _store.getCompletion(uid, scopeKey);
      if (data == null) {
        return SyllabusCompletion.notStarted(
          scopeKey: scopeKey,
          courseId: scope.courseId,
          paperId: scope.paperId,
          partId: scope.partId,
          syllabusUnitId: scope.syllabusUnitId,
        );
      }

      final bodyUid = data['uid'];
      if (bodyUid is String && bodyUid.trim().isNotEmpty && bodyUid != uid) {
        throw FormatException(
          'Syllabus completion uid mismatch: path=$uid body=$bodyUid',
        );
      }

      return SyllabusCompletion.fromFirestore(scopeKey, data);
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in SyllabusCompletionCloudRepository.getCompletion: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint(
        'SyllabusCompletionCloudRepository.getCompletion: $error\n$stack',
      );
      rethrow;
    }
  }

  Future<SyllabusCompletion> setInProgress(CanonicalScope scope) {
    return _mutate(
      scope: scope,
      status: SyllabusCompletionStatus.inProgress,
    );
  }

  Future<SyllabusCompletion> setCompleted(CanonicalScope scope) {
    return _mutate(
      scope: scope,
      status: SyllabusCompletionStatus.completed,
    );
  }

  Future<SyllabusCompletion> resetToNotStarted(CanonicalScope scope) {
    return _mutate(
      scope: scope,
      status: SyllabusCompletionStatus.notStarted,
    );
  }

  Future<SyllabusCompletion> _mutate({
    required CanonicalScope scope,
    required SyllabusCompletionStatus status,
  }) async {
    _requireUid();
    scope.validate();

    final response = await _mutationClient.setCompletionStatus(
      courseId: scope.courseId,
      paperId: scope.paperId,
      partId: scope.partId,
      syllabusUnitId: scope.syllabusUnitId,
      status: status.wireValue,
    );

    final completionData = response['completion'];
    if (completionData is Map) {
      final map = Map<String, dynamic>.from(completionData);
      final key =
          (map['scopeKey'] as String?)?.trim().isNotEmpty == true
          ? (map['scopeKey'] as String).trim()
          : scope.scopeKey;
      if (status == SyllabusCompletionStatus.notStarted &&
          map['status'] == null) {
        return SyllabusCompletion.notStarted(
          scopeKey: key,
          courseId: scope.courseId,
          paperId: scope.paperId,
          partId: scope.partId,
          syllabusUnitId: scope.syllabusUnitId,
        );
      }
      return SyllabusCompletion.fromFirestore(key, map);
    }

    if (status == SyllabusCompletionStatus.notStarted) {
      return SyllabusCompletion.notStarted(
        scopeKey: scope.scopeKey,
        courseId: scope.courseId,
        paperId: scope.paperId,
        partId: scope.partId,
        syllabusUnitId: scope.syllabusUnitId,
      );
    }

    throw StateError('Invalid setSyllabusCompletion response payload');
  }

  String _requireUid() {
    final uid = _currentUid();
    if (uid == null || uid.trim().isEmpty) {
      throw StateError(
        'Cannot access syllabus completion: no authenticated user.',
      );
    }
    return uid;
  }
}
