import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';

class StatusBar extends StatefulWidget {
  const StatusBar({super.key});

  @override
  State<StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<StatusBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  final double _batteryLevel = 0.72;
  final int _wifiStrength = 3;
  final bool _isOnline = true;
  final bool _cloudConnected = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.glassBackground,
        border: const Border(
          bottom: BorderSide(color: AppColors.glassBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          // ── Robot name + status ────────────────────────────
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isOnline
                        ? AppColors.statusOnline
                        : AppColors.statusOffline,
                    boxShadow: [
                      BoxShadow(
                        color: (_isOnline
                                ? AppColors.statusOnline
                                : AppColors.statusOffline)
                            .withValues(alpha: _pulseAnim.value),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BellaBot Pro',
                    style: GoogleFonts.montserrat(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    _isOnline ? 'ONLINE' : 'OFFLINE',
                    style: GoogleFonts.montserrat(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: _isOnline
                          ? AppColors.statusOnline
                          : AppColors.statusOffline,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // ── Right side indicators ──────────────────────────
          Row(
            children: [
              _WiFiIndicator(strength: _wifiStrength),
              SizedBox(width: 12.w),
              _CloudIndicator(connected: _cloudConnected),
              SizedBox(width: 12.w),
              _BatteryIndicator(level: _batteryLevel),
            ],
          ),
        ],
      ),
    );
  }
}

// ── WiFi Indicator ──────────────────────────────────────────
class _WiFiIndicator extends StatelessWidget {
  final int strength;
  const _WiFiIndicator({required this.strength});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          strength >= 3 ? Icons.wifi : Icons.wifi_2_bar,
          color: strength >= 3 ? AppColors.puduBlue : AppColors.statusWarning,
          size: 20.sp,
        ),
        Text(
          strength >= 3 ? 'Strong' : 'Weak',
          style: TextStyle(fontSize: 9.sp, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ── Cloud Indicator ─────────────────────────────────────────
class _CloudIndicator extends StatelessWidget {
  final bool connected;
  const _CloudIndicator({required this.connected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          connected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
          color: connected ? AppColors.puduBlue : AppColors.textMuted,
          size: 20.sp,
        ),
        Text(
          connected ? 'Synced' : 'Offline',
          style: TextStyle(fontSize: 9.sp, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ── Battery Indicator ───────────────────────────────────────
class _BatteryIndicator extends StatelessWidget {
  final double level;
  const _BatteryIndicator({required this.level});

  Color get _color {
    if (level > 0.5) return AppColors.statusOnline;
    if (level > 0.2) return AppColors.statusWarning;
    return AppColors.safetyOrange;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 32.w,
          height: 16.h,
          child: CustomPaint(
            painter: _BatteryPainter(level: level, color: _color),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          '${(level * 100).toInt()}%',
          style: GoogleFonts.montserrat(
            fontSize: 9.sp,
            fontWeight: FontWeight.w600,
            color: _color,
          ),
        ),
      ],
    );
  }
}

class _BatteryPainter extends CustomPainter {
  final double level;
  final Color color;
  const _BatteryPainter({required this.level, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width - 4, size.height),
      const Radius.circular(3),
    );
    final outlinePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(bodyRect, outlinePaint);

    final tipPaint = Paint()..color = color.withValues(alpha: 0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 4, size.height * 0.3, 3, size.height * 0.4),
        const Radius.circular(1),
      ),
      tipPaint,
    );

    final fillWidth = (size.width - 8) * level;
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, fillWidth, size.height - 4),
        const Radius.circular(2),
      ),
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(_BatteryPainter old) => old.level != level;
}
