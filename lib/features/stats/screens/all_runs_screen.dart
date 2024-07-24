import 'package:flutter/material.dart';
import 'package:new_runaway/models/running_session.dart';
import 'package:new_runaway/services/api_service.dart';
import 'package:new_runaway/services/storage_service.dart';

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

  Widget _buildRecentRunItem(String date, String distance, String time, String pace, int strength) {
    String badgeImage;
    if (strength >= 1 && strength <= 3) {
      badgeImage = 'assets/images/strength1-3.png';
    } else if (strength >= 4 && strength <= 6) {
      badgeImage = 'assets/images/strength4-6.png';
    } else if (strength >= 7 && strength <= 9) {
      badgeImage = 'assets/images/strength7-9.png';
    } else if (strength == 10) {
      badgeImage = 'assets/images/strength10.png';
    } else {
      badgeImage = ''; // 기본값을 설정하거나 필요에 따라 다르게 처리
    }

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
              // 컨테이너는 코스 이미지로 추후에 대체
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(date, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text('총 킬로미터', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(
                      distance,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                        fontFamily: 'Giants',
                        height: 1.2, // 위아래 자간 설정
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
                            Text(time, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.2,))
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('평균 페이스', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(pace, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.2)),
                          ],
                        ),
                        SizedBox(width: 13), // 평균 페이스를 왼쪽으로 이동시키기 위해 간격 조정
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
              badgeImage, // 뱃지 이미지 경로
              width: 45,
              height: 45,
            ),
          ),
        ],
      ),
    );
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
          final run = _allRuns[index];
          return _buildRecentRunItem(
            run.date.toString().split(' ')[0],
            '${run.distance.toStringAsFixed(2)} km',
            _formatDuration(run.duration),
            _formatPace(run.averagePace),
            run.strength, // Assuming there is a strength field in RunningSession
          );
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



