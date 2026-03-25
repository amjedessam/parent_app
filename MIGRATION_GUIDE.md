# Comprehensive Architectural Analysis & Migration Plan
## Parent App: Mock Data → Supabase Integration

**Version:** 1.0  
**Date:** February 2026  
**Status:** Production-Ready Migration Guide

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [System Architecture Overview](#2-system-architecture-overview)
3. [Current State Analysis](#3-current-state-analysis)
4. [Mock Data → Supabase Mapping](#4-mock-data--supabase-mapping)
5. [Gap Analysis](#5-gap-analysis)
6. [Migration Plan](#6-migration-plan)
7. [Implementation Code Examples](#7-implementation-code-examples)
8. [Risk Assessment](#8-risk-assessment)
9. [Best Practices](#9-best-practices)
10. [Appendix: Complete Table Inventory](#10-appendix-complete-table-inventory)

---

## 1. Executive Summary

### 1.1 Current State

| Component | Status | Integration Level |
|-----------|--------|-------------------|
| Student App | Production | 100% Supabase |
| Parent App | Development | 40% Supabase, 60% Mock |
| Teacher App | Not Started | N/A |
| Database Schema | Production | 95% Complete |

### 1.2 Critical Finding

The Parent App has a partially implemented `ParentSupabaseService` but controllers still rely on dummy services with fallback patterns. The migration requires:

1. **Schema extension** for `activities` table (4 new columns)
2. **Controller refactoring** to remove mock data fallbacks
3. **Model updates** to support Supabase JSON structures
4. **Service cleanup** to delete dummy implementations

### 1.3 Migration Timeline

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| Phase 1: Schema Extension | 2-3 days | SQL migrations, RLS policies |
| Phase 2: Service Completion | 3-4 days | Repository methods, model factories |
| Phase 3: Controller Migration | 5-7 days | Updated controllers, error handling |
| Phase 4: Cleanup & Testing | 2-3 days | Remove dummy services, integration tests |
| **Total** | **2-3 weeks** | Production-ready Parent App |

---

## 2. System Architecture Overview

### 2.1 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     FLUTTER PARENT APP                          │
├─────────────────────────────────────────────────────────────────┤
│  Presentation Layer                                             │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────────┐   │
│  │   Views         │ │   Controllers   │ │    View Models      │   │
│  │   (Screens)     │ │   (GetX)        │ │    (Rx observables)│   │
│  └────────┬────────┘ └────────┬────────┘ └─────────────────────┘   │
│           │                   │                                     │
│  Business Logic Layer          │                                     │
│  ┌────────┴───────────────────┴────────┐                          │
│  │                                    │                          │
│  ▼                                    ▼                          │
│  ┌─────────────────────┐  ┌──────────────────────────┐          │
│  │  Dummy Services     │  │  Supabase Services       │          │
│  │  (Being retired)    │  │  (Production target)     │          │
│  └─────────────────────┘  └──────────┬─────────────────┘          │
│                                      │                           │
└──────────────────────────────────────┼───────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                      SUPABASE BACKEND                           │
├─────────────────────────────────────────────────────────────────┤
│  ┌────────────┐  ┌────────────┐  ┌────────────────────────────┐  │
│  │ PostgreSQL │  │   Auth     │  │  Realtime / Edge Functions │  │
│  │ (Tables)   │  │ (GoTrue)   │  │                            │  │
│  └────────────┘  └────────────┘  └────────────────────────────┘  │
│                                                                  │
│  Security: Row Level Security (RLS) Policies                   │
│  Performance: Materialized Views, Indexes                        │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| State Management | GetX | Reactive programming, dependency injection |
| Backend | Supabase | Database, Auth, Realtime |
| Local Storage | GetStorage | Auth tokens, user preferences |
| Database | PostgreSQL | Primary data store |
| Security | RLS Policies | Row-level access control |

### 2.3 Data Flow

```
User Action → Controller → Service → Supabase Client → PostgreSQL
                                               ↓
User Interface ← State Update ← Response ← Query Result
```

---

## 3. Current State Analysis

### 3.1 Project Structure

```
lib/
├── config/
│   └── supabase_config.dart          # Supabase credentials
├── modules/
│   └── parent/
│       ├── controllers/              # Business logic
│       │   ├── dashboard_controller.dart
│       │   ├── reports_controller.dart
│       │   ├── communication_controller.dart
│       │   └── notification_controller.dart
│       ├── models/                   # Data models
│       │   ├── child_model.dart
│       │   ├── activity_model.dart
│       │   ├── attendance_model.dart
│       │   ├── daily_summary_model.dart
│       │   ├── test_model.dart
│       │   ├── message_model.dart
│       │   ├── notification_model.dart
│       │   └── teacher_model.dart
│       ├── services/                 # Data access layer
│       │   ├── supabase_service.dart           # ✅ Core service
│       │   ├── parent_supabase_service.dart     # ✅ Partially implemented
│       │   ├── parent_service_dummy.dart        # ❌ To be deleted
│       │   ├── reports_service_dummy.dart     # ❌ To be deleted
│       │   ├── communication_service_dummy.dart # ❌ To be deleted
│       │   └── notification_service_dummy.dart  # ❌ To be deleted
│       ├── views/                    # UI screens
│       └── widgets/                  # Reusable components
└── main.dart                         # App entry point
```

### 3.2 Mock Services Inventory

| Service | File | Lines of Code | Mock Data Coverage |
|---------|------|---------------|-------------------|
| `ParentServiceDummy` | `parent_service_dummy.dart` | 135 | Parent profile, 3 children, test history |
| `ReportsServiceDummy` | `reports_service_dummy.dart` | 401 | Activities, attendance, daily summaries |
| `CommunicationServiceDummy` | `communication_service_dummy.dart` | 111 | Teachers list, messages |
| `NotificationServiceDummy` | `notification_service_dummy.dart` | 61 | Notifications list |

### 3.3 Existing Supabase Integration

**File:** `parent_supabase_service.dart`

| Method | Status | Description |
|--------|--------|-------------|
| `loadCurrentParent()` | ✅ Implemented | Load parent profile |
| `loadChildren()` | ✅ Implemented | Load linked students |
| `loadChildExamResults()` | ✅ Implemented | Load exam results |
| `loadChildAttendance()` | ✅ Implemented | Load attendance records |
| `loadDailySummaries()` | ✅ Implemented | Load daily summaries |
| `loadActivities()` | ✅ Implemented | Load activities |
| `loadMessages()` | ✅ Implemented | Load parent-teacher messages |
| `sendMessage()` | ✅ Implemented | Send message to teacher |
| `loadNotifications()` | ✅ Implemented | Load notifications |
| `markNotificationAsRead()` | ✅ Implemented | Update notification status |

---

## 4. Mock Data → Supabase Mapping

### 4.1 Complete Mapping Document

#### ChildModel Mapping

| Mock Field | Supabase Table | Supabase Column | Notes |
|------------|---------------|-----------------|-------|
| `id` | `students` | `id` | Primary key |
| `name` | `students` | `full_name` | |
| `grade` | `grades` | `name` | Join via `students.grade_id` |
| `avatarUrl` | `students` | `profile_image_url` | Nullable |
| `latestScore` | `exam_results` | `obtained_marks` | Latest completed exam |
| `averageScore` | `exam_results` | Calculated | `AVG(percentage)` |
| `recentAlerts` | `notifications` | Multiple columns | Filter by `recipient_parent_id` |
| `testHistory` | `exam_results` + `exams` | Joined data | See TestModel mapping |
| `curriculumGaps` | **NOT IN DB** | Computed field | Requires view or application logic |

**Supabase Query Example:**
```sql
SELECT 
    s.id,
    s.full_name as name,
    g.name as grade,
    s.profile_image_url as avatar_url,
    (
        SELECT er.obtained_marks 
        FROM exam_results er 
        WHERE er.student_id = s.id AND er.status = 'completed'
        ORDER BY er.submitted_at DESC 
        LIMIT 1
    ) as latest_score,
    (
        SELECT AVG(er.percentage)
        FROM exam_results er
        WHERE er.student_id = s.id AND er.status = 'completed'
    ) as average_score
FROM students s
JOIN grades g ON s.grade_id = g.id
JOIN parent_students ps ON s.id = ps.student_id
WHERE ps.parent_id = :parent_id;
```

#### ActivityModel Mapping

| Mock Field | Supabase Table | Supabase Column | Status |
|------------|---------------|-----------------|--------|
| `id` | `activities` | `id` | ✅ Exists |
| `childId` | `activities` | `student_id` | ✅ Exists |
| `title` | `activities` | `title` | ✅ Exists |
| `description` | `activities` | `description` | ✅ Exists |
| `type` | `activities` | `activity_type` | ❌ **MISSING** - Required ENUM |
| `status` | `activities` | `status` | ❌ **MISSING** - Required ENUM |
| `dueDate` | `activities` | `due_date` | ❌ **MISSING** - Required DATE |
| `subject` | `subjects` | `name` | ❌ **MISSING FK** - Need `subject_id` |
| `priority` | `activities` | `priority` | ❌ **MISSING** - Required INTEGER |

**Critical:** The `activities` table requires schema extension before migration.

#### AttendanceModel Mapping

| Mock Field | Supabase Table | Supabase Column | Aggregation |
|------------|---------------|-----------------|-------------|
| `childId` | `attendance` | `student_id` | |
| `childName` | `students` | `full_name` | Join |
| `month` | `attendance` | `attendance_date` | Date range filter |
| `totalDays` | `attendance` | Count | `COUNT(*)` for school days |
| `presentDays` | `attendance` | Count | `COUNT(*) WHERE status='present'` |
| `absentDays` | `attendance` | Count | `COUNT(*) WHERE status='absent'` |
| `lateDays` | `attendance` | Count | `COUNT(*) WHERE status='late'` |
| `excusedAbsences` | `attendance` | Count | `COUNT(*) WHERE status='excused'` |
| `dailyRecords` | `attendance` | Multiple columns | Raw rows |

**Supabase Query Example:**
```sql
SELECT 
    a.student_id,
    s.full_name as child_name,
    DATE_TRUNC('month', a.attendance_date) as month,
    COUNT(*) FILTER (WHERE a.status = 'present') as present_days,
    COUNT(*) FILTER (WHERE a.status = 'absent') as absent_days,
    COUNT(*) FILTER (WHERE a.status = 'late') as late_days,
    COUNT(*) FILTER (WHERE a.status = 'excused') as excused_absences,
    json_agg(
        json_build_object(
            'date', a.attendance_date,
            'status', a.status,
            'note', a.notes,
            'checkInTime', a.check_in_time
        )
    ) as daily_records
FROM attendance a
JOIN students s ON a.student_id = s.id
WHERE a.student_id IN (
    SELECT student_id FROM parent_students WHERE parent_id = :parent_id
)
AND a.attendance_date >= :start_date
AND a.attendance_date <= :end_date
GROUP BY a.student_id, s.full_name, DATE_TRUNC('month', a.attendance_date);
```

#### DailySummaryModel Mapping

| Mock Field | Supabase Table | Supabase Column | Type |
|------------|---------------|-----------------|------|
| `id` | `daily_summaries` | `id` | INTEGER |
| `childId` | `daily_summaries` | `student_id` | INTEGER FK |
| `childName` | `students` | `full_name` | Join |
| `date` | `daily_summaries` | `summary_date` | DATE |
| `recap` | `daily_summaries` | `summary_content` | TEXT |
| `participationLevel` | `daily_summaries` | `participation_level` | INTEGER (1-5) |
| `behaviorLevel` | `daily_summaries` | `behavior_level` | INTEGER (1-5) |
| `focusLevel` | `daily_summaries` | `focus_level` | INTEGER (1-5) |
| `teacherNote` | `daily_summaries` | `teacher_notes` | TEXT |
| `highlightOfDay` | `daily_summaries` | `highlight` | TEXT |
| `subjectsStudied` | `daily_summaries` | `subjects_covered` | JSONB array |
| `subjectNotes` | `daily_summaries` | `subject_notes` | JSONB object |

#### TestModel Mapping

| Mock Field | Supabase Table | Supabase Column | Join Path |
|------------|---------------|-----------------|-----------|
| `id` | `exam_results` | `id` | |
| `title` | `exams` | `title` | `exam_results.exam_id` |
| `subject` | `subjects` | `name` | `exams.subject_id` |
| `date` | `exam_results` | `submitted_at` | |
| `score` | `exam_results` | `obtained_marks` | |
| `totalQuestions` | `exams` | `total_questions` | |
| `correctAnswers` | `exam_results` | `correct_answers` | |
| `duration` | `exam_results` | `time_taken_seconds` | Convert to Duration |
| `details` | `exam_results` | `metadata` | JSONB |

**Query Pattern in Existing Code:**
```dart
final response = await _supabase
    .from('exam_results')
    .select('*, exams(title, subject_id, subjects(name))')
    .eq('student_id', studentId)
    .eq('status', 'completed')
    .order('submitted_at', ascending: false);
```

#### MessageModel Mapping

| Mock Field | Supabase Table | Supabase Column | Notes |
|------------|---------------|-----------------|-------|
| `id` | `messages` | `id` | |
| `senderId` | `messages` | `sender_parent_id` OR `sender_teacher_id` | Polymorphic |
| `receiverId` | `messages` | `recipient_parent_id` OR `recipient_teacher_id` | Polymorphic |
| `content` | `messages` | `content` | |
| `timestamp` | `messages` | `created_at` | |
| `isFromParent` | Calculated | Compare with current user | |
| `isRead` | `messages` | `is_read` | BOOLEAN |

---

## 5. Gap Analysis

### 5.1 Schema Gaps

#### CRITICAL: Activities Table Extension Required

```sql
-- Current activities table structure (from SQL dump):
CREATE TABLE public.activities (
    id integer NOT NULL,
    student_id integer NOT NULL,
    title character varying(300) NOT NULL,
    description text,
    activity_date date NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- MISSING COLUMNS (required by Parent App):
-- 1. activity_type (ENUM: homework, project, task, reading, practice)
-- 2. status (ENUM: pending, in_progress, completed, missing, submitted)
-- 3. priority (INTEGER: 1-5)
-- 4. subject_id (INTEGER FK to subjects)
-- 5. due_date (DATE)
```

#### Required ENUM Types

```sql
-- Activity Type ENUM
CREATE TYPE public.activity_type_enum AS ENUM (
    'homework',
    'project', 
    'task',
    'reading',
    'practice'
);

-- Activity Status ENUM
CREATE TYPE public.activity_status_enum AS ENUM (
    'pending',
    'in_progress',
    'completed',
    'missing',
    'submitted'
);
```

#### Required RLS Policies

```sql
-- Parents can view their children's activities
CREATE POLICY "Parents view own children's activities"
ON public.activities
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.parent_students ps
        WHERE ps.student_id = activities.student_id
        AND ps.parent_id = public.effective_app_user_id()
    )
);

-- Parents can view their children's daily summaries
CREATE POLICY "Parents view own children's daily summaries"
ON public.daily_summaries
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.parent_students ps
        WHERE ps.student_id = daily_summaries.student_id
        AND ps.parent_id = public.effective_app_user_id()
    )
);

-- Parents can view messages they sent or received
CREATE POLICY "Parents view own messages"
ON public.messages
FOR SELECT
USING (
    sender_parent_id = public.effective_app_user_id()
    OR recipient_parent_id = public.effective_app_user_id()
);

-- Parents can send messages
CREATE POLICY "Parents can send messages"
ON public.messages
FOR INSERT
WITH CHECK (
    sender_parent_id = public.effective_app_user_id()
);
```

### 5.2 Application Layer Gaps

| Gap | Location | Priority | Effort |
|-----|----------|----------|--------|
| ActivityModel.fromJson() incomplete | `activity_model.dart` | HIGH | 2 hours |
| No model conversion in ParentSupabaseService | `parent_supabase_service.dart` | HIGH | 4 hours |
| Dummy fallback pattern in controllers | Multiple controllers | CRITICAL | 8 hours |
| Missing error handling | All services | MEDIUM | 4 hours |
| No pagination implementation | All list queries | MEDIUM | 4 hours |
| Missing realtime subscriptions | Notifications, messages | LOW | 6 hours |

### 5.3 Test Coverage Gaps

| Component | Current Coverage | Required Coverage |
|-----------|------------------|-------------------|
| ParentSupabaseService | 0% | 80% |
| Controllers | 0% | 70% |
| Models | 0% | 90% |
| RLS Policies | Manual | Automated integration tests |

---

## 6. Migration Plan

### 6.1 Phase 1: Schema Extension (Days 1-3)

**Objective:** Extend database schema to support all Parent App requirements

#### Day 1: Create ENUM Types

```sql
-- File: migrations/001_add_activity_enums.sql

-- Create activity type ENUM
CREATE TYPE public.activity_type_enum AS ENUM (
    'homework',
    'project',
    'task',
    'reading',
    'practice'
);

COMMENT ON TYPE public.activity_type_enum IS 
    'Types of activities assigned to students';

-- Create activity status ENUM  
CREATE TYPE public.activity_status_enum AS ENUM (
    'pending',
    'in_progress',
    'completed',
    'missing',
    'submitted'
);

COMMENT ON TYPE public.activity_status_enum IS 
    'Status tracking for student activities';
```

#### Day 2: Alter Activities Table

```sql
-- File: migrations/002_extend_activities_table.sql

-- Add new columns to activities table
ALTER TABLE public.activities
    ADD COLUMN activity_type public.activity_type_enum 
        NOT NULL DEFAULT 'homework',
    ADD COLUMN status public.activity_status_enum 
        NOT NULL DEFAULT 'pending',
    ADD COLUMN priority INTEGER 
        DEFAULT 3 
        CHECK (priority >= 1 AND priority <= 5),
    ADD COLUMN subject_id INTEGER 
        REFERENCES public.subjects(id) 
        ON DELETE SET NULL,
    ADD COLUMN due_date DATE;

-- Add indexes for performance
CREATE INDEX idx_activities_student_type 
    ON public.activities(student_id, activity_type);
    
CREATE INDEX idx_activities_status 
    ON public.activities(status);
    
CREATE INDEX idx_activities_due_date 
    ON public.activities(due_date);

CREATE INDEX idx_activities_student_status 
    ON public.activities(student_id, status);

-- Add trigger to update updated_at
CREATE OR REPLACE FUNCTION public.fn_update_activities_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_activities_timestamp
    BEFORE UPDATE ON public.activities
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_update_activities_timestamp();
```

#### Day 3: RLS Policies and Testing

```sql
-- File: migrations/003_add_parent_rls_policies.sql

-- Activities policies
CREATE POLICY "Parents view own children's activities"
ON public.activities
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.parent_students ps
        WHERE ps.student_id = activities.student_id
        AND ps.parent_id = public.effective_app_user_id()
    )
);

-- Daily summaries policies  
CREATE POLICY "Parents view own children's daily summaries"
ON public.daily_summaries
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.parent_students ps
        WHERE ps.student_id = daily_summaries.student_id
        AND ps.parent_id = public.effective_app_user_id()
    )
);

-- Messages policies
CREATE POLICY "Parents view own messages"
ON public.messages
FOR SELECT
USING (
    sender_parent_id = public.effective_app_user_id()
    OR recipient_parent_id = public.effective_app_user_id()
);

CREATE POLICY "Parents can send messages"
ON public.messages
FOR INSERT
WITH CHECK (
    sender_parent_id = public.effective_app_user_id()
);

-- Notifications policies
CREATE POLICY "Parents view own notifications"
ON public.notifications
FOR SELECT
USING (
    recipient_parent_id = public.effective_app_user_id()
);

CREATE POLICY "Parents can mark notifications read"
ON public.notifications
FOR UPDATE
USING (
    recipient_parent_id = public.effective_app_user_id()
)
WITH CHECK (
    recipient_parent_id = public.effective_app_user_id()
);
```

**Testing Checklist:**
- [ ] ENUM types created successfully
- [ ] Columns added to activities table
- [ ] Indexes created and working
- [ ] RLS policies applied
- [ ] Student app unaffected by schema changes

### 6.2 Phase 2: Service Layer Completion (Days 4-7)

**Objective:** Complete ParentSupabaseService with model conversions

#### Day 4: Model Factory Methods

**File:** `lib/modules/parent/models/activity_model.dart`

```dart
// Add to existing ActivityModel class

factory ActivityModel.fromJson(Map<String, dynamic> json) {
  // Support both Supabase and legacy mock structure
  return ActivityModel(
    id: _parseInt(json['id']),
    childId: _parseInt(json['student_id'] ?? json['childId']),
    title: json['title']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    type: _parseActivityType(json['activity_type'] ?? json['type']),
    status: _parseActivityStatus(json['status']),
    dueDate: _parseDate(json['due_date'] ?? json['dueDate']),
    subject: json['subjects']?['name']?.toString() ?? 
              json['subject']?.toString() ?? '',
    priority: _parseInt(json['priority']) ?? 3,
  );
}

static ActivityType _parseActivityType(String? value) {
  switch (value?.toLowerCase()) {
    case 'homework': return ActivityType.homework;
    case 'project': return ActivityType.project;
    case 'task': return ActivityType.task;
    case 'reading': return ActivityType.reading;
    case 'practice': return ActivityType.practice;
    default: return ActivityType.task;
  }
}

static ActivityStatus _parseActivityStatus(String? value) {
  switch (value?.toLowerCase()) {
    case 'pending': return ActivityStatus.pending;
    case 'in_progress': return ActivityStatus.inProgress;
    case 'completed': return ActivityStatus.completed;
    case 'missing': return ActivityStatus.missing;
    case 'submitted': return ActivityStatus.submitted;
    default: return ActivityStatus.pending;
  }
}

static int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? 0;
}

static DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}
```

**File:** `lib/modules/parent/models/attendance_model.dart`

```dart
// Add factory method

factory AttendanceModel.fromSupabaseJson(
  Map<String, dynamic> json, {
  required DateTime month,
}) {
  final dailyRecords = (json['daily_records'] as List? ?? [])
      .map((day) => AttendanceDay(
            date: DateTime.parse(day['date']),
            status: _parseAttendanceStatus(day['status']),
            note: day['note']?.toString(),
            checkInTime: day['checkInTime'] != null 
                ? DateTime.parse(day['checkInTime']) 
                : null,
          ))
      .toList();

  return AttendanceModel(
    childId: _parseInt(json['student_id']),
    childName: json['child_name']?.toString() ?? '',
    month: month,
    totalDays: _parseInt(json['total_days']),
    presentDays: _parseInt(json['present_days']),
    absentDays: _parseInt(json['absent_days']),
    lateDays: _parseInt(json['late_days']),
    excusedAbsences: _parseInt(json['excused_absences']),
    dailyRecords: dailyRecords,
  );
}
```

#### Day 5-6: Extend ParentSupabaseService

**File:** `lib/modules/parent/services/parent_supabase_service.dart`

```dart
// Add these methods to existing ParentSupabaseService

/// Load activities as ActivityModel objects
Future<List<ActivityModel>> loadActivitiesAsModels(
  int studentId, {
  int? limit,
  ActivityStatus? statusFilter,
  DateTime? dueDateFrom,
  DateTime? dueDateTo,
}) async {
  try {
    dynamic query = _supabase
        .from('activities')
        .select('*, subjects(name)')
        .eq('student_id', studentId)
        .order('due_date', ascending: true);

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
      query = query.limit(limit);
    }

    final response = await query;

    return List<Map<String, dynamic>>.from(response)
        .map((json) => ActivityModel.fromJson(json))
        .toList();
  } catch (e) {
    print('❌ Error loading activities as models: $e');
    rethrow;
  }
}

/// Load attendance with aggregation
Future<List<AttendanceModel>> loadAttendanceAsModels({
  required DateTime month,
  int? studentId,
}) async {
  try {
    final storage = GetStorage();
    final parentId = storage.read<int>('app_entity_id');

    if (parentId == null) {
      throw Exception('Parent not authenticated');
    }

    // Get linked student IDs if specific student not provided
    List<int> studentIds;
    if (studentId != null) {
      studentIds = [studentId];
    } else {
      final links = await _supabase
          .from('parent_students')
          .select('student_id')
          .eq('parent_id', parentId);
      
      studentIds = List<Map<String, dynamic>>.from(links)
          .map((l) => l['student_id'] as int)
          .toList();
    }

    if (studentIds.isEmpty) return [];

    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);

    // Load raw attendance data for each student
    final results = <AttendanceModel>[];
    
    for (final id in studentIds) {
      final response = await _supabase
          .from('attendance')
          .select()
          .eq('student_id', id)
          .gte('attendance_date', startOfMonth.toIso8601String())
          .lte('attendance_date', endOfMonth.toIso8601String())
          .order('attendance_date');

      final records = List<Map<String, dynamic>>.from(response);
      
      if (records.isNotEmpty) {
        // Aggregate data
        final dailyRecords = records.map((r) => AttendanceDay(
          date: DateTime.parse(r['attendance_date']),
          status: _parseAttendanceStatus(r['status']),
          note: r['notes']?.toString(),
          checkInTime: r['check_in_time'] != null
              ? DateTime.parse(r['check_in_time'])
              : null,
        )).toList();

        results.add(AttendanceModel(
          childId: id,
          childName: records.first['student_name_cache'] ?? '',
          month: month,
          totalDays: records.length,
          presentDays: records.where((r) => r['status'] == 'present').length,
          absentDays: records.where((r) => r['status'] == 'absent').length,
          lateDays: records.where((r) => r['status'] == 'late').length,
          excusedAbsences: records.where((r) => r['status'] == 'excused').length,
          dailyRecords: dailyRecords,
        ));
      }
    }

    return results;
  } catch (e) {
    print('❌ Error loading attendance as models: $e');
    rethrow;
  }
}

// Helper methods
String _activityStatusToString(ActivityStatus status) {
  switch (status) {
    case ActivityStatus.pending: return 'pending';
    case ActivityStatus.inProgress: return 'in_progress';
    case ActivityStatus.completed: return 'completed';
    case ActivityStatus.missing: return 'missing';
    case ActivityStatus.submitted: return 'submitted';
  }
}

static AttendanceStatus _parseAttendanceStatus(String? value) {
  switch (value?.toLowerCase()) {
    case 'present': return AttendanceStatus.present;
    case 'absent': return AttendanceStatus.absent;
    case 'late': return AttendanceStatus.late;
    case 'excused': return AttendanceStatus.excused;
    default: return AttendanceStatus.notRecorded;
  }
}
```

#### Day 7: Unit Testing

**File:** `test/services/parent_supabase_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:parent/modules/parent/services/parent_supabase_service.dart';

class MockSupabaseService extends Mock implements SupabaseService {}

void main() {
  late ParentSupabaseService service;
  late MockSupabaseService mockSupabase;

  setUp(() {
    mockSupabase = MockSupabaseService();
    service = ParentSupabaseService();
    // Inject mock via GetX or constructor injection
  });

  group('loadChildren', () {
    test('returns list of children for authenticated parent', () async {
      // Arrange
      final expectedChildren = [
        {'student_id': 1, 'students': {'id': 1, 'full_name': 'Child 1'}},
        {'student_id': 2, 'students': {'id': 2, 'full_name': 'Child 2'}},
      ];
      
      // Mock GetStorage to return parent ID
      // Mock Supabase query
      
      // Act
      final result = await service.loadChildren();
      
      // Assert
      expect(result, hasLength(2));
      expect(result.first['students']['full_name'], 'Child 1');
    });

    test('returns empty list when parent not authenticated', () async {
      // Arrange - mock GetStorage returning null
      
      // Act
      final result = await service.loadChildren();
      
      // Assert
      expect(result, isEmpty);
    });
  });
}
```

### 6.3 Phase 3: Controller Migration (Days 8-14)

**Objective:** Replace dummy service calls with Supabase service, remove fallbacks

#### Day 8-9: DashboardController

**File:** `lib/modules/parent/controllers/dashboard_controller.dart`

**Current State:** Mixed pattern with fallback
```dart
// ❌ CURRENT ANTI-PATTERN
Future<void> loadData() async {
  isLoading.value = true;
  try {
    await _supabaseService.loadCurrentParent();
    final childrenData = await _supabaseService.loadChildren();
    children.value = childrenData.map((json) => ChildModel.fromJson(json)).toList();
    // ... notifications and messages
  } catch (e) {
    print('❌ Error loading dashboard data: $e');
    Get.snackbar('خطأ', 'فشل تحميل البيانات');
    // Fallback to dummy service - HIDES ERRORS
    final dummyData = await parentService.getParentData();
    children.value = dummyData.children;
  } finally {
    isLoading.value = false;
  }
}
```

**Target State:** Pure Supabase with explicit error handling
```dart
// ✅ TARGET STATE
Future<void> loadData() async {
  isLoading.value = true;
  errorMessage.value = null;
  
  try {
    // Load parent profile
    final parentData = await _supabaseService.loadCurrentParent();
    if (parentData != null) {
      parent.value = ParentModel.fromJson(parentData);
    }

    // Load children with full details
    final childrenData = await _supabaseService.loadChildren();
    children.value = await _enrichChildrenData(childrenData);

    // Load unread notifications count
    final notifications = await _supabaseService.loadNotifications(
      unreadOnly: true,
      limit: 100,
    );
    unreadNotificationsCount.value = notifications.length;

    // Load unread messages count
    final messages = await _supabaseService.loadMessages();
    unreadMessages.value = messages.where((m) => m['is_read'] == false).length;

  } on PostgrestException catch (e) {
    print('❌ Database error: ${e.message}');
    errorMessage.value = 'فشل الاتصال بقاعدة البيانات';
    _showErrorSnackbar(errorMessage.value!);
  } on AuthException catch (e) {
    print('❌ Auth error: $e');
    // Redirect to login
    Get.offAllNamed(AppRoutes.PARENT_LOGIN);
  } catch (e) {
    print('❌ Unexpected error: $e');
    errorMessage.value = 'حدث خطأ غير متوقع';
    _showErrorSnackbar(errorMessage.value!);
  } finally {
    isLoading.value = false;
  }
}

/// Enrich children data with additional details
Future<List<ChildModel>> _enrichChildrenData(
  List<Map<String, dynamic>> childrenData,
) async {
  final result = <ChildModel>[];
  
  for (final childJson in childrenData) {
    final studentId = childJson['student_id'] ?? 
                      childJson['students']?['id'];
    
    if (studentId == null) continue;

    // Load latest exam result
    final examResults = await _supabaseService.loadChildExamResults(
      studentId,
      limit: 1,
    );

    // Load average score
    final avgScore = await _supabaseService.getAverageScore(studentId);

    // Load recent notifications (alerts)
    final alerts = await _supabaseService.loadChildAlerts(studentId);

    // Load test history
    final testHistory = await _supabaseService.loadChildExamResults(
      studentId,
      limit: 10,
    );

    result.add(ChildModel.fromJson({
      ...childJson,
      'latestScore': examResults.isNotEmpty ? examResults.first['obtained_marks'] : 0,
      'averageScore': avgScore,
      'recentAlerts': alerts.map((a) => a['message']).toList(),
      'testHistory': testHistory,
    }));
  }
  
  return result;
}
```

#### Day 10-11: ReportsController

**File:** `lib/modules/parent/controllers/reports_controller.dart`

**Key Changes:**
1. Replace `_reportsService.getActivities()` with `_supabaseService.loadActivitiesAsModels()`
2. Replace `_reportsService.getAttendance()` with `_supabaseService.loadAttendanceAsModels()`
3. Replace `_reportsService.getDailySummaries()` with `_supabaseService.loadDailySummaries()`
4. Remove weekly summary aggregation (compute in Flutter or create DB view)

#### Day 12: CommunicationController

**File:** `lib/modules/parent/controllers/communication_controller.dart`

**Key Changes:**
1. Replace `CommunicationServiceDummy` with `ParentSupabaseService`
2. Implement realtime message updates using Supabase Stream
3. Add message sending with optimistic UI updates

#### Day 13: NotificationController

**File:** `lib/modules/parent/controllers/notification_controller.dart`

**Key Changes:**
1. Replace `NotificationServiceDummy` with `ParentSupabaseService`
2. Implement realtime notification subscription
3. Mark notifications as read with immediate UI update

#### Day 14: Integration Testing

**Test Scenarios:**
- [ ] Dashboard loads with Supabase data
- [ ] Reports display activities from database
- [ ] Attendance shows correct aggregated data
- [ ] Messages send and receive correctly
- [ ] Notifications update in realtime
- [ ] Error states handled gracefully (no mock fallbacks)

### 6.4 Phase 4: Cleanup (Days 15-17)

**Objective:** Remove dummy services, finalize architecture

#### Day 15: Delete Dummy Services

**Files to Delete:**
- `lib/modules/parent/services/parent_service_dummy.dart`
- `lib/modules/parent/services/reports_service_dummy.dart`
- `lib/modules/parent/services/communication_service_dummy.dart`
- `lib/modules/parent/services/notification_service_dummy.dart`

**Files to Update:**
- `main.dart` - Remove dummy service registrations
- All controllers - Remove fallback logic and imports

#### Day 16: Add Repository Abstractions (Optional but Recommended)

**File:** `lib/modules/parent/repositories/i_parent_repository.dart`

```dart
abstract class IParentRepository {
  Future<ParentModel?> getCurrentParent();
  Future<List<ChildModel>> getChildren();
  Future<List<ActivityModel>> getActivities(int childId);
  Future<List<AttendanceModel>> getAttendance(DateTime month);
  Future<List<DailySummaryModel>> getDailySummaries(DateTime date);
  Future<List<NotificationModel>> getNotifications({bool unreadOnly});
  Future<List<MessageModel>> getMessages();
  Future<bool> sendMessage(int teacherId, String subject, String content);
  Future<bool> markNotificationAsRead(int notificationId);
}
```

**File:** `lib/modules/parent/repositories/supabase_parent_repository.dart`

```dart
class SupabaseParentRepository implements IParentRepository {
  final ParentSupabaseService _service;
  
  SupabaseParentRepository(this._service);
  
  @override
  Future<ParentModel?> getCurrentParent() async {
    final data = await _service.loadCurrentParent();
    return data != null ? ParentModel.fromJson(data) : null;
  }
  
  // ... implement all methods
}
```

#### Day 17: Final Testing & Documentation

**Final Checklist:**
- [ ] All dummy services removed
- [ ] No mock data fallbacks in code
- [ ] All tests passing
- [ ] Integration tests with real Supabase
- [ ] Performance testing (query speed, memory usage)
- [ ] Documentation updated
- [ ] Student app verified working

---

## 7. Implementation Code Examples

### 7.1 Error Handling Pattern

```dart
// lib/core/error/error_handler.dart

class AppErrorHandler {
  static void handle(Object error, StackTrace stackTrace) {
    if (error is PostgrestException) {
      _handleDatabaseError(error);
    } else if (error is AuthException) {
      _handleAuthError(error);
    } else if (error is SocketException) {
      _handleNetworkError();
    } else {
      _handleUnknownError(error, stackTrace);
    }
  }
  
  static void _handleDatabaseError(PostgrestException error) {
    print('Database Error: ${error.message}');
    // Log to monitoring service
    // Show user-friendly message based on error code
  }
  
  static void _handleAuthError(AuthException error) {
    print('Auth Error: $error');
    Get.snackbar(
      'انتهت الجلسة',
      'يرجى تسجيل الدخول مرة أخرى',
      duration: Duration(seconds: 5),
    );
    Get.offAllNamed(AppRoutes.PARENT_LOGIN);
  }
  
  static void _handleNetworkError() {
    Get.snackbar(
      'خطأ في الاتصال',
      'يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى',
      duration: Duration(seconds: 5),
    );
  }
  
  static void _handleUnknownError(Object error, StackTrace stackTrace) {
    print('Unknown Error: $error');
    print(stackTrace);
    // Send to crash reporting service
    Get.snackbar('خطأ', 'حدث خطأ غير متوقع');
  }
}
```

### 7.2 Pagination Implementation

```dart
// lib/modules/parent/controllers/paginated_controller.dart

mixin PaginationMixin<T> on GetxController {
  final items = <T>[].obs;
  final isLoading = false.obs;
  final hasMore = true.obs;
  final currentPage = 0.obs;
  final error = Rxn<String>();
  
  static const int pageSize = 20;
  
  Future<void> loadMore();
  
  Future<void> refresh() async {
    currentPage.value = 0;
    hasMore.value = true;
    items.clear();
    await loadMore();
  }
}

class PaginatedActivitiesController extends GetxController 
    with PaginationMixin<ActivityModel> {
  
  final ParentSupabaseService _service;
  final int childId;
  
  PaginatedActivitiesController(this._service, this.childId);
  
  @override
  Future<void> loadMore() async {
    if (isLoading.value || !hasMore.value) return;
    
    isLoading.value = true;
    error.value = null;
    
    try {
      final newItems = await _service.loadActivitiesAsModels(
        childId,
        limit: pageSize,
        offset: currentPage.value * pageSize,
      );
      
      if (newItems.length < pageSize) {
        hasMore.value = false;
      }
      
      items.addAll(newItems);
      currentPage.value++;
    } catch (e) {
      error.value = 'Failed to load activities';
    } finally {
      isLoading.value = false;
    }
  }
}
```

### 7.3 Realtime Subscription

```dart
// lib/modules/parent/services/realtime_service.dart

class RealtimeService extends GetxService {
  late final SupabaseClient _client;
  final Map<String, StreamSubscription> _subscriptions = {};
  
  @override
  void onInit() {
    super.onInit();
    _client = Supabase.instance.client;
  }
  
  /// Subscribe to notifications for a parent
  void subscribeToNotifications(
    int parentId,
    void Function(List<Map<String, dynamic>>) onData,
  ) {
    final channelName = 'notifications:parent:$parentId';
    
    _subscriptions[channelName] = _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_parent_id', parentId)
        .order('created_at')
        .listen(
          onData,
          onError: (error) {
            print('Realtime error: $error');
          },
        );
  }
  
  /// Subscribe to messages
  void subscribeToMessages(
    int parentId,
    void Function(List<Map<String, dynamic>>) onData,
  ) {
    final channelName = 'messages:parent:$parentId';
    
    _subscriptions[channelName] = _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .or('sender_parent_id.eq.$parentId,recipient_parent_id.eq.$parentId')
        .order('created_at')
        .listen(
          onData,
          onError: (error) {
            print('Realtime error: $error');
          },
        );
  }
  
  void unsubscribe(String channelName) {
    _subscriptions[channelName]?.cancel();
    _subscriptions.remove(channelName);
  }
  
  @override
  void onClose() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    super.onClose();
  }
}
```

### 7.4 Complete Migration of ReportsController

```dart
// lib/modules/parent/controllers/reports_controller.dart (Migrated)

class ReportsController extends GetxController {
  final ParentSupabaseService _supabaseService;
  
  ReportsController(this._supabaseService);
  
  // State
  final activities = <ActivityModel>[].obs;
  final attendanceRecords = <AttendanceModel>[].obs;
  final dailySummaries = <DailySummaryModel>[].obs;
  final weeklySummary = Rxn<WeeklySummaryModel>();
  
  final isLoadingActivities = false.obs;
  final isLoadingAttendance = false.obs;
  final isLoadingSummaries = false.obs;
  
  final selectedMonth = DateTime.now().obs;
  final selectedDate = DateTime.now().obs;
  final selectedChildId = Rxn<int>();
  
  final errorActivities = Rxn<String>();
  final errorAttendance = Rxn<String>();
  final errorSummaries = Rxn<String>();
  
  @override
  void onInit() {
    super.onInit();
    loadAllData();
  }
  
  Future<void> loadAllData() async {
    await Future.wait([
      loadActivities(),
      loadAttendance(),
      loadDailySummaries(),
    ]);
  }
  
  Future<void> loadActivities() async {
    isLoadingActivities.value = true;
    errorActivities.value = null;
    
    try {
      final List<ActivityModel> result;
      
      if (selectedChildId.value != null) {
        result = await _supabaseService.loadActivitiesAsModels(
          selectedChildId.value!,
        );
      } else {
        // Load activities for all children
        final children = await _supabaseService.loadChildren();
        result = [];
        
        for (final child in children) {
          final childActivities = await _supabaseService.loadActivitiesAsModels(
            child['student_id'],
          );
          result.addAll(childActivities);
        }
      }
      
      activities.value = result;
      
      // Compute weekly summary
      _computeWeeklySummary();
      
    } catch (e) {
      print('❌ Error loading activities: $e');
      errorActivities.value = 'فشل تحميل الأنشطة';
    } finally {
      isLoadingActivities.value = false;
    }
  }
  
  Future<void> loadAttendance() async {
    isLoadingAttendance.value = true;
    errorAttendance.value = null;
    
    try {
      final result = await _supabaseService.loadAttendanceAsModels(
        month: selectedMonth.value,
        studentId: selectedChildId.value,
      );
      
      attendanceRecords.value = result;
    } catch (e) {
      print('❌ Error loading attendance: $e');
      errorAttendance.value = 'فشل تحميل بيانات الحضور';
    } finally {
      isLoadingAttendance.value = false;
    }
  }
  
  Future<void> loadDailySummaries() async {
    isLoadingSummaries.value = true;
    errorSummaries.value = null;
    
    try {
      final data = await _supabaseService.loadDailySummaries(
        selectedChildId.value,
        date: selectedDate.value,
      );
      
      dailySummaries.value = data
          .map((json) => DailySummaryModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error loading daily summaries: $e');
      errorSummaries.value = 'فشل تحميل الخلاصة اليومية';
    } finally {
      isLoadingSummaries.value = false;
    }
  }
  
  void _computeWeeklySummary() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    final weekActivities = activities.where((a) {
      return a.dueDate.isAfter(weekStart) && a.dueDate.isBefore(weekEnd);
    }).toList();
    
    weeklySummary.value = WeeklySummaryModel(
      weekStart: weekStart,
      weekEnd: weekEnd,
      totalActivities: weekActivities.length,
      completedActivities: weekActivities
          .where((a) => a.status == ActivityStatus.completed)
          .length,
      pendingActivities: weekActivities
          .where((a) => a.status == ActivityStatus.pending)
          .length,
      missedActivities: weekActivities
          .where((a) => a.status == ActivityStatus.missing)
          .length,
      activitiesPerChild: _groupByChild(weekActivities),
    );
  }
  
  Map<int, int> _groupByChild(List<ActivityModel> activities) {
    final result = <int, int>{};
    for (final activity in activities) {
      result[activity.childId] = (result[activity.childId] ?? 0) + 1;
    }
    return result;
  }
  
  void setChildFilter(int? childId) {
    selectedChildId.value = childId;
    loadAllData();
  }
  
  void changeMonth(DateTime newMonth) {
    selectedMonth.value = newMonth;
    loadAttendance();
  }
  
  void changeDate(DateTime newDate) {
    selectedDate.value = newDate;
    loadDailySummaries();
  }
}
```

---

## 8. Risk Assessment

### 8.1 Critical Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Schema migration breaks Student app | Medium | Critical | Test Student app after each migration |
| RLS policy misconfiguration exposes data | Low | Critical | Audit all policies, test with different users |
| Mixed service usage causes data inconsistency | High | High | Complete migration in single release cycle |
| GetStorage fallback stores outdated data | Medium | Medium | Clear storage on successful Supabase fetch |
| Realtime subscriptions cause memory leaks | Medium | Medium | Implement proper cleanup in onClose() |
| Missing error handling crashes app | Medium | High | Add comprehensive error boundaries |

### 8.2 Anti-Patterns to Avoid

```dart
// ❌ ANTI-PATTERN 1: Silent fallback to mock data
try {
  final data = await _supabaseService.loadChildren();
  children.value = data;
} catch (e) {
  // Silent fallback - HIDES ERRORS
  final dummyData = await parentService.getParentData();
  children.value = dummyData.children;
}

// ✅ CORRECT: Explicit error handling with retry
try {
  final data = await _supabaseService.loadChildren();
  children.value = data;
} catch (e) {
  errorMessage.value = 'Failed to load children. Pull to retry.';
  _showErrorSnackbar(errorMessage.value!);
}
```

```dart
// ❌ ANTI-PATTERN 2: Direct GetStorage access scattered in code
final parentId = GetStorage().read<int>('app_entity_id');

// ✅ CORRECT: Centralized auth state management
final parentId = AuthService.currentUserId; // From JWT claims
```

```dart
// ❌ ANTI-PATTERN 3: Loading all data at once
Future<void> loadDashboardData() async {
  final parent = await _service.loadCurrentParent();
  final children = await _service.loadChildren();
  final notifications = await _service.loadNotifications();
  final messages = await _service.loadMessages();
  // Slow sequential loading
}

// ✅ CORRECT: Parallel loading
Future<void> loadDashboardData() async {
  final results = await Future.wait([
    _service.loadCurrentParent(),
    _service.loadChildren(),
    _service.loadNotifications(unreadOnly: true, limit: 5),
    _service.loadMessages(limit: 5),
  ]);
  // All loaded in parallel
}
```

### 8.3 Rollback Plan

If critical issues occur after migration:

1. **Immediate (0-1 hour):**
   - Revert to previous app version via app store rollback
   - Enable maintenance mode if necessary

2. **Short-term (1-4 hours):**
   - Identify failing queries/components
   - Restore dummy services as temporary fallback
   - Hotfix critical bugs

3. **Long-term (1-2 days):**
   - Fix root cause in Supabase service layer
   - Re-test all scenarios
   - Gradual rollout with feature flags

---

## 9. Best Practices

### 9.1 Flutter + Supabase Best Practices

```dart
// 1. Use repository pattern for testability
abstract class IParentRepository {
  Future<List<ChildModel>> getChildren();
}

class SupabaseParentRepository implements IParentRepository {
  final SupabaseClient _client;
  SupabaseParentRepository(this._client);
  
  @override
  Future<List<ChildModel>> getChildren() async {
    // Implementation
  }
}

class MockParentRepository implements IParentRepository {
  @override
  Future<List<ChildModel>> getChildren() async {
    // Mock implementation for testing
  }
}

// 2. Implement proper error handling with retry
class SupabaseErrorHandler {
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        return await operation();
      } on PostgrestException catch (e) {
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(delay * (i + 1));
      }
    }
    throw Exception('Max retries exceeded');
  }
}

// 3. Reactive data with realtime and cleanup
class ParentController extends GetxController {
  StreamSubscription? _notificationsSub;
  
  @override
  void onInit() {
    super.onInit();
    _subscribeToNotifications();
  }
  
  void _subscribeToNotifications() {
    _notificationsSub = Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_parent_id', parentId)
        .listen(
          (data) => notifications.value = data,
          onError: (e) => print('Realtime error: $e'),
        );
  }
  
  @override
  void onClose() {
    _notificationsSub?.cancel();
    super.onClose();
  }
}

// 4. Optimize queries with select() projection
// ❌ Don't fetch all columns
final response = await _supabase.from('students').select();

// ✅ Select only needed columns
final response = await _supabase
    .from('students')
    .select('id, full_name, grade_id, profile_image_url')
    .eq('id', studentId);

// 5. Use computed fields in database when possible
// ❌ Don't calculate in Flutter for large datasets
final avgScore = scores.reduce((a, b) => a + b) / scores.length;

// ✅ Create materialized view or function in PostgreSQL
// CREATE MATERIALIZED VIEW mv_student_performance AS ...
```

### 9.2 Testing Strategy

```dart
// Unit test with mocked Supabase
void main() {
  group('ParentSupabaseService', () {
    late MockSupabaseClient mockClient;
    late ParentSupabaseService service;
    
    setUp(() {
      mockClient = MockSupabaseClient();
      service = ParentSupabaseService();
      Get.put<SupabaseService>(MockSupabaseService());
    });
    
    test('loadChildren returns list of children', () async {
      // Arrange
      final expectedData = [
        {'id': 1, 'full_name': 'Child 1'},
      ];
      
      when(() => mockClient.from('parent_students').select())
          .thenReturn(...);
      
      // Act
      final result = await service.loadChildren();
      
      // Assert
      expect(result, hasLength(1));
      expect(result.first['full_name'], 'Child 1');
    });
  });
}

// Integration test with real Supabase
void main() {
  group('ParentSupabaseService Integration', () {
    late ParentSupabaseService service;
    
    setUpAll(() async {
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!,
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      );
      
      // Authenticate as test parent
      await Supabase.instance.client.auth.signInWithPassword(
        email: 'test.parent@school.com',
        password: 'test-password',
      );
    });
    
    test('loadChildren returns linked students', () async {
      final children = await service.loadChildren();
      expect(children, isNotEmpty);
      expect(children.first['student_id'], isNotNull);
    });
    
    tearDownAll(() async {
      await Supabase.instance.client.auth.signOut();
    });
  });
}
```

### 9.3 Performance Optimization

```dart
// 1. Pagination for lists
Future<List<ActivityModel>> loadActivitiesPage(
  int studentId, {
  required int page,
  int pageSize = 20,
}) async {
  return await _supabase
      .from('activities')
      .select()
      .eq('student_id', studentId)
      .range(page * pageSize, (page + 1) * pageSize - 1)
      .order('due_date', ascending: false)
      .then((data) => data.map(ActivityModel.fromJson).toList());
}

// 2. Caching with GetX Workers
class DashboardController extends GetxController {
  final children = <ChildModel>[].obs;
  final _cache = <String, dynamic>{};
  
  @override
  void onInit() {
    super.onInit();
    
    // Auto-refresh cache every 5 minutes
    ever(children, (_) => _updateCache());
    
    Timer.periodic(Duration(minutes: 5), (_) => loadChildren());
  }
  
  void _updateCache() {
    _cache['children'] = children.toList();
    _cache['timestamp'] = DateTime.now();
  }
}

// 3. Debounce search queries
final searchQuery = ''.obs;

@override
void onInit() {
  super.onInit();
  
  debounce(searchQuery, (value) {
    performSearch(value);
  }, time: Duration(milliseconds: 500));
}
```

---

## 10. Appendix: Complete Table Inventory

### Database Schema Reference

| Table | Primary Key | Foreign Keys | Parent App Usage |
|-------|-------------|--------------|------------------|
| `parents` | `id` | `auth_user_id` → `auth.users` | Profile viewing |
| `parent_students` | `id` | `parent_id` → `parents`, `student_id` → `students` | Access control |
| `students` | `id` | `grade_id` → `grades`, `section_id` → `sections` | Child details |
| `grades` | `id` | - | Grade names |
| `sections` | `id` | `grade_id` → `grades` | Section names |
| `subjects` | `id` | - | Subject names |
| `section_subjects` | `id` | `section_id`, `subject_id`, `teacher_id` | Teacher assignments |
| `teachers` | `id` | `auth_user_id` → `auth.users` | Contact info |
| `exams` | `id` | `subject_id`, `section_id`, `created_by_teacher` | Exam details |
| `exam_results` | `id` | `student_id`, `exam_id` | Test history |
| `exam_questions` | `id` | `exam_id`, `question_id` | Exam structure |
| `questions` | `id` | `subject_id`, `chapter_id` | Question bank |
| `chapters` | `id` | `subject_id` | Curriculum chapters |
| `chapter_topics` | `id` | `chapter_id` | Topic breakdown |
| `attendance` | `id` | `student_id`, `section_id` | Attendance tracking |
| `daily_summaries` | `id` | `student_id`, `teacher_id` | Daily reports |
| `activities` | `id` | `student_id` | Homework/assignments |
| `messages` | `id` | `sender_parent_id`, `recipient_teacher_id`, etc. | Communication |
| `notifications` | `id` | `recipient_parent_id`, `recipient_student_id`, etc. | Alerts |
| `student_summaries` | `id` | `student_id`, `subject_id` | Student-created notes |
| `practice_quiz_attempts` | `id` | `student_id`, `subject_id` | Practice quizzes |
| `practice_quiz_answers` | `id` | `attempt_id`, `question_id` | Quiz answers |
| `pending_content` | `id` | `teacher_id` | Teacher content approval |
| `reports` | `id` | `student_id`, `parent_id`, `teacher_id` | Generated reports |
| `app_user` | `id` | `auth_user_id` → `auth.users` | Auth mapping |
| `activity_logs` | `id` | - | Audit trail |
| `school_settings` | `id` | - | Configuration |

### Materialized Views

| View | Purpose | Refresh Strategy |
|------|---------|------------------|
| `mv_student_monthly_performance` | Aggregated monthly stats | Daily |
| `mv_weekly_activity` | Weekly activity summaries | Daily |
| `mv_subject_statistics` | Subject-level analytics | Daily |
| `mv_dashboard_stats` | Dashboard aggregations | Hourly |
| `mv_monthly_attendance` | Attendance reports | Daily |

---

## Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Feb 2026 | Senior Architect | Initial comprehensive analysis |

---

**End of Document**
