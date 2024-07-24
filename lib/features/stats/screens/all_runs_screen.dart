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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // 배경색 설정
        title: Text('모든 러닝 기록'),
      ),
      backgroundColor: Colors.white, // 배경색 설정
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _allRuns.length,
        itemBuilder: (context, index) {
          final run = _allRuns[index];
          return ListTile(
            title: Text('${run.date.toString().split(' ')[0]}'),
            subtitle: Text('거리: ${run.distance.toStringAsFixed(2)} km'),
            trailing: Text('시간: ${_formatDuration(run.duration)}'),
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
}