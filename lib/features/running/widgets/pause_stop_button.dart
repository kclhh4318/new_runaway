import 'package:flutter/material.dart';

class PauseStopButton extends StatefulWidget {
  final bool isRunning;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  const PauseStopButton({
    Key? key,
    required this.isRunning,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  }) : super(key: key);

  @override
  _PauseStopButtonState createState() => _PauseStopButtonState();
}

class _PauseStopButtonState extends State<PauseStopButton> {
  bool _isLongPressed = false;
  int _longPressCounter = 0;

  void _handleLongPressStart(LongPressStartDetails details) {
    setState(() {
      _isLongPressed = true;
    });
    _startLongPressTimer();
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    setState(() {
      _isLongPressed = false;
      _longPressCounter = 0;
    });
  }

  void _startLongPressTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (_isLongPressed) {
        setState(() {
          _longPressCounter++;
        });
        if (_longPressCounter < 3) {
          _startLongPressTimer();
        } else {
          widget.onStop();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isRunning ? widget.onPause : widget.onResume,
      onLongPressStart: _handleLongPressStart,
      onLongPressEnd: _handleLongPressEnd,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isLongPressed ? Colors.red : Colors.white,
        ),
        child: Icon(
          widget.isRunning ? Icons.pause : Icons.play_arrow,
          size: 40,
          color: _isLongPressed ? Colors.white : Colors.blue,
        ),
      ),
    );
  }
}