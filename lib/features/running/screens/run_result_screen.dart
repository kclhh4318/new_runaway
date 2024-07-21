import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:new_runaway/features/running/running_provider.dart';
import 'package:new_runaway/features/running/widgets/run_map.dart';

class RunResultScreen extends StatefulWidget {
  const RunResultScreen({Key? key}) : super(key: key);

  @override
  _RunResultScreenState createState() => _RunResultScreenState();
}

class _RunResultScreenState extends State<RunResultScreen> {
  double _runningIntensity = 5.0; // 초기값 설정

  @override
  Widget build(BuildContext context) {
    final runningProvider = context.read<RunningProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('러닝 결과'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildResultItem('날짜', '${DateTime.now().toString().split(' ')[0]}'),
            _buildResultItem('거리', '${runningProvider.distance.toStringAsFixed(2)} km'),
            _buildResultItem('시간', _formatTime(runningProvider.seconds)),
            _buildResultItem('평균 페이스', _formatPace(runningProvider.avgPace)),
            Container(
              height: 300,
              child: RunMap(routePoints: runningProvider.routePoints),
            ),
            _buildRunningIntensity(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 18)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRunningIntensity() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('러닝 강도', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Slider(
            value: _runningIntensity,
            min: 1,
            max: 10,
            divisions: 9,
            label: _runningIntensity.toString(),
            onChanged: (double value) {
              setState(() {
                _runningIntensity = value;
              });
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatPace(double pace) {
    final paceInSeconds = pace.toInt();
    final minutes = paceInSeconds ~/ 60;
    final remainingSeconds = paceInSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
