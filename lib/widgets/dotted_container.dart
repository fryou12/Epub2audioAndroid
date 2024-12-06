import 'package:flutter/material.dart';

class DottedContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const DottedContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        left: 8.0,
        right: 8.0,
        bottom: 8.0,
        top: -32.0, // Dépasse sous le Header
      ),
      child: CustomPaint(
        painter: DottedBorderPainter(
          color: Theme.of(context).colorScheme.outline,
          strokeWidth: 2.0,
          gap: 5.0,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: DotPatternPainter(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  spacing: 15.0,
                  dotSize: 1.5,
                ),
              ),
            ),
            Padding(
              padding: padding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DottedBorderPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final dashPath = Path();
    const dashWidth = 5.0;

    for (double i = 0; i < path.computeMetrics().first.length; i += dashWidth + gap) {
      dashPath.addPath(
        path.computeMetrics().first.extractPath(i, i + dashWidth),
        Offset.zero,
      );
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(DottedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      gap != oldDelegate.gap;
}

class DotPatternPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double dotSize;

  DotPatternPainter({
    required this.color,
    this.spacing = 15.0,
    this.dotSize = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const spacing = 15.0;

    for (double x = spacing; x < size.width - spacing; x += spacing) {
      for (double y = spacing; y < size.height - spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DotPatternPainter oldDelegate) =>
      color != oldDelegate.color ||
      spacing != oldDelegate.spacing ||
      dotSize != oldDelegate.dotSize;
}
