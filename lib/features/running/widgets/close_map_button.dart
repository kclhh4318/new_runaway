import 'package:flutter/material.dart';

class CloseMapButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CloseMapButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.close),
      onPressed: onPressed,
    );
  }
}