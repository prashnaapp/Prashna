/// Thrown when student client code attempts to grant or mutate entitlements.
///
/// Paid (and client-written) enrollments are reserved for a trusted backend.
class EntitlementMutationForbidden implements Exception {
  const EntitlementMutationForbidden([
    this.message =
        'Client entitlement writes are disabled. '
        'Paid access requires a trusted payment backend.',
  ]);

  final String message;

  @override
  String toString() => 'EntitlementMutationForbidden: $message';
}
