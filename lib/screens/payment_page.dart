import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/iot_provider.dart';
import '../core/app_colors.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  PAYMENT PAGE
// ══════════════════════════════════════════════════════════════════════════════
class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with TickerProviderStateMixin {
  // ─── Pulse ring animation (idle state) ─────────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // ─── Overlay entrance animation ────────────────────────────────────────────
  late final AnimationController _overlayCtrl;
  late final Animation<double> _overlayScale;
  late final Animation<double> _overlayFade;

  // ─── Shake animation (decline) ─────────────────────────────────────────────
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  String _lastShownStatus = 'IDLE';

  @override
  void initState() {
    super.initState();

    // Idle pulse
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    // Overlay scale + fade
    _overlayCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _overlayScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _overlayCtrl, curve: Curves.elasticOut),
    );
    _overlayFade = CurvedAnimation(
      parent: _overlayCtrl,
      curve: Curves.easeOut,
    );

    // Shake
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);

    // Start RFID polling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IotProvider>().startRfidPolling();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _overlayCtrl.dispose();
    _shakeCtrl.dispose();
    context.read<IotProvider>().stopRfidPolling();
    super.dispose();
  }

  void _triggerOverlay(String status) {
    if (status == 'SUCCESS') {
      HapticFeedback.heavyImpact();
      _overlayCtrl.forward(from: 0);
    } else if (status == 'FAILED') {
      HapticFeedback.vibrate();
      _overlayCtrl.forward(from: 0);
      _shakeCtrl.forward(from: 0).then((_) => _shakeCtrl.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IotProvider>();
    final status   = provider.rfidStatus;

    // Trigger overlay when status changes
    if (status != 'IDLE' && status != _lastShownStatus) {
      _lastShownStatus = status;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerOverlay(status);
      });
    }
    if (status == 'IDLE' && _lastShownStatus != 'IDLE') {
      _lastShownStatus = 'IDLE';
      _overlayCtrl.reverse();
    }

    final isSuccess = status == 'SUCCESS';
    final isFailed  = status == 'FAILED';
    final isActive  = isSuccess || isFailed;

    return Stack(
      children: [
        // ── Main POS UI ──────────────────────────────────────────────────────
        ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          children: [
            // Amount card
            _AmountCard(),
            SizedBox(height: 16.h),

            // Tap zone
            _TapZone(pulseAnim: _pulseAnim, isActive: isActive),
            SizedBox(height: 24.h),

            // Transaction history header
            Padding(
              padding: EdgeInsets.only(left: 4.w, bottom: 10.h),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_rounded,
                      color: AppColors.puduBlue, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'TRANSACTION LOG',
                    style: GoogleFonts.montserrat(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  if (provider.transactionHistory.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        // Future: clear history
                      },
                      child: Text(
                        '${provider.transactionHistory.length} scans',
                        style: GoogleFonts.montserrat(
                          fontSize: 10.sp,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // History list
            if (provider.transactionHistory.isEmpty)
              _EmptyHistory()
            else
              ...provider.transactionHistory
                  .take(15)
                  .map((tx) => _TransactionTile(tx: tx)),

            SizedBox(height: 24.h),
          ],
        ),

        // ── Success / Failure Overlay ─────────────────────────────────────────
        if (isActive)
          AnimatedBuilder(
            animation: _overlayCtrl,
            builder: (_, __) => FadeTransition(
              opacity: _overlayFade,
              child: Container(
                color: Colors.black.withValues(alpha: 0.75),
                child: Center(
                  child: ScaleTransition(
                    scale: _overlayScale,
                    child: AnimatedBuilder(
                      animation: _shakeAnim,
                      builder: (_, child) {
                        final shake = isFailed
                            ? math.sin(_shakeAnim.value * math.pi * 6) * 14
                            : 0.0;
                        return Transform.translate(
                          offset: Offset(shake, 0),
                          child: child,
                        );
                      },
                      child: _PaymentResultCard(
                        isSuccess: isSuccess,
                        name:      provider.rfidName,
                        uid:       provider.rfidUid,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  AMOUNT CARD  (top of screen — shows $12.50)
// ══════════════════════════════════════════════════════════════════════════════
class _AmountCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2137), Color(0xFF0A3D62)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.puduBlue.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.puduBlue.withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ORDER TOTAL',
                  style: GoogleFonts.montserrat(
                    fontSize: 10.sp,
                    color: AppColors.textMuted,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '\$12.50',
                  style: GoogleFonts.montserrat(
                    fontSize: 34.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'BellaBot Pro Restaurant',
                  style: GoogleFonts.montserrat(
                    fontSize: 10.sp,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.puduBlue.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.puduBlue.withValues(alpha: 0.4)),
                ),
                child: Icon(
                  Icons.contactless_rounded,
                  color: AppColors.puduBlue,
                  size: 28.sp,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'RFID Pay',
                style: GoogleFonts.montserrat(
                  fontSize: 9.sp,
                  color: AppColors.puduBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  TAP ZONE  (animated pulsing ring)
// ══════════════════════════════════════════════════════════════════════════════
class _TapZone extends StatelessWidget {
  final Animation<double> pulseAnim;
  final bool isActive;

  const _TapZone({required this.pulseAnim, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, __) {
        final pulse = pulseAnim.value;
        return Column(
          children: [
            SizedBox(
              height: 200.h,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow ring
                  Container(
                    width:  (140 + pulse * 20).w,
                    height: (140 + pulse * 20).w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.puduBlue
                            .withValues(alpha: 0.12 + pulse * 0.08),
                        width: 2,
                      ),
                    ),
                  ),
                  // Middle ring
                  Container(
                    width:  (110 + pulse * 12).w,
                    height: (110 + pulse * 12).w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.puduBlue
                            .withValues(alpha: 0.2 + pulse * 0.1),
                        width: 2,
                      ),
                    ),
                  ),
                  // Core circle
                  Container(
                    width: 88.w,
                    height: 88.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.puduBlue.withValues(alpha: 0.25 + pulse * 0.1),
                          AppColors.puduBlue.withValues(alpha: 0.05),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.puduBlue.withValues(alpha: 0.6),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.puduBlue
                              .withValues(alpha: 0.2 + pulse * 0.15),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.contactless_rounded,
                      color: AppColors.puduBlue,
                      size: 42.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              isActive ? 'Processing...' : 'Tap card to pay',
              style: GoogleFonts.montserrat(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: isActive ? AppColors.puduBlue : AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              isActive
                  ? 'Hold card near reader'
                  : 'Hold your RFID card near the robot sensor',
              style: GoogleFonts.montserrat(
                fontSize: 10.sp,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  PAYMENT RESULT CARD  (full-screen overlay card)
// ══════════════════════════════════════════════════════════════════════════════
class _PaymentResultCard extends StatelessWidget {
  final bool isSuccess;
  final String name;
  final String uid;

  const _PaymentResultCard({
    required this.isSuccess,
    required this.name,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final color  = isSuccess ? const Color(0xFF00E676) : const Color(0xFFFF5252);
    final bg1    = isSuccess ? const Color(0xFF0A2A1A) : const Color(0xFF2A0A0A);
    final bg2    = isSuccess ? const Color(0xFF0D4A2A) : const Color(0xFF4A0D0D);
    final icon   = isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final title  = isSuccess ? 'Payment Approved!' : 'Payment Declined';
    final sub    = isSuccess
        ? 'Thank you, $name! 🎉\n\$12.50 charged successfully.'
        : 'Sorry, $name.\nYour card was not authorised.';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.all(28.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bg1, bg2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 40,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Glow icon
          Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 52.sp),
          ),
          SizedBox(height: 20.h),

          // Title
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10.h),

          // Sub message
          Text(
            sub,
            style: GoogleFonts.montserrat(
              fontSize: 13.sp,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 18.h),

          // UID chip
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.nfc_rounded,
                    color: AppColors.textMuted, size: 14.sp),
                SizedBox(width: 6.w),
                Text(
                  uid.isEmpty ? '-- -- -- --' : uid.toUpperCase(),
                  style: GoogleFonts.robotoMono(
                    fontSize: 12.sp,
                    color: AppColors.textMuted,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),

          Text(
            'Auto-closing…',
            style: GoogleFonts.montserrat(
              fontSize: 10.sp,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  TRANSACTION TILE  (history list item)
// ══════════════════════════════════════════════════════════════════════════════
class _TransactionTile extends StatelessWidget {
  final RfidTransaction tx;
  const _TransactionTile({required this.tx});

  String _timeLabel(DateTime t) {
    final now  = DateTime.now();
    final diff = now.difference(t);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${t.hour.toString().padLeft(2, "0")}:${t.minute.toString().padLeft(2, "0")}';
  }

  @override
  Widget build(BuildContext context) {
    final color = tx.isSuccess ? const Color(0xFF00E676) : const Color(0xFFFF5252);
    final icon  = tx.isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: color, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tx.isSuccess ? 'Approved' : 'Declined',
                      style: GoogleFonts.montserrat(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      tx.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3.h),
                Text(
                  tx.uid.toUpperCase(),
                  style: GoogleFonts.robotoMono(
                    fontSize: 10.sp,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (tx.isSuccess)
                Text(
                  '\$12.50',
                  style: GoogleFonts.montserrat(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              SizedBox(height: 4.h),
              Text(
                _timeLabel(tx.time),
                style: GoogleFonts.montserrat(
                  fontSize: 9.sp,
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

// ══════════════════════════════════════════════════════════════════════════════
//  EMPTY HISTORY
// ══════════════════════════════════════════════════════════════════════════════
class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 32.h),
      child: Column(
        children: [
          Icon(Icons.history_rounded,
              color: AppColors.textMuted, size: 36.sp),
          SizedBox(height: 10.h),
          Text(
            'No transactions yet',
            style: GoogleFonts.montserrat(
              fontSize: 13.sp,
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Tap a card to see logs here',
            style: GoogleFonts.montserrat(
              fontSize: 10.sp,
              color: AppColors.textMuted.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
