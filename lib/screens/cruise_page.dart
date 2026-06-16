import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../widgets/robot_cat_face.dart';

class CruisePage extends StatefulWidget {
  const CruisePage({super.key});

  @override
  State<CruisePage> createState() => _CruisePageState();
}

class _CruisePageState extends State<CruisePage>
    with TickerProviderStateMixin {
  bool _cruiseActive = false;
  String _selectedPattern = 'Table Loop';
  double _cruiseSpeed = 0.6;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  final List<String> _patterns = [
    'Table Loop',
    'Perimeter',
    'Custom Path',
    'Zone A Only',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.8, end: 1.0).animate(
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
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Robot status card
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
              gradient: LinearGradient(
                colors: _cruiseActive
                    ? [
                        AppColors.puduBlue.withValues(alpha: 0.2),
                        AppColors.puduBlue.withValues(alpha: 0.05),
                      ]
                    : [AppColors.surface, AppColors.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: _cruiseActive
                    ? AppColors.puduBlue.withValues(alpha: 0.5)
                    : AppColors.glassBorder,
                width: 1.5,
              ),
              boxShadow: _cruiseActive
                  ? [
                      BoxShadow(
                        color: AppColors.puduBlue.withValues(alpha: 0.2),
                        blurRadius: 24,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Transform.scale(
                    scale: _cruiseActive ? _pulseAnim.value : 1.0,
                    child: SizedBox(
                      width: 80.w,
                      height: 80.w,
                      child: RobotCatFace(
                          mode: _cruiseActive
                              ? RobotFaceMode.happy
                              : RobotFaceMode.idle),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _cruiseActive ? 'Cruising...' : 'Standing By',
                        style: GoogleFonts.montserrat(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          color: _cruiseActive
                              ? AppColors.puduBlue
                              : AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _cruiseActive
                            ? 'Pattern: $_selectedPattern'
                            : 'Select a pattern below',
                        style: GoogleFonts.montserrat(
                          fontSize: 13.sp,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Live dot
                if (_cruiseActive)
                  Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.statusOnline,
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // Speed slider
          Text(
            'Cruise Speed',
            style: GoogleFonts.montserrat(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.speed_rounded,
                  color: AppColors.textMuted, size: 18.sp),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.puduBlue,
                    inactiveTrackColor: AppColors.surface,
                    thumbColor: AppColors.puduBlue,
                    overlayColor: AppColors.puduBlue.withValues(alpha: 0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _cruiseSpeed,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    onChanged: (v) => setState(() => _cruiseSpeed = v),
                  ),
                ),
              ),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.puduBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${(_cruiseSpeed * 100).toInt()}%',
                  style: GoogleFonts.montserrat(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.puduBlue,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // Pattern select
          Text(
            'Cruise Pattern',
            style: GoogleFonts.montserrat(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 10.h),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10.w,
            mainAxisSpacing: 10.h,
            childAspectRatio: 2.8,
            children: _patterns.map((p) {
              final selected = _selectedPattern == p;
              return GestureDetector(
                onTap: () => setState(() => _selectedPattern = p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14.r),
                    color: selected
                        ? AppColors.puduBlue.withValues(alpha: 0.2)
                        : AppColors.surface,
                    border: Border.all(
                      color: selected
                          ? AppColors.puduBlue
                          : AppColors.glassBorder,
                      width: selected ? 1.8 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      p,
                      style: GoogleFonts.montserrat(
                        fontSize: 13.sp,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? AppColors.puduBlue
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: 24.h),

          // Start/Stop button
          GestureDetector(
            onTap: () {
              setState(() => _cruiseActive = !_cruiseActive);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _cruiseActive ? '🛤️ Cruise Mode Activated!' : '⏹️ Cruise Stopped',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
                  ),
                  backgroundColor: _cruiseActive
                      ? AppColors.puduBlue
                      : AppColors.textMuted,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 18.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                gradient: _cruiseActive
                    ? LinearGradient(
                        colors: [
                          AppColors.safetyOrange.withValues(alpha: 0.8),
                          AppColors.safetyOrange,
                        ],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF0099D4), AppColors.puduBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: (_cruiseActive
                            ? AppColors.safetyOrange
                            : AppColors.puduBlue)
                        .withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _cruiseActive
                        ? Icons.stop_circle_rounded
                        : Icons.electric_rickshaw_rounded,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    _cruiseActive ? 'STOP CRUISE' : 'START CRUISE',
                    style: GoogleFonts.montserrat(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
