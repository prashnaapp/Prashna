import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../course_enrollment/service/course_loader_service.dart';
import '../../../payments/model/payment_plan.dart';
import '../../../payments/service/payment_service.dart';

/// Paywall for a paid course.
///
/// Shows plan catalog for preview. Does not create transactions or activate
/// enrollment — paid checkout is unavailable until a trusted payment backend
/// exists.
class CourseSubscriptionScreen extends StatefulWidget {
  const CourseSubscriptionScreen({
    super.key,
    required this.courseId,
    this.paymentService,
  });

  final String courseId;
  final PaymentService? paymentService;

  @override
  State<CourseSubscriptionScreen> createState() =>
      _CourseSubscriptionScreenState();
}

class _CourseSubscriptionScreenState extends State<CourseSubscriptionScreen> {
  late Future<List<PaymentPlan>> _plansFuture;

  PaymentService get _payments =>
      widget.paymentService ?? PaymentService.instance;

  @override
  void initState() {
    super.initState();
    _plansFuture = _loadPlans();
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
      'group-ii' => 'Group-II',
      'group-iii' => 'Group-III',
      _ => widget.courseId,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('$_courseTitle Subscription')),
      body: SafeArea(
        child: FutureBuilder<List<PaymentPlan>>(
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
                        'Paid enrollment for $_courseTitle is temporarily '
                        'unavailable. Secure checkout will be enabled once '
                        'trusted payment verification is ready.',
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(
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
        ),
      ),
    );
  }
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
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.title,
                  style: AppTextStyles.titleMedium(context),
                ),
              ),
              if (highlighted) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Popular',
                    style: AppTextStyles.label(
                      context,
                    ).copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ],
          ),
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
    final currency = plan.currency.toUpperCase() == 'INR'
        ? '₹'
        : '${plan.currency} ';
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
