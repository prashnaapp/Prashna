import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'features/admin/admin_app.dart';
import 'features/admin/services/admin_question_service.dart';
import 'features/admin/services/admin_test_service.dart';
import 'features/authentication/services/auth_service.dart';
import 'features/question_bank/repository/question_cloud_repository.dart';
import 'firebase_options.dart';

/// Admin Web entry point.
///
/// Build:
///   flutter build web -t lib/main_admin.dart
///
/// Does not start the student Android navigation shell.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final questionRepository = QuestionCloudRepository(
    firestore: FirebaseFirestore.instance,
  );
  AdminQuestionService.configureProduction(questionRepository);
  AdminTestService.configureProduction(questionRepository);
  await AuthService.instance.initialize();
  runApp(const AdminApp());
}
