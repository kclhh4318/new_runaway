import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_runaway/features/courses/course_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CourseAnalysisResultScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    final recommendedCourse = courseProvider.recommendedCourse;

    return Scaffold(
      appBar: AppBar(title: Text('코스 분석 결과')),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: recommendedCourse?.points.first ?? LatLng(37.5665, 126.9780),
                zoom: 14.0,
              ),
              polylines: {
                if (recommendedCourse != null)
                  Polyline(
                    polylineId: PolylineId('recommended_course'),
                    points: recommendedCourse.points,
                    color: Colors.blue,
                    width: 5,
                  ),
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('총 거리: ${courseProvider.totalDistance.toStringAsFixed(2)} km', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('코스 설명: ${recommendedCourse?.description ?? ""}', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('안전 팁: ${recommendedCourse?.safetyTips ?? ""}', style: TextStyle(fontSize: 16)),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // TODO: 러닝 세션 시작 로직 구현
                      },
                      child: Text('GO!'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        courseProvider.reanalyze();
                      },
                      child: Text('재분석'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}