import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../course_enrollment/service/course_loader_service.dart';
import '../../../payments/config/play_billing_config.dart';
import '../../../payments/model/payment_plan.dart';
import '../../../payments/model/play_purchase_models.dart';
import '../../../payments/service/payment_service.dart';
import '../../../payments/service/play_billing_service.dart';
import '../../../subscription/service/subscription_access_service.dart';

/// Paywall for a paid course.
///
/// Group II uses Google Play Billing with server-side verification.
/// Other courses keep the catalog preview until products are configured.
class CourseSubscriptionScreen extends StatefulWidget {
  const CourseSubscriptionScreen({
    super.key,
    required this.courseId,
    this.paymentService,
    this.playBillingService,
    this.accessService,
  });

  final String courseId;
  final PaymentService? paymentService;
  final PlayBillingService? playBillingService;
  final SubscriptionAccessService? accessService;

  @override
  State<CourseSubscriptionScreen> createState() =>
      _CourseSubscriptionScreenState();
}

class _CourseSubscriptionScreenState extends State<CourseSubscriptionScreen> {
  late Future<List<PaymentPlan>> _plansFuture;
  late Future<_GroupIiOfferLoad> _groupIiFuture;
  PlayPurchaseUiState _uiState = PlayPurchaseUiState.available;
  String? _statusMessage;

  PaymentService get _payments =>
      widget.paymentService ?? PaymentService.instance;

  PlayBillingService get _play =>
      widget.playBillingService ?? PlayBillingService.instance;

  SubscriptionAccessService get _access =>
      widget.accessService ?? SubscriptionAccessService.instance;

  bool get _isGroupIiPlay =>
      PlayBillingConfig.supportsPlayPurchase(widget.courseId);

  @override
  void initState() {
    super.initState();
    _plansFuture = _loadPlans();
    _groupIiFuture = _loadGroupIi();
  }

  Future<List<PaymentPlan>> _loadPlans() async {
    final all = await _payments.loadActivePlans();
    final plans = [
      for (final plan in all)
        if (plan.courseId == widget.courseId && plan.isActive) plan,
    ];
    plans.sort((a, b) {
      final aDays = a.durationDays ?? 1 << 30;
      final bDays = b.durationDays ?? 1 << 30;
      return aDays.compareTo(bDays);
    });
    return plans;
  }

  Future<_GroupIiOfferLoad> _loadGroupIi() async {
    if (!_isGroupIiPlay) {
      return const _GroupIiOfferLoad(offer: null, alreadyOwned: false);
    }
    final alreadyOwned = await _access.hasCourseAccess(widget.courseId);
    final offer = await _play.loadGroupIiOffer();
    return _GroupIiOfferLoad(offer: offer, alreadyOwned: alreadyOwned);
  }

  String get _courseTitle {
    final published =
        CourseLoaderService.instance.current?.publishedCourses ?? const [];
    for (final course in published) {
      if (course.courseId == widget.courseId) {
        if (course.title.isNotEmpty) return course.title;
        if (course.shortTitle.isNotEmpty) return course.shortTitle;
      }
    }
    return switch (widget.courseId) {
      'group-ii' => 'Group II',
      'group-iii' => 'Group III',
      _ => widget.courseId,
    };
  }

  Future<void> _buyGroupIi() async {
    setState(() {
      _uiState = PlayPurchaseUiState.purchasing;
      _statusMessage = 'Opening Google Play…';
    });

    final result = await _play.purchaseProduct(
      PlayBillingConfig.groupIi12MonthProductId,
    );

    if (!mounted) return;
    setState(() {
      _uiState = result.state == PlayPurchaseUiState.purchased ||
              result.state == PlayPurchaseUiState.alreadyOwned
          ? result.state
          : result.state;
      _statusMessage = result.message;
      if (result.state == PlayPurchaseUiState.verifying) {
        _statusMessage = 'Verifying purchase with server…';
      }
    });

    if (result.unlockedAccess) {
      setState(() {
        _groupIiFuture = _loadGroupIi();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('$_courseTitle Subscription')),
      body: SafeArea(
        child: _isGroupIiPlay ? _buildGroupIiBody(context) : _buildLegacyBody(),
      ),
    );
  }

  Widget _buildGroupIiBody(BuildContext context) {
    return FutureBuilder<_GroupIiOfferLoad>(
      future: _groupIiFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: AppCircularProgress());
        }
        if (snapshot.hasError) {
          return _MessageBody(
            title: 'Unable to load offer',
            message: 'Please check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () {
              setState(() {
                _groupIiFuture = _loadGroupIi();
              });
            },
          );
        }

        final load = snapshot.data!;
        final offer = load.offer;
        final busy = _uiState == PlayPurchaseUiState.purchasing ||
            _uiState == PlayPurchaseUiState.verifying ||
            _uiState == PlayPurchaseUiState.pending;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                  AppSpacing.lg,
                ),
                children: [
                  Text('Group II', style: AppTextStyles.headline(context)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    PlayBillingConfig.groupIiAccessLabel,
                    style: AppTextStyles.titleMedium(context),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'One-time Google Play purchase. Access is unlocked only '
                    'after server verification — not when the Play sheet closes.',
                    style: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  if (offer == null)
                    Text(
                      'Product ${PlayBillingConfig.groupIi12MonthProductId} '
                      'is not available from Google Play yet. Configure it in '
                      'Play Console and use a license tester account.',
                      style: AppTextStyles.bodyMedium(
                        context,
                      ).copyWith(color: AppColors.textSecondary),
                    )
                  else
                    Container(
                      padding: AppSpacing.cardPadding,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.lgAll,
                        border: Border.all(
                          color: AppColors.divider.withValues(alpha: 0.8),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.title.isNotEmpty
                                ? offer.title
                                : 'Group II — ${PlayBillingConfig.groupIiAccessLabel}',
                            style: AppTextStyles.titleMedium(context),
                          ),
                          if (offer.description.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              offer.description,
                              style: AppTextStyles.bodyMedium(
                                context,
                              ).copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            offer.priceLabel,
                            style: AppTextStyles.titleMedium(
                              context,
                            ).copyWith(color: AppColors.primary),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Price from Google Play (${offer.currencyCode})',
                            style: AppTextStyles.label(
                              context,
                            ).copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      _statusMessage!,
                      style: AppTextStyles.bodyMedium(context),
                    ),
                  ],
                  if (load.alreadyOwned ||
                      _uiState == PlayPurchaseUiState.purchased ||
                      _uiState == PlayPurchaseUiState.alreadyOwned) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'You already have Group II access on this account.',
                      style: AppTextStyles.titleMedium(context),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.md,
                AppSpacing.xxl,
                AppSpacing.xxl,
              ),
              child: AppPrimaryButton(
                label: _buttonLabel(
                  offer: offer,
                  alreadyOwned: load.alreadyOwned,
                  busy: busy,
                ),
                onPressed: offer == null ||
                        busy ||
                        load.alreadyOwned ||
                        _uiState == PlayPurchaseUiState.purchased ||
                        _uiState == PlayPurchaseUiState.alreadyOwned
                    ? null
                    : _buyGroupIi,
              ),
            ),
          ],
        );
      },
    );
  }

  String _buttonLabel({
    required PlayProductOffer? offer,
    required bool alreadyOwned,
    required bool busy,
  }) {
    if (alreadyOwned ||
        _uiState == PlayPurchaseUiState.purchased ||
        _uiState == PlayPurchaseUiState.alreadyOwned) {
      return 'Purchased';
    }
    switch (_uiState) {
      case PlayPurchaseUiState.purchasing:
        return 'Purchasing…';
      case PlayPurchaseUiState.verifying:
        return 'Verifying…';
      case PlayPurchaseUiState.pending:
        return 'Payment pending…';
      case PlayPurchaseUiState.cancelled:
        return offer == null ? 'Unavailable' : 'Buy with Google Play';
      case PlayPurchaseUiState.failed:
        return offer == null ? 'Unavailable' : 'Try again';
      case PlayPurchaseUiState.unavailable:
        return 'Unavailable';
      case PlayPurchaseUiState.available:
      case PlayPurchaseUiState.purchased:
      case PlayPurchaseUiState.alreadyOwned:
        if (offer == null) return 'Unavailable';
        return 'Buy · ${offer.priceLabel}';
    }
  }

  Widget _buildLegacyBody() {
    return FutureBuilder<List<PaymentPlan>>(
      future: _plansFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: AppCircularProgress());
        }

        if (snapshot.hasError) {
          return _MessageBody(
            title: 'Unable to load plans',
            message: 'Please check your connection and try again.',
            actionLabel: 'Retry',
            onAction: () {
              setState(() {
                _plansFuture = _loadPlans();
              });
            },
          );
        }

        final plans = snapshot.data ?? const <PaymentPlan>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                  AppSpacing.lg,
                ),
                children: [
                  Text(
                    'Payments coming soon',
                    style: AppTextStyles.headline(context),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Paid enrollment for $_courseTitle is not configured for '
                    'Google Play yet.',
                    style: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
                  if (plans.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'Planned options',
                      style: AppTextStyles.titleMedium(context),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (var i = 0; i < plans.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.md),
                      _PlanTile(
                        plan: plans[i],
                        highlighted: plans[i].durationDays == 90,
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.md,
                AppSpacing.xxl,
                AppSpacing.xxl,
              ),
              child: AppPrimaryButton(
                label: 'Payments coming soon',
                onPressed: null,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GroupIiOfferLoad {
  const _GroupIiOfferLoad({
    required this.offer,
    required this.alreadyOwned,
  });

  final PlayProductOffer? offer;
  final bool alreadyOwned;
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.highlighted,
  });

  final PaymentPlan plan;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: highlighted
              ? AppColors.primary.withValues(alpha: 0.45)
              : AppColors.divider.withValues(alpha: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(plan.title, style: AppTextStyles.titleMedium(context)),
          if (plan.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              plan.description,
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            '${_formatAmount(plan)} · ${_formatDuration(plan)}',
            style: AppTextStyles.titleMedium(
              context,
            ).copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  String _formatAmount(PaymentPlan plan) {
    final amount = plan.amount;
    final whole = amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toString();
    final currency =
        plan.currency.toUpperCase() == 'INR' ? '₹' : '${plan.currency} ';
    return '$currency$whole';
  }

  String _formatDuration(PaymentPlan plan) {
    final days = plan.durationDays;
    if (days == null) return 'Flexible duration';
    if (days == 1) return '1 day';
    return '$days days';
  }
}

class _MessageBody extends StatelessWidget {
  const _MessageBody({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: AppTextStyles.titleLarge(context)),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: AppColors.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              AppPrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
