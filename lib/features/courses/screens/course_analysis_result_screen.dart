import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_runaway/features/courses/course_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:new_runaway/features/running/screens/running_session_screen.dart';
import 'package:new_runaway/features/running/widgets/countdown_timer.dart';

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
                        _showCountdownAndStartRunning(context, recommendedCourse!.points);
                      },
                      child: Text('GO!'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await courseProvider.reanalyze();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('코스가 재분석되었습니다.')),
                        );
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

  void _showCountdownAndStartRunning(BuildContext context, List<LatLng> coursePoints) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: CountdownTimer(
            onFinished: () {
              Navigator.of(context).pop(); // Close the dialog
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RunningSessionScreen(
                    showCountdown: false,
                    predefinedCourse: coursePoints,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}