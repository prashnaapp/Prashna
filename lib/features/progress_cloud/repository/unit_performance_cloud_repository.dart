import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../authentication/services/auth_service.dart';
import '../../progress/data/models/unit_performance.dart';

/// Read-only seam for `user_progress/{uid}/unit_performance/{scopeKey}`.
abstract class UnitPerformanceDocumentStore {
  Future<Map<String, dynamic>?> getUnitPerformance(String uid, String scopeKey);
}

/// Firestore implementation — read only.
class FirestoreUnitPerformanceDocumentStore
    implements UnitPerformanceDocumentStore {
  FirestoreUnitPerformanceDocumentStore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'user_progress';
  static const String unitPerformanceSubcollectionName = 'unit_performance';

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> docRef(String uid, String scopeKey) {
    return _firestore
        .collection(collectionName)
        .doc(uid)
        .collection(unitPerformanceSubcollectionName)
        .doc(scopeKey);
  }

  @override
  Future<Map<String, dynamic>?> getUnitPerformance(
    String uid,
    String scopeKey,
  ) async {
    final snapshot = await docRef(uid, scopeKey).get();
    if (!snapshot.exists) return null;
    return snapshot.data();
  }
}

/// In-memory store for unit tests.
class InMemoryUnitPerformanceDocumentStore
    implements UnitPerformanceDocumentStore {
  final Map<String, Map<String, Map<String, dynamic>>> _byUid = {};

  void seed(String uid, String scopeKey, Map<String, dynamic> data) {
    _byUid.putIfAbsent(uid, () => {})[scopeKey] = Map<String, dynamic>.from(
      data,
    );
  }

  String? lastUid;
  String? lastScopeKey;

  @override
  Future<Map<String, dynamic>?> getUnitPerformance(
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

/// Student read path for canonical unit performance.
///
/// Never creates, updates, or deletes documents.
class UnitPerformanceCloudRepository {
  UnitPerformanceCloudRepository({
    UnitPerformanceDocumentStore? store,
    FirebaseFirestore? firestore,
    String? Function()? currentUid,
  }) : _store =
           store ??
           FirestoreUnitPerformanceDocumentStore(firestore: firestore),
       _currentUid = currentUid ?? _defaultUid;

  static const String collectionName =
      FirestoreUnitPerformanceDocumentStore.collectionName;
  static const String unitPerformanceSubcollectionName =
      FirestoreUnitPerformanceDocumentStore.unitPerformanceSubcollectionName;

  final UnitPerformanceDocumentStore _store;
  final String? Function() _currentUid;

  static String? _defaultUid() => AuthService.instance.currentUser?.uid;

  /// Loads `user_progress/{uid}/unit_performance/{scopeKey}` for the current
  /// authenticated user.
  ///
  /// Returns `null` when the document does not exist.
  /// Throws [StateError] when signed out.
  /// Rethrows Firestore / parse failures so UI can show Retry.
  Future<UnitPerformance?> getUnitPerformance(String scopeKey) async {
    final uid = _currentUid();
    if (uid == null || uid.trim().isEmpty) {
      throw StateError('Cannot load unit performance: no authenticated user.');
    }
    final cleanKey = scopeKey.trim();
    if (cleanKey.isEmpty) {
      throw ArgumentError('scopeKey must be a non-empty string');
    }

    try {
      final data = await _store.getUnitPerformance(uid, cleanKey);
      if (data == null) return null;

      final bodyUid = data['uid'];
      if (bodyUid is String && bodyUid.trim().isNotEmpty && bodyUid != uid) {
        throw FormatException(
          'Unit performance uid mismatch: path=$uid body=$bodyUid',
        );
      }

      return UnitPerformance.fromFirestore(cleanKey, data);
    } on FirebaseException catch (error, stack) {
      debugPrint(
        'FirebaseException in UnitPerformanceCloudRepository.getUnitPerformance: '
        'code=${error.code} message=${error.message}\n$stack',
      );
      rethrow;
    } catch (error, stack) {
      debugPrint(
        'UnitPerformanceCloudRepository.getUnitPerformance: $error\n$stack',
      );
      rethrow;
    }
  }
}
