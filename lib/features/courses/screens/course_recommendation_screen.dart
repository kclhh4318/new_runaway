import 'package:flutter/material.dart';

class CourseRecommendationScreen extends StatelessWidget {
  const CourseRecommendationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course Recommendations')),
      body: const Center(child: Text('Course Recommendation Screen')),
    );
  }
}