import 'package:flutter/material.dart';
import 'package:new_runaway/features/onboarding/widgets/onboarding_content.dart';
import 'package:new_runaway/features/onboarding/widgets/login_signup_content.dart';
import 'package:new_runaway/features/onboarding/widgets/start_content.dart';

class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Widget> _pages = [
    StartContent(
      title: "RUNAWAY",
      description: "",
    ),
    OnboardingContent(
      title: "당신의 코스를 그려보세요",
      description: "원하는 대로 코스를 그리고 달려보세요.",
      image: "assets/images/draw_course.gif",
    ),
    OnboardingContent(
      title: "당신의 발전을 느껴보세요",
      description: "러닝 기록과 통계를 확인하세요.",
      image: "assets/images/stats.gif",
    ),
    LoginSignupContent(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 고정된 배경 이미지
          Image.asset(
            "assets/images/onboarding_background.jpg",
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // 배경 위에 어두운 오버레이
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          // 페이지 컨텐츠
          PageView(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            children: _pages,
          ),
          // 페이지 인디케이터
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                    (index) => buildDot(index: index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDot({required int index}) {
    return Container(
      height: 10,
      width: 10,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index ? Colors.blue : Colors.grey,
      ),
    );
  }
}
