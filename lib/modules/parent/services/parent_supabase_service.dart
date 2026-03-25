import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:parent/modules/parent/models/activity_model.dart';
import 'package:parent/modules/parent/models/attendance_model.dart';
import 'package:parent/modules/parent/models/daily_summary_model.dart';
import 'package:parent/modules/parent/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:parent/modules/parent/models/subject_performance_model.dart';

/// خدمة تحميل بيانات ولي الأمر من Supabase
class ParentSupabaseService extends GetxService {
  final SupabaseService _supabase = Get.find<SupabaseService>();
  final _storage = GetStorage(); // ✅ instance واحدة فقط

  // ════════════════════════════════════════════════════════════
  // AUTH HELPERS — مركزية، لا تكرار
  // ════════════════════════════════════════════════════════════

  /// قراءة parentId من الـ storage مباشرة
  int? get _parentId {
    final value = _storage.read('app_entity_id');
    if (value == null) return null;

    // Handle different types from GetStorage
    if (value is int) return (value != 0) ? value : null;
    if (value is String) {
      final parsed = int.tryParse(value);
      return (parsed != null && parsed != 0) ? parsed : null;
    }
    return null;
  }

  /// جلب parentId بأمان مع recovery تلقائي من قاعدة البيانات
  /// فيها خطأين:

  Future<int?> _getParentIdSafe() async {
    final stored = _parentId;
    if (stored != null) return stored;

    print('⚠️ app_entity_id not in storage — attempting recovery...');

    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) {
      print('❌ No authenticated user');
      return null;
    }

    try {
      final data = await _supabase
          .from('app_user') // ✅ بدون s
          .select('app_entity_id') // ✅ الحقل الصحيح
          .eq('auth_user_id', authUser.id)
          .eq('user_type', 'parent') // ✅ تأكد أنه parent وليس نوع آخر
          .maybeSingle();

      if (data == null) {
        print('❌ No parent record found for auth_user_id: ${authUser.id}');
        return null;
      }

      final recoveredId = data['app_entity_id'] as int; // ✅
      _storage.write('app_entity_id', recoveredId);
      print('✅ parentId recovered and saved: $recoveredId');
      return recoveredId;
    } catch (e) {
      print('❌ Recovery failed: $e');
      return null;
    }
  }

  /// الحصول على parent ID الحالي (للاستخدام الخارجي)
  Future<int?> getCurrentParentId() async {
    return await _getParentIdSafe();
  }

  Future<Map<String, dynamic>?> loadCurrentParent() async {
    try {
      final parentId = await _getParentIdSafe();
      if (parentId == null) return null;

      return await _supabase
          .from('parents')
          .select()
          .eq('id', parentId)
          .maybeSingle();
    } catch (e) {
      print('❌ Error loading parent: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> loadChildren() async {
    try {
      final parentId = await _getParentIdSafe();
      if (parentId == null) return [];

      final response = await _supabase
          .from('parent_students')
          .select('''
          student_id,
          relationship,
          linked_at,
          students (
            id,
            student_code,
            full_name,
            profile_image_url,
            section:sections (
              name,
              grade:grades ( name )
            )
          )
        ''')
          .eq('parent_id', parentId)
          .order('linked_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error loading children: $e');
      return [];
    }
  }

  Future<String?> linkChildByStudentCode(
    int studentCode,
    String relationship,
  ) async {
    try {
      final parentId = await _getParentIdSafe();
      if (parentId == null)
        return 'لم يتم التعرف على حسابك، يرجى إعادة تسجيل الدخول';

      // 1. ابحث عن الطالب
      final studentResult = await _supabase
          .from('students')
          .select('id, full_name')
          .eq('student_code', studentCode)
          .eq('is_active', true)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (studentResult == null) {
        return 'لا يوجد طالب بهذا الكود: $studentCode';
      }

      final studentId = studentResult['id'] as int;

      // 2. تحقق من عدم التكرار
      final existing = await _supabase
          .from('parent_students')
          .select('id')
          .eq('parent_id', parentId)
          .eq('student_id', studentId)
          .maybeSingle();

      if (existing != null) {
        return 'هذا الطالب (${studentResult['full_name']}) مرتبط بحسابك مسبقاً';
      }

      // 3. أضف الربط
      await _supabase.from('parent_students').insert({
        'parent_id': parentId,
        'student_id': studentId,
        'relationship': relationship,
      });

      print('✅ Child linked: studentId=$studentId, parentId=$parentId');
      return null; // null = نجاح
    } on PostgrestException catch (e) {
      print('❌ PostgrestException linking child: ${e.message}');
      return 'خطأ في قاعدة البيانات: ${e.message}';
    } catch (e) {
      print('❌ Error linking child: $e');
      return 'حدث خطأ غير متوقع';
    }
  }

  // ════════════════════════════════════════════════════════════
  // EXAM RESULTS
  // ════════════════════════════════════════════════════════════

  /// تحميل نتائج الاختبارات لطفل معين
  /// تعمل بعد إضافة policy "Parents can view their children exam results"
  Future<List<Map<String, dynamic>>> loadChildExamResults(
    int studentId, {
    int? limit,
    int offset = 0,
  }) async {
    try {
      dynamic query = _supabase
          .from('exam_results')
          .select('*, exams(title, subject_id, subjects(name))')
          .eq('student_id', studentId)
          .eq('status', 'completed')
          .order('submitted_at', ascending: false);

      if (limit != null) {
        query = query.range(offset, offset + limit - 1);
      }

      return List<Map<String, dynamic>>.from(await query);
    } catch (e) {
      print('❌ Error loading exam results: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════
  // ATTENDANCE (RAW)
  // ════════════════════════════════════════════════════════════

  /// تحميل الحضور الخام لطفل معين
  Future<List<Map<String, dynamic>>> loadChildAttendance(
    int studentId, {
    DateTime? month,
  }) async {
    try {
      dynamic query = _supabase
          .from('attendance')
          .select()
          .eq('student_id', studentId);

      if (month != null) {
        final startOfMonth = DateTime(month.year, month.month, 1);
        final endOfMonth = DateTime(month.year, month.month + 1, 0);
        query = query
            .gte('attendance_date', startOfMonth.toIso8601String())
            .lte('attendance_date', endOfMonth.toIso8601String());
      }

      query = query.order('attendance_date', ascending: false);

      return List<Map<String, dynamic>>.from(await query);
    } catch (e) {
      print('❌ Error loading attendance: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════
  // DAILY SUMMARIES (RAW)
  // ════════════════════════════════════════════════════════════

  /// تحميل الملخصات اليومية الخام لطفل معين
  Future<List<Map<String, dynamic>>> loadDailySummaries(
    int studentId, {
    DateTime? date,
    int? limit,
    int offset = 0,
  }) async {
    try {
      dynamic query = _supabase
          .from('daily_summaries')
          .select()
          .eq('student_id', studentId)
          .order('summary_date', ascending: false);

      if (date != null) {
        query = query.eq('summary_date', date.toIso8601String().split('T')[0]);
      }

      if (limit != null) {
        query = query.range(offset, offset + limit - 1);
      }

      return List<Map<String, dynamic>>.from(await query);
    } catch (e) {
      print('❌ Error loading daily summaries: $e');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════
  // ACTIVITIES (RAW)
  // ════════════════════════════════════════════════════════════

  /// تحميل الأنشطة الخام لطفل معين
  Future<List<Map<String, dynamic>>> loadActivities(
    int studentId, {
    int? limit,
    int offset = 0,
  }) async {
    try {
      dynamic query = _supabase
          .from('activities')
          .select('*, subjects(name)')
          .eq('student_id', studentId)
          .order('due_date', ascending: false);

      if (limit != null) {
        query = query.range(offset, offset + limit - 1);
      }

      return List<Map<String, dynamic>>.from(await query);
    } catch (e) {
      print('❌ Error loading activities: $e');
      return [];
    }
  }

  /// تحديث حالة النشاط (مثلاً من pending إلى completed)
  Future<void> updateActivityStatus(int activityId, String status) async {
    try {
      await _supabase
          .from('activities')
          .update({'status': status})
          .eq('id', activityId);
      print('✅ Activity $activityId status updated to $status');
    } catch (e) {
      print('❌ Error updating activity status: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // MESSAGES — Parent ↔ Admin (تم التعديل من Parent ↔ Teacher)
  // ════════════════════════════════════════════════════════════

  /// تحميل الرسائل بين ولي الأمر والإدارة
  Future<List<Map<String, dynamic>>> loadMessages({
    int? adminId,
    int? limit,
    int offset = 0,
  }) async {
    try {
      final parentId = await _getParentIdSafe();
      print(
        '🔍 loadMessages() — parentId=$parentId (${parentId?.runtimeType}), adminId=$adminId (${adminId?.runtimeType})',
      );

      if (parentId == null) {
        print('❌ parentId is null, returning empty list');
        return [];
      }

      // التحقق من أن parentId صالح
      if (parentId <= 0) {
        print('❌ parentId is invalid: $parentId');
        return [];
      }

      // التحقق من adminId
      if (adminId != null && adminId <= 0) {
        print('❌ adminId is invalid: $adminId');
        return [];
      }

      // إذا لم يتم تحديد adminId، نجلب جميع الرسائل المتعلقة بالـ parent
      if (adminId == null) {
        print('🔎 Getting all messages for parent: $parentId');

        // استخدام استعلامين منفصلين ودمج النتائج
        print('📤 Query 1: sender_parent_id=$parentId');
        List<dynamic> sentMessages;
        try {
          sentMessages = await _supabase
              .from('messages')
              .select(
                '*, '
                'sender_admin:admins!sender_admin_id(id, full_name), '
                'recipient_admin:admins!recipient_admin_id(id, full_name)',
              )
              .eq('sender_parent_id', parentId)
              .order('sent_at', ascending: false);
          print('✅ Sent messages query done: ${sentMessages.length}');
        } catch (e) {
          print('❌ Query 1 failed: $e');
          sentMessages = [];
        }

        print('📥 Query 2: recipient_parent_id=$parentId');
        List<dynamic> receivedMessages;
        try {
          receivedMessages = await _supabase
              .from('messages')
              .select(
                '*, '
                'sender_admin:admins!sender_admin_id(id, full_name), '
                'recipient_admin:admins!recipient_admin_id(id, full_name)',
              )
              .eq('recipient_parent_id', parentId)
              .order('sent_at', ascending: false);
          print('✅ Received messages query done: ${receivedMessages.length}');
        } catch (e) {
          print('❌ Query 2 failed: $e');
          receivedMessages = [];
        }

        final allResults = [
          ...List<Map<String, dynamic>>.from(sentMessages),
          ...List<Map<String, dynamic>>.from(receivedMessages),
        ];

        // إزالة التكرار وترتيب حسب التاريخ
        final uniqueMessages = <String, Map<String, dynamic>>{};
        for (final msg in allResults) {
          final id = msg['id']?.toString();
          if (id != null) {
            uniqueMessages[id] = msg;
          }
        }

        final sortedMessages = uniqueMessages.values.toList()
          ..sort((a, b) {
            final aTime =
                DateTime.tryParse(a['sent_at'] ?? '') ?? DateTime(1970);
            final bTime =
                DateTime.tryParse(b['sent_at'] ?? '') ?? DateTime(1970);
            return bTime.compareTo(aTime);
          });

        print('✅ All messages loaded: ${sortedMessages.length}');

        if (limit != null) {
          return sortedMessages.take(limit).toList();
        }
        return sortedMessages;
      }

      // إذا تم تحديد adminId، نجلب الرسائل بين هذا الـ parent والـ admin المحدد
      print('🔎 Getting messages between parent=$parentId and admin=$adminId');

      // جلب الرسائل المرسلة من parent إلى admin
      print(
        '📤 Query 3: sender_parent_id=$parentId, recipient_admin_id=$adminId',
      );
      List<dynamic> outgoing;
      try {
        outgoing = await _supabase
            .from('messages')
            .select(
              '*, '
              'sender_admin:admins!sender_admin_id(id, full_name), '
              'recipient_admin:admins!recipient_admin_id(id, full_name)',
            )
            .eq('sender_parent_id', parentId)
            .eq('recipient_admin_id', adminId)
            .order('sent_at', ascending: false);
        print('✅ Outgoing query done: ${outgoing.length}');
      } catch (e) {
        print('❌ Query 3 failed: $e');
        outgoing = [];
      }

      // جلب الرسائل الواردة من admin إلى parent
      print(
        '📥 Query 4: sender_admin_id=$adminId, recipient_parent_id=$parentId',
      );
      List<dynamic> incoming;
      try {
        incoming = await _supabase
            .from('messages')
            .select(
              '*, '
              'sender_admin:admins!sender_admin_id(id, full_name), '
              'recipient_admin:admins!recipient_admin_id(id, full_name)',
            )
            .eq('sender_admin_id', adminId)
            .eq('recipient_parent_id', parentId)
            .order('sent_at', ascending: false);
        print('✅ Incoming query done: ${incoming.length}');
      } catch (e) {
        print('❌ Query 4 failed: $e');
        incoming = [];
      }

      final outgoingList = List<Map<String, dynamic>>.from(outgoing);
      final incomingList = List<Map<String, dynamic>>.from(incoming);

      print('✅ Outgoing messages: ${outgoingList.length}');
      print('✅ Incoming messages: ${incomingList.length}');

      // دمج وترتيب
      final allMessages = [...outgoingList, ...incomingList];
      allMessages.sort((a, b) {
        final aTime = DateTime.tryParse(a['sent_at'] ?? '') ?? DateTime(1970);
        final bTime = DateTime.tryParse(b['sent_at'] ?? '') ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      if (limit != null) {
        return allMessages.take(limit).toList();
      }

      return allMessages;
    } catch (e, stackTrace) {
      print('❌ Error loading messages: $e');
      print('📊 Stack trace: $stackTrace');
      return [];
    }
  }

  /// إرسال رسالة إلى الإدارة
  Future<bool> sendMessage({
    required int adminId,
    required String subject,
    required String content,
  }) async {
    try {
      final parentId = await _getParentIdSafe();
      if (parentId == null) return false;

      await _supabase.from('messages').insert({
        'sender_parent_id': parentId,
        'recipient_admin_id': adminId,
        'subject': subject,
        'message_text': content,
        'is_read': false,
      });

      return true;
    } catch (e) {
      print('❌ Error sending message: $e');
      return false;
    }
  }

  /// تحميل قائمة الإداريين المتاحين للتواصل
  Future<List<Map<String, dynamic>>> loadAdmins() async {
    try {
      print('🔍 Loading admins from Supabase...');

      final response = await _supabase
          .from('admins')
          .select(
            'id, full_name, email, profile_image_url, phone_number, is_active',
          )
          .eq('is_active', true)
          .order('full_name');

      print('✅ Admins loaded: ${response.length} admins found');
      print('📋 Admins data: $response');

      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      print('❌ Error loading admins: $e');
      print('📊 Stack trace: $stackTrace');
      return [];
    }
  }

  // ════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ════════════════════════════════════════════════════════════

  /// تحميل الإشعارات لولي الأمر
  Future<List<Map<String, dynamic>>> loadNotifications({
    bool unreadOnly = false,
    int? limit,
    int offset = 0,
  }) async {
    try {
      final parentId = await _getParentIdSafe();
      if (parentId == null) return [];

      dynamic query = _supabase
          .from('notifications')
          .select()
          .eq('recipient_parent_id', parentId);

      if (unreadOnly) {
        query = query.eq('is_read', false);
      }
      query = query.order('created_at', ascending: false);

      if (limit != null) {
        query = query.range(offset, offset + limit - 1);
      }

      return List<Map<String, dynamic>>.from(await query);
    } catch (e) {
      print('❌ Error loading notifications: $e');
      return [];
    }
  }

  /// تحديث حالة قراءة إشعار معين
  Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      return true;
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      return false;
    }
  }

  /// تحديث جميع الإشعارات كمقروءة دفعة واحدة
  Future<bool> markAllNotificationsAsRead() async {
    try {
      final parentId = await _getParentIdSafe();
      if (parentId == null) return false;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('recipient_parent_id', parentId)
          .eq('is_read', false);

      return true;
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════
  // MODEL CONVERSION — ACTIVITIES
  // ════════════════════════════════════════════════════════════

  /// تحميل الأنشطة كـ ActivityModel مع فلترة كاملة و pagination
  Future<List<ActivityModel>> loadActivitiesAsModels(
    int studentId, {
    int? limit,
    int offset = 0,
    ActivityStatus? statusFilter,
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
  }) async {
    try {
      // ✅ تعديل الاستعلام لجلب اسم الطالب والمعلم والصف مع JOIN
      dynamic query = _supabase
          .from('activities')
          .select('''
            *,
            subjects(name),
            students!inner(full_name, section_id, sections(name)),
            teachers(full_name)
          ''')
          .eq('student_id', studentId)
          .order('due_date', ascending: false);

      if (statusFilter != null) {
        query = query.eq('status', _activityStatusToString(statusFilter));
      }
      if (dueDateFrom != null) {
        query = query.gte('due_date', dueDateFrom.toIso8601String());
      }
      if (dueDateTo != null) {
        query = query.lte('due_date', dueDateTo.toIso8601String());
      }
      if (limit != null) {
        query = query.range(offset, offset + limit - 1);
      }

      final response = await query;

      // ✅ تحويل البيانات لإضافة اسم الطالب والمعلم والصف
      final processedData = List<Map<String, dynamic>>.from(response).map((
        json,
      ) {
        // استخرج بيانات الطالب من العلاقة
        final studentData = json['students'] as Map<String, dynamic>?;
        final sectionData = studentData?['sections'] as Map<String, dynamic>?;
        final teacherData = json['teachers'] as Map<String, dynamic>?;

        return {
          ...json,
          // اسم الطالب من جدول students مباشرة
          'student_name': studentData?['full_name']?.toString(),
          // اسم الصف من جدول sections
          'section_name': sectionData?['name']?.toString(),
          // اسم المعلم من جدول teachers
          'teacher_name': teacherData?['full_name']?.toString(),
        };
      }).toList();

      return processedData.map(ActivityModel.fromJson).toList();
    } catch (e) {
      print('❌ Error loading activities as models: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  // MODEL CONVERSION — ATTENDANCE
  // ════════════════════════════════════════════════════════════

  /// تحميل الحضور كـ AttendanceModel مع تحميل متوازي لكل الأطفال
  Future<List<AttendanceModel>> loadAttendanceAsModels({
    required DateTime month,
    int? studentId,
  }) async {
    try {
      // ✅ recovery بدل exception مباشر
      final parentId = await _getParentIdSafe();
      if (parentId == null) {
        print('⚠️ Cannot load attendance: parent not authenticated');
        return [];
      }

      // تحديد الطلاب المستهدفين
      final List<int> studentIds;
      if (studentId != null) {
        studentIds = [studentId];
      } else {
        final links = await _supabase
            .from('parent_students')
            .select('student_id')
            .eq('parent_id', parentId);

        studentIds = List<Map<String, dynamic>>.from(
          links,
        ).map((l) => l['student_id'] as int).toList();
      }

      if (studentIds.isEmpty) return [];

      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0);

      // ✅ تحميل متوازي — كل الأطفال في نفس الوقت
      final futures = studentIds.map((id) async {
        final response = await _supabase
            .from('attendance')
            // ✅ join للحصول على الاسم بدل student_name_cache الوهمي
            .select('*, students(full_name)')
            .eq('student_id', id)
            .gte('attendance_date', startOfMonth.toIso8601String())
            .lte('attendance_date', endOfMonth.toIso8601String())
            .order('attendance_date');

        final records = List<Map<String, dynamic>>.from(response);
        if (records.isEmpty) return null;

        final studentName =
            records.first['students']?['full_name']?.toString() ?? '';

        return AttendanceModel.fromRawRecords(id, studentName, month, records);
      });

      final results = await Future.wait(futures);

      // فلترة الطلاب الذين لا توجد لهم سجلات في هذا الشهر
      return results.whereType<AttendanceModel>().toList();
    } catch (e) {
      print('❌ Error loading attendance as models: $e');
      rethrow;
    }
  }

  Future<List<DailySummaryModel>> loadDailySummariesAsModels(
    int studentId, {
    DateTime? date,
    int? limit,
    int offset = 0,
  }) async {
    try {
      // ✅ تعديل الاستعلام لجلب اسم الطالب والمعلم والصف مع JOIN
      dynamic query = _supabase
          .from('daily_summaries')
          .select('''
            *,
            students!inner(full_name, section_id, sections(name)),
            teachers(full_name)
          ''')
          .eq('student_id', studentId);

      if (date != null) {
        query = query.eq('summary_date', date.toIso8601String().split('T')[0]);
      }

      // order() يأتي أخيراً قبل range فقط
      query = query.order('summary_date', ascending: false);

      if (limit != null) {
        query = query.range(offset, offset + limit - 1);
      }

      final response = await query;

      // ✅ تحويل البيانات لإضافة اسم الطالب والمعلم والصف
      final processedData = List<Map<String, dynamic>>.from(response).map((
        json,
      ) {
        // استخرج بيانات الطالب من العلاقة
        final studentData = json['students'] as Map<String, dynamic>?;
        final sectionData = studentData?['sections'] as Map<String, dynamic>?;
        final teacherData = json['teachers'] as Map<String, dynamic>?;

        return {
          ...json,
          // اسم الطالب من جدول students مباشرة
          'student_name': studentData?['full_name']?.toString(),
          // اسم الصف من جدول sections
          'section_name': sectionData?['name']?.toString(),
          // اسم المعلم من جدول teachers
          'teacher_name_from_join': teacherData?['full_name']?.toString(),
        };
      }).toList();

      return processedData.map(DailySummaryModel.fromJson).toList();
    } catch (e) {
      print('❌ Error loading daily summaries as models: $e');
      rethrow;
    }
  }
  // ════════════════════════════════════════════════════════════
  // ENUM CONVERSION HELPERS
  // ════════════════════════════════════════════════════════════

  String _activityStatusToString(ActivityStatus status) {
    const map = {
      ActivityStatus.pending: 'pending',
      ActivityStatus.inProgress: 'in_progress',
      ActivityStatus.completed: 'completed',
      ActivityStatus.missing: 'missing',
      ActivityStatus.submitted: 'submitted',
    };
    return map[status] ?? 'pending';
  }

  /// تحميل ملخص التدريب الذاتي للطالب (من practice_quiz_attempts)
  Future<Map<String, dynamic>> loadChildPracticeSummary(int studentId) async {
    try {
      print('🔄 Calling practice summary for studentId=$studentId');
      final response = await _supabase.client.rpc(
        'get_child_practice_summary',
        params: {'p_student_id': studentId},
      );
      print('📊 Practice summary response: $response');
      if (response == null) return {};
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      print('❌ Error loading practice summary for student $studentId: $e');
      return {};
    }
  }

  /// تحميل أداء الطالب لكل مادة دراسية
  /// تعمل بعد إضافة policy على exam_results
  Future<List<SubjectPerformanceModel>> loadStudentSubjectPerformances(
    int studentId,
  ) async {
    try {
      // 1. section_id للطالب
      final studentRow = await _supabase
          .from('students')
          .select('section_id')
          .eq('id', studentId)
          .maybeSingle();

      if (studentRow == null) return [];
      final sectionId = studentRow['section_id'] as int?;
      if (sectionId == null) return [];

      // 2. المواد النشطة في الـ section
      final sectionSubjectsRows = await _supabase
          .from('section_subjects')
          .select('subjects(id, name, icon, color)')
          .eq('section_id', sectionId)
          .eq('is_active', true);

      if (sectionSubjectsRows.isEmpty) return [];

      final subjectsMap = <int, Map<String, dynamic>>{};
      for (final row in List<Map<String, dynamic>>.from(sectionSubjectsRows)) {
        final subj = row['subjects'] as Map<String, dynamic>?;
        if (subj == null) continue;
        final id = subj['id'] as int?;
        if (id == null) continue;
        subjectsMap[id] = subj;
      }

      if (subjectsMap.isEmpty) return [];

      // 3. نتائج الاختبارات المكتملة — تعمل الآن بعد إضافة الـ policy
      final examResultsRows = await _supabase
          .from('exam_results')
          .select(
            'percentage, obtained_marks, total_marks, submitted_at, exams(id, subject_id, title)',
          )
          .eq('student_id', studentId)
          .eq('status', 'completed')
          .order('submitted_at', ascending: false);

      final examResults = List<Map<String, dynamic>>.from(examResultsRows);

      // 4. تجميع per subject
      final Map<int, List<double>> percentagesPerSubject = {};
      final Map<int, Map<String, dynamic>> latestExamPerSubject = {};

      for (final result in examResults) {
        final examData = result['exams'] as Map<String, dynamic>?;
        if (examData == null) continue;
        final subjectId = examData['subject_id'] as int?;
        if (subjectId == null) continue;

        double pct;
        if (result['percentage'] != null) {
          pct = (result['percentage'] as num).toDouble();
        } else if (result['total_marks'] != null &&
            (result['total_marks'] as num) > 0) {
          pct =
              (result['obtained_marks'] as num).toDouble() /
              (result['total_marks'] as num).toDouble() *
              100;
        } else {
          pct = 0.0;
        }

        percentagesPerSubject.putIfAbsent(subjectId, () => []).add(pct);
        latestExamPerSubject.putIfAbsent(
          subjectId,
          () => {
            'percentage': pct,
            'title': examData['title'],
            'submitted_at': result['submitted_at'],
          },
        );
      }

      // 5. بناء القائمة النهائية
      final resultList = <SubjectPerformanceModel>[];

      for (final entry in subjectsMap.entries) {
        final subjectId = entry.key;
        final subjectInfo = entry.value;
        final percentages = percentagesPerSubject[subjectId] ?? [];
        final latestExam = latestExamPerSubject[subjectId];

        final averageScore = percentages.isNotEmpty
            ? percentages.reduce((a, b) => a + b) / percentages.length
            : 0.0;

        DateTime? lastExamDate;
        if (latestExam?['submitted_at'] != null) {
          lastExamDate = DateTime.tryParse(
            latestExam!['submitted_at'].toString(),
          );
        }

        resultList.add(
          SubjectPerformanceModel(
            subjectId: subjectId,
            subjectName: subjectInfo['name']?.toString() ?? '',
            icon: subjectInfo['icon']?.toString() ?? '📚',
            colorHex: subjectInfo['color']?.toString() ?? '0xFF6C63FF',
            averageScore: averageScore,
            totalExams: percentages.length,
            lastScore: latestExam != null
                ? (latestExam['percentage'] as num?)?.toDouble()
                : null,
            lastExamTitle: latestExam?['title']?.toString(),
            lastExamDate: lastExamDate,
          ),
        );
      }

      resultList.sort((a, b) {
        if (a.hasExams && !b.hasExams) return -1;
        if (!a.hasExams && b.hasExams) return 1;
        return b.averageScore.compareTo(a.averageScore);
      });

      return resultList;
    } catch (e) {
      print('❌ Error loading subject performances: $e');
      return [];
    }
  }
}
