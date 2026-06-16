import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/iot_provider.dart';
import 'dart:ui';

class IotControlPage extends StatefulWidget {
  const IotControlPage({super.key});

  @override
  State<IotControlPage> createState() => _IotControlPageState();
}

class _IotControlPageState extends State<IotControlPage> with SingleTickerProviderStateMixin {
  final TextEditingController _ipController = TextEditingController();
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<IotProvider>(context, listen: false);
    _ipController.text = provider.ipAddress;
    
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ipController.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<IotProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium Connection Header
              ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: AppColors.glassBorder, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: provider.isConnected 
                                    ? AppColors.statusOnline.withValues(alpha: 0.15)
                                    : AppColors.statusOffline.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: AnimatedBuilder(
                                animation: _pulseCtrl,
                                builder: (context, child) {
                                  return Icon(
                                    provider.isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                                    color: provider.isConnected 
                                        ? AppColors.statusOnline.withValues(alpha: 0.7 + (_pulseCtrl.value * 0.3))
                                        : AppColors.textMuted,
                                    size: 20.sp,
                                  );
                                }
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'BellaBot Pro',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: provider.isConnected 
                                    ? AppColors.statusOnline.withValues(alpha: 0.2)
                                    : AppColors.statusOffline.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: provider.isConnected 
                                      ? AppColors.statusOnline.withValues(alpha: 0.5)
                                      : AppColors.statusOffline.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                provider.isConnected ? 'SYNCED' : 'OFFLINE',
                                style: GoogleFonts.montserrat(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w800,
                                  color: provider.isConnected ? AppColors.statusOnline : AppColors.textMuted,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 44.h,
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: AppColors.glassBorder),
                                ),
                                child: TextField(
                                  controller: _ipController,
                                  style: GoogleFonts.sourceCodePro(
                                    color: AppColors.puduBlue, 
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: '192.168.x.x',
                                    hintStyle: TextStyle(color: AppColors.textMuted),
                                    icon: Icon(Icons.router_rounded, color: AppColors.textMuted, size: 18.sp),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            GestureDetector(
                              onTap: () {
                                provider.setIpAddress(_ipController.text);
                                FocusScope.of(context).unfocus();
                              },
                              child: Container(
                                height: 44.h,
                                width: 44.h,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppColors.puduBlue, const Color(0xFF0072FF)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.puduBlueGlow,
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ],
                                ),
                                child: Icon(Icons.check_rounded, color: Colors.white, size: 24.sp),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // Device Controls
              Expanded(
                child: provider.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.puduBlue,
                        strokeWidth: 3,
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                      children: [
                        // ─── Waiter Mode Big Button ───────────────────────
                        GestureDetector(
                          onTap: provider.waiterActive ? null : () => provider.activateWaiter(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutQuart,
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 20.w),
                            decoration: BoxDecoration(
                              gradient: provider.waiterActive
                                  ? const LinearGradient(
                                      colors: [Color(0xFFf97316), Color(0xFFf59e0b)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : const LinearGradient(
                                      colors: [Color(0xFF1e293b), Color(0xFF0f172a)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              borderRadius: BorderRadius.circular(22.r),
                              border: Border.all(
                                color: provider.waiterActive
                                    ? const Color(0xFFf59e0b)
                                    : const Color(0xFFf59e0b).withValues(alpha: 0.4),
                                width: 2,
                              ),
                              boxShadow: provider.waiterActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFf59e0b).withValues(alpha: 0.5),
                                        blurRadius: 30,
                                        spreadRadius: 4,
                                      )
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  provider.waiterActive ? '🍽️' : '🤖',
                                  style: TextStyle(fontSize: 28.sp),
                                ),
                                SizedBox(width: 14.w),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      provider.waiterActive ? 'Serving...' : 'Waiter Mode',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w900,
                                        color: provider.waiterActive ? Colors.black : Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      provider.waiterActive
                                          ? 'Robot is performing!'
                                          : 'Tap to serve with style',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 11.sp,
                                        color: provider.waiterActive
                                            ? Colors.black.withValues(alpha: 0.7)
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        // ─── Individual Controls ───────────────────────────
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16.w,
                          mainAxisSpacing: 16.h,
                          childAspectRatio: 0.85,
                          children: [
                            _PremiumControlCard(
                              title: 'Left\nEye',
                              icon: Icons.lightbulb_rounded,
                              isActive: provider.led1On,
                              onToggle: () => provider.toggleLed1(),
                              activeColor: const Color(0xFF00FFAA),
                            ),
                            _PremiumControlCard(
                              title: 'Right\nEye',
                              icon: Icons.lightbulb_outline_rounded,
                              isActive: provider.led2On,
                              onToggle: () => provider.toggleLed2(),
                              activeColor: const Color(0xFFFF4444),
                            ),
                            _PremiumControlCard(
                              title: 'Robot\nArm',
                              icon: Icons.precision_manufacturing_rounded,
                              isActive: provider.motorOn,
                              onToggle: () => provider.toggleMotor(),
                              activeColor: AppColors.safetyOrange,
                            ),
                            _PremiumControlCard(
                              title: 'Reset\nRobot',
                              icon: Icons.refresh_rounded,
                              isActive: false,
                              onToggle: () => provider.resetRobot(),
                              activeColor: const Color(0xFF6366f1),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ),  // SingleChildScrollView
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PremiumControlCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final VoidCallback onToggle;
  final Color activeColor;

  const _PremiumControlCard({
    required this.title,
    required this.icon,
    required this.isActive,
    required this.onToggle,
    required this.activeColor,
  });

  @override
  State<_PremiumControlCard> createState() => _PremiumControlCardState();
}

class _PremiumControlCardState extends State<_PremiumControlCard> with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onToggle();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutQuart,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: widget.isActive 
                    ? widget.activeColor.withValues(alpha: 0.15) 
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: widget.isActive 
                      ? widget.activeColor.withValues(alpha: 0.6) 
                      : AppColors.glassBorder,
                  width: widget.isActive ? 2 : 1,
                ),
                boxShadow: widget.isActive
                    ? [
                        BoxShadow(
                          color: widget.activeColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: widget.activeColor.withValues(alpha: 0.1),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: widget.isActive 
                              ? widget.activeColor.withValues(alpha: 0.2) 
                              : AppColors.glassBackground,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.isActive ? widget.activeColor : AppColors.textMuted,
                          size: 28.sp,
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 12.w,
                        height: 12.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isActive ? widget.activeColor : AppColors.glassBorder,
                          boxShadow: widget.isActive ? [
                            BoxShadow(
                              color: widget.activeColor,
                              blurRadius: 8,
                            )
                          ] : null,
                        ),
                      )
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.montserrat(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: widget.isActive ? Colors.white : AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        widget.isActive ? 'ACTIVE' : 'STANDBY',
                        style: GoogleFonts.montserrat(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: widget.isActive ? widget.activeColor : AppColors.textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}
