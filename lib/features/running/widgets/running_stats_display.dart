import 'package:flutter/material.dart';

class RunningStatsDisplay extends StatelessWidget {
  final bool isRunning;
  final int seconds;
  final double distance;
  final double avgPace;
  final double currentPace;

  const RunningStatsDisplay({
    Key? key,
    required this.isRunning,
    required this.seconds,
    required this.distance,
    required this.avgPace,
    required this.currentPace,
  }) : super(key: key);

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatPace(double pace) {
    final paceInSeconds = pace.toInt();
    final minutes = paceInSeconds ~/ 60;
    final remainingSeconds = paceInSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem("평균 페이스", _formatPace(avgPace)),
              _buildStatItem("현재 페이스", _formatPace(currentPace)),
            ],
          ),
          SizedBox(height: 20),
          Text(
            _formatTime(seconds),
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 10),
          Text(
            "${distance.toStringAsFixed(2)} km",
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white70)),
        Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
