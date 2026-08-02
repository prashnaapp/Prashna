import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/practice_models.dart';
import '../../data/quiz_completion_bridge.dart';
import '../controllers/quiz_controller.dart';
import '../widgets/practice_entrance.dart';
import 'practice_question_page.dart';
import 'practice_result_screen.dart';

class PracticeQuestionScreen extends StatefulWidget {
  const PracticeQuestionScreen({
    super.key,
    required this.session,
  });

  final PracticeSessionModel session;

  @override
  State<PracticeQuestionScreen> createState() => _PracticeQuestionScreenState();
}

class _PracticeQuestionScreenState extends State<PracticeQuestionScreen> {
  late final QuizController _quiz;

  @override
  void initState() {
    super.initState();
    _quiz = QuizController(
      onUpdated: () => setState(() {}),
      totalQuestions: widget.session.questionCount,
    );
    _quiz.startQuestion();
  }

  @override
  void dispose() {
    _quiz.dispose();
    super.dispose();
  }

  void _finish(BuildContext context) {
    if (!_quiz.submitted) return;
    QuizCompletionBridge.run(
      _quiz.statistics.correctAnswers,
      _quiz.statistics.totalQuestions,
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PracticeResultScreen(statistics: _quiz.statistics),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.session.chapterLabel)),
      body: PracticeEntrance(
        child: AppResponsivePadding(
          child: AnimatedSwitcher(
            duration: AppAnimations.medium,
            switchInCurve: AppAnimations.curveStandard,
            switchOutCurve: AppAnimations.curveStandard,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.02),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: PracticeQuestionPage(
              key: ValueKey(_quiz.questionIndex),
              controller: _quiz,
              onSubmit: _quiz.submit,
              onNext: _quiz.nextQuestion,
              onFinish: () => _finish(context),
            ),
          ),
        ),
      ),
    );
  }
}
