import 'package:flutter/material.dart';
import 'package:new_runaway/features/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:new_runaway/features/onboarding/screens/start_page.dart';
import 'package:new_runaway/features/running/running_provider.dart';
import 'package:new_runaway/features/courses/course_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:new_runaway/features/courses/screens/course_analysis_result_screen.dart';
import 'package:new_runaway/services/session_service.dart';
import 'package:new_runaway/features/stats/screens/stats_screen.dart';
import 'package:new_runaway/utils/logger.dart';
import 'package:new_runaway/services/api_service.dart';
import 'features/stats/screens/all_runs_screen.dart';
import 'package:new_runaway/services/auth_service.dart';
import 'models/recommended_course.dart';

void main() async {
  setupLogger();

  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  final GoogleMapsFlutterPlatform mapsImplementation = GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    mapsImplementation.useAndroidViewSurface = true;
  }

  await _checkLocationPermission();

  runApp(MyApp());
}

Future<void> _checkLocationPermission() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error('Location permissions are permanently denied, we cannot request permissions.');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RunningProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        Provider<ApiService>(create: (_) => ApiService()),
        Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Runaway',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Giants',
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: AppEntry(),
        routes: {
          '/course_analysis_result': (context) => CourseAnalysisResultScreen(
            initialCourse: ModalRoute.of(context)!.settings.arguments as RecommendedCourse,
          ),
          '/all_runs': (context) => AllRunsScreen(),
        },
      ),
    );
  }
}

class AppEntry extends StatefulWidget {
  @override
  _AppEntryState createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 비동기 초기화 작업 (예: 데이터베이스 초기화, 사용자 인증 등)
    await Future.delayed(Duration(seconds: 3)); // 여기를 실제 초기화 작업으로 대체
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SplashScreen();
    } else {
      return FutureBuilder<bool>(
        future: SessionService().isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SplashScreen(); // 여기도 로딩 화면을 표시
          } else {
            if (snapshot.data == true) {
              return StatsScreen();
            } else {
              return StartPage();
            }
          }
        },
      );
    }
  }
}
