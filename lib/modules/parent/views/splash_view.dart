import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:parent/modules/parent/services/parent_auth_service.dart';
import 'package:parent/routes/app_routes.dart';
import 'package:parent/theme/parent_app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// صفحة Splash للتحقق من حالة المصادقة عند بدء التطبيق
class SplashView extends StatefulWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  final _storage = GetStorage();

  // ── Animation Controllers ───────────────────────────────────
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _pulseController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // ── Logo animation ──────────────────────────────────────
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    // ── Text animation ──────────────────────────────────────
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // ── Pulse animation للدوائر الخلفية ────────────────────
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // ── تشغيل الـ animations بالتتابع ──────────────────────
    _logoController.forward().then((_) {
      _textController.forward();
    });

    print('🚀 SplashView initState called');
    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    print('🔍 Starting auth check...');
    await Future.delayed(const Duration(seconds: 2));
    print('⏱️ Splash delay completed');

    try {
      print('🔍 Waiting for session restoration...');
      Session? session = await _awaitSessionRestore();

      print('🔍 Session restore result:');
      print('   Session exists: ${session != null}');
      print('   Session expired: ${session?.isExpired ?? true}');

      if (session != null && session.isExpired) {
        print('🔄 Access token expired — attempting refresh...');
        session = await _tryRefreshSession();
        print(
          '   Refresh result: ${session != null ? "✅ Success" : "❌ Failed"}',
        );
      }

      final savedEntityId = _storage.read<int>('app_entity_id');
      final savedUserType = _storage.read<String>('user_type');

      // ── تحقق من Onboarding ─────────────────────────────
      final hasSeenOnboarding =
          _storage.read<bool>('has_seen_onboarding') ?? false;

      print('🔍 Splash Check:');
      print('   Active session: ${session != null && !session.isExpired}');
      print('   Saved entityId: $savedEntityId');
      print('   Saved userType: $savedUserType');
      print('   Seen onboarding: $hasSeenOnboarding');

      if (session != null && !session.isExpired) {
        if (savedEntityId != null && savedEntityId != 0) {
          print('🔄 Restoring auth data...');
          final authService = Get.find<ParentAuthService>();
          authService.appEntityId.value = savedEntityId;
          authService.userType.value = savedUserType ?? '';
          print('✅ Auto-login success: entityId=$savedEntityId');
          print('🚀 Navigating to MAIN_NAVIGATION...');
          Get.offAllNamed(AppRoutes.PARENT_MAIN_NAVIGATION);
          return;
        } else {
          print('🔄 Session exists but no saved data - attempting sync...');
          final authService = Get.find<ParentAuthService>();
          final syncResult = await authService.syncAppUserOnStartup();
          if (syncResult) {
            print('✅ Sync successful, navigating to MAIN_NAVIGATION');
            Get.offAllNamed(AppRoutes.PARENT_MAIN_NAVIGATION);
            return;
          }
        }
      }

      // ── لا يوجد جلسة — هل شاهد الـ Onboarding؟ ──────────
      if (!hasSeenOnboarding) {
        print('🎯 First time user — navigating to ONBOARDING');
        Get.offAllNamed(AppRoutes.PARENT_ONBOARDING);
      } else {
        print('🚫 No valid session - redirecting to LOGIN');
        Get.offAllNamed(AppRoutes.PARENT_LOGIN);
      }
    } catch (e, stackTrace) {
      print('❌ Error in splash auth check: $e');
      print('❌ Stack trace: $stackTrace');
      Get.offAllNamed(AppRoutes.PARENT_LOGIN);
    }
  }

  Future<Session?> _awaitSessionRestore() async {
    final existing = Supabase.instance.client.auth.currentSession;
    if (existing != null) {
      print('✅ Session already available');
      return existing;
    }
    try {
      final authState = await Supabase.instance.client.auth.onAuthStateChange
          .firstWhere(
            (state) =>
                state.event == AuthChangeEvent.initialSession ||
                state.event == AuthChangeEvent.signedIn ||
                state.event == AuthChangeEvent.tokenRefreshed,
          )
          .timeout(const Duration(seconds: 5));
      print('✅ Auth event received: ${authState.event}');
      return authState.session;
    } catch (e) {
      print('⚠️ Session restore timeout or error: $e');
      return Supabase.instance.client.auth.currentSession;
    }
  }

  Future<Session?> _tryRefreshSession() async {
    try {
      final response = await Supabase.instance.client.auth.refreshSession();
      if (response.session != null && !response.session!.isExpired) {
        print('✅ Session refreshed successfully');
        return response.session;
      }
      print('⚠️ refreshSession returned null or still expired');
      return null;
    } catch (e) {
      print('❌ Session refresh failed: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    print('🎨 SplashView build called');

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.gradientStart, AppColors.primaryLight],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Stack(
          children: [
            // ── دوائر زخرفية خلفية ───────────────────────────
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Stack(
                children: [
                  Positioned(
                    top: -size.height * 0.08,
                    right: -size.width * 0.15,
                    child: Transform.scale(
                      scale: _pulseAnim.value,
                      child: Container(
                        width: size.width * 0.65,
                        height: size.width * 0.65,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -size.height * 0.05,
                    left: -size.width * 0.2,
                    child: Transform.scale(
                      scale: 2.0 - _pulseAnim.value,
                      child: Container(
                        width: size.width * 0.7,
                        height: size.width * 0.7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: size.height * 0.3,
                    right: -size.width * 0.1,
                    child: Container(
                      width: size.width * 0.35,
                      height: size.width * 0.35,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.04),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── المحتوى المركزي ──────────────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── اللوقو مع animation ────────────────────
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (_, __) => Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // ── هالة خارجية ──────────────────────
                            Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            // ── هالة داخلية ──────────────────────
                            Container(
                              width: 122,
                              height: 122,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            // ── دائرة بيضاء مع الشعار ────────────
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Padding(
                                  padding: const EdgeInsets.all(13),
                                  child: Image.asset(
                                    'assets/images/roshd.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── اسم التطبيق ────────────────────────────
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (_, __) => FadeTransition(
                      opacity: _textOpacity,
                      child: SlideTransition(
                        position: _textSlide,
                        child: Column(
                          children: [
                            const Text(
                              'منصة رُشد',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.family_restroom_rounded,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    'بوابة ولي الأمر',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 64),

                  // ── مؤشر التحميل ───────────────────────────
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (_, __) => Opacity(
                      opacity: _textOpacity.value,
                      child: Column(
                        children: [
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              strokeWidth: 2.5,
                              backgroundColor: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'جاري التحميل...',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Version tag ──────────────────────────────────
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _textController,
                builder: (_, __) => Opacity(
                  opacity: _textOpacity.value * 0.5,
                  child: const Text(
                    'منصة رُشد التعليمية الذكية© 2026',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: Colors.white,
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
