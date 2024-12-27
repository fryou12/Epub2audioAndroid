import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../constants/colors.dart';

class DottedContainer extends StatelessWidget {
  final Widget? child;

  const DottedContainer({
    super.key,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.current.containerBackground,
      child: CustomPaint(
        painter: DottedBorderPainter(
          color: AppColors.current.dottedBorderColor,
          strokeWidth: 2.0,
          gap: 5.0,
          radius: 8.0,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: DotPatternPainter(
                    color: AppColors.current.dottedBorderColor,
                    spacing: 20.0,
                    dotSize: 1.0,
                  ),
                ),
              ),
              if (child != null) child!,
            ],
          ),
        ),
      ),
    );
  }
}

class DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double radius;

  DottedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
    this.radius = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    path.addRRect(RRect.fromRectAndRadius(
      rect,
      Radius.circular(radius),
    ));

    final Path dashedPath = Path();
    final double dash = 5;

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dash),
          Offset.zero,
        );
        distance += dash + gap;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(DottedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      gap != oldDelegate.gap ||
      radius != oldDelegate.radius;
}

class DotPatternPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double dotSize;

  DotPatternPainter({
    required this.color,
    required this.spacing,
    required this.dotSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(
          Offset(x, y),
          dotSize,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(DotPatternPainter oldDelegate) =>
      color != oldDelegate.color ||
      spacing != oldDelegate.spacing ||
      dotSize != oldDelegate.dotSize;
}
