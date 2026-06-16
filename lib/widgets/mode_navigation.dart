import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';

enum RobotMode { delivery, cruise, birthday, dishReturn, adDisplay, iotControl, pay }

class ModeNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onModeChanged;

  const ModeNavigation({
    super.key,
    required this.selectedIndex,
    required this.onModeChanged,
  });

  static const _modes = [
    (icon: Icons.delivery_dining_rounded,  label: 'Delivery'),
    (icon: Icons.electric_rickshaw_rounded, label: 'Cruise'),
    (icon: Icons.cake_rounded,              label: 'Birthday'),
    (icon: Icons.replay_rounded,            label: 'Return'),
    (icon: Icons.campaign_rounded,          label: 'Display'),
    (icon: Icons.developer_board_rounded,   label: 'IoT'),
    (icon: Icons.contactless_rounded,       label: 'Pay'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E1621),
        border: const Border(
          top: BorderSide(color: AppColors.glassBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68.h,
          child: Row(
            children: List.generate(_modes.length, (i) {
              final isSelected = selectedIndex == i;
              final item = _modes[i];
              return Expanded(
                child: _NavItem(
                  icon: item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  onTap: () => onModeChanged(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.isSelected ? 1.0 : 0.0,
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(_NavItem old) {
    super.didUpdateWidget(old);
    if (old.isSelected != widget.isSelected) {
      widget.isSelected ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Indicator dot at top
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: widget.isSelected ? 24.w : 0,
              height: 3.h,
              margin: EdgeInsets.only(bottom: 6.h),
              decoration: BoxDecoration(
                color: AppColors.puduBlue,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            // Icon with background pill when selected
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? AppColors.puduBlue.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                widget.icon,
                size: 24.sp,
                color: Color.lerp(
                  AppColors.textMuted,
                  AppColors.puduBlue,
                  _anim.value,
                ),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              widget.label,
              style: GoogleFonts.montserrat(
                fontSize: 10.sp,
                fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                color: Color.lerp(
                  AppColors.textMuted,
                  AppColors.puduBlue,
                  _anim.value,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
