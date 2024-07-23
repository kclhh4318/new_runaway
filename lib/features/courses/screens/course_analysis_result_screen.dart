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
            child: recommendedCourse != null
                ? GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _calculateCenter(recommendedCourse.points),
                zoom: 14.0,
              ),
              polylines: {
                Polyline(
                  polylineId: PolylineId('recommended_course'),
                  points: recommendedCourse.points,
                  color: Colors.blue,
                  width: 5,
                ),
              },
              onMapCreated: (GoogleMapController controller) {
                _fitBounds(controller, recommendedCourse.points);
              },
            )
                : Center(child: CircularProgressIndicator()),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('총 거리: ${courseProvider.totalDistance.toStringAsFixed(2)} km',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('코스 설명: ${recommendedCourse?.description ?? ""}',
                    style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('안전 팁: ${recommendedCourse?.safetyTips ?? ""}',
                    style: TextStyle(fontSize: 16)),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: recommendedCourse != null
                          ? () => _showCountdownAndStartRunning(context, recommendedCourse.points)
                          : null,
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

  LatLng _calculateCenter(List<LatLng> points) {
    if (points.isEmpty) return LatLng(37.5665, 126.9780); // 기본값: 서울

    double sumLat = 0, sumLng = 0;
    for (var point in points) {
    sumLat += point.latitude;
    sumLng += point.longitude;
    }
    return LatLng(sumLat / points.length, sumLng / points.length);
  }

  void _fitBounds(GoogleMapController controller, List<LatLng> points) {
    if (points.isEmpty) return;

    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50.0, // 패딩
      ),
    );
  }

  void _showCountdownAndStartRunning(BuildContext context, List<LatLng> coursePoints) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          body: CountdownTimer(
            onFinished: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => RunningSessionScreen(
                    showCountdown: false,
                    predefinedCourse: coursePoints,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}