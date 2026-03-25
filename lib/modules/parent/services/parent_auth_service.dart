import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:parent/modules/parent/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ParentAuthService extends GetxService {
  final SupabaseService _supabase = Get.find<SupabaseService>();
  final _storage = GetStorage();

  // ════════════════════════════════════════════════════════════
  // OBSERVABLE STATE
  // ════════════════════════════════════════════════════════════

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt appEntityId = 0.obs;
  final RxString userType = ''.obs;

  // ════════════════════════════════════════════════════════════
  // GETTERS
  // ════════════════════════════════════════════════════════════

  bool get isAuthenticated =>
      _supabase.isAuthenticated && appEntityId.value != 0;

  User? get currentUser => _supabase.currentUser;

  // ════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ════════════════════════════════════════════════════════════

  @override
  void onInit() {
    super.onInit();
    _restoreFromStorage();
    _listenToAuthChanges();
  }

  // ════════════════════════════════════════════════════════════
  // STORAGE RESTORE
  // ════════════════════════════════════════════════════════════

  void _restoreFromStorage() {
    final savedId = _storage.read<int>('app_entity_id');
    final savedType = _storage.read<String>('user_type');

    if (savedId != null && savedId != 0) {
      appEntityId.value = savedId;
      userType.value = savedType ?? '';
      print('✅ Auth restored from storage: id=$savedId, type=$savedType');
    } else {
      print('ℹ️ No saved auth data found in storage');
    }
  }

  // ════════════════════════════════════════════════════════════
  // AUTH STATE LISTENER
  // ════════════════════════════════════════════════════════════

  void _listenToAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      print('🔐 Auth event: $event');

      switch (event) {
        case AuthChangeEvent.signedIn:
          if (session != null && appEntityId.value == 0) {
            print('🔄 signedIn event — performing sync...');
            final synced = await _performSync();
            // ✅ تجديد الـ JWT بعد الـ sync ليحتوي app_user_id
            if (synced) {
              await Future.delayed(const Duration(milliseconds: 300));
              await Supabase.instance.client.auth.refreshSession();
              print('🔄 JWT refreshed after signedIn sync');
            }
          }
          break;

        case AuthChangeEvent.tokenRefreshed:
          if (session != null && appEntityId.value == 0) {
            print('🔄 tokenRefreshed — recovering sync...');
            await _performSync();
          }
          break;

        case AuthChangeEvent.signedOut:
          print('🚪 signedOut — clearing data');
          _clearLocalData();
          break;

        default:
          break;
      }
    });
  }

  // ════════════════════════════════════════════════════════════
  // SIGN IN
  // ════════════════════════════════════════════════════════════

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // الخطوة 1: المصادقة
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null || response.session == null) {
        errorMessage.value = 'فشل تسجيل الدخول';
        return false;
      }

      print('✅ Auth success for: ${response.user!.email}');

      // الخطوة 2: انتظار ضبط الـ JWT
      await Future.delayed(const Duration(milliseconds: 500));

      // الخطوة 3: sync
      final synced = await _performSync(maxRetries: 3);
      if (!synced) {
        errorMessage.value =
            'فشل التحقق من حساب ولي الأمر، يرجى المحاولة مرة أخرى';
        await _supabase.auth.signOut();
        return false;
      }

      // ✅ الخطوة 4: تجديد الـ JWT ليحتوي app_user_id الجديد
      // ضروري لأن الـ JWT صدر قبل إنشاء app_user
      print('🔄 Refreshing JWT to inject app_user_id...');
      await Supabase.instance.client.auth.refreshSession();
      await Future.delayed(const Duration(milliseconds: 500));
      print('✅ JWT refreshed with app_user_id=${appEntityId.value}');

      // الخطوة 5: التحقق من نوع المستخدم
      if (userType.value != 'parent') {
        errorMessage.value = 'هذا الحساب ليس حساب ولي أمر';
        print('⛔ Wrong user type: ${userType.value}');
        await signOut();
        return false;
      }

      print(
        '✅ Login complete: id=${appEntityId.value}, type=${userType.value}',
      );
      return true;
    } on AuthException catch (e) {
      errorMessage.value = _mapAuthError(e.message);
      print('❌ AuthException: ${e.message}');
      return false;
    } on PostgrestException catch (e) {
      errorMessage.value = 'خطأ في قاعدة البيانات';
      print('❌ PostgrestException: ${e.message}');
      return false;
    } catch (e) {
      errorMessage.value = 'حدث خطأ غير متوقع';
      print('❌ Unexpected error in signIn: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // SIGN OUT
  // ════════════════════════════════════════════════════════════

  Future<void> signOut() async {
    try {
      isLoading.value = true;
      await _supabase.auth.signOut();
    } catch (e) {
      print('❌ Error during sign out: $e');
      _clearLocalData();
    } finally {
      isLoading.value = false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // SYNC APP USER
  // ════════════════════════════════════════════════════════════

  Future<bool> _performSync({int maxRetries = 2}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('🔄 Sync attempt $attempt/$maxRetries...');

        final session = Supabase.instance.client.auth.currentSession;

        if (session == null) {
          print('⚠️ No session on attempt $attempt');
          if (attempt < maxRetries) {
            await Future.delayed(Duration(milliseconds: 400 * attempt));
            continue;
          }
          return false;
        }

        if (session.isExpired) {
          print('⚠️ Session expired — refreshing token...');
          await Supabase.instance.client.auth.refreshSession();
          await Future.delayed(const Duration(milliseconds: 300));
        }

        final syncResult = await _supabase.syncAppUser();

        if (syncResult != null) {
          final id = syncResult['app_entity_id'];
          final type = syncResult['user_type'];

          if (id == null || type == null) {
            print('⚠️ syncResult missing fields: $syncResult');
            continue;
          }

          appEntityId.value = id as int;
          userType.value = type as String;

          await _storage.write('app_entity_id', appEntityId.value);
          await _storage.write('user_type', userType.value);

          print(
            '✅ Sync success: id=${appEntityId.value}, type=${userType.value}',
          );
          return true;
        }

        print('⚠️ syncResult is null on attempt $attempt');
      } catch (e) {
        print('❌ Sync attempt $attempt failed: $e');
      }

      if (attempt < maxRetries) {
        final delay = Duration(milliseconds: 500 * attempt);
        print('⏳ Retrying in ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
      }
    }

    print('❌ All $maxRetries sync attempts failed');
    return false;
  }

  // ════════════════════════════════════════════════════════════
  // LOCAL DATA MANAGEMENT
  // ════════════════════════════════════════════════════════════

  void _clearLocalData() {
    appEntityId.value = 0;
    userType.value = '';
    errorMessage.value = '';
    _storage.remove('app_entity_id');
    _storage.remove('user_type');
    print('🧹 Local auth data cleared');
  }

  // ════════════════════════════════════════════════════════════
  // SESSION MANAGEMENT
  // ════════════════════════════════════════════════════════════

  Future<bool> refreshSession() async {
    try {
      final result = await Supabase.instance.client.auth.refreshSession();
      if (result.session != null) {
        print('✅ Session refreshed successfully');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error refreshing session: $e');
      return false;
    }
  }

  Future<bool> syncAppUserOnStartup() async {
    try {
      print('🔄 Startup sync initiated...');

      if (!hasValidSession) {
        print('⚠️ No valid session for startup sync');
        return false;
      }

      final synced = await _performSync(maxRetries: 2);

      if (synced) {
        if (userType.value == 'parent') {
          // ✅ تجديد الـ JWT عند بدء التطبيق أيضاً
          await Supabase.instance.client.auth.refreshSession();
          print('✅ Startup sync successful - user is parent');
          return true;
        } else {
          print('⛔ Startup sync failed - wrong user type: ${userType.value}');
          await signOut();
          return false;
        }
      }

      print('❌ Startup sync failed');
      return false;
    } catch (e) {
      print('❌ Error in startup sync: $e');
      return false;
    }
  }

  bool get hasValidSession {
    final session = Supabase.instance.client.auth.currentSession;
    return session != null && !session.isExpired;
  }

  // ════════════════════════════════════════════════════════════
  // DEBUG TOOL
  // ════════════════════════════════════════════════════════════

  void debugState() {
    final session = Supabase.instance.client.auth.currentSession;
    print('════════════ AUTH DEBUG ════════════');
    print('isAuthenticated : $isAuthenticated');
    print('currentUser     : ${currentUser?.id ?? "NULL ❌"}');
    print('currentEmail    : ${currentUser?.email ?? "NULL ❌"}');
    print('session exists  : ${session != null ? "YES ✅" : "NO ❌"}');
    print('session expired : ${session?.isExpired ?? "N/A"}');
    print('hasValidSession : $hasValidSession');
    print(
      'appEntityId     : ${appEntityId.value == 0 ? "0 ❌" : "${appEntityId.value} ✅"}',
    );
    print(
      'userType        : ${userType.value.isEmpty ? "EMPTY ❌" : "${userType.value} ✅"}',
    );
    print('storage id      : ${_storage.read('app_entity_id') ?? "NULL ❌"}');
    print('storage type    : ${_storage.read('user_type') ?? "NULL ❌"}');
    print('isLoading       : ${isLoading.value}');
    print(
      'errorMessage    : ${errorMessage.value.isEmpty ? "none" : errorMessage.value}',
    );
    print('════════════════════════════════════');
  }

  // ════════════════════════════════════════════════════════════
  // ERROR MAPPING
  // ════════════════════════════════════════════════════════════

  String _mapAuthError(String message) {
    final msg = message.toLowerCase();

    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid email or password')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    }
    if (msg.contains('user not found')) {
      return 'لا يوجد حساب بهذا البريد الإلكتروني';
    }
    if (msg.contains('email not confirmed')) {
      return 'يرجى تأكيد بريدك الإلكتروني أولاً';
    }
    if (msg.contains('too many requests')) {
      return 'محاولات كثيرة، يرجى الانتظار قليلاً والمحاولة مرة أخرى';
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return 'تعذر الاتصال، يرجى التحقق من الإنترنت';
    }
    if (msg.contains('email already in use') ||
        msg.contains('user already registered')) {
      return 'البريد الإلكتروني مستخدم بالفعل';
    }

    return message;
  }
}
