import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/iot_provider.dart';
import '../widgets/robot_cat_face.dart';

class BirthdayPage extends StatefulWidget {
  const BirthdayPage({super.key});

  @override
  State<BirthdayPage> createState() => _BirthdayPageState();
}

class _BirthdayPageState extends State<BirthdayPage>
    with TickerProviderStateMixin {
  bool _active = false;
  bool _loading = false;
  int _countdown = 11; // 10 s party + 1 buffer
  Timer? _countdownTimer;

  final _nameController = TextEditingController();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _nameController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _startBirthday() async {
    final name = _nameController.text.trim();
    if (_loading || _active) return;

    setState(() {
      _loading = true;
    });

    final provider = Provider.of<IotProvider>(context, listen: false);
    await provider.triggerBirthday(name);

    if (!mounted) return;

    // Start the 10-second countdown
    setState(() {
      _loading = false;
      _active = true;
      _countdown = 10;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        setState(() => _active = false);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          name.isNotEmpty
              ? '🎉 Happy Birthday, $name! Playing on robot...'
              : '🎉 Birthday Mode Started on robot!',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFFE91E63),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _nameController.text.trim();
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Festive header card ──────────────────────────────────────────
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (ctx, child) {
              return Transform.scale(
                scale: _active ? _pulseAnim.value : 1.0,
                child: child,
              );
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                gradient: LinearGradient(
                  colors: _active
                      ? [
                          const Color(0xFFE91E63).withValues(alpha: 0.3),
                          const Color(0xFFFF9800).withValues(alpha: 0.2),
                        ]
                      : [AppColors.surface, AppColors.surface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: _active
                      ? const Color(0xFFE91E63).withValues(alpha: 0.7)
                      : AppColors.glassBorder,
                  width: 1.8,
                ),
                boxShadow: _active
                    ? [
                        BoxShadow(
                          color:
                              const Color(0xFFE91E63).withValues(alpha: 0.35),
                          blurRadius: 28,
                          spreadRadius: 4,
                        )
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 100.w,
                    height: 100.w,
                    child: RobotCatFace(
                        mode: _active
                            ? RobotFaceMode.happy
                            : RobotFaceMode.idle),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    _active && name.isNotEmpty
                        ? '🎉 Happy Birthday, $name!'
                        : _active
                            ? '🎉 Birthday Mode Active!'
                            : '🎂 Birthday Mode',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: _active
                          ? const Color(0xFFE91E63)
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (_active) ...[
                    SizedBox(height: 8.h),
                    // Live countdown bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: LinearProgressIndicator(
                        value: _countdown / 10.0,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFE91E63)),
                        minHeight: 6,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      '🎵 Playing on robot... $_countdown s left',
                      style: GoogleFonts.montserrat(
                        fontSize: 12.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          SizedBox(height: 24.h),

          // ── Guest Name Input ─────────────────────────────────────────────
          Text(
            'Guest Name',
            style: GoogleFonts.montserrat(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _nameController,
            enabled: !_active && !_loading,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}), // refresh name preview
            style: GoogleFonts.montserrat(
                color: AppColors.textPrimary, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: 'e.g. Sarah',
              hintStyle: GoogleFonts.montserrat(
                  color: AppColors.textMuted, fontSize: 14.sp),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide:
                    const BorderSide(color: AppColors.glassBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide:
                    const BorderSide(color: AppColors.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: const BorderSide(
                    color: Color(0xFFE91E63), width: 1.5),
              ),
              prefixIcon: const Icon(Icons.person_rounded,
                  color: AppColors.textMuted),
            ),
          ),

          // LCD preview chip
          if (name.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                color: Colors.black,
                border: Border.all(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LCD Preview',
                      style: GoogleFonts.montserrat(
                          fontSize: 10.sp,
                          color: const Color(0xFF00FF88).withValues(alpha: 0.7),
                          letterSpacing: 1.5)),
                  SizedBox(height: 6.h),
                  Text(' Happy Birthday',
                      style: GoogleFonts.sourceCodePro(
                          fontSize: 13.sp,
                          color: const Color(0xFF00FF88))),
                  Text(
                    ' ${name.length > 11 ? name.substring(0, 11) : name}! :D',
                    style: GoogleFonts.sourceCodePro(
                        fontSize: 13.sp,
                        color: const Color(0xFF00FF88)),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 24.h),

          // ── Info card ────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              color: const Color(0xFFFF9800).withValues(alpha: 0.08),
              border: Border.all(
                  color:
                      const Color(0xFFFF9800).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Text('🎵', style: TextStyle(fontSize: 28)),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('What happens on the robot:',
                          style: GoogleFonts.montserrat(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      SizedBox(height: 4.h),
                      Text(
                        '• LCD shows "Happy Birthday / [Name]! :D"\n'
                        '• Full Happy Birthday song plays on buzzer\n'
                        '• Eyes flash & alternate for ~10 seconds',
                        style: GoogleFonts.montserrat(
                            fontSize: 11.sp,
                            color: AppColors.textMuted,
                            height: 1.6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // ── Start Button ─────────────────────────────────────────────────
          GestureDetector(
            onTap: _active || _loading ? null : _startBirthday,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 18.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                gradient: _active || _loading
                    ? LinearGradient(colors: [
                        Colors.grey.shade800,
                        Colors.grey.shade700
                      ])
                    : const LinearGradient(
                        colors: [Color(0xFFE91E63), Color(0xFFFF9800)],
                      ),
                boxShadow: _active || _loading
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFFE91E63)
                              .withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_loading)
                    SizedBox(
                      width: 22.w,
                      height: 22.w,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white)),
                    )
                  else
                    Icon(
                      _active
                          ? Icons.hourglass_top_rounded
                          : Icons.cake_rounded,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  SizedBox(width: 12.w),
                  Text(
                    _loading
                        ? 'SENDING TO ROBOT...'
                        : _active
                            ? 'PARTY IN PROGRESS... 🎉'
                            : 'START BIRTHDAY',
                    style: GoogleFonts.montserrat(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}
