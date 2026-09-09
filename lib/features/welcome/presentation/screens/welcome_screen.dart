import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:youmatter_mobile/features/authentication/providers/auth_provider.dart';

// ================================================================
// ENUMS (Moved to top level)
// ================================================================

enum ScreenSize { small, medium, large, xlarge }

enum ScreenOrientation { portrait, landscape, square }

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
  // SCREEN DETECTION
  // ================================================================

  ScreenOrientation _getOrientation(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final aspectRatio = size.width / size.height;

    if (aspectRatio > 1.2) return ScreenOrientation.landscape;
    if (aspectRatio < 0.8) return ScreenOrientation.portrait;
    return ScreenOrientation.square;
  }

  ScreenSize _getScreenSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;

    // Use the smaller dimension for categorization
    final minDimension = math.min(width, height);

    if (minDimension < 360) return ScreenSize.small;
    if (minDimension < 600) return ScreenSize.medium;
    if (minDimension < 900) return ScreenSize.large;
    return ScreenSize.xlarge;
  }

  // ================================================================
  // RESPONSIVE SCALE
  // ================================================================

  double _scale(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final widthScale = size.width / designWidth;
    final heightScale = size.height / designHeight;

    return math.min(widthScale, heightScale).clamp(0.0, 1.0);
  }

  double _scaleValue(BuildContext context, double value) {
    final scale = _scale(context);
    return value * scale;
  }

  double _responsiveSpacing(
    BuildContext context, {
    double fractionOfHeight = 0.02,
    double minSpacing = 4.0,
    double maxSpacing = 40.0,
  }) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final calculated = screenHeight * fractionOfHeight;
    return calculated.clamp(minSpacing, maxSpacing);
  }

  double _responsiveFontSize(
    BuildContext context, {
    required double designSize,
    double minSize = 10.0,
    double maxSize = 40.0,
  }) {
    final scale = _scale(context);
    final calculated = designSize * scale;
    return calculated.clamp(minSize, maxSize);
  }

  double _calculateButtonWidth(
    BuildContext context, {
    bool isLandscape = false,
  }) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final _ = size.height;

    if (isLandscape) {
      // In landscape, buttons are side by side
      final maxWidth = (screenWidth - 48) / 2;
      return maxWidth.clamp(180.0, 400.0);
    } else {
      // In portrait, buttons span most of the width
      final maxWidth = screenWidth - 32;
      return maxWidth.clamp(180.0, 600.0);
    }
  }

  double _calculateButtonHeight(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    // Scale with screen height but with min/max
    return (screenHeight * 0.075).clamp(48.0, 120.0);
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
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final orientation = _getOrientation(context);
    final screenSize = _getScreenSize(context);
    final isLandscape = orientation == ScreenOrientation.landscape;

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;
          final availableWidth = constraints.maxWidth;

          return Stack(
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
              // MAIN CONTENT
              // ==========================================================
              if (isLandscape)
                _buildLandscapeLayout(
                  context,
                  availableWidth,
                  availableHeight,
                  screenSize,
                )
              else
                _buildPortraitLayout(
                  context,
                  availableWidth,
                  availableHeight,
                  screenSize,
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
                    height: _calculateWavesHeight(context),
                    child: CustomPaint(painter: _BottomWavePainter()),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ================================================================
  // PORTRAIT LAYOUT
  // ================================================================

  Widget _buildPortraitLayout(
    BuildContext context,
    double availableWidth,
    double availableHeight,
    ScreenSize screenSize,
  ) {
    final _ = _scale(context);
    final isSmallScreen = screenSize == ScreenSize.small;
    final isLargeScreen =
        screenSize == ScreenSize.large || screenSize == ScreenSize.xlarge;

    // Calculate sizes
    final logoWidth = _scaleValue(
      context,
      designWidth * 0.58,
    ).clamp(isSmallScreen ? 180.0 : 230.0, isLargeScreen ? 650.0 : 595.0);
    final logoHeight = _scaleValue(
      context,
      390.0,
    ).clamp(isSmallScreen ? 140.0 : 170.0, isLargeScreen ? 420.0 : 390.0);

    final buttonWidth = _calculateButtonWidth(context, isLandscape: false);
    final buttonHeight = _calculateButtonHeight(context);

    // Determine spacing based on screen height
    final isVeryTall = availableHeight > 900;
    final isVeryShort = availableHeight < 650;

    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ============================================================
          // CENTERED CONTENT WITH FLEXIBLE SPACING
          // ============================================================

          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Container(
              height: availableHeight, // Fill the available height
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ====================================================
                  // TOP FLEXIBLE SPACER (distributes space evenly)
                  // ====================================================

                  Expanded(flex: isVeryTall ? 2 : 1, child: SizedBox.shrink()),

                  // ====================================================
                  // LOGO
                  // ====================================================
                  _animate(
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

                  // ====================================================
                  // SPACING AFTER LOGO
                  // ====================================================
                  SizedBox(
                    height: isVeryTall
                        ? _responsiveSpacing(
                            context,
                            fractionOfHeight: 0.04,
                            minSpacing: 25,
                            maxSpacing: 60,
                          )
                        : _responsiveSpacing(
                            context,
                            fractionOfHeight: 0.025,
                            minSpacing: 15,
                            maxSpacing: 35,
                          ),
                  ),

                  // ====================================================
                  // HEADLINE
                  // ====================================================
                  _animate(
                    start: 0.12,
                    end: 0.38,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'A place to be heard.',
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: _responsiveFontSize(
                              context,
                              designSize: isVeryTall ? 48.0 : 43.0,
                              minSize: 27.0,
                              maxSize: isVeryTall ? 55.0 : 43.0,
                            ),
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
                  // SPACING AFTER HEADLINE
                  // ====================================================
                  SizedBox(
                    height: _responsiveSpacing(
                      context,
                      fractionOfHeight: isVeryTall ? 0.025 : 0.015,
                      minSpacing: 8,
                      maxSpacing: isVeryTall ? 40 : 25,
                    ),
                  ),

                  // ====================================================
                  // DESCRIPTION
                  // ====================================================
                  _animate(
                    start: 0.20,
                    end: 0.46,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'YouMatter connects people who want\n'
                        'someone to talk to with people\n'
                        'willing to listen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: _responsiveFontSize(
                            context,
                            designSize: isVeryTall ? 26.0 : 23.0,
                            minSize: 15.0,
                            maxSize: isVeryTall ? 30.0 : 23.0,
                          ),
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
                  SizedBox(
                    height: _responsiveSpacing(
                      context,
                      fractionOfHeight: isVeryTall ? 0.05 : 0.03,
                      minSpacing: isVeryShort ? 15 : 25,
                      maxSpacing: isVeryTall ? 60 : 40,
                    ),
                  ),

                  _animate(
                    start: 0.30,
                    end: 0.55,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: _responsiveFontSize(
                              context,
                              designSize: isVeryTall ? 35.0 : 31.0,
                              minSize: 20.0,
                              maxSize: isVeryTall ? 40.0 : 31.0,
                            ),
                            color: const Color(0xFF7E8B9B),
                          ),
                          SizedBox(
                            width: _responsiveFontSize(
                              context,
                              designSize: 11.0,
                              minSize: 6.0,
                              maxSize: 11.0,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              'YouMatter is not a crisis or emergency service.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: _responsiveFontSize(
                                  context,
                                  designSize: isVeryTall ? 17.0 : 15.0,
                                  minSize: 10.5,
                                  maxSize: isVeryTall ? 20.0 : 15.0,
                                ),
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
                  // FLEXIBLE SPACER (pushes buttons down evenly)
                  // ====================================================
                  Expanded(flex: isVeryTall ? 3 : 2, child: SizedBox.shrink()),

                  // ====================================================
                  // TALK BUTTON
                  // ====================================================
                  _animate(
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

                  // ====================================================
                  // SPACING BETWEEN BUTTONS
                  // ====================================================
                  SizedBox(
                    height: _responsiveSpacing(
                      context,
                      fractionOfHeight: isVeryTall ? 0.025 : 0.015,
                      minSpacing: 10,
                      maxSpacing: isVeryTall ? 40 : 25,
                    ),
                  ),

                  // ====================================================
                  // LISTEN BUTTON
                  // ====================================================
                  _animate(
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

                  // ====================================================
                  // SPACING BEFORE SIGN IN
                  // ====================================================
                  SizedBox(
                    height: _responsiveSpacing(
                      context,
                      fractionOfHeight: isVeryTall ? 0.035 : 0.02,
                      minSpacing: 15,
                      maxSpacing: isVeryTall ? 50 : 30,
                    ),
                  ),

                  // ====================================================
                  // SIGN IN LINK
                  // ====================================================
                  _animate(
                    start: 0.58,
                    end: 0.90,
                    child: Center(
                      child: TextButton(
                        onPressed: () {
                          context.go('/login');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: _responsiveFontSize(
                              context,
                              designSize: 8.0,
                              minSize: 4.0,
                              maxSize: 8.0,
                            ),
                            vertical: _responsiveFontSize(
                              context,
                              designSize: 7.0,
                              minSize: 4.0,
                              maxSize: 7.0,
                            ),
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
                              TextSpan(
                                text: 'Already have an account?  ',
                                style: TextStyle(
                                  fontSize: _responsiveFontSize(
                                    context,
                                    designSize: isVeryTall ? 20.0 : 18.0,
                                    minSize: 12.0,
                                    maxSize: isVeryTall ? 24.0 : 18.0,
                                  ),
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF71829A),
                                ),
                              ),
                              TextSpan(
                                text: 'Sign in',
                                style: TextStyle(
                                  fontSize: _responsiveFontSize(
                                    context,
                                    designSize: isVeryTall ? 21.0 : 19.0,
                                    minSize: 13.0,
                                    maxSize: isVeryTall ? 25.0 : 19.0,
                                  ),
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF075DE8),
                                ),
                              ),
                              TextSpan(
                                text: '  →',
                                style: TextStyle(
                                  fontSize: _responsiveFontSize(
                                    context,
                                    designSize: isVeryTall ? 25.0 : 23.0,
                                    minSize: 15.0,
                                    maxSize: isVeryTall ? 30.0 : 23.0,
                                  ),
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

                  // ====================================================
                  // BOTTOM FLEXIBLE SPACER
                  // ====================================================
                  Expanded(flex: 1, child: SizedBox.shrink()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // LANDSCAPE LAYOUT
  // ================================================================

  Widget _buildLandscapeLayout(
    BuildContext context,
    double availableWidth,
    double availableHeight,
    ScreenSize screenSize,
  ) {
    final _ = _scale(context);
    final isLargeScreen =
        screenSize == ScreenSize.large || screenSize == ScreenSize.xlarge;
    final isVeryTall = availableHeight > 900;

    // Calculate sizes
    final logoWidth = _scaleValue(
      context,
      designWidth * 0.4,
    ).clamp(150.0, isLargeScreen ? 400.0 : 350.0);
    final logoHeight = _scaleValue(
      context,
      250.0,
    ).clamp(120.0, isLargeScreen ? 300.0 : 250.0);

    final _ = _calculateButtonWidth(context, isLandscape: true);
    final buttonHeight = _calculateButtonHeight(context);

    return SafeArea(
      child: Row(
        children: [
          // ============================================================
          // LEFT SIDE - CONTENT
          // ============================================================

          Expanded(
            flex: isLargeScreen ? 1 : 2,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: SizedBox(
                height: availableHeight - 40,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    _animate(
                      start: 0.0,
                      end: 0.25,
                      child: SizedBox(
                        width: logoWidth,
                        height: logoHeight,
                        child: Image.asset(
                          'assets/images/youmatterlogo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    SizedBox(
                      height: _responsiveSpacing(
                        context,
                        fractionOfHeight: isVeryTall ? 0.04 : 0.02,
                        minSpacing: 16,
                        maxSpacing: isVeryTall ? 60 : 30,
                      ),
                    ),

                    // Headline
                    _animate(
                      start: 0.12,
                      end: 0.38,
                      child: Text(
                        'A place to be heard.',
                        style: TextStyle(
                          fontSize: _responsiveFontSize(
                            context,
                            designSize: isVeryTall ? 48.0 : 40.0,
                            minSize: 28.0,
                            maxSize: isVeryTall ? 56.0 : 48.0,
                          ),
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          letterSpacing: -0.8,
                          color: const Color(0xFF0B2857),
                        ),
                      ),
                    ),

                    SizedBox(
                      height: _responsiveSpacing(
                        context,
                        fractionOfHeight: isVeryTall ? 0.025 : 0.015,
                        minSpacing: 8,
                        maxSpacing: isVeryTall ? 40 : 25,
                      ),
                    ),

                    // Description
                    _animate(
                      start: 0.20,
                      end: 0.46,
                      child: Text(
                        'YouMatter connects people who want\n'
                        'someone to talk to with people\n'
                        'willing to listen.',
                        style: TextStyle(
                          fontSize: _responsiveFontSize(
                            context,
                            designSize: isVeryTall ? 24.0 : 20.0,
                            minSize: 14.0,
                            maxSize: isVeryTall ? 28.0 : 22.0,
                          ),
                          fontWeight: FontWeight.w400,
                          height: 1.38,
                          letterSpacing: -0.1,
                          color: const Color(0xFF193A6A),
                        ),
                      ),
                    ),

                    SizedBox(
                      height: _responsiveSpacing(
                        context,
                        fractionOfHeight: isVeryTall ? 0.04 : 0.025,
                        minSpacing: 20,
                        maxSpacing: isVeryTall ? 50 : 30,
                      ),
                    ),

                    // Safety message
                    _animate(
                      start: 0.30,
                      end: 0.55,
                      child: Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: _responsiveFontSize(
                              context,
                              designSize: isVeryTall ? 32.0 : 28.0,
                              minSize: 18.0,
                              maxSize: isVeryTall ? 38.0 : 28.0,
                            ),
                            color: const Color(0xFF7E8B9B),
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'YouMatter is not a crisis or emergency service.',
                              style: TextStyle(
                                fontSize: _responsiveFontSize(
                                  context,
                                  designSize: isVeryTall ? 16.0 : 14.0,
                                  minSize: 10.0,
                                  maxSize: isVeryTall ? 20.0 : 14.0,
                                ),
                                fontWeight: FontWeight.w400,
                                color: const Color.fromARGB(255, 231, 96, 5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(flex: 1, child: SizedBox.shrink()),

                    // Buttons row
                    Row(
                      children: [
                        Expanded(
                          child: _animate(
                            start: 0.40,
                            end: 0.67,
                            child: _WelcomeActionButton(
                              width: double.infinity,
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
                        SizedBox(width: 16),
                        Expanded(
                          child: _animate(
                            start: 0.48,
                            end: 0.75,
                            child: _WelcomeActionButton(
                              width: double.infinity,
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
                      ],
                    ),

                    SizedBox(
                      height: _responsiveSpacing(
                        context,
                        fractionOfHeight: isVeryTall ? 0.035 : 0.02,
                        minSpacing: 16,
                        maxSpacing: isVeryTall ? 50 : 30,
                      ),
                    ),

                    // Sign in link
                    _animate(
                      start: 0.58,
                      end: 0.90,
                      child: TextButton(
                        onPressed: () {
                          context.go('/login');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: _responsiveFontSize(
                              context,
                              designSize: 8.0,
                              minSize: 4.0,
                              maxSize: 8.0,
                            ),
                            vertical: _responsiveFontSize(
                              context,
                              designSize: 7.0,
                              minSize: 4.0,
                              maxSize: 7.0,
                            ),
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
                              TextSpan(
                                text: 'Already have an account?  ',
                                style: TextStyle(
                                  fontSize: _responsiveFontSize(
                                    context,
                                    designSize: isVeryTall ? 20.0 : 18.0,
                                    minSize: 12.0,
                                    maxSize: isVeryTall ? 24.0 : 18.0,
                                  ),
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF71829A),
                                ),
                              ),
                              TextSpan(
                                text: 'Sign in',
                                style: TextStyle(
                                  fontSize: _responsiveFontSize(
                                    context,
                                    designSize: isVeryTall ? 21.0 : 19.0,
                                    minSize: 13.0,
                                    maxSize: isVeryTall ? 25.0 : 19.0,
                                  ),
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF075DE8),
                                ),
                              ),
                              TextSpan(
                                text: '  →',
                                style: TextStyle(
                                  fontSize: _responsiveFontSize(
                                    context,
                                    designSize: isVeryTall ? 25.0 : 23.0,
                                    minSize: 15.0,
                                    maxSize: isVeryTall ? 30.0 : 23.0,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF075DE8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ============================================================
          // RIGHT SIDE - DECORATIVE (only on large screens)
          // ============================================================
          if (isLargeScreen)
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.purple.shade50.withValues(alpha: 0.3),
                      Colors.blue.shade50.withValues(alpha: 0.3),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.forum_outlined,
                    size: 200,
                    color: Colors.purple.shade100.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================================================================
  // WAVES HEIGHT
  // ================================================================

  double _calculateWavesHeight(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return (screenHeight * 0.08).clamp(70.0, 150.0);
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
                  color: Colors.black.withValues(alpha: 0.13),
                  blurRadius: (height * 0.14).clamp(7.0, 18.0),
                  offset: Offset(0, (height * 0.055).clamp(3.0, 8.0)),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = constraints.maxHeight;
                final w = constraints.maxWidth;

                // Responsive internal sizes
                final iconSize = (h * 0.42).clamp(25.0, 58.0);
                final titleSize = (h * 0.18).clamp(14.0, 25.0);
                final subtitleSize = (h * 0.125).clamp(10.0, 17.0);
                final arrowSize = (h * 0.31).clamp(20.0, 43.0);

                // Areas for icon and arrow
                final iconArea = (h * 0.78).clamp(48.0, 105.0);
                final arrowArea = (h * 0.70).clamp(48.0, 90.0);

                // Check if we need to compact the layout for very small buttons
                final isCompact = h < 60 || w < 200;

                if (isCompact) {
                  // Compact layout: icon and text only, no subtitle
                  return Row(
                    children: [
                      SizedBox(
                        width: iconArea,
                        child: Center(
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: iconSize,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
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
                        ),
                      ),
                      SizedBox(
                        width: arrowArea * 0.6,
                        child: Center(
                          child: Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: arrowSize * 0.7,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // Full layout with subtitle
                return Row(
                  children: [
                    // Icon
                    SizedBox(
                      width: iconArea,
                      child: Center(
                        child: Icon(icon, color: Colors.white, size: iconSize),
                      ),
                    ),

                    // Text
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.0),
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

                    // Arrow
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
    // LEFT INNER WAVE    // ================================================================

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
