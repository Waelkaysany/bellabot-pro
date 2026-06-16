import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/app_colors.dart';

enum RobotFaceMode { idle, happy, focus }

class RobotCatFace extends StatefulWidget {
  final RobotFaceMode mode;
  const RobotCatFace({super.key, this.mode = RobotFaceMode.idle});

  @override
  State<RobotCatFace> createState() => _RobotCatFaceState();
}

class _RobotCatFaceState extends State<RobotCatFace>
    with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late AnimationController _expressionController;
  late AnimationController _floatController;
  late Animation<double> _blinkAnim;
  late Animation<double> _expressionAnim;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();

    // Blink: fast close, pause, open
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _blinkAnim = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeIn),
    );
    _scheduleBlink();

    // Expression transition
    _expressionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _expressionAnim = CurvedAnimation(
      parent: _expressionController,
      curve: Curves.easeOut,
    );

    // Float animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  void _scheduleBlink() async {
    await Future.delayed(
      Duration(milliseconds: 2500 + (1500 * (DateTime.now().millisecond / 1000)).toInt()),
    );
    if (mounted && widget.mode == RobotFaceMode.idle) {
      await _blinkController.forward();
      await _blinkController.reverse();
    }
    if (mounted) _scheduleBlink();
  }

  @override
  void didUpdateWidget(RobotCatFace old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode) {
      if (widget.mode == RobotFaceMode.happy) {
        _expressionController.forward();
      } else if (widget.mode == RobotFaceMode.focus) {
        _expressionController.reverse();
      } else {
        _expressionController.animateTo(0.0);
      }
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _expressionController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnim.value),
          child: child,
        );
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_blinkAnim, _expressionAnim]),
        builder: (context, _) {
          return SizedBox(
            width: 520.w,
            height: 520.w,
            child: CustomPaint(
              painter: _CatFacePainter(
                blinkAmount: _blinkAnim.value,
                expressionAmount: _expressionAnim.value,
                mode: widget.mode,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CatFacePainter extends CustomPainter {
  final double blinkAmount;
  final double expressionAmount;
  final RobotFaceMode mode;

  const _CatFacePainter({
    required this.blinkAmount,
    required this.expressionAmount,
    required this.mode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.48;

    // ── Outer glow ring ───────────────────────────────────
    final glowColor = mode == RobotFaceMode.happy
        ? AppColors.puduBlue
        : mode == RobotFaceMode.focus
            ? AppColors.safetyOrange
            : AppColors.puduBlue;

    for (int i = 3; i > 0; i--) {
      canvas.drawCircle(
        Offset(cx, cy),
        r + i * 14,
        Paint()
          ..color = glowColor.withOpacity(0.06 * (4 - i))
          ..style = PaintingStyle.fill,
      );
    }

    // ── Face base ─────────────────────────────────────────
    final facePaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF2A2A2A), const Color(0xFF181818)],
        stops: const [0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, facePaint);

    // Face border
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = glowColor.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // ── Cat ears ──────────────────────────────────────────
    _drawEar(canvas, Offset(cx - r * 0.65, cy - r * 0.75), isLeft: true, glowColor: glowColor);
    _drawEar(canvas, Offset(cx + r * 0.65, cy - r * 0.75), isLeft: false, glowColor: glowColor);

    // ── Eyes ──────────────────────────────────────────────
    final eyeY = cy - r * 0.12;
    _drawEye(canvas, Offset(cx - r * 0.38, eyeY), size: r * 0.28, mode: mode, glowColor: glowColor);
    _drawEye(canvas, Offset(cx + r * 0.38, eyeY), size: r * 0.28, mode: mode, glowColor: glowColor);

    // ── Nose ──────────────────────────────────────────────
    final nosePaint = Paint()..color = AppColors.puduBlue.withOpacity(0.9);
    final nosePath = Path()
      ..moveTo(cx - r * 0.06, cy + r * 0.18)
      ..lineTo(cx + r * 0.06, cy + r * 0.18)
      ..lineTo(cx, cy + r * 0.26)
      ..close();
    canvas.drawPath(nosePath, nosePaint);

    // ── Mouth ─────────────────────────────────────────────
    _drawMouth(canvas, cx, cy, r, expressionAmount);

    // ── Cheek blush (happy mode) ─────────────────────────
    if (expressionAmount > 0) {
      final blushPaint = Paint()
        ..color = AppColors.safetyOrange.withOpacity(0.15 * expressionAmount)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawCircle(Offset(cx - r * 0.55, cy + r * 0.2), r * 0.2, blushPaint);
      canvas.drawCircle(Offset(cx + r * 0.55, cy + r * 0.2), r * 0.2, blushPaint);
    }

    // ── Whiskers ──────────────────────────────────────────
    _drawWhiskers(canvas, cx, cy, r, glowColor);

    // ── Focus mode: scanning line ─────────────────────────
    if (mode == RobotFaceMode.focus) {
      _drawScanLine(canvas, cx, cy, r);
    }
  }

  void _drawEar(Canvas canvas, Offset tip, {required bool isLeft, required Color glowColor}) {
    final sign = isLeft ? -1.0 : 1.0;
    final baseCx = tip.dx;
    final earPaint = Paint()
      ..shader = LinearGradient(
        colors: [glowColor.withOpacity(0.8), const Color(0xFF2A2A2A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCenter(center: tip, width: 80, height: 80));

    final path = Path()
      ..moveTo(baseCx - sign * 36, tip.dy + 38)
      ..lineTo(tip.dx, tip.dy - 10)
      ..lineTo(baseCx + sign * 36, tip.dy + 38)
      ..close();
    canvas.drawPath(path, earPaint);

    // Inner ear
    final innerPaint = Paint()
      ..color = glowColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    final innerPath = Path()
      ..moveTo(baseCx - sign * 18, tip.dy + 28)
      ..lineTo(tip.dx, tip.dy + 2)
      ..lineTo(baseCx + sign * 18, tip.dy + 28)
      ..close();
    canvas.drawPath(innerPath, innerPaint);
  }

  void _drawEye(Canvas canvas, Offset center, {required double size, required RobotFaceMode mode, required Color glowColor}) {
    // Eye glow
    canvas.drawCircle(center, size * 1.3,
        Paint()..color = glowColor.withOpacity(0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));

    if (mode == RobotFaceMode.happy) {
      // Happy: curved arc (^)
      final paint = Paint()
        ..color = glowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCenter(center: center, width: size * 2, height: size * 1.5),
        pi,
        pi,
        false,
        paint,
      );
    } else if (mode == RobotFaceMode.focus) {
      // Focus: horizontal slit
      final scanPaint = Paint()
        ..color = glowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(center.dx - size * 0.9, center.dy),
        Offset(center.dx + size * 0.9, center.dy),
        scanPaint,
      );
      // Glow on slit
      canvas.drawLine(
        Offset(center.dx - size * 0.9, center.dy),
        Offset(center.dx + size * 0.9, center.dy),
        Paint()
          ..color = glowColor.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    } else {
      // Idle: full circle eye with pupil
      canvas.drawCircle(center, size, Paint()..color = const Color(0xFF0D0D0D));
      canvas.drawCircle(center, size * 0.85,
          Paint()..color = glowColor.withOpacity(0.15));
      // Iris ring
      canvas.drawCircle(
        center,
        size * 0.72,
        Paint()
          ..color = glowColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      // Pupil
      canvas.drawCircle(center, size * 0.35,
          Paint()..color = const Color(0xFF000000));
      // Reflection
      canvas.drawCircle(
        Offset(center.dx - size * 0.2, center.dy - size * 0.25),
        size * 0.12,
        Paint()..color = Colors.white.withOpacity(0.8),
      );
    }
  }

  void _drawMouth(Canvas canvas, double cx, double cy, double r, double expression) {
    final mouthPaint = Paint()
      ..color = AppColors.puduBlue.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final mouthY = cy + r * 0.42;
    final mouthWidth = r * 0.4;

    // Interpolate between neutral (flat) and happy (curve up)
    final controlY = mouthY + lerpDouble(0, -r * 0.18, expression)!;

    final path = Path()
      ..moveTo(cx - mouthWidth, mouthY)
      ..quadraticBezierTo(cx, controlY, cx + mouthWidth, mouthY);
    canvas.drawPath(path, mouthPaint);
  }

  void _drawWhiskers(Canvas canvas, double cx, double cy, double r, Color glowColor) {
    final paint = Paint()
      ..color = glowColor.withOpacity(0.3)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const offsets = [-1.0, 0.0, 1.0];
    for (final i in offsets) {
      // Left whiskers
      canvas.drawLine(
        Offset(cx - r * 0.25, cy + r * 0.3 + i * r * 0.08),
        Offset(cx - r * 0.9, cy + r * 0.25 + i * r * 0.1),
        paint,
      );
      // Right whiskers
      canvas.drawLine(
        Offset(cx + r * 0.25, cy + r * 0.3 + i * r * 0.08),
        Offset(cx + r * 0.9, cy + r * 0.25 + i * r * 0.1),
        paint,
      );
    }
  }

  void _drawScanLine(Canvas canvas, double cx, double cy, double r) {
    // Animated scan overlay (static frame instance)
    final scanPaint = Paint()
      ..color = AppColors.safetyOrange.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(cx - r, cy - 12, r * 2, 24),
      scanPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(cx - r, cy - 12, r * 2, 24),
      Paint()
        ..color = AppColors.safetyOrange.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_CatFacePainter old) =>
      old.blinkAmount != blinkAmount ||
      old.expressionAmount != expressionAmount ||
      old.mode != mode;
}

double? lerpDouble(double a, double b, double t) => a + (b - a) * t;
