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
  int _runningIntensity = 5;

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
          GestureDetector(
            onTapUp: (details) {
              RenderBox box = context.findRenderObject() as RenderBox;
              double localDx = box.globalToLocal(details.globalPosition).dx;
              int newIntensity = ((localDx / box.size.width) * 10).round();
              if (newIntensity < 1) newIntensity = 1;
              if (newIntensity > 10) newIntensity = 10;
              setState(() {
                _runningIntensity = newIntensity;
              });
            },
            child: Container(
              height: 100, // 막대의 높이를 늘려 직사각형으로 만듦
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[300],
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: _runningIntensity / 10,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: _runningIntensity == 10 ? Color(0xFFFF5200) : Colors.blue,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      _runningIntensity.toString(),
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 24, // 글자 크기를 키움
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
