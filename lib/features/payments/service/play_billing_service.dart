import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../../course_enrollment/service/course_enrollment_service.dart';
import '../config/play_billing_config.dart';
import '../model/play_purchase_models.dart';

/// Abstraction over Google Play Billing for the Flutter client.
///
/// Never writes entitlements or payment transactions. After a PURCHASED
/// update, sends the purchase token to the trusted backend for verification.
class PlayBillingService {
  PlayBillingService({
    InAppPurchase? inAppPurchase,
    FirebaseAuth? firebaseAuth,
    FirebaseFunctions? functions,
    CourseEnrollmentService? enrollmentService,
    this.verifyPurchaseOverride,
  })  : _iap = inAppPurchase ?? InAppPurchase.instance,
        _auth = firebaseAuth ?? FirebaseAuth.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-south1'),
        _enrollmentService =
            enrollmentService ?? CourseEnrollmentService.instance;

  static final PlayBillingService instance = PlayBillingService();

  final InAppPurchase _iap;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;
  final CourseEnrollmentService _enrollmentService;

  /// Test seam for backend verification without Cloud Functions.
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> payload)?
      verifyPurchaseOverride;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  final _pendingCompleters = <String, Completer<PlayPurchaseFlowResult>>{};

  bool get isStoreAvailableSync => true;

  Future<bool> isAvailable() => _iap.isAvailable();

  /// SHA-256 hex of the Firebase UID, truncated to Play's 64-char limit.
  /// Never send the raw UID as a public purchase identifier.
  static String obfuscatedAccountIdForUid(String uid) {
    final digest = sha256.convert(utf8.encode(uid.trim()));
    final hex = digest.toString();
    return hex.length <= 64 ? hex : hex.substring(0, 64);
  }

  Future<PlayProductOffer?> loadGroupIiOffer() async {
    final available = await _iap.isAvailable();
    if (!available) return null;

    final response = await _iap.queryProductDetails(
      PlayBillingConfig.queryProductIds,
    );
    if (response.error != null) {
      debugPrint('Play product query error: ${response.error}');
      return null;
    }
    if (response.productDetails.isEmpty) return null;

    final product = response.productDetails.firstWhere(
      (p) => p.id == PlayBillingConfig.groupIi12MonthProductId,
      orElse: () => response.productDetails.first,
    );
    return PlayProductOffer(
      productId: product.id,
      title: product.title,
      description: product.description,
      priceLabel: product.price,
      rawPrice: product.rawPrice,
      currencyCode: product.currencyCode,
    );
  }

  /// Starts purchase for [productId] and waits for the matching stream update
  /// plus backend verification when status is purchased.
  Future<PlayPurchaseFlowResult> purchaseProduct(String productId) async {
    final user = _auth.currentUser;
    if (user == null) {
      return const PlayPurchaseFlowResult(
        state: PlayPurchaseUiState.failed,
        message: 'Sign in required before purchasing.',
      );
    }

    final available = await _iap.isAvailable();
    if (!available) {
      return const PlayPurchaseFlowResult(
        state: PlayPurchaseUiState.unavailable,
        message: 'Google Play Billing is unavailable on this device.',
      );
    }

    final response = await _iap.queryProductDetails({productId});
    if (response.error != null || response.productDetails.isEmpty) {
      return PlayPurchaseFlowResult(
        state: PlayPurchaseUiState.failed,
        message: response.error?.message ??
            'Product not found in Google Play. Check Play Console setup.',
        productId: productId,
      );
    }

    final product = response.productDetails.first;
    await _ensurePurchaseListener();

    final completer = Completer<PlayPurchaseFlowResult>();
    _pendingCompleters[productId] = completer;

    final obfuscated = obfuscatedAccountIdForUid(user.uid);
    final PurchaseParam purchaseParam = defaultTargetPlatform == TargetPlatform.android
        ? GooglePlayPurchaseParam(
            productDetails: product,
            // Maps to Google Play obfuscatedAccountId.
            applicationUserName: obfuscated,
          )
        : PurchaseParam(
            productDetails: product,
            applicationUserName: obfuscated,
          );

    final launched = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    if (!launched) {
      _pendingCompleters.remove(productId);
      return PlayPurchaseFlowResult(
        state: PlayPurchaseUiState.cancelled,
        message: 'Purchase was not started.',
        productId: productId,
      );
    }

    return completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        _pendingCompleters.remove(productId);
        return PlayPurchaseFlowResult(
          state: PlayPurchaseUiState.failed,
          message: 'Purchase timed out waiting for Google Play.',
          productId: productId,
        );
      },
    );
  }

  /// Restores / re-verifies existing Google Play purchases via the backend.
  Future<List<PlayPurchaseFlowResult>> restoreAndVerifyPurchases() async {
    final user = _auth.currentUser;
    if (user == null) return const [];

    await _ensurePurchaseListener();
    final results = <PlayPurchaseFlowResult>[];

    // Capture purchases emitted during restore.
    final restoreCompleter = Completer<void>();
    final seen = <String>{};
    late final StreamSubscription<List<PurchaseDetails>> sub;
    sub = _iap.purchaseStream.listen((purchases) async {
      for (final purchase in purchases) {
        if (purchase.status != PurchaseStatus.purchased &&
            purchase.status != PurchaseStatus.restored) {
          continue;
        }
        final token = _purchaseToken(purchase);
        if (token == null || !seen.add(token)) continue;
        final verified = await _verifyWithBackend(purchase);
        results.add(verified);
      }
    });

    try {
      await _iap.restorePurchases(
        applicationUserName: obfuscatedAccountIdForUid(user.uid),
      );
      // Allow stream deliveries to settle briefly.
      await Future<void>.delayed(const Duration(seconds: 2));
    } finally {
      await sub.cancel();
      if (!restoreCompleter.isCompleted) restoreCompleter.complete();
    }

    if (results.any((r) => r.unlockedAccess)) {
      await _enrollmentService.reloadCourseContext();
    }
    return results;
  }

  Future<void> _ensurePurchaseListener() async {
    if (_purchaseSub != null) return;
    _purchaseSub = _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object error, StackTrace stack) {
        debugPrint('Play purchase stream error: $error\n$stack');
      },
    );
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      final productId = purchase.productID;
      final completer = _pendingCompleters[productId];

      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Do not verify, grant, or acknowledge.
          completer?.complete(
            PlayPurchaseFlowResult(
              state: PlayPurchaseUiState.pending,
              message:
                  'Payment is pending. Access unlocks after Google confirms.',
              productId: productId,
            ),
          );
          _pendingCompleters.remove(productId);
          break;
        case PurchaseStatus.canceled:
          completer?.complete(
            PlayPurchaseFlowResult(
              state: PlayPurchaseUiState.cancelled,
              message: 'Purchase cancelled.',
              productId: productId,
            ),
          );
          _pendingCompleters.remove(productId);
          break;
        case PurchaseStatus.error:
          completer?.complete(
            PlayPurchaseFlowResult(
              state: PlayPurchaseUiState.failed,
              message: purchase.error?.message ?? 'Purchase failed.',
              productId: productId,
            ),
          );
          _pendingCompleters.remove(productId);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final verified = await _verifyWithBackend(purchase);
          if (verified.unlockedAccess) {
            await _enrollmentService.reloadCourseContext();
          }
          // Finish local Play Billing queue only after backend handling.
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          completer?.complete(verified);
          _pendingCompleters.remove(productId);
          break;
      }
    }
  }

  Future<PlayPurchaseFlowResult> _verifyWithBackend(
    PurchaseDetails purchase,
  ) async {
    final token = _purchaseToken(purchase);
    if (token == null || token.isEmpty) {
      return PlayPurchaseFlowResult(
        state: PlayPurchaseUiState.failed,
        message: 'Missing Google Play purchase token.',
        productId: purchase.productID,
      );
    }

    try {
      final data = await _callVerify(
        productId: purchase.productID,
        purchaseToken: token,
      );
      final status = data['status'] as String? ?? 'error';
      if (status == 'pending') {
        return PlayPurchaseFlowResult(
          state: PlayPurchaseUiState.pending,
          message: data['message'] as String? ?? 'Purchase still pending.',
          productId: purchase.productID,
          purchaseToken: token,
        );
      }
      if (status == 'already_owned' || data['duplicate'] == true) {
        return PlayPurchaseFlowResult(
          state: PlayPurchaseUiState.alreadyOwned,
          message: data['message'] as String? ?? 'Purchase already applied.',
          productId: purchase.productID,
          purchaseToken: token,
          transactionId: data['transactionId'] as String?,
          courseId: data['courseId'] as String?,
        );
      }
      if (status == 'success') {
        return PlayPurchaseFlowResult(
          state: PlayPurchaseUiState.purchased,
          message: 'Purchase verified. Access unlocked.',
          productId: purchase.productID,
          purchaseToken: token,
          transactionId: data['transactionId'] as String?,
          courseId: data['courseId'] as String?,
        );
      }
      return PlayPurchaseFlowResult(
        state: PlayPurchaseUiState.failed,
        message: data['message'] as String? ?? 'Verification failed.',
        productId: purchase.productID,
        purchaseToken: token,
      );
    } on FirebaseFunctionsException catch (error) {
      return PlayPurchaseFlowResult(
        state: PlayPurchaseUiState.failed,
        message: error.message ?? error.code,
        productId: purchase.productID,
        purchaseToken: token,
      );
    } catch (error) {
      return PlayPurchaseFlowResult(
        state: PlayPurchaseUiState.failed,
        message: error.toString(),
        productId: purchase.productID,
        purchaseToken: token,
      );
    }
  }

  Future<Map<String, dynamic>> _callVerify({
    required String productId,
    required String purchaseToken,
  }) async {
    if (verifyPurchaseOverride != null) {
      return verifyPurchaseOverride!({
        'productId': productId,
        'purchaseToken': purchaseToken,
        'packageName': PlayBillingConfig.packageName,
      });
    }

    final callable = _functions.httpsCallable('verifyPlayPurchase');
    final result = await callable.call(<String, dynamic>{
      'productId': productId,
      'purchaseToken': purchaseToken,
      'packageName': PlayBillingConfig.packageName,
    });
    final data = result.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{'status': 'error', 'message': 'Invalid response'};
  }

  String? _purchaseToken(PurchaseDetails purchase) {
    if (purchase is GooglePlayPurchaseDetails) {
      final token = purchase.billingClientPurchase.purchaseToken;
      if (token.isNotEmpty) return token;
    }
    // Fallback for platform interface verification in tests.
    final verification = purchase.verificationData.serverVerificationData;
    return verification.isEmpty ? null : verification;
  }

  Future<void> dispose() async {
    await _purchaseSub?.cancel();
    _purchaseSub = null;
  }
}
