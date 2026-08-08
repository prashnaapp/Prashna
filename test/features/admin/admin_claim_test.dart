import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/services/admin_claim.dart';

void main() {
  group('hasAdminClaim', () {
    test('1: admin claim true → admin', () {
      expect(hasAdminClaim({'admin': true}), isTrue);
    });

    test('2: admin claim false → not admin', () {
      expect(hasAdminClaim({'admin': false}), isFalse);
    });

    test('3: missing admin claim → not admin', () {
      expect(hasAdminClaim(const {}), isFalse);
      expect(hasAdminClaim({'role': 'admin'}), isFalse);
      expect(hasAdminClaim({'admin': 'true'}), isFalse);
      expect(hasAdminClaim({'admin': 1}), isFalse);
    });

    test('4: no authenticated user / null claims → not admin', () {
      expect(hasAdminClaim(null), isFalse);
    });
  });
}
