import 'package:flutter/material.dart';
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
import 'package:new_runaway/models/course.dart';
import 'features/stats/screens/all_runs_screen.dart';
import 'package:mongo_dart/mongo_dart.dart';

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
        Provider<ApiService>(create: (_) => ApiService()), // 추가된 부분
      ],
      child: MaterialApp(
        title: 'Runaway',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Giants',
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: FutureBuilder<bool>(
          future: SessionService().isLoggedIn(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else {
              if (snapshot.data == true) {
                return StatsScreen();
              } else {
                return StartPage();
              }
            }
          },
        ),
        routes: {
          '/course_analysis_result': (context) => CourseAnalysisResultScreen(
            course: ModalRoute.of(context)!.settings.arguments as RecommendedCourse, // 수정된 부분
          ),
          '/all_runs': (context) => AllRunsScreen(),
        },
      ),
    );
  }
}

