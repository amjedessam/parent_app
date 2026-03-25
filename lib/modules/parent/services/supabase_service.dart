import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService extends GetxService {
  static SupabaseService get to => Get.find<SupabaseService>();

  late final SupabaseClient _client;

  // ════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ════════════════════════════════════════════════════════════

  @override
  void onInit() {
    super.onInit();
    _client = Supabase.instance.client;
    print('✅ SupabaseService initialized');
  }

  // ════════════════════════════════════════════════════════════
  // CLIENT ACCESS
  // ════════════════════════════════════════════════════════════

  /// الـ Supabase client الرئيسي
  SupabaseClient get client => _client;

  /// الـ Auth client
  GoTrueClient get auth => _client.auth;

  // ════════════════════════════════════════════════════════════
  // AUTH STATE
  // ════════════════════════════════════════════════════════════

  /// المستخدم الحالي — null إذا لم يكن مسجلاً
  User? get currentUser => _client.auth.currentUser;

  /// هل هناك مستخدم مسجل الدخول
  bool get isAuthenticated => currentUser != null;

  /// UUID المستخدم الحالي
  String? get currentUserId => currentUser?.id;

  /// الـ session الحالية
  Session? get currentSession => _client.auth.currentSession;

  /// هل الـ session صالحة وغير منتهية
  bool get hasValidSession {
    final session = currentSession;
    return session != null && !session.isExpired;
  }

  /// Stream لمراقبة تغيرات الـ Auth State
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ════════════════════════════════════════════════════════════
  // DATABASE
  // ════════════════════════════════════════════════════════════

  /// الوصول لجدول معين
  SupabaseQueryBuilder from(String table) => _client.from(table);

  /// تنفيذ RPC — Stored Procedure أو Function في PostgreSQL
  Future<dynamic> rpc(String function, {Map<String, dynamic>? params}) async {
    try {
      final response = await _client.rpc(function, params: params);
      return response;
    } catch (e) {
      print('❌ RPC Error [$function]: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // REALTIME
  // ════════════════════════════════════════════════════════════

  /// الاشتراك في تغييرات جدول معين (Realtime stream)
  SupabaseStreamBuilder stream(String table, {String primaryKey = 'id'}) =>
      _client.from(table).stream(primaryKey: [primaryKey]);

  // ════════════════════════════════════════════════════════════
  // STORAGE
  // ════════════════════════════════════════════════════════════

  /// الوصول لـ Supabase Storage bucket معين
  SupabaseStorageClient get storage => _client.storage;

  // ════════════════════════════════════════════════════════════
  // EDGE FUNCTIONS
  // ════════════════════════════════════════════════════════════

  /// استدعاء Edge Function عام مع معالجة الأخطاء
  Future<Map<String, dynamic>?> invokeFunction(
    String functionName, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _client.functions.invoke(functionName, body: body);

      if (response.status == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }

      print(
        '⚠️ Function [$functionName] returned status: ${response.status}, '
        'data: ${response.data}',
      );
      return null;
    } on FunctionException catch (e) {
      print(
        '❌ FunctionException [$functionName]: '
        'status=${e.status}, details=${e.details}',
      );
      rethrow;
    } catch (e) {
      print('❌ Error invoking function [$functionName]: $e');
      rethrow;
    }
  }

  /// استدعاء Edge Function: sync-app-user
  ///
  /// يربط Supabase Auth user بـ app_user في قاعدة البيانات
  /// ويُرجع: { app_entity_id: int, user_type: String }
  ///
  /// الشرط: يجب أن تكون الـ session نشطة قبل الاستدعاء
  Future<Map<String, dynamic>?> syncAppUser() async {
    try {
      // تحقق من وجود session صالحة قبل الاستدعاء
      if (!hasValidSession) {
        print('⚠️ syncAppUser called without valid session — skipping');
        return null;
      }

      // ✅ أرسل الـ JWT يدوياً — لا تعتمد على الـ SDK
      final accessToken = _client.auth.currentSession!.accessToken;
      print('🔑 Token preview: ${accessToken.substring(0, 30)}...');

      final response = await _client.functions.invoke(
        'sync-app-user',
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.status == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        // التحقق من وجود الحقول المطلوبة
        if (data['app_entity_id'] == null || data['user_type'] == null) {
          print('⚠️ sync-app-user response missing required fields: $data');
          return null;
        }

        print(
          '✅ sync-app-user success: '
          'app_entity_id=${data['app_entity_id']}, '
          'user_type=${data['user_type']}',
        );
        return data;
      }

      print(
        '⚠️ sync-app-user unexpected response: '
        'status=${response.status}, data=${response.data}',
      );
      return null;
    } on FunctionException catch (e) {
      print(
        '❌ sync-app-user FunctionException: '
        'status=${e.status}, details=${e.details}',
      );
      // نُعيد الـ exception ليتعامل معها _performSync بالـ retry
      rethrow;
    } catch (e) {
      print('❌ sync-app-user unexpected error: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // SESSION HELPERS
  // ════════════════════════════════════════════════════════════

  /// تجديد الـ session يدوياً
  Future<bool> refreshSession() async {
    try {
      final result = await _client.auth.refreshSession();
      if (result.session != null) {
        print('✅ Session refreshed');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error refreshing session: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // DEBUG
  // ════════════════════════════════════════════════════════════

  /// طباعة حالة الـ Supabase للتشخيص
  void debugState() {
    print('════════ SUPABASE SERVICE DEBUG ════════');
    print('isAuthenticated : $isAuthenticated');
    print('currentUserId   : ${currentUserId ?? "NULL ❌"}');
    print('currentEmail    : ${currentUser?.email ?? "NULL ❌"}');
    print('session exists  : ${currentSession != null ? "YES ✅" : "NO ❌"}');
    print('session expired : ${currentSession?.isExpired ?? "N/A"}');
    print('hasValidSession : $hasValidSession');
    print('════════════════════════════════════════');
  }
}
