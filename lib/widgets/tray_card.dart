import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../models/tray.dart';
import '../providers/tray_provider.dart';
import 'package:provider/provider.dart';
import 'numpad_sheet.dart';

class TrayCard extends StatefulWidget {
  final int index;
  const TrayCard({super.key, required this.index});

  @override
  State<TrayCard> createState() => _TrayCardState();
}

class _TrayCardState extends State<TrayCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnim;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _glowAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _triggerConfirmGlow() async {
    setState(() => _confirming = true);
    await _glowController.forward();
    await _glowController.reverse();
    setState(() => _confirming = false);
  }

  Color _statusColor(TrayStatus status) {
    switch (status) {
      case TrayStatus.empty:
        return AppColors.trayEmpty;
      case TrayStatus.loaded:
        return AppColors.trayLoaded;
      case TrayStatus.delivering:
        return AppColors.trayDelivering;
    }
  }

  String _statusLabel(TrayStatus status) {
    switch (status) {
      case TrayStatus.empty:
        return 'EMPTY';
      case TrayStatus.loaded:
        return 'LOADED';
      case TrayStatus.delivering:
        return 'DELIVERING';
    }
  }

  void _openNumpad(BuildContext context, TrayProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NumpadSheet(
        trayIndex: widget.index,
        provider: provider,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TrayProvider>(
      builder: (context, provider, _) {
        final tray = provider.trays[widget.index];
        final color = _statusColor(tray.status);
        final isLoaded = tray.status != TrayStatus.empty;

        return AnimatedBuilder(
          animation: _glowAnim,
          builder: (context, child) {
            return GestureDetector(
              onTap: () => _openNumpad(context, provider),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                margin: EdgeInsets.symmetric(vertical: 5.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  color: AppColors.surface,
                  border: Border.all(
                    color: _confirming
                        ? color.withOpacity(0.4 + _glowAnim.value * 0.6)
                        : isLoaded
                            ? color.withOpacity(0.5)
                            : AppColors.glassBorder,
                    width: _confirming ? 2.5 + _glowAnim.value * 2 : 1.5,
                  ),
                  boxShadow: isLoaded
                      ? [
                          BoxShadow(
                            color: color.withOpacity(
                                _confirming ? 0.3 + _glowAnim.value * 0.4 : 0.2),
                            blurRadius: _confirming
                                ? 20 + _glowAnim.value * 30
                                : 16.r,
                            spreadRadius: _confirming
                                ? _glowAnim.value * 8
                                : 0,
                          ),
                        ]
                      : null,
                ),
                child: child,
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                // Tray number badge
                Container(
                  width: 42.w,
                  height: 42.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _statusColor(tray.status).withOpacity(0.3),
                        _statusColor(tray.status).withOpacity(0.05),
                      ],
                    ),
                    border: Border.all(
                      color: _statusColor(tray.status).withOpacity(0.6),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${tray.id}',
                      style: GoogleFonts.montserrat(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        color: _statusColor(tray.status),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12.w),

                // Main content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tray ${tray.id}',
                        style: GoogleFonts.montserrat(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: 10.w,
                            height: 10.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _statusColor(tray.status),
                              boxShadow: isLoaded
                                  ? [
                                      BoxShadow(
                                        color: _statusColor(tray.status)
                                            .withOpacity(0.6),
                                        blurRadius: 8,
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            _statusLabel(tray.status),
                            style: GoogleFonts.montserrat(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: _statusColor(tray.status),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      if (tray.destinationTable != null) ...[
                        SizedBox(height: 2.h),
                        Text(
                          'Table: ${tray.destinationTable}',
                          style: GoogleFonts.montserrat(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Confirm button
                if (tray.destinationTable != null)
                  GestureDetector(
                    onTap: () {
                      provider.confirmLoad(widget.index);
                      _triggerConfirmGlow();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.r),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.puduBlue.withOpacity(0.8),
                            AppColors.puduBlue,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.puduBlueGlow,
                            blurRadius: 12.r,
                          ),
                        ],
                      ),
                      child: Text(
                        'Confirm',
                        style: GoogleFonts.montserrat(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 34.w,
                    height: 34.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.glassBackground,
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: AppColors.textMuted,
                      size: 18.sp,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
