import 'package:flutter/material.dart';
import 'package:new_runaway/models/running_session.dart';

class AllRunsScreen extends StatefulWidget {
  @override
  _AllRunsScreenState createState() => _AllRunsScreenState();
}

class _AllRunsScreenState extends State<AllRunsScreen> {
  List<RunningSession> _runSessions = [];
  bool _isLoading = false;
  int _currentPage = 1;
  final int _itemsPerPage = 20;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMoreRuns();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      _loadMoreRuns();
    }
  }

  Future<void> _loadMoreRuns() async {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });

      // TODO: Replace this with actual API call to fetch more runs
      await Future.delayed(Duration(seconds: 1));
      List<RunningSession> newRuns = List.generate(
        _itemsPerPage,
            (index) => RunningSession(
          id: 'run_${_currentPage * _itemsPerPage + index}',
          date: DateTime.now().subtract(Duration(days: _currentPage * _itemsPerPage + index)),
          distance: (5 + index % 5).toDouble(),
          duration: 1800 + index * 60,
          averagePace: 300.0 + index,
        ),
      );

      setState(() {
        _runSessions.addAll(newRuns);
        _currentPage++;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('모든 러닝 기록'),
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _runSessions.length + 1,
        itemBuilder: (context, index) {
          if (index < _runSessions.length) {
            return _buildRunItem(_runSessions[index]);
          } else if (_isLoading) {
            return Center(child: CircularProgressIndicator());
          } else {
            return SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _buildRunItem(RunningSession run) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${run.date.year}.${run.date.month.toString().padLeft(2, '0')}.${run.date.day.toString().padLeft(2, '0')}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRunStat('거리', '${run.distance.toStringAsFixed(2)} km'),
              _buildRunStat('시간', _formatDuration(run.duration)),
              _buildRunStat('평균 페이스', _formatPace(run.averagePace)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRunStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey)),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
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