import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../authentication/services/auth_service.dart';
import '../../../course_dashboard/presentation/screens/course_dashboard_screen.dart';
import '../../../course_enrollment/service/course_loader_service.dart';
import '../../../payments/model/payment_plan.dart';
import '../../../payments/service/payment_service.dart';

/// Paywall for a paid course — plans from Firestore via [PaymentService].
class CourseSubscriptionScreen extends StatefulWidget {
  const CourseSubscriptionScreen({super.key, required this.courseId});

  final String courseId;

  @override
  State<CourseSubscriptionScreen> createState() =>
      _CourseSubscriptionScreenState();
}

class _CourseSubscriptionScreenState extends State<CourseSubscriptionScreen> {
  late Future<List<PaymentPlan>> _plansFuture;
  PaymentPlan? _selectedPlan;
  bool _purchasing = false;
  String? _purchaseError;

  @override
  void initState() {
    super.initState();
    _plansFuture = _loadPlans();
  }

  Future<List<PaymentPlan>> _loadPlans() async {
    final all = await PaymentService.instance.loadActivePlans();
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

  void _ensureDefaultSelection(List<PaymentPlan> plans) {
    if (plans.isEmpty) return;
    if (_selectedPlan != null) {
      final stillThere = plans.any((p) => p.planId == _selectedPlan!.planId);
      if (stillThere) return;
    }

    PaymentPlan? preferred;
    for (final plan in plans) {
      if (plan.durationDays == 90) {
        preferred = plan;
        break;
      }
    }
    final next = preferred ?? plans.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_selectedPlan?.planId == next.planId) return;
      setState(() => _selectedPlan = next);
    });
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

  Future<void> _purchase() async {
    final plan = _selectedPlan;
    if (plan == null || _purchasing) return;

    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      setState(() {
        _purchaseError = 'Please sign in to continue.';
      });
      return;
    }

    setState(() {
      _purchasing = true;
      _purchaseError = null;
    });

    try {
      await PaymentService.instance.purchaseCourse(
        uid: uid,
        courseId: widget.courseId,
        plan: plan,
      );

      if (!mounted) return;

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CourseDashboardScreen(courseId: widget.courseId),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _purchasing = false;
        _purchaseError = 'Purchase failed. Please try again.';
      });
    }
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
                    _selectedPlan = null;
                    _plansFuture = _loadPlans();
                  });
                },
              );
            }

            final plans = snapshot.data ?? const <PaymentPlan>[];
            if (plans.isEmpty) {
              return const _MessageBody(
                title: 'No plans available',
                message:
                    'There are no active subscription plans for this course yet.',
              );
            }

            _ensureDefaultSelection(plans);

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
                        'Choose a plan',
                        style: AppTextStyles.headline(context),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Unlock full access to $_courseTitle with a subscription.',
                        style: AppTextStyles.bodyMedium(
                          context,
                        ).copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      for (var i = 0; i < plans.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.md),
                        _PlanTile(
                          plan: plans[i],
                          selected: _selectedPlan?.planId == plans[i].planId,
                          highlighted: plans[i].durationDays == 90,
                          enabled: !_purchasing,
                          onTap: () {
                            setState(() {
                              _selectedPlan = plans[i];
                              _purchaseError = null;
                            });
                          },
                        ),
                      ],
                      if (_purchaseError != null) ...[
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          _purchaseError!,
                          style: AppTextStyles.bodyMedium(
                            context,
                          ).copyWith(color: AppColors.error),
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
                    label: _purchaseLabel(_selectedPlan),
                    isLoading: _purchasing,
                    onPressed: _selectedPlan == null || _purchasing
                        ? null
                        : _purchase,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _purchaseLabel(PaymentPlan? plan) {
    if (plan == null) return 'Select a plan';
    return 'Continue · ${_formatAmount(plan)}';
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
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.selected,
    required this.highlighted,
    required this.enabled,
    required this.onTap,
  });

  final PaymentPlan plan;
  final bool selected;
  final bool highlighted;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.primary
        : AppColors.divider.withValues(alpha: 0.8);
    final background = selected
        ? AppColors.primary.withValues(alpha: 0.06)
        : AppColors.surface;

    return Opacity(
      opacity: enabled ? 1 : 0.7,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppRadius.lgAll,
          child: AnimatedContainer(
            duration: AppAnimations.fast,
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: background,
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: borderColor, width: selected ? 2 : 1),
              boxShadow: selected ? AppShadows.soft : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? AppColors.primary : AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
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
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
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
                ),
              ],
            ),
          ),
        ),
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
