import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:new_runaway/config/google_maps_config.dart';

class RunMap extends StatelessWidget {
  final List<LatLng> routePoints;

  const RunMap({Key? key, required this.routePoints}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('Building RunMap widget');
    print('Route points: $routePoints');
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: routePoints.isNotEmpty ? routePoints.last : LatLng(37.5665, 126.9780),
        zoom: 15.0,
      ),
      polylines: {
        Polyline(
          polylineId: PolylineId('route'),
          points: routePoints,
          color: Colors.red,
          width: 4,
        ),
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }
}