import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:new_runaway/config/app_config.dart';

class StatsBarChart extends StatefulWidget {
  final String selectedPeriod;
  final DateTime selectedDate;
  final String userId;

  const StatsBarChart({
    Key? key,
    required this.selectedPeriod,
    required this.selectedDate,
    required this.userId,
  }) : super(key: key);

  @override
  _StatsBarChartState createState() => _StatsBarChartState();
}

class _StatsBarChartState extends State<StatsBarChart> {
  List<double> _data = [];
  List<String> _labels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final String endpoint = _getEndpoint(widget.selectedPeriod);
    final String url = '${AppConfig.apiBaseUrl}/stats/$endpoint/${widget.userId}';
    print('graph Fetching data from URL: $url'); // 디버깅용

    try {
      final response = await http.get(Uri.parse(url));
      print('graph Response status: ${response.statusCode}'); // 디버깅용

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('graph API Response: $result'); // 디버깅용

        setState(() {
          _labels = List<String>.from(result['x'].map((e) => e.toString()));
          _data = List<double>.from(result['y'].map((e) => e.toDouble()));
          print('_labels: $_labels'); // 디버깅용
          print('_data: $_data'); // 디버깅용
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  String _getEndpoint(String period) {
    switch (period) {
      case '주':
        return 'weekly_data';
      case '월':
        return 'monthly_data';
      case '년':
        return 'yearly_data';
      case '전체':
        return 'all_time_data';
      default:
        return 'weekly_data';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_data.isEmpty) {
      return Center(child: Text('데이터가 없습니다.'));
    }

    final double maxY = _data.isNotEmpty ? _data.reduce((a, b) => a > b ? a : b) : 0;
    final double interval = _calculateInterval(maxY);

    return Container(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY + interval,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.blueAccent,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.round()} km',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final intValue = value.toInt();
                  if (widget.selectedPeriod == '월' && intValue != 0 && intValue != 9 && intValue != 19) {
                    return SizedBox.shrink(); // 빈 공간 반환
                  }
                  if (intValue < _labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _labels[intValue],
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    );
                  } else {
                    return Text('');
                  }
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value % interval == 0) {
                    return Text(
                      '${value.toInt()}km',
                      style: TextStyle(fontSize: 8),
                    );
                  }
                  return Text('');
                },
                reservedSize: 30,
                interval: interval,
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _getBarGroups(_data),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            horizontalInterval: interval,
            drawVerticalLine: false,
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups(List<double> data) {
    return List.generate(data.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data[index],
            color: Colors.blue,
            width: 12,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  double _calculateInterval(double maxY) {
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    if (maxY <= 200) return 50;
    return 100;
  }
}

