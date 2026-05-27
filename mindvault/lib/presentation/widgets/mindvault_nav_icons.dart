import 'package:flutter/material.dart';

enum MindVaultNavIconKind { archive, sparks, clusters }

class MindVaultNavIcon extends StatelessWidget {
  final MindVaultNavIconKind kind;
  final double size;
  final Color? color;

  const MindVaultNavIcon({
    super.key,
    required this.kind,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ??
        IconTheme.of(context).color ??
        DefaultTextStyle.of(context).style.color;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MindVaultNavIconPainter(
          kind: kind,
          color: resolvedColor ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _MindVaultNavIconPainter extends CustomPainter {
  final MindVaultNavIconKind kind;
  final Color color;

  const _MindVaultNavIconPainter({
    required this.kind,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (kind) {
      case MindVaultNavIconKind.archive:
        _paintArchive(canvas, paint);
      case MindVaultNavIconKind.sparks:
        _paintSparks(canvas, paint);
      case MindVaultNavIconKind.clusters:
        _paintClusters(canvas, paint);
    }

    canvas.restore();
  }

  void _paintArchive(Canvas canvas, Paint paint) {
    canvas.drawLine(const Offset(7, 5), const Offset(17, 5), paint);
    canvas.drawLine(const Offset(5, 8), const Offset(19, 8), paint);
    canvas.drawPath(
      Path()
        ..moveTo(5, 10)
        ..lineTo(5, 18)
        ..quadraticBezierTo(5, 20, 7, 20)
        ..lineTo(17, 20)
        ..quadraticBezierTo(19, 20, 19, 18)
        ..lineTo(19, 10),
      paint,
    );
    canvas.drawLine(const Offset(8, 12.5), const Offset(16, 12.5), paint);
    canvas.drawLine(const Offset(8, 16), const Offset(14, 16), paint);
  }

  void _paintSparks(Canvas canvas, Paint paint) {
    final sparkle = Path()
      ..moveTo(12, 3.5)
      ..cubicTo(12.7, 8.1, 15.9, 11.3, 20.5, 12)
      ..cubicTo(15.9, 12.7, 12.7, 15.9, 12, 20.5)
      ..cubicTo(11.3, 15.9, 8.1, 12.7, 3.5, 12)
      ..cubicTo(8.1, 11.3, 11.3, 8.1, 12, 3.5)
      ..close();
    canvas.drawPath(sparkle, paint);
    canvas.drawLine(const Offset(4.2, 4.4), const Offset(5.8, 6), paint);
    canvas.drawLine(const Offset(19.8, 4.4), const Offset(18.2, 6), paint);
    canvas.drawLine(const Offset(4.2, 19.6), const Offset(5.8, 18), paint);
    canvas.drawLine(const Offset(19.8, 19.6), const Offset(18.2, 18), paint);
  }

  void _paintClusters(Canvas canvas, Paint paint) {
    final brainPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final outline = Path()
      ..moveTo(12, 20)
      ..cubicTo(8.1, 20, 5, 17.4, 5.2, 14.2)
      ..cubicTo(3.9, 13.4, 4.4, 10.9, 6.3, 10.3)
      ..cubicTo(5.9, 7.8, 7.9, 5.8, 10.1, 6.4)
      ..cubicTo(10.7, 5.2, 13.3, 5.2, 13.9, 6.4)
      ..cubicTo(16.1, 5.8, 18.1, 7.8, 17.7, 10.3)
      ..cubicTo(19.6, 10.9, 20.1, 13.4, 18.8, 14.2)
      ..cubicTo(19, 17.4, 15.9, 20, 12, 20)
      ..close();
    canvas.drawPath(outline, brainPaint);

    canvas.drawLine(const Offset(12, 7), const Offset(12, 19), brainPaint);
    canvas.drawPath(
      Path()
        ..moveTo(12, 10)
        ..cubicTo(10.1, 9.1, 8.4, 10.2, 8.8, 12.1)
        ..cubicTo(7.2, 12.7, 7.5, 15.2, 9.2, 15.7),
      brainPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(12, 10)
        ..cubicTo(13.9, 9.1, 15.6, 10.2, 15.2, 12.1)
        ..cubicTo(16.8, 12.7, 16.5, 15.2, 14.8, 15.7),
      brainPaint,
    );
    canvas.drawLine(
        const Offset(9.3, 15.7), const Offset(12, 15.7), brainPaint);
    canvas.drawLine(
        const Offset(14.7, 15.7), const Offset(12, 15.7), brainPaint);
  }

  @override
  bool shouldRepaint(_MindVaultNavIconPainter oldDelegate) {
    return oldDelegate.kind != kind || oldDelegate.color != color;
  }
}
