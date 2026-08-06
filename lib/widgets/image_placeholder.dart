import 'package:flutter/material.dart';

class NewslyImagePlaceholder extends StatelessWidget {
  final double height;
  final double? iconSize;

  const NewslyImagePlaceholder({
    super.key,
    required this.height,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepOrange.withValues(alpha: 0.85),
            Colors.deepOrange.shade700,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.newspaper_rounded,
          size: iconSize ?? (height * 0.32).clamp(28, 60),
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}