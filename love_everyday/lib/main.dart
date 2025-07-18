import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/family_setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/account_deleted_screen.dart';
import 'services/firebase_service.dart';
import 'services/child_app_service.dart';
import 'services/notification_service.dart';
import 'models/family_record.dart';
import 'constants/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notification service
  try {
    await NotificationService().initialize();
    print('Notification service initialized successfully');
  } catch (e) {
    print('Notification service initialization failed: $e');
  }

  // Anonymous authentication
  try {
    final userCredential = await FirebaseAuth.instance.signInAnonymously();
    print('Anonymous authentication successful: ${userCredential.user?.uid}');
  } catch (e) {
    print('Anonymous authentication failed: $e');
  }

  runApp(const LoveEverydayApp());
}

class LoveEverydayApp extends StatelessWidget {
  const LoveEverydayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '식사 기록',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: AppColors.primaryBlue,
        fontFamily: 'NotoSans',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryBlue),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 스플래시 화면 표시 시간
    await Future.delayed(const Duration(seconds: 2));

    try {
      // 기존 가족 코드 확인
      final prefs = await SharedPreferences.getInstance();
      final familyCode = prefs.getString('family_code');

      if (familyCode != null) {
        // 가족 코드가 있으면 계정 삭제 여부부터 확인
        final childService = ChildAppService();
        final familyExists = await childService.checkFamilyExists(familyCode);

        if (!familyExists) {
          // 가족 계정이 삭제된 경우
          await prefs.clear(); // 모든 저장된 데이터 삭제
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AccountDeletedScreen(),
            ),
          );
          return;
        }

        // 가족 코드가 존재하면 유효성 검사 (connectionCode를 사용)
        final familyData = await childService.getFamilyInfo(familyCode);

        if (familyData != null && familyData['approved'] == true) {
          // 유효하고 승인된 가족 코드이면 홈 화면으로 이동
          final familyInfo = FamilyInfo.fromMap({
            'familyCode': familyCode,
            ...familyData,
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  HomeScreen(familyCode: familyCode, familyInfo: familyInfo),
            ),
          );
          return;
        } else {
          // 유효하지 않거나 승인되지 않은 가족 코드이면 제거
          await prefs.remove('family_code');
        }
      }

      // 가족 코드가 없거나 유효하지 않으면 설정 화면으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FamilySetupScreen()),
      );
    } catch (e) {
      print('Error initializing app: $e');
      // 에러 발생 시 설정 화면으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FamilySetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 앱 아이콘
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.family_restroom,
                size: 60,
                color: AppColors.primaryBlue,
              ),
            ),

            const SizedBox(height: 30),

            // 앱 이름
            const Text(
              '식사 기록',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 10),

            // 부제목
            const Text(
              '가족과 함께하는 식사 관리',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),

            const SizedBox(height: 50),

            // 로딩 인디케이터
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
