import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:youmatter_mobile/features/authentication/providers/auth_provider.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  // ================================================================
  // REFERENCE DESIGN SIZE
  // ================================================================

  static const double designWidth = 1024.0;
  static const double designHeight = 1536.0;

  @override
  void initState() {
    super.initState();

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _checkAuthStatus();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    await ref.read(authStateProvider.notifier).checkAuthStatus();
  }

  // ================================================================
  // RESPONSIVE SCALE
  // ================================================================

  double _scale(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final widthScale = size.width / designWidth;
    final heightScale = size.height / designHeight;

    /*
     * Use the SMALLER scale.
     *
     * This is the important part that prevents:
     *
     * SMALL PHONE = BIG BUTTONS
     *
     * The entire design scales down proportionally.
     */

    return widthScale < heightScale ? widthScale : heightScale;
  }

  double _s(BuildContext context, double value) {
    final scale = _scale(context);

    /*
     * Never allow the design to grow beyond the reference size.
     */
    final safeScale = scale.clamp(0.0, 1.0);

    return value * safeScale;
  }

  // ================================================================
  // ANIMATION
  // ================================================================

  Widget _animate({
    required Widget child,
    required double start,
    required double end,
  }) {
    final animation = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  // ================================================================
  // PAGE
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final scale = _scale(context).clamp(0.0, 1.0);

    // ================================================================
    // RESPONSIVE VALUES
    // ================================================================

    final logoWidth = (designWidth * 0.58 * scale).clamp(230.0, 595.0);

    final logoHeight = (390.0 * scale).clamp(170.0, 390.0);

    final buttonWidth = (705.0 * scale).clamp(size.width - 32.0, 705.0);

    final buttonHeight = (137.0 * scale).clamp(58.0, 137.0);

    // ================================================================
    // POSITION VALUES
    // ================================================================

    final logoTop = 65.0 * scale;

    final headlineTop = 625.0 * scale;

    final descriptionTop = 710.0 * scale;

    final safetyTop = 1988.0 * scale;

    // ================================================================
    // LOWER SECTION POSITIONS
    // ================================================================

    final talkTop = 1600.0 * scale;

    final listenTop = 1790.0 * scale;

    final signInTop = 2050.0 * scale;

    final wavesHeight = (150.0 * scale).clamp(70.0, 150.0);

    return Scaffold(
      backgroundColor: Colors.white,

      // ==============================================================
      // BODY
      // ==============================================================
      body: Stack(
        fit: StackFit.expand,

        children: [
          // ==========================================================
          // BACKGROUND IMAGE
          // ==========================================================

          Positioned.fill(
            child: Image.asset(
              'assets/images/homebackground.png',

              fit: BoxFit.cover,

              alignment: Alignment.center,
            ),
          ),

          // ==========================================================
          // BACKGROUND WHITE OVERLAY
          // ==========================================================
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,

                  stops: [0.00, 0.16, 0.32, 0.48, 0.63, 0.76, 0.90, 1.00],

                  colors: [
                    Color(0x22FFFFFF),
                    Color(0x3FFFFFFF),
                    Color(0x65FFFFFF),
                    Color(0xA8FFFFFF),
                    Color(0xDFFFFFFF),
                    Color(0xF0FFFFFF),
                    Color(0xFAFFFFFF),
                    Color(0xFFFFFFFF),
                  ],
                ),
              ),
            ),
          ),

          // ==========================================================
          // SAFE AREA CONTENT
          // ==========================================================
          SafeArea(
            child: Stack(
              fit: StackFit.expand,

              children: [
                // ====================================================
                // LOGO
                // ====================================================

                Positioned(
                  top: logoTop,

                  left: 0,
                  right: 0,

                  child: _animate(
                    start: 0.0,
                    end: 0.25,

                    child: Center(
                      child: SizedBox(
                        width: logoWidth,
                        height: logoHeight,

                        child: Image.asset(
                          'assets/images/youmatterlogo.png',

                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),

                // ====================================================
                // HEADLINE
                // ====================================================
                Positioned(
                  top: headlineTop,

                  left: 16,
                  right: 16,

                  child: _animate(
                    start: 0.12,
                    end: 0.38,

                    child: FittedBox(
                      fit: BoxFit.scaleDown,

                      child: Text(
                        'A place to be heard.',

                        maxLines: 1,

                        textAlign: TextAlign.center,

                        style: TextStyle(
                          fontSize: (43.0 * scale).clamp(27.0, 43.0),

                          fontWeight: FontWeight.w800,

                          height: 1.1,

                          letterSpacing: -0.8,

                          color: const Color(0xFF0B2857),
                        ),
                      ),
                    ),
                  ),
                ),

                // ====================================================
                // DESCRIPTION
                // ====================================================
                Positioned(
                  top: descriptionTop,

                  left: 25,
                  right: 25,

                  child: _animate(
                    start: 0.20,
                    end: 0.46,

                    child: Text(
                      'YouMatter connects people who want\n'
                      'someone to talk to with people\n'
                      'willing to listen.',

                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: (23.0 * scale).clamp(15.0, 23.0),

                        fontWeight: FontWeight.w400,

                        height: 1.38,

                        letterSpacing: -0.1,

                        color: const Color(0xFF193A6A),
                      ),
                    ),
                  ),
                ),

                // ====================================================
                // SAFETY MESSAGE
                // ====================================================
                Positioned(
                  top: safetyTop,

                  left: 25,
                  right: 25,

                  child: _animate(
                    start: 0.30,
                    end: 0.55,

                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        // ------------------------------------------------
                        // SHIELD
                        // ------------------------------------------------

                        Icon(
                          Icons.shield_outlined,

                          size: (31.0 * scale).clamp(20.0, 31.0),

                          color: const Color(0xFF7E8B9B),
                        ),

                        SizedBox(width: (11.0 * scale).clamp(6.0, 11.0)),

                        // ------------------------------------------------
                        // TEXT
                        // ------------------------------------------------
                        Flexible(
                          child: Text(
                            'YouMatter is not a crisis or emergency service.',

                            textAlign: TextAlign.center,

                            style: TextStyle(
                              fontSize: (15.0 * scale).clamp(10.5, 15.0),

                              fontWeight: FontWeight.w400,

                              color: const Color.fromARGB(255, 231, 96, 5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ====================================================
                // TALK BUTTON
                // ====================================================
                Positioned(
                  top: talkTop,

                  left: (size.width - buttonWidth) / 2,

                  child: _animate(
                    start: 0.40,
                    end: 0.67,

                    child: _WelcomeActionButton(
                      width: buttonWidth,

                      height: buttonHeight,

                      icon: Icons.chat_bubble_outline,

                      title: 'I want to talk',

                      subtitle: 'Find someone who will listen',

                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,

                        end: Alignment.centerRight,

                        colors: [Color(0xFF7120F4), Color(0xFFC72DF2)],
                      ),

                      onPressed: () {
                        context.go('/register?intent=talk');
                      },
                    ),
                  ),
                ),

                // ====================================================
                // LISTEN BUTTON
                // ====================================================
                Positioned(
                  top: listenTop,

                  left: (size.width - buttonWidth) / 2,

                  child: _animate(
                    start: 0.48,
                    end: 0.75,

                    child: _WelcomeActionButton(
                      width: buttonWidth,

                      height: buttonHeight,

                      icon: Icons.hearing_outlined,

                      title: 'I want to listen',

                      subtitle: 'Be there for someone today',

                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,

                        end: Alignment.centerRight,

                        colors: [Color(0xFF1489F5), Color(0xFF2CC6D5)],
                      ),

                      onPressed: () {
                        context.go('/register?intent=listen');
                      },
                    ),
                  ),
                ),

                // ====================================================
                // ALREADY HAVE ACCOUNT / SIGN IN
                // ====================================================
                Positioned(
                  top: signInTop,

                  left: 10,
                  right: 10,

                  child: _animate(
                    start: 0.58,
                    end: 0.90,

                    child: Center(
                      child: TextButton(
                        onPressed: () {
                          context.go('/login');
                        },

                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: (8.0 * scale).clamp(4.0, 8.0),

                            vertical: (7.0 * scale).clamp(4.0, 7.0),
                          ),

                          minimumSize: Size.zero,

                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),

                        child: RichText(
                          textAlign: TextAlign.center,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          text: TextSpan(
                            children: [
                              // ------------------------------------------
                              // ALREADY HAVE ACCOUNT
                              // ------------------------------------------

                              TextSpan(
                                text: 'Already have an account?  ',

                                style: TextStyle(
                                  fontSize: (18.0 * scale).clamp(12.0, 18.0),

                                  fontWeight: FontWeight.w400,

                                  color: const Color(0xFF71829A),
                                ),
                              ),

                              // ------------------------------------------
                              // SIGN IN
                              // ------------------------------------------
                              TextSpan(
                                text: 'Sign in',

                                style: TextStyle(
                                  fontSize: (19.0 * scale).clamp(13.0, 19.0),

                                  fontWeight: FontWeight.w700,

                                  color: const Color(0xFF075DE8),
                                ),
                              ),

                              // ------------------------------------------
                              // ARROW
                              // ------------------------------------------
                              TextSpan(
                                text: '  →',

                                style: TextStyle(
                                  fontSize: (23.0 * scale).clamp(15.0, 23.0),

                                  fontWeight: FontWeight.w600,

                                  color: const Color(0xFF075DE8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==========================================================
          // BOTTOM WAVES
          // ==========================================================
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,

            child: IgnorePointer(
              child: SizedBox(
                height: wavesHeight,

                child: CustomPaint(painter: _BottomWavePainter()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// WELCOME ACTION BUTTON
// ====================================================================

class _WelcomeActionButton extends StatelessWidget {
  final double width;
  final double height;

  final IconData icon;

  final String title;
  final String subtitle;

  final Gradient gradient;

  final VoidCallback onPressed;

  const _WelcomeActionButton({
    required this.width,
    required this.height,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: onPressed,

          borderRadius: BorderRadius.circular(height / 2),

          child: Ink(
            width: width,
            height: height,

            decoration: BoxDecoration(
              gradient: gradient,

              borderRadius: BorderRadius.circular(height / 2),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.13),

                  blurRadius: (height * 0.14).clamp(7.0, 18.0),

                  offset: Offset(0, (height * 0.055).clamp(3.0, 8.0)),
                ),
              ],
            ),

            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = constraints.maxHeight;

                // ======================================================
                // RESPONSIVE INTERNAL SIZES
                // ======================================================

                final iconSize = (h * 0.42).clamp(25.0, 58.0);

                final titleSize = (h * 0.18).clamp(14.0, 25.0);

                final subtitleSize = (h * 0.125).clamp(10.0, 17.0);

                final arrowSize = (h * 0.31).clamp(20.0, 43.0);

                final iconArea = (h * 0.78).clamp(48.0, 105.0);

                final arrowArea = (h * 0.70).clamp(48.0, 90.0);

                return Row(
                  children: [
                    // ==================================================
                    // ICON
                    // ==================================================

                    SizedBox(
                      width: iconArea,

                      child: Center(
                        child: Icon(icon, color: Colors.white, size: iconSize),
                      ),
                    ),

                    // ==================================================
                    // TEXT
                    // ==================================================
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 3, right: 3),

                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,

                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              title,

                              maxLines: 1,

                              overflow: TextOverflow.ellipsis,

                              style: TextStyle(
                                color: Colors.white,

                                fontSize: titleSize,

                                fontWeight: FontWeight.w800,

                                height: 1.05,
                              ),
                            ),

                            SizedBox(height: (h * 0.065).clamp(3.0, 9.0)),

                            Text(
                              subtitle,

                              maxLines: 1,

                              overflow: TextOverflow.ellipsis,

                              style: TextStyle(
                                color: Colors.white,

                                fontSize: subtitleSize,

                                fontWeight: FontWeight.w400,

                                height: 1.05,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ==================================================
                    // ARROW
                    // ==================================================
                    SizedBox(
                      width: arrowArea,

                      child: Center(
                        child: Icon(
                          Icons.arrow_forward,

                          color: Colors.white,

                          size: arrowSize,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ====================================================================
// BOTTOM WAVE PAINTER
// ====================================================================

class _BottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // ================================================================
    // LEFT OUTER WAVE
    // ================================================================

    final leftOuterPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFE9E2FF);

    final leftOuterPath = Path();

    leftOuterPath.moveTo(0, size.height);

    leftOuterPath.lineTo(0, size.height * 0.28);

    leftOuterPath.cubicTo(
      size.width * 0.09,
      size.height * 0.31,
      size.width * 0.15,
      size.height * 0.43,
      size.width * 0.24,
      size.height * 0.61,
    );

    leftOuterPath.cubicTo(
      size.width * 0.32,
      size.height * 0.79,
      size.width * 0.41,
      size.height * 0.93,
      size.width * 0.50,
      size.height,
    );

    leftOuterPath.close();

    canvas.drawPath(leftOuterPath, leftOuterPaint);

    // ================================================================
    // LEFT INNER WAVE
    // ================================================================

    final leftInnerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFD9CEFF);

    final leftInnerPath = Path();

    leftInnerPath.moveTo(0, size.height);

    leftInnerPath.lineTo(0, size.height * 0.52);

    leftInnerPath.cubicTo(
      size.width * 0.11,
      size.height * 0.56,
      size.width * 0.20,
      size.height * 0.72,
      size.width * 0.31,
      size.height * 0.87,
    );

    leftInnerPath.cubicTo(
      size.width * 0.38,
      size.height * 0.96,
      size.width * 0.44,
      size.height,
      size.width * 0.50,
      size.height,
    );

    leftInnerPath.close();

    canvas.drawPath(leftInnerPath, leftInnerPaint);

    // ================================================================
    // RIGHT OUTER WAVE
    // ================================================================

    final rightOuterPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFE1F5FF);

    final rightOuterPath = Path();

    rightOuterPath.moveTo(size.width, size.height);

    rightOuterPath.lineTo(size.width, size.height * 0.28);

    rightOuterPath.cubicTo(
      size.width * 0.91,
      size.height * 0.31,
      size.width * 0.85,
      size.height * 0.43,
      size.width * 0.76,
      size.height * 0.61,
    );

    rightOuterPath.cubicTo(
      size.width * 0.68,
      size.height * 0.79,
      size.width * 0.59,
      size.height * 0.93,
      size.width * 0.50,
      size.height,
    );

    rightOuterPath.close();

    canvas.drawPath(rightOuterPath, rightOuterPaint);

    // ================================================================
    // RIGHT INNER WAVE
    // ================================================================

    final rightInnerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFCDEEFF);

    final rightInnerPath = Path();

    rightInnerPath.moveTo(size.width, size.height);

    rightInnerPath.lineTo(size.width, size.height * 0.52);

    rightInnerPath.cubicTo(
      size.width * 0.89,
      size.height * 0.56,
      size.width * 0.80,
      size.height * 0.72,
      size.width * 0.69,
      size.height * 0.87,
    );

    rightInnerPath.cubicTo(
      size.width * 0.62,
      size.height * 0.96,
      size.width * 0.56,
      size.height,
      size.width * 0.50,
      size.height,
    );

    rightInnerPath.close();

    canvas.drawPath(rightInnerPath, rightInnerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
