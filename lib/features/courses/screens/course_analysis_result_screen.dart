import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_runaway/features/courses/course_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:new_runaway/features/running/screens/running_session_screen.dart';

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
              children: [
                Text('총 거리: ${courseProvider.totalDistance.toStringAsFixed(2)} km'),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RunningSessionScreen(
                              showCountdown: true,
                              initialRoute: recommendedCourse?.points,
                            ),
                          ),
                        );
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