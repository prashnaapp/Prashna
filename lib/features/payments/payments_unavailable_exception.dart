/// Thrown when a client attempts a purchase or payment write that is disabled
/// until a trusted payment provider + backend exist.
class PaymentsUnavailableException implements Exception {
  const PaymentsUnavailableException([
    this.message =
        'Payments are not available yet. '
        'Paid enrollment requires a trusted payment system.',
  ]);

  final String message;

  @override
  String toString() => 'PaymentsUnavailableException: $message';
}
