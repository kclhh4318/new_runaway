import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0064FF),// 배경색을 설정합니다.
      body: Center(
        child: Text(
          'RUNAWAY',
          style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFamily: 'Giants',
              fontStyle: FontStyle.italic,
              color: Colors.white,
          ),
        ),
      ),
    );
  }
}
