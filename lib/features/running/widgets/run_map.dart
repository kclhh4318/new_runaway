import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:new_runaway/config/mapbox_config.dart';

class RunMap extends StatelessWidget {
  final List<LatLng> routePoints;

  const RunMap({Key? key, required this.routePoints}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MapboxMap(
      accessToken: MapboxConfig.accessToken,
      styleString: MapboxConfig.styleUrl,
      initialCameraPosition: CameraPosition(
        target: routePoints.isNotEmpty ? routePoints.last : LatLng(0, 0),
        zoom: 15.0,
      ),
      onMapCreated: (MapboxMapController controller) {
        controller.addLine(
          LineOptions(
            geometry: routePoints,
            lineColor: "#3887be",
            lineWidth: 5.0,
          ),
        );
      },
      myLocationEnabled: false,
      compassEnabled: false,
      zoomGesturesEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      scrollGesturesEnabled: false,
      doubleClickZoomEnabled: false,
    );
  }
}