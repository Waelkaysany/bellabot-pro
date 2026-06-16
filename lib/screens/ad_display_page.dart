import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../widgets/robot_cat_face.dart';

class AdDisplayPage extends StatefulWidget {
  const AdDisplayPage({super.key});

  @override
  State<AdDisplayPage> createState() => _AdDisplayPageState();
}

class _AdDisplayPageState extends State<AdDisplayPage>
    with SingleTickerProviderStateMixin {
  bool _displaying = false;
  String _selectedAd = 'Today\'s Specials';
  double _volume = 0.7;
  bool _motionSensor = true;

  late AnimationController _screenController;
  late Animation<double> _screenAnim;

  final List<Map<String, dynamic>> _ads = [
    {'title': 'Today\'s Specials', 'icon': Icons.restaurant_menu_rounded, 'color': const Color(0xFF4CAF50)},
    {'title': 'Happy Hour 🍹', 'icon': Icons.local_bar_rounded, 'color': const Color(0xFFFF9800)},
    {'title': 'Chef\'s Picks', 'icon': Icons.star_rounded, 'color': const Color(0xFFFFD700)},
    {'title': 'Dessert Menu', 'icon': Icons.icecream_rounded, 'color': const Color(0xFFE91E63)},
  ];

  @override
  void initState() {
    super.initState();
    _screenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _screenAnim = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _screenController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _screenController.dispose();
    super.dispose();
  }

  Color get _adColor =>
      _ads.firstWhere((a) => a['title'] == _selectedAd)['color'] as Color;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview screen card
          AnimatedBuilder(
            animation: _screenAnim,
            builder: (_, __) => Container(
              width: double.infinity,
              height: 180.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                gradient: LinearGradient(
                  colors: _displaying
                      ? [
                          _adColor.withValues(alpha: 0.3),
                          _adColor.withValues(alpha: 0.1),
                        ]
                      : [AppColors.surface, AppColors.surface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: _displaying
                      ? _adColor.withValues(alpha: 0.6)
                      : AppColors.glassBorder,
                  width: _displaying ? 2 : 1,
                ),
                boxShadow: _displaying
                    ? [
                        BoxShadow(
                          color: _adColor.withValues(alpha: 0.3 * _screenAnim.value),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_displaying) ...[
                    Icon(Icons.live_tv_rounded,
                        color: AppColors.textMuted, size: 40.sp),
                    SizedBox(height: 8.h),
                    Text(
                      'Display Preview',
                      style: GoogleFonts.montserrat(
                          fontSize: 14.sp, color: AppColors.textMuted),
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 60.w,
                          height: 60.w,
                          child: const RobotCatFace(mode: RobotFaceMode.happy),
                        ),
                        SizedBox(width: 16.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NOW SHOWING',
                              style: GoogleFonts.montserrat(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: _adColor,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              _selectedAd,
                              style: GoogleFonts.montserrat(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: _adColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                            color: _adColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        '● LIVE ON DISPLAY',
                        style: GoogleFonts.montserrat(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: _adColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          SizedBox(height: 20.h),

          // Ad content selector
          Text(
            'Ad Content',
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
            childAspectRatio: 2.2,
            children: (_ads.map((ad) {
              final selected = _selectedAd == ad['title'];
              final color = ad['color'] as Color;
              return GestureDetector(
                onTap: () => setState(() => _selectedAd = ad['title']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14.r),
                    color: selected
                        ? color.withValues(alpha: 0.15)
                        : AppColors.surface,
                    border: Border.all(
                      color: selected
                          ? color.withValues(alpha: 0.7)
                          : AppColors.glassBorder,
                      width: selected ? 1.8 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(ad['icon'] as IconData,
                          color: selected ? color : AppColors.textMuted,
                          size: 18.sp),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          ad['title'] as String,
                          style: GoogleFonts.montserrat(
                            fontSize: 12.sp,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected ? color : AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList()),
          ),

          SizedBox(height: 20.h),

          // Volume
          Row(
            children: [
              Text(
                'Volume',
                style: GoogleFonts.montserrat(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Icon(
                _volume > 0.5
                    ? Icons.volume_up_rounded
                    : Icons.volume_down_rounded,
                color: AppColors.textMuted,
                size: 18.sp,
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.puduBlue,
              inactiveTrackColor: AppColors.surface,
              thumbColor: AppColors.puduBlue,
              overlayColor: AppColors.puduBlue.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: _volume,
              min: 0,
              max: 1,
              divisions: 10,
              onChanged: (v) => setState(() => _volume = v),
            ),
          ),

          // Motion sensor toggle
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              color: AppColors.surface,
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.motion_photos_on_rounded,
                    color: AppColors.puduBlue, size: 22.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Motion Sensor Trigger',
                        style: GoogleFonts.montserrat(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Play ad when movement detected',
                        style: GoogleFonts.montserrat(
                          fontSize: 11.sp,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _motionSensor,
                  onChanged: (v) => setState(() => _motionSensor = v),
                  activeColor: AppColors.puduBlue,
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // Start button
          GestureDetector(
            onTap: () {
              setState(() => _displaying = !_displaying);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _displaying
                        ? '📺 Display Mode On!'
                        : '⏹️ Display Stopped',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
                  ),
                  backgroundColor:
                      _displaying ? AppColors.puduBlue : AppColors.textMuted,
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
                gradient: _displaying
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
                    color: (_displaying
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
                    _displaying
                        ? Icons.stop_circle_rounded
                        : Icons.campaign_rounded,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    _displaying ? 'STOP DISPLAY' : 'START DISPLAY',
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
