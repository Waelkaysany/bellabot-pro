import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../widgets/status_bar.dart';
import '../widgets/mode_navigation.dart';
import 'delivery_page.dart';
import 'cruise_page.dart';
import 'birthday_page.dart';
import 'dish_return_page.dart';
import 'ad_display_page.dart';
import 'iot_control_page.dart';
import 'payment_page.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late final PageController _pageController;

  late AnimationController _bgGlowController;
  late Animation<double> _bgGlowAnim;

  static const _pageTitles = [
    'Delivery',
    'Cruise Mode',
    'Birthday',
    'Dish Return',
    'Ad Display',
    'IoT Control',
    'Payment Terminal',
  ];

  static const _pageSubtitles = [
    'Manage trays & deliver orders',
    'Autonomous patrol mode',
    'Celebrate with your guests',
    'Return dishes to kitchen',
    'Promote your specials',
    'Control ESP32 devices',
    'RFID contactless payments',
  ];

  static const _pageIcons = [
    Icons.delivery_dining_rounded,
    Icons.electric_rickshaw_rounded,
    Icons.cake_rounded,
    Icons.replay_rounded,
    Icons.campaign_rounded,
    Icons.developer_board_rounded,
    Icons.contactless_rounded,
  ];

  final _pages = const [
    DeliveryPage(),
    CruisePage(),
    BirthdayPage(),
    DishReturnPage(),
    AdDisplayPage(),
    IotControlPage(),
    PaymentPage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _bgGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _bgGlowAnim = CurvedAnimation(
        parent: _bgGlowController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgGlowController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Animated ambient glow ──────────────────────────
          AnimatedBuilder(
            animation: _bgGlowAnim,
            builder: (_, __) => Positioned.fill(
              child: CustomPaint(
                painter: _AmbientGlowPainter(
                  t: _bgGlowAnim.value,
                  mode: _selectedIndex,
                ),
              ),
            ),
          ),

          // ── Main columns ────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top status bar
                const StatusBar(),

                // Page header with title + subtitle
                _PageHeader(
                  title: _pageTitles[_selectedIndex],
                  subtitle: _pageSubtitles[_selectedIndex],
                  icon: _pageIcons[_selectedIndex],
                  selectedIndex: _selectedIndex,
                ),

                // Page content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _pages,
                  ),
                ),

                // Bottom navigation
                ModeNavigation(
                  selectedIndex: _selectedIndex,
                  onModeChanged: _onTabChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page header ─────────────────────────────────────────────
class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final int selectedIndex;

  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selectedIndex,
  });

  static const _colors = [
    AppColors.puduBlue,
    AppColors.puduBlue,
    Color(0xFFE91E63),
    AppColors.safetyOrange,
    AppColors.puduBlue,
    Colors.teal,
    Color(0xFF00E676),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[selectedIndex];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: color.withValues(alpha: 0.3), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                  color: color.withValues(alpha: 0.4), width: 1),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  title,
                  key: ValueKey(title),
                  style: GoogleFonts.montserrat(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.montserrat(
                  fontSize: 11.sp,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Ambient glow background ─────────────────────────────────
class _AmbientGlowPainter extends CustomPainter {
  final double t;
  final int mode;

  const _AmbientGlowPainter({required this.t, required this.mode});

  static const _primaryColors = [
    AppColors.puduBlue,
    AppColors.puduBlue,
    Color(0xFFE91E63),
    AppColors.safetyOrange,
    AppColors.puduBlue,
    Colors.teal,
    Color(0xFF00E676),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final color = _primaryColors[mode];

    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.15),
      size.width * (0.35 + 0.06 * t),
      Paint()
        ..color = color.withValues(alpha: 0.05 + 0.02 * t)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100),
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.85),
      size.width * (0.3 + 0.05 * (1 - t)),
      Paint()
        ..color = color.withValues(alpha: 0.04 + 0.02 * (1 - t))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80),
    );
  }

  @override
  bool shouldRepaint(_AmbientGlowPainter old) =>
      old.t != t || old.mode != mode;
}
