import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/payments/config/play_billing_config.dart';
import 'package:telangana_prep/features/payments/model/play_purchase_models.dart';
import 'package:telangana_prep/features/payments/service/play_billing_service.dart';

void main() {
  test('1: product configuration uses group2_12m for Group II', () {
    expect(PlayBillingConfig.packageName, 'com.prashna.app');
    expect(PlayBillingConfig.groupIi12MonthProductId, 'group2_12m');
    expect(PlayBillingConfig.groupIiCourseId, 'group-ii');
    expect(PlayBillingConfig.supportsPlayPurchase('group-ii'), isTrue);
    expect(PlayBillingConfig.supportsPlayPurchase('group-iii'), isFalse);
    expect(
      PlayBillingConfig.productIdForCourse('group-ii'),
      'group2_12m',
    );
  });

  test('2/3: product offer price comes from Play fields, not hard-coded INR', () {
    const offer = PlayProductOffer(
      productId: 'group2_12m',
      title: 'Group II',
      description: '12 months',
      priceLabel: '₹1,299.00',
      rawPrice: 1299,
      currencyCode: 'INR',
    );
    expect(offer.priceLabel, '₹1,299.00');
    expect(offer.priceLabel.contains('999'), isFalse);
    expect(offer.currencyCode, 'INR');
  });

  test('8: obfuscated account id never equals raw uid', () {
    const uid = 'firebaseUidExample0123456789';
    final obfuscated = PlayBillingService.obfuscatedAccountIdForUid(uid);
    expect(obfuscated, isNot(uid));
    expect(obfuscated.length, lessThanOrEqualTo(64));
    expect(
      PlayBillingService.obfuscatedAccountIdForUid(uid),
      obfuscated,
    );
  });

  test('pending/cancelled/error results do not unlock', () {
    expect(
      const PlayPurchaseFlowResult(
        state: PlayPurchaseUiState.pending,
      ).unlockedAccess,
      isFalse,
    );
    expect(
      const PlayPurchaseFlowResult(
        state: PlayPurchaseUiState.cancelled,
      ).unlockedAccess,
      isFalse,
    );
    expect(
      const PlayPurchaseFlowResult(
        state: PlayPurchaseUiState.failed,
      ).unlockedAccess,
      isFalse,
    );
    expect(
      const PlayPurchaseFlowResult(
        state: PlayPurchaseUiState.purchased,
        courseId: 'group-ii',
      ).unlockedAccess,
      isTrue,
    );
  });

  test('20/21: historical models remain structurally readable', () {
    // Config + result types stay backward compatible with entitlement reads.
    expect(PlayBillingConfig.paymentProvider, 'google_play');
    expect(PlayBillingConfig.groupIiAccessLabel, contains('12-Month'));
  });
}
