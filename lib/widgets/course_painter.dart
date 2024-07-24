import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CoursePainter extends CustomPainter {
  final List<LatLng> points;

  CoursePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final double minX = points.map((point) => point.longitude).reduce((a, b) => a < b ? a : b);
    final double maxX = points.map((point) => point.longitude).reduce((a, b) => a > b ? a : b);
    final double minY = points.map((point) => point.latitude).reduce((a, b) => a < b ? a : b);
    final double maxY = points.map((point) => point.latitude).reduce((a, b) => a > b ? a : b);

    final double scaleX = size.width / (maxX - minX);
    final double scaleY = size.height / (maxY - minY);

    final double scale = scaleX < scaleY ? scaleX : scaleY;

    final double translateX = -minX * scale + (size.width - (maxX - minX) * scale) / 2;
    final double translateY = -minY * scale + (size.height - (maxY - minY) * scale) / 2;

    Paint paint = Paint()
      ..color = Colors.blue
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    for (int i = 0; i < points.length - 1; i++) {
      double startX = (points[i].longitude * scale) + translateX;
      double startY = size.height - (points[i].latitude * scale) - translateY;
      double endX = (points[i + 1].longitude * scale) + translateX;
      double endY = size.height - (points[i + 1].latitude * scale) - translateY;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(CoursePainter oldDelegate) => oldDelegate.points != points;
}