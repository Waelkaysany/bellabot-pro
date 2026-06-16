import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../providers/tray_provider.dart';

class NumpadSheet extends StatefulWidget {
  final int trayIndex;
  final TrayProvider provider;

  const NumpadSheet({super.key, required this.trayIndex, required this.provider});

  @override
  State<NumpadSheet> createState() => _NumpadSheetState();
}

class _NumpadSheetState extends State<NumpadSheet> {
  String _input = '';

  void _onKey(String val) {
    if (_input.length < 3) {
      setState(() => _input += val);
    }
  }

  void _onDelete() {
    if (_input.isNotEmpty) {
      setState(() => _input = _input.substring(0, _input.length - 1));
    }
  }

  void _confirm() {
    if (_input.isNotEmpty) {
      widget.provider.updateTrayTable(widget.trayIndex, _input);
      Navigator.pop(context);
    }
  }

  Widget _key(String label, {bool isDelete = false, bool isConfirm = false}) {
    Color bgColor = AppColors.surface;
    Color textColor = AppColors.textPrimary;
    if (isConfirm) {
      bgColor = AppColors.puduBlue;
      textColor = Colors.white;
    } else if (isDelete) {
      bgColor = const Color(0xFF2A2A2A);
      textColor = AppColors.safetyOrange;
    }

    return GestureDetector(
      onTap: () {
        if (isDelete) {
          _onDelete();
        } else if (isConfirm) {
          _confirm();
        } else {
          _onKey(label);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isConfirm ? AppColors.puduBlueGlow : AppColors.glassBorder,
          ),
          boxShadow: isConfirm
              ? [BoxShadow(color: AppColors.puduBlueGlow, blurRadius: 14.r)]
              : null,
        ),
        child: Center(
          child: isDelete
              ? Icon(Icons.backspace_rounded, color: textColor, size: 36.sp)
              : Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 30.sp,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(32.w, 28.h, 32.w, 40.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(36.r)),
        border: Border(
          top: BorderSide(color: AppColors.puduBlue.withOpacity(0.3), width: 1.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 60.w,
            height: 5.h,
            margin: EdgeInsets.only(bottom: 28.h),
            decoration: BoxDecoration(
              color: AppColors.glassBorder,
              borderRadius: BorderRadius.circular(3.r),
            ),
          ),

          Text(
            'Select Table for Tray ${widget.trayIndex + 1}',
            style: GoogleFonts.montserrat(
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 24.h),

          // Input display
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 22.h),
            decoration: BoxDecoration(
              color: AppColors.glassBackground,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: _input.isNotEmpty
                    ? AppColors.puduBlue.withOpacity(0.6)
                    : AppColors.glassBorder,
              ),
            ),
            child: Center(
              child: Text(
                _input.isEmpty ? '—' : 'Table $_input',
                style: GoogleFonts.montserrat(
                  fontSize: 36.sp,
                  fontWeight: FontWeight.w800,
                  color:
                      _input.isEmpty ? AppColors.textMuted : AppColors.puduBlue,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),

          SizedBox(height: 24.h),

          // Numpad grid
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14.w,
            mainAxisSpacing: 14.h,
            childAspectRatio: 2.0,
            children: [
              ...'123456789'.split('').map((d) => _key(d)),
              _key('', isDelete: true),
              _key('0'),
              _key('OK', isConfirm: true),
            ],
          ),
        ],
      ),
    );
  }
}
