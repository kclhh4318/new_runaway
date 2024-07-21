import 'package:flutter/material.dart';

class CourseDrawingScreen extends StatelessWidget {
  const CourseDrawingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Draw Course')),
      body: const Center(child: Text('Course Drawing Screen')),
    );
  }
}