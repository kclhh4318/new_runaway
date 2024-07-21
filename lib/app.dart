import 'package:flutter/material.dart';
import 'package:new_runaway/features/onboarding/screens/start_page.dart';
import 'package:new_runaway/features/stats/screens/stats_screen.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Runaway',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StartPage(), // 처음 실행 시 시작 페이지로 이동
      routes: {
        '/stats': (context) => StatsScreen(), // 메인 화면으로 StatsScreen을 사용
      },
    );
  }
}
