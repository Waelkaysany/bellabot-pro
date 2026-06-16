import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/tray_provider.dart';
import '../widgets/robot_cat_face.dart';

class DishReturnPage extends StatefulWidget {
  const DishReturnPage({super.key});

  @override
  State<DishReturnPage> createState() => _DishReturnPageState();
}

class _DishReturnPageState extends State<DishReturnPage> {
  bool _returning = false;
  final List<bool> _traySelected = [false, false, false, false];

  @override
  Widget build(BuildContext context) {
    return Consumer<TrayProvider>(
      builder: (context, provider, _) {
        final selectedCount = _traySelected.where((v) => v).length;

        return Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Row(
                children: [
                  SizedBox(
                    width: 80.w,
                    height: 80.w,
                    child: RobotCatFace(
                        mode: _returning
                            ? RobotFaceMode.focus
                            : RobotFaceMode.idle),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _returning ? 'Returning Dishes...' : 'Dish Return',
                          style: GoogleFonts.montserrat(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                            color: _returning
                                ? AppColors.safetyOrange
                                : AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Select trays to bring back to kitchen',
                          style: GoogleFonts.montserrat(
                            fontSize: 12.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: AppColors.glassBorder, thickness: 1, height: 1),

            // Tray selection header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Row(
                children: [
                  Icon(Icons.replay_rounded,
                      color: AppColors.safetyOrange, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Select Trays to Return',
                    style: GoogleFonts.montserrat(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.safetyOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                          color: AppColors.safetyOrange.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '$selectedCount selected',
                      style: GoogleFonts.montserrat(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.safetyOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tray checkboxes
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: 4,
                itemBuilder: (_, i) {
                  return GestureDetector(
                    onTap: () => setState(
                        () => _traySelected[i] = !_traySelected[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: EdgeInsets.symmetric(vertical: 6.h),
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 18.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.r),
                        color: AppColors.surface,
                        border: Border.all(
                          color: _traySelected[i]
                              ? AppColors.safetyOrange.withValues(alpha: 0.7)
                              : AppColors.glassBorder,
                          width: _traySelected[i] ? 2 : 1,
                        ),
                        boxShadow: _traySelected[i]
                            ? [
                                BoxShadow(
                                  color: AppColors.safetyOrange
                                      .withValues(alpha: 0.2),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          // Tray number circle
                          Container(
                            width: 48.w,
                            height: 48.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _traySelected[i]
                                  ? AppColors.safetyOrange.withValues(alpha: 0.2)
                                  : AppColors.glassBackground,
                              border: Border.all(
                                color: _traySelected[i]
                                    ? AppColors.safetyOrange
                                    : AppColors.glassBorder,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w800,
                                  color: _traySelected[i]
                                      ? AppColors.safetyOrange
                                      : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tray ${i + 1}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  _traySelected[i]
                                      ? 'Marked for return'
                                      : 'Tap to select',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12.sp,
                                    color: _traySelected[i]
                                        ? AppColors.safetyOrange
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 28.w,
                            height: 28.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _traySelected[i]
                                  ? AppColors.safetyOrange
                                  : Colors.transparent,
                              border: Border.all(
                                color: _traySelected[i]
                                    ? AppColors.safetyOrange
                                    : AppColors.glassBorder,
                                width: 2,
                              ),
                            ),
                            child: _traySelected[i]
                                ? Icon(Icons.check_rounded,
                                    color: Colors.white, size: 16.sp)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Return button
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: selectedCount > 0 ? 1.0 : 0.4,
                child: GestureDetector(
                  onTap: selectedCount > 0
                      ? () {
                          setState(() => _returning = !_returning);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _returning
                                    ? '↩️ Return journey started!'
                                    : '✅ Return complete!',
                                style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w700),
                              ),
                              backgroundColor: AppColors.safetyOrange,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12.r)),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      : null,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.safetyOrange.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _returning
                              ? Icons.check_circle_rounded
                              : Icons.replay_rounded,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          _returning
                              ? 'RETURN IN PROGRESS'
                              : 'START RETURN ($selectedCount)',
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
              ),
            ),
          ],
        );
      },
    );
  }
}
