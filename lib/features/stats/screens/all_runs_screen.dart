import 'package:flutter/material.dart';
import 'package:new_runaway/models/running_session.dart';
import 'package:new_runaway/services/api_service.dart';
import 'package:new_runaway/services/storage_service.dart';
import 'package:new_runaway/widgets/course_painter.dart';

class AllRunsScreen extends StatefulWidget {
  @override
  _AllRunsScreenState createState() => _AllRunsScreenState();
}

class _AllRunsScreenState extends State<AllRunsScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  List<RunningSession> _allRuns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllRuns();
  }

  Future<void> _loadAllRuns() async {
    setState(() => _isLoading = true);
    final userId = await _storageService.getUserId();
    if (userId != null) {
      final runs = await _apiService.getAllRuns(userId);
      setState(() {
        _allRuns = runs;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildRunItem(RunningSession run) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Container(
                width: 100,
                height: 100,
                child: run.route != null && run.route!.isNotEmpty
                    ? CustomPaint(
                  painter: CoursePainter(run.route!),
                  size: Size(100, 100),
                )
                    : Container(color: Colors.grey[300]),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(run.date.toString().split(' ')[0], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text('총 킬로미터', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(
                      '${run.distance.toStringAsFixed(2)} km',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                        fontFamily: 'Giants',
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('시간', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(_formatDuration(run.duration), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.2))
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('평균 페이스', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(_formatPace(run.averagePace), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.2)),
                          ],
                        ),
                        SizedBox(width: 13),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Image.asset(
              _getStrengthBadgeImage(run.strength),
              width: 45,
              height: 45,
            ),
          ),
        ],
      ),
    );
  }

  String _getStrengthBadgeImage(int strength) {
    if (strength >= 1 && strength <= 3) {
      return 'assets/images/strength1-3.png';
    } else if (strength >= 4 && strength <= 6) {
      return 'assets/images/strength4-6.png';
    } else if (strength >= 7 && strength <= 9) {
      return 'assets/images/strength7-9.png';
    } else if (strength == 10) {
      return 'assets/images/strength10.png';
    } else {
      return 'assets/images/default_strength.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('모든 러닝 기록'),
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _allRuns.length,
        itemBuilder: (context, index) {
          return _buildRunItem(_allRuns[index]);
        },
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatPace(double paceInSeconds) {
    final minutes = paceInSeconds ~/ 60;
    final seconds = (paceInSeconds % 60).toInt();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}