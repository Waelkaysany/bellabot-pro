import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/tray_provider.dart';
import '../models/tray.dart';
import '../widgets/tray_card.dart';
import '../widgets/robot_cat_face.dart';

class DeliveryPage extends StatefulWidget {
  const DeliveryPage({super.key});

  @override
  State<DeliveryPage> createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  RobotFaceMode _getFaceMode(TrayProvider provider) {
    if (provider.trays.any((t) => t.status == TrayStatus.delivering)) {
      return RobotFaceMode.focus;
    }
    if (provider.canStartDelivery) return RobotFaceMode.happy;
    return RobotFaceMode.idle;
  }

  void _startDelivery(BuildContext context, TrayProvider provider) {
    provider.startDelivery();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.rocket_launch_rounded, color: Colors.white),
            SizedBox(width: 12.w),
            Text(
              'Delivery Started! 🚀',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        backgroundColor: AppColors.puduBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TrayProvider>(
      builder: (context, provider, _) {
        final faceMode = _getFaceMode(provider);
        final canDeliver = provider.canStartDelivery;
        final isDelivering = provider.trays.any((t) => t.status == TrayStatus.delivering);
        final loadedCount = provider.trays.where((t) => t.status != TrayStatus.empty).length;

        return Column(
          children: [
            // ── Robot face + status header ──────────────────
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Row(
                children: [
                  // Robot face (compact for mobile)
                  SizedBox(
                    width: 90.w,
                    height: 90.w,
                    child: RobotCatFace(mode: faceMode),
                  ),
                  SizedBox(width: 18.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDelivering
                              ? 'Delivering...'
                              : canDeliver
                                  ? 'Ready to Go!'
                                  : 'Awaiting Orders',
                          style: GoogleFonts.montserrat(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                            color: isDelivering
                                ? AppColors.safetyOrange
                                : canDeliver
                                    ? AppColors.puduBlue
                                    : AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: AppColors.puduBlue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                    color: AppColors.puduBlue.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                '$loadedCount / 4 trays loaded',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.puduBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Quick clear all button
                  if (isDelivering)
                    GestureDetector(
                      onTap: () {
                        for (int i = 0; i < 4; i++) {
                          provider.clearTray(i);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('All trays cleared ✓',
                                style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w600)),
                            backgroundColor: AppColors.statusOnline,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r)),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: AppColors.safetyOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                              color: AppColors.safetyOrange.withValues(alpha: 0.4)),
                        ),
                        child: Icon(Icons.check_circle_outline_rounded,
                            color: AppColors.safetyOrange, size: 22.sp),
                      ),
                    ),
                ],
              ),
            ),

            Divider(
                color: AppColors.glassBorder, thickness: 1, height: 1),

            // ── Section header ──────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Row(
                children: [
                  Icon(Icons.grid_view_rounded,
                      color: AppColors.puduBlue, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Tray Management',
                    style: GoogleFonts.montserrat(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tap a tray to set table',
                    style: GoogleFonts.montserrat(
                      fontSize: 11.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // ── Tray cards ──────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: 4,
                itemBuilder: (_, i) => TrayCard(index: i),
              ),
            ),

            // ── Start Delivery button ────────────────────────
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: canDeliver || isDelivering ? 1.0 : 0.4,
                child: GestureDetector(
                  onTap: canDeliver
                      ? () => _startDelivery(context, provider)
                      : null,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
                      gradient: canDeliver
                          ? const LinearGradient(
                              colors: [Color(0xFF0099D4), AppColors.puduBlue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: canDeliver ? null : AppColors.surface,
                      border: Border.all(
                        color: canDeliver
                            ? Colors.transparent
                            : AppColors.glassBorder,
                      ),
                      boxShadow: canDeliver
                          ? [
                              BoxShadow(
                                color: AppColors.puduBlueGlow,
                                blurRadius: 20.r,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isDelivering
                              ? Icons.check_circle_rounded
                              : Icons.rocket_launch_rounded,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          isDelivering ? 'DELIVERY IN PROGRESS' : 'START DELIVERY',
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
