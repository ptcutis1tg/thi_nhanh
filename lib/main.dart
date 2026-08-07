import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'screens/auth/greeting_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/search_screen.dart';
import 'screens/exam/create_exam_screen.dart';
import 'screens/room/create_room_screen.dart';
import 'screens/room/teacher_waiting_room_screen.dart';
import 'screens/room/student_waiting_room_screen.dart';
import 'screens/exam/taking_exam_screen.dart';
import 'screens/exam/live_dashboard_screen.dart';
import 'screens/exam/result_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/main_layout_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Tải biến môi trường từ file .env nếu có
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Không tìm thấy file .env, sử dụng biến môi trường mặc định.');
  }

  // Ưu tiên lấy từ .env, nếu không có thì lấy từ tham số build --dart-define
  final isEnvInitialized = dotenv.isInitialized;
  final supabaseUrl = (isEnvInitialized ? dotenv.env['SUPABASE_URL'] : null) ?? const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  final supabaseKey = (isEnvInitialized ? dotenv.env['SUPABASE_PUBLISHABLE_KEY'] : null) ?? const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: '');

  bool isSupabaseInitialized = false;
  final isPlaceholderKey = supabaseUrl.contains('your_supabase_url') || supabaseKey.contains('your_supabase_anon_key');

  if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty && !isPlaceholderKey) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
      );
      isSupabaseInitialized = true;
    } catch (e) {
      debugPrint('Lỗi khởi tạo Supabase: $e');
    }
  } else {
    debugPrint('CẢNH BÁO: Chưa cấu hình SUPABASE_URL hoặc SUPABASE_PUBLISHABLE_KEY hợp lệ.');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(isSupabaseInitialized: isSupabaseInitialized)),
        if (isSupabaseInitialized)
          Provider.value(value: Supabase.instance.client),
      ],
      child: const ThiNhanhApp(),
    ),
  );
}

// Map các route với thứ tự index để tính toán hướng trượt
final Map<String, int> _routeIndices = {
  '/home': 0,
  '/search': 1,
  '/create_exam': 2,
  '/create_room': 3,
  '/profile': 4,
};

int _lastIndex = 0;

CustomTransitionPage<T> buildPageWithSlideTransition<T>({
  required BuildContext context, 
  required GoRouterState state, 
  required Widget child,
}) {
  final currentIndex = _routeIndices[state.matchedLocation] ?? _lastIndex;
  final isMovingRight = currentIndex >= _lastIndex;
  
  // Chỉ cập nhật _lastIndex nếu route nằm trong menu chính
  if (_routeIndices.containsKey(state.matchedLocation)) {
    _lastIndex = currentIndex;
  }

  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Offset dx = 1.0 (trượt từ phải sang), dx = -1.0 (trượt từ trái sang)
      final begin = Offset(isMovingRight ? 1.0 : -1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOutCubic;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

final GoRouter _router = GoRouter(
  initialLocation: '/greeting',
  routes: [
    GoRoute(
      path: '/greeting',
      builder: (context, state) => const GreetingScreen(),
    ),
    // Các màn hình thuộc TopNavBar
    ShellRoute(
      builder: (context, state, child) {
        return MainLayoutScreen(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => buildPageWithSlideTransition(
            context: context,
            state: state,
            child: const HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) => buildPageWithSlideTransition(
            context: context,
            state: state,
            child: const SearchScreen(),
          ),
        ),
        GoRoute(
          path: '/create_exam',
          pageBuilder: (context, state) => buildPageWithSlideTransition(
            context: context,
            state: state,
            child: const CreateExamScreen(),
          ),
        ),
        GoRoute(
          path: '/create_room',
          pageBuilder: (context, state) => buildPageWithSlideTransition(
            context: context,
            state: state,
            child: const CreateRoomScreen(),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => buildPageWithSlideTransition(
            context: context,
            state: state,
            child: const ProfileScreen(),
          ),
        ),
      ],
    ),
    // Các màn hình không có TopNavBar
    GoRoute(
      path: '/teacher_waiting_room',
      builder: (context, state) => const TeacherWaitingRoomScreen(),
    ),
    GoRoute(
      path: '/student_waiting_room',
      builder: (context, state) => const StudentWaitingRoomScreen(),
    ),
    GoRoute(
      path: '/taking_exam',
      builder: (context, state) => const TakingExamScreen(),
    ),
    GoRoute(
      path: '/live_dashboard',
      builder: (context, state) => const LiveDashboardScreen(),
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) => const ResultScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Lỗi 404')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Không tìm thấy trang!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Về Trang Chủ'),
          ),
        ],
      ),
    ),
  ),
);

class ThiNhanhApp extends StatelessWidget {
  const ThiNhanhApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Thi Nhanh',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
