import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'screens/auth/greeting_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/exam/create_exam_screen.dart';
import 'screens/room/create_room_screen.dart';
import 'screens/room/teacher_waiting_room_screen.dart';
import 'screens/room/student_waiting_room_screen.dart';
import 'screens/exam/taking_exam_screen.dart';
import 'screens/exam/live_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Đọc biến môi trường từ tham số build --dart-define
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: '');

  if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
  } else {
    debugPrint('CẢNH BÁO: Chưa cấu hình SUPABASE_URL hoặc SUPABASE_PUBLISHABLE_KEY');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        Provider.value(value: Supabase.instance.client),
      ],
      child: const ThiNhanhApp(),
    ),
  );
}

class ThiNhanhApp extends StatelessWidget {
  const ThiNhanhApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thi Nhanh',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/greeting',
      routes: {
        '/greeting': (context) => const GreetingScreen(),
        '/home': (context) => const HomeScreen(),
        '/create_exam': (context) => const CreateExamScreen(),
        '/create_room': (context) => const CreateRoomScreen(),
        '/teacher_waiting_room': (context) => const TeacherWaitingRoomScreen(),
        '/student_waiting_room': (context) => const StudentWaitingRoomScreen(),
        '/taking_exam': (context) => const TakingExamScreen(),
        '/live_dashboard': (context) => const LiveDashboardScreen(),
      },
    );
  }
}
