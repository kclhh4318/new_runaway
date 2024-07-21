import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CourseDrawingScreen extends StatefulWidget {
  const CourseDrawingScreen({Key? key}) : super(key: key);

  @override
  _CourseDrawingScreenState createState() => _CourseDrawingScreenState();
}

class _CourseDrawingScreenState extends State<CourseDrawingScreen> {
  List<LatLng> _points = [];
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('코스 그리기')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(37.5665, 126.9780), // 서울 좌표
          zoom: 14.0,
        ),
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        onTap: _addPoint,
        polylines: {
          Polyline(
            polylineId: PolylineId('course'),
            points: _points,
            color: Colors.blue,
            width: 4,
          ),
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _finishDrawing,
        child: Icon(Icons.check),
      ),
    );
  }

  void _addPoint(LatLng point) {
    setState(() {
      _points.add(point);
    });
  }

  void _finishDrawing() {
    // 여기에서 그린 코스를 저장하거나 다음 화면으로 넘기는 로직을 구현
  }
}