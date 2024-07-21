import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  final VoidCallback onFinished;

  const CountdownTimer({Key? key, required this.onFinished}) : super(key: key);

  @override
  _CountdownTimerState createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _count = 3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          if (_count > 1) {
            _count--;
            _controller.reset();
            _controller.forward();
          } else {
            widget.onFinished();
          }
        });
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + _controller.value * 0.5,
            child: Opacity(
              opacity: 1.0 - _controller.value * 0.5,
              child: Text(
                '$_count',
                style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }
}