import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, // 백그라운드 색상 설정
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Runaway',
              style: TextStyle(
                fontFamily: 'Giants', // 원하는 폰트 패밀리 설정
                fontSize: 48, // 텍스트 크기 설정
                color: Colors.white, // 텍스트 색상 설정
              ),
            ),
          ],
        ),
      ),
    );
  }
}
