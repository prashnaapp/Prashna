/// Client-side purchase UI / flow states for Google Play Billing.
enum PlayPurchaseUiState {
  available,
  purchasing,
  pending,
  verifying,
  purchased,
  alreadyOwned,
  cancelled,
  failed,
  unavailable,
}

/// Localized product offer returned by Google Play (never hard-coded INR).
class PlayProductOffer {
  const PlayProductOffer({
    required this.productId,
    required this.title,
    required this.description,
    required this.priceLabel,
    required this.rawPrice,
    required this.currencyCode,
  });

  final String productId;
  final String title;
  final String description;

  /// Localized price string from Google Play (e.g. "₹999.00").
  final String priceLabel;
  final double rawPrice;
  final String currencyCode;
}

/// Result of a client purchase attempt after backend verification (if any).
class PlayPurchaseFlowResult {
  const PlayPurchaseFlowResult({
    required this.state,
    this.message,
    this.productId,
    this.purchaseToken,
    this.transactionId,
    this.courseId,
  });

  final PlayPurchaseUiState state;
  final String? message;
  final String? productId;
  final String? purchaseToken;
  final String? transactionId;
  final String? courseId;

  bool get unlockedAccess =>
      state == PlayPurchaseUiState.purchased ||
      state == PlayPurchaseUiState.alreadyOwned;
}
