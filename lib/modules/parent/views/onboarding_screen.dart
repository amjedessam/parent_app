import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:parent/routes/app_routes.dart';

class _Constants {
  // Animation Durations
  static const transitionDuration = Duration(milliseconds: 700);
  static const pageChangeDuration = Duration(milliseconds: 300);
  static const backgroundChangeDuration = Duration(milliseconds: 500);
  static const floatDuration = Duration(seconds: 3);
  static const particleDuration = Duration(seconds: 8);

  // Animation Values
  static const double cardSlideOffset = 80.0;
  static const double cardInitialScale = 0.92;

  // Icon
  static const double iconSize = 140.0;
  static const double iconBorderRadius = 32.0;
  static const double emojiFontSize = 70.0; // محسّن من 120
  static const double iconFloatRange = 8.0;
  static const double iconRotateRange = 0.03;

  // Chip
  static const double chipFloatRange = 6.0;
  static const double chipBorderRadius = 20.0;

  // Card
  static const double cardBorderRadius = 36.0;
  static const double handleWidth = 40.0;
  static const double handleHeight = 4.0;
  static const double buttonHeight = 56.0;
  static const double buttonBorderRadius = 16.0;

  // Particles
  static const int particleCount = 15; // محسّن من 20
  static const double particleOpacity = 0.07;
}

// ══════════════════════════════════════════════════════════════════
//  THEME
// ══════════════════════════════════════════════════════════════════

class _Theme {
  static const titleColor = Color(0xFF0D1B2A);
  static const descriptionColor = Color(0xFF546E7A);
  static const handleColor = Color(0xFFE0E7EF);

  static const titleStyle = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: titleColor,
    height: 1.2,
  );

  static const descriptionStyle = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 14,
    color: descriptionColor,
    height: 1.65,
    fontWeight: FontWeight.w400,
  );

  static const buttonTextStyle = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: 0.3,
  );

  static const skipButtonStyle = TextStyle(
    fontFamily: 'Cairo',
    color: Colors.white,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const chipTextStyle = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );
}

// ══════════════════════════════════════════════════════════════════
//  PAGE MODEL
// ══════════════════════════════════════════════════════════════════

class _PageModel {
  final String imagePath; // مسار الصورة بدل الـ emoji
  final String title;
  final String subtitle;
  final String description;
  final List<Color> gradient;
  final Color chipColor;

  const _PageModel({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.gradient,
    required this.chipColor,
  });
}

// ══════════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ══════════════════════════════════════════════════════════════════

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int _page = 0;
  final _pageCtrl = PageController();

  // ── محسّن: 3 Controllers بدلاً من 5 ───────────────────────────
  late AnimationController _transitionCtrl; // card transition
  late AnimationController _floatCtrl; // floating elements
  late AnimationController _particleCtrl; // particles

  // ── Animations ─────────────────────────────────────────────────
  late Animation<double> _cardSlide;
  late Animation<double> _cardFade;
  late Animation<double> _cardScale;

  // ── الصفحات ───────────────────────────────────────────────────
  static const _pages = [
    _PageModel(
      imagePath: 'assets/images/onboarding_1.png',
      title: 'تابع أداء طفلك',
      subtitle: 'لحظة بلحظة',
      description:
          'احصل على تقارير مفصّلة عن درجات طفلك في جميع المواد، وراقب تطوره التعليمي بدقة عالية.',

      gradient: [Color(0xFF1565C0), Color(0xFF1E88E5)],
      chipColor: Color(0xFF1E88E5),
    ),
    _PageModel(
      imagePath: 'assets/images/onboarding_2.png',
      title: 'حضور وغياب',
      subtitle: 'في كل وقت',
      description:
          'إشعارات فورية عند تسجيل غياب طفلك، مع سجل شهري تفصيلي لجميع أيام الدراسة.',

      gradient: [Color(0xFF0D47A1), Color(0xFF1976D2)],
      chipColor: Color(0xFF1976D2),
    ),
    _PageModel(
      imagePath: 'assets/images/onboarding_3.png',
      title: 'تواصل مباشر',
      subtitle: 'مع المدرسة',
      description:
          'راسل إدارة المدرسة مباشرة واستقبل تقارير يومية عن سلوك طفلك ومشاركته في الفصل.',

      gradient: [Color(0xFF1976D2), Color(0xFF2196F3)],
      chipColor: Color(0xFF2196F3),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupSystemUI();
    _initAnimations();
    _transitionCtrl.forward();
  }

  void _setupSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _initAnimations() {
    // ── Card Transition (محسّن: دمج slide + fade + scale) ───────
    _transitionCtrl = AnimationController(
      vsync: this,
      duration: _Constants.transitionDuration,
    );

    _cardSlide = Tween(begin: _Constants.cardSlideOffset, end: 0.0).animate(
      CurvedAnimation(parent: _transitionCtrl, curve: Curves.easeOutQuart),
    );

    _cardFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _transitionCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _cardScale = Tween(begin: _Constants.cardInitialScale, end: 1.0).animate(
      CurvedAnimation(parent: _transitionCtrl, curve: Curves.easeOutQuart),
    );

    // ── Floating Elements ──────────────────────────────────────
    _floatCtrl = AnimationController(
      vsync: this,
      duration: _Constants.floatDuration,
    )..repeat(reverse: true);

    // ── Particles ──────────────────────────────────────────────
    _particleCtrl = AnimationController(
      vsync: this,
      duration: _Constants.particleDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _transitionCtrl.dispose();
    _floatCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  // ── Navigation (محسّن: مع Haptic feedback) ────────────────────
  void _next() {
    HapticFeedback.lightImpact(); // ✅ جديد

    if (_page < _pages.length - 1) {
      _transitionCtrl.reverse().then((_) {
        _pageCtrl.nextPage(
          duration: _Constants.pageChangeDuration,
          curve: Curves.easeInOut,
        );
      });
    } else {
      _finishOnboarding();
    }
  }

  void _skip() {
    HapticFeedback.mediumImpact(); // ✅ جديد
    _finishOnboarding();
  }

  void _finishOnboarding() {
    GetStorage().write('has_seen_onboarding', true);
    Get.offAllNamed(AppRoutes.PARENT_LOGIN);
  }

  void _onPageChanged(int p) {
    setState(() => _page = p);
    _transitionCtrl.forward(from: 0);
    HapticFeedback.selectionClick(); // ✅ جديد
  }

  // ── Jump to page (✅ جديد: للنقاط التفاعلية) ────────────────
  void _jumpToPage(int index) {
    if (index == _page) return;
    HapticFeedback.lightImpact();

    _transitionCtrl.reverse().then((_) {
      _pageCtrl.animateToPage(
        index,
        duration: _Constants.pageChangeDuration,
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final page = _pages[_page];

    return Scaffold(
      body: GestureDetector(
        // ✅ جديد: Swipe Support
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < -500 && _page < _pages.length - 1) {
            _next();
          } else if (details.primaryVelocity! > 500 && _page > 0) {
            _transitionCtrl.reverse().then((_) {
              _pageCtrl.previousPage(
                duration: _Constants.pageChangeDuration,
                curve: Curves.easeInOut,
              );
            });
          }
        },
        child: AnimatedContainer(
          duration: _Constants.backgroundChangeDuration,
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: page.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // ── Particles (محسّن: مع RepaintBoundary) ──────────
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _particleCtrl,
                    builder: (_, __) => CustomPaint(
                      painter: _ParticlePainter(_particleCtrl.value),
                    ),
                  ),
                ),
              ),

              // ── Decorative Circles ─────────────────────────────
              _buildDecorativeCircles(size),

              // ── Skip Button ────────────────────────────────────
              _buildSkipButton(context),

              // ── Main Content ───────────────────────────────────
              Positioned.fill(
                child: PageView.builder(
                  controller: _pageCtrl,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (_, i) => _buildPageContent(_pages[i], size),
                ),
              ),

              // ── Bottom Card ────────────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _transitionCtrl,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _cardSlide.value),
                    child: FadeTransition(
                      opacity: _cardFade,
                      child: ScaleTransition(
                        scale: _cardScale,
                        alignment: Alignment.bottomCenter,
                        child: _buildCard(page, size, context),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Skip Button (محسّن: مع Semantics) ──────────────────────────
  Widget _buildSkipButton(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 20,
      child: Semantics(
        label: 'تخطي مقدمة التطبيق',
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _skip,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Decorative Circles ─────────────────────────────────────────
  Widget _buildDecorativeCircles(Size size) {
    return Stack(
      children: [
        Positioned(
          top: -size.height * 0.08,
          right: -size.width * 0.15,
          child: Container(
            width: size.width * 0.5,
            height: size.width * 0.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
        ),
        Positioned(
          bottom: size.height * 0.35,
          left: -size.width * 0.25,
          child: Container(
            width: size.width * 0.6,
            height: size.width * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),
        Positioned(
          top: size.height * 0.25,
          left: size.width * 0.1,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.12),
            ),
          ),
        ),
      ],
    );
  }

  // ── Page Content (محسّن: مع Semantics) ─────────────────────────
  Widget _buildPageContent(_PageModel page, Size size) {
    return Column(
      children: [
        SizedBox(height: size.height * 0.10),

        // ── Icon (محسّن: حجم أصغر + Semantics) ───────────────
        Semantics(
          label: '${page.title} - رمز توضيحي',
          image: true,
          child: AnimatedBuilder(
            animation: _floatCtrl,
            builder: (_, __) {
              final floatOffset =
                  math.sin(_floatCtrl.value * math.pi) *
                  _Constants.iconFloatRange;
              final rotateAngle =
                  math.sin(_floatCtrl.value * math.pi) *
                  _Constants.iconRotateRange;

              return Transform.translate(
                offset: Offset(0, floatOffset),
                child: Transform.rotate(
                  angle: rotateAngle,
                  child: Image.asset(
                    page.imagePath,
                    width: _Constants.iconSize * 1.6,
                    height: _Constants.iconSize * 1.6,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_outlined,
                      color: Colors.white54,
                      size: 80,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Bottom Card (محسّن: مع Semantics) ──────────────────────────
  Widget _buildCard(_PageModel page, Size size, BuildContext context) {
    final isLast = _page == _pages.length - 1;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Semantics(
      container: true,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(_Constants.cardBorderRadius),
            topRight: Radius.circular(_Constants.cardBorderRadius),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x25000000),
              blurRadius: 40,
              offset: Offset(0, -8),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(28, 28, 28, bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ── Handle ─────────────────────────────────────────
            Center(
              child: Container(
                width: _Constants.handleWidth,
                height: _Constants.handleHeight,
                decoration: BoxDecoration(
                  color: _Theme.handleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // ── Page Dots (✅ محسّن: تفاعلية) ──────────────────
            Semantics(
              label: 'مؤشر الصفحة: ${_page + 1} من ${_pages.length}',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: List.generate(_pages.length, (i) {
                  final isActive = i == _page;
                  return GestureDetector(
                    onTap: () => _jumpToPage(i), // ✅ جديد: clickable
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOutCubic,
                      margin: const EdgeInsets.only(left: 6),
                      width: isActive ? 32.0 : 8.0,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? page.chipColor
                            : page.chipColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 18),

            // ── Title (محسّن: مع Semantics) ────────────────────
            Semantics(
              header: true,
              label: '${page.title} ${page.subtitle}',
              child: RichText(
                textAlign: TextAlign.right,
                text: TextSpan(
                  children: [
                    TextSpan(text: '${page.title}\n', style: _Theme.titleStyle),
                    TextSpan(
                      text: page.subtitle,
                      style: _Theme.titleStyle.copyWith(color: page.chipColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Description (محسّن: مع Semantics) ──────────────
            Semantics(
              label: page.description,
              child: Text(
                page.description,
                textAlign: TextAlign.right,
                style: _Theme.descriptionStyle,
              ),
            ),
            const SizedBox(height: 24),

            // ── Action Button (محسّن: مع Semantics) ────────────
            Semantics(
              button: true,
              label: isLast
                  ? 'ابدأ استخدام التطبيق'
                  : 'الانتقال للصفحة التالية',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _next,
                  borderRadius: BorderRadius.circular(
                    _Constants.buttonBorderRadius,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    height: _Constants.buttonHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: page.gradient,
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      ),
                      borderRadius: BorderRadius.circular(
                        _Constants.buttonBorderRadius,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: page.chipColor.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        isLast ? 'ابدأ الآن' : 'التالي',
                        style: _Theme.buttonTextStyle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  PARTICLE PAINTER (محسّن للأداء)
// ══════════════════════════════════════════════════════════════════

class _ParticlePainter extends CustomPainter {
  final double progress;
  static final List<_Particle> _cachedParticles = _generateParticles();

  _ParticlePainter(this.progress);

  static List<_Particle> _generateParticles() {
    final rng = math.Random(99);
    final particles = <_Particle>[];

    for (int i = 0; i < _Constants.particleCount; i++) {
      particles.add(
        _Particle(
          x: rng.nextDouble(),
          baseY: rng.nextDouble() * 0.65,
          speed: 0.2 + rng.nextDouble() * 0.3,
          radius: 2.0 + rng.nextDouble() * 3,
        ),
      );
    }

    return particles;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(_Constants.particleOpacity)
      ..style = PaintingStyle.fill;

    for (final particle in _cachedParticles) {
      final x = particle.x * size.width;
      final y =
          particle.baseY -
          ((progress * particle.speed * 80) % (size.height * 0.65 + 20));

      canvas.drawCircle(Offset(x, y), particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double x;
  final double baseY;
  final double speed;
  final double radius;

  const _Particle({
    required this.x,
    required this.baseY,
    required this.speed,
    required this.radius,
  });
}
