import 'package:flutter/material.dart';
import 'package:new_runaway/features/courses/screens/course_drawing_screen.dart';
import 'package:new_runaway/features/running/screens/running_session_screen.dart';
import 'package:new_runaway/features/stats/widgets/period_selector.dart';
import 'package:new_runaway/features/stats/widgets/stats_bar_chart.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showRunningButtons = true;
  String _selectedPeriod = '년';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.offset > 100 && _showRunningButtons) {
      setState(() => _showRunningButtons = false);
    } else if (_scrollController.offset <= 100 && !_showRunningButtons) {
      setState(() => _showRunningButtons = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(child: _buildTotalStats()),
                SliverToBoxAdapter(
                  child: PeriodSelector(
                    initialPeriod: _selectedPeriod,
                    onPeriodSelected: (period) {
                      setState(() {
                        _selectedPeriod = period;
                      });
                    },
                  ),
                ),
                if (_selectedPeriod != '전체' && _selectedPeriod != '주')
                  SliverToBoxAdapter(child: _buildDateFilter()),
                SliverToBoxAdapter(child: _buildStatsChart()),
                SliverToBoxAdapter(child: _buildCourseStatistics()),
                SliverToBoxAdapter(child: _buildRecentRuns()),
                SliverToBoxAdapter(child: _buildMyDrawnCourses()),
              ],
            ),
          ),
          _buildRunningButtons(),
        ],
      ),
    );
  }

  Widget _buildTotalStats() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '총 킬로미터',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            '99,999 km',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          Text(
            '총 시간',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            '999:99',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Text(_selectedPeriod == '월간' ? '월 선택: ' : '년 선택: '),
          TextButton(
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null && picked != _selectedDate) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
            child: Text(
              _selectedPeriod == '월간'
                  ? '${_selectedDate.year}년 ${_selectedDate.month}월'
                  : '${_selectedDate.year}년',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsChart() {
    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      child: StatsBarChart(
        selectedPeriod: _selectedPeriod,
        selectedDate: _selectedDate,
      ),
    );
  }

  Widget _buildCourseStatistics() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('코스 통계', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCourseStatItem('코스 그리기로 달린 횟수', '15'),
              _buildCourseStatItem('코스 추천으로 달린 횟수', '8'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourseStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildRecentRuns() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('최근 러닝', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                child: Text('더 보기'),
                onPressed: () {
                  // TODO: Navigate to all running records screen
                },
              ),
            ],
          ),
          SizedBox(height: 10),
          _buildRecentRunItem('24.07.19', '8.11 km', '1:35:18', '05:30'),
          _buildRecentRunItem('24.07.18', '6.5 km', '1:15:30', '05:45'),
          _buildRecentRunItem('24.07.17', '10.2 km', '1:55:40', '05:20'),
        ],
      ),
    );
  }

  Widget _buildRecentRunItem(String date, String distance, String time, String pace) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: TextStyle(fontWeight: FontWeight.bold)),
              Text(distance),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(time),
              Text('평균 페이스 $pace'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyDrawnCourses() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('내가 그린 코스', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(5, (index) => _buildCourseItem()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseItem() {
    return Container(
      width: 100,
      height: 100,
      margin: EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(child: Text('코스')),
    );
  }

  Widget _buildRunningButtons() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: AnimatedOpacity(
        opacity: _showRunningButtons ? 1.0 : 0.0,
        duration: Duration(milliseconds: 200),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.edit),
              label: Text('코스 그리기'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CourseDrawingScreen()),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.directions_run),
              label: Text('러닝 시작'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RunningSessionScreen()),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}