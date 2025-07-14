import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'constants/app_theme.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize local storage
  await StorageService.init();
  
  // Initialize notification service
  await NotificationService.initialize();
  
  runApp(const GraceNotesApp());
}

class GraceNotesApp extends StatelessWidget {
  const GraceNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grace Notes',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
