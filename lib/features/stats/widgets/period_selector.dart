import 'package:flutter/material.dart';

class PeriodSelector extends StatefulWidget {
  final String initialPeriod;
  final ValueChanged<String> onPeriodSelected;

  const PeriodSelector({
    Key? key,
    required this.initialPeriod,
    required this.onPeriodSelected,
  }) : super(key: key);

  @override
  _PeriodSelectorState createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<PeriodSelector> {
  late String _selectedPeriod;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.initialPeriod;
  }

  void _handlePeriodSelected(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    widget.onPeriodSelected(period);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0), // 양 옆에 12픽셀 여백 추가
      child: Container(
        height: 30,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['주', '월', '년', '전체'].map((period) {
            bool isSelected = _selectedPeriod == period;
            return Expanded(
              child: GestureDetector(
                onTap: () => _handlePeriodSelected(period),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      period,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}