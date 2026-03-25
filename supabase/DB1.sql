--
-- PostgreSQL database dump
--

\restrict QpEtDPVDYAV3SWhX82fWyN4sYs8iZlna2ichpagRFoCz3pcrJj6kO6bcVLqZS6I

-- Dumped from database version 17.6
-- Dumped by pg_dump version 18.1

-- Started on 2026-03-02 00:33:10

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 30 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- TOC entry 4667 (class 0 OID 0)
-- Dependencies: 30
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 1493 (class 1247 OID 23234)
-- Name: activity_status_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.activity_status_enum AS ENUM (
    'pending',
    'in_progress',
    'completed',
    'missing',
    'submitted'
);


ALTER TYPE public.activity_status_enum OWNER TO postgres;

--
-- TOC entry 4669 (class 0 OID 0)
-- Dependencies: 1493
-- Name: TYPE activity_status_enum; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TYPE public.activity_status_enum IS 'Status tracking for student activities';


--
-- TOC entry 1490 (class 1247 OID 23222)
-- Name: activity_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.activity_type_enum AS ENUM (
    'homework',
    'project',
    'task',
    'reading',
    'practice'
);


ALTER TYPE public.activity_type_enum OWNER TO postgres;

--
-- TOC entry 4670 (class 0 OID 0)
-- Dependencies: 1490
-- Name: TYPE activity_type_enum; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TYPE public.activity_type_enum IS 'Types of activities assigned to students';


--
-- TOC entry 1338 (class 1247 OID 17452)
-- Name: approval_status_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.approval_status_enum AS ENUM (
    'pending',
    'approved',
    'rejected'
);


ALTER TYPE public.approval_status_enum OWNER TO postgres;

--
-- TOC entry 1335 (class 1247 OID 17460)
-- Name: attendance_status_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.attendance_status_enum AS ENUM (
    'present',
    'absent',
    'late',
    'excused'
);


ALTER TYPE public.attendance_status_enum OWNER TO postgres;

--
-- TOC entry 1341 (class 1247 OID 17470)
-- Name: difficulty_level_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.difficulty_level_enum AS ENUM (
    'easy',
    'medium',
    'hard'
);


ALTER TYPE public.difficulty_level_enum OWNER TO postgres;

--
-- TOC entry 1344 (class 1247 OID 17478)
-- Name: exam_attempt_status_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.exam_attempt_status_enum AS ENUM (
    'in_progress',
    'completed',
    'pending_manual_grading'
);


ALTER TYPE public.exam_attempt_status_enum OWNER TO postgres;

--
-- TOC entry 1347 (class 1247 OID 17486)
-- Name: exam_status_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.exam_status_enum AS ENUM (
    'draft',
    'pending',
    'approved',
    'published',
    'completed',
    'rejected'
);


ALTER TYPE public.exam_status_enum OWNER TO postgres;

--
-- TOC entry 1350 (class 1247 OID 17500)
-- Name: notification_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.notification_type_enum AS ENUM (
    'exam_published',
    'exam_result',
    'content_approved',
    'content_rejected',
    'attendance_absent',
    'report_sent',
    'message_received',
    'general'
);


ALTER TYPE public.notification_type_enum OWNER TO postgres;

--
-- TOC entry 1353 (class 1247 OID 17518)
-- Name: pending_content_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.pending_content_type_enum AS ENUM (
    'question',
    'exam'
);


ALTER TYPE public.pending_content_type_enum OWNER TO postgres;

--
-- TOC entry 1356 (class 1247 OID 17524)
-- Name: question_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.question_type_enum AS ENUM (
    'multiple_choice',
    'true_false',
    'essay',
    'fill_blank'
);


ALTER TYPE public.question_type_enum OWNER TO postgres;

--
-- TOC entry 1359 (class 1247 OID 17534)
-- Name: semester_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.semester_type_enum AS ENUM (
    'first',
    'second'
);


ALTER TYPE public.semester_type_enum OWNER TO postgres;

--
-- TOC entry 520 (class 1255 OID 17539)
-- Name: app_current_user_id(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.app_current_user_id() RETURNS integer
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
DECLARE
  v TEXT;
BEGIN
  v := current_setting('app.current_user_id', true);
  IF v IS NULL OR TRIM(COALESCE(v, '')) = '' THEN
    RETURN NULL;
  END IF;
  RETURN v::INTEGER;
EXCEPTION WHEN OTHERS THEN
  RETURN NULL;
END;
$$;


ALTER FUNCTION public.app_current_user_id() OWNER TO postgres;

--
-- TOC entry 610 (class 1255 OID 20989)
-- Name: create_student_summary(integer, integer, character varying, text, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_student_summary(p_subject_id integer, p_chapter_id integer, p_title character varying, p_content text, p_summary_type character varying DEFAULT 'summary'::character varying) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_student_id INTEGER;
    v_id         INTEGER;
BEGIN
    v_student_id := public.get_current_student_id();
    IF v_student_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated as student';
    END IF;

    INSERT INTO public.student_summaries (
        student_id, subject_id, chapter_id, title, content, summary_type
    ) VALUES (
        v_student_id, p_subject_id, p_chapter_id,
        p_title, p_content, p_summary_type
    )
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$;


ALTER FUNCTION public.create_student_summary(p_subject_id integer, p_chapter_id integer, p_title character varying, p_content text, p_summary_type character varying) OWNER TO postgres;

--
-- TOC entry 521 (class 1255 OID 17540)
-- Name: custom_access_token_claims(jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.custom_access_token_claims(event jsonb) RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
DECLARE
  auth_user_uuid UUID;
  app_user_row RECORD;
  original_claims jsonb;
  new_claims jsonb;
BEGIN
  -- 1. Extract original claims from event (REQUIRED - must pass them through)
  original_claims := event->'claims';
  IF original_claims IS NULL THEN
    original_claims := '{}'::jsonb;
  END IF;
  
  new_claims := original_claims;
  
  -- 2. Extract user_id - support both event.user_id and event.id
  auth_user_uuid := (event->>'user_id')::UUID;
  IF auth_user_uuid IS NULL THEN
    auth_user_uuid := (event->>'id')::UUID;
  END IF;
  
  -- 3. Look up app_user by auth_user_id
  IF auth_user_uuid IS NOT NULL THEN
    SELECT app_entity_id, user_type
    INTO app_user_row
    FROM public.app_user
    WHERE auth_user_id = auth_user_uuid
    LIMIT 1;
    
    IF app_user_row IS NOT NULL THEN
      new_claims := new_claims || jsonb_build_object(
        'app_user_id', app_user_row.app_entity_id,
        'user_type', app_user_row.user_type
      );
    END IF;
  END IF;
  
  -- 4. CRITICAL: Return { "claims": ... } - Supabase requires this exact format
  RETURN jsonb_build_object('claims', new_claims);
END;
$$;


ALTER FUNCTION public.custom_access_token_claims(event jsonb) OWNER TO postgres;

--
-- TOC entry 4673 (class 0 OID 0)
-- Dependencies: 521
-- Name: FUNCTION custom_access_token_claims(event jsonb); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.custom_access_token_claims(event jsonb) IS 'Returns JWT custom claims wrapped in "claims" key. Adds app_user_id and user_type from app_user table.';


--
-- TOC entry 522 (class 1255 OID 17541)
-- Name: deactivate_section_subject_with_context(integer, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.deactivate_section_subject_with_context(p_user_id integer, p_user_type text, p_id integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  UPDATE section_subjects
  SET is_active = false, updated_at = CURRENT_TIMESTAMP
  WHERE id = p_id;
END;
$$;


ALTER FUNCTION public.deactivate_section_subject_with_context(p_user_id integer, p_user_type text, p_id integer) OWNER TO postgres;

--
-- TOC entry 523 (class 1255 OID 17542)
-- Name: delete_parent_student_link_with_context(integer, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_parent_student_link_with_context(p_user_id integer, p_user_type text, p_id integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);

  DELETE FROM parent_students WHERE id = p_id;
END;
$$;


ALTER FUNCTION public.delete_parent_student_link_with_context(p_user_id integer, p_user_type text, p_id integer) OWNER TO postgres;

--
-- TOC entry 611 (class 1255 OID 20990)
-- Name: delete_student_summary(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_student_summary(p_summary_id integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_student_id INTEGER;
BEGIN
    v_student_id := public.get_current_student_id();
    IF v_student_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated as student';
    END IF;

    -- Security: only deletes if summary belongs to this student
    DELETE FROM public.student_summaries
    WHERE id         = p_summary_id
      AND student_id = v_student_id;
END;
$$;


ALTER FUNCTION public.delete_student_summary(p_summary_id integer) OWNER TO postgres;

--
-- TOC entry 524 (class 1255 OID 17543)
-- Name: effective_app_user_id(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.effective_app_user_id() RETURNS integer
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $$
  SELECT COALESCE(
    NULLIF(trim(current_setting('app.current_user_id', true)), '')::integer,
    NULLIF(auth.jwt() ->> 'app_user_id', '')::integer
  );
$$;


ALTER FUNCTION public.effective_app_user_id() OWNER TO postgres;

--
-- TOC entry 525 (class 1255 OID 17544)
-- Name: effective_user_type(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.effective_user_type() RETURNS text
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $$
  SELECT COALESCE(
    NULLIF(trim(current_setting('app.user_type', true)), ''),
    auth.jwt() ->> 'user_type'
  );
$$;


ALTER FUNCTION public.effective_user_type() OWNER TO postgres;

--
-- TOC entry 526 (class 1255 OID 17545)
-- Name: fn_calculate_exam_total_marks(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_calculate_exam_total_marks() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    exam_total INTEGER;
BEGIN
    SELECT COALESCE(SUM(marks), 0)
    INTO exam_total
    FROM exam_questions
    WHERE exam_id = COALESCE(NEW.exam_id, OLD.exam_id);
    
    UPDATE exams
    SET total_marks = exam_total
    WHERE id = COALESCE(NEW.exam_id, OLD.exam_id);
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_calculate_exam_total_marks() OWNER TO postgres;

--
-- TOC entry 527 (class 1255 OID 17546)
-- Name: fn_check_teacher_subject_access(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_check_teacher_subject_access() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_TABLE_NAME = 'pending_content' THEN
        IF NOT EXISTS (
            SELECT 1
            FROM section_subjects ss
            WHERE ss.teacher_id = NEW.teacher_id
            AND ss.subject_id = (NEW.content_data->>'subject_id')::INTEGER
            AND ss.is_active = true
        ) THEN
            RAISE EXCEPTION 'Teacher does not teach this subject';
        END IF;
    END IF;
    
    IF TG_TABLE_NAME = 'questions' AND NEW.created_by_teacher IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1
            FROM section_subjects ss
            WHERE ss.teacher_id = NEW.created_by_teacher
            AND ss.subject_id = NEW.subject_id
            AND ss.is_active = true
        ) THEN
            RAISE EXCEPTION 'Teacher does not teach this subject';
        END IF;
    END IF;
    
    IF TG_TABLE_NAME = 'exams' AND NEW.created_by_teacher IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1
            FROM section_subjects ss
            WHERE ss.teacher_id = NEW.created_by_teacher
            AND ss.subject_id = NEW.subject_id
            AND ss.section_id = NEW.section_id
            AND ss.is_active = true
        ) THEN
            RAISE EXCEPTION 'Teacher does not teach this subject for this section';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_check_teacher_subject_access() OWNER TO postgres;

--
-- TOC entry 528 (class 1255 OID 17547)
-- Name: fn_generate_student_code(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_generate_student_code() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.student_code IS NULL THEN
        NEW.student_code := nextval('seq_student_code');
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_generate_student_code() OWNER TO postgres;

--
-- TOC entry 529 (class 1255 OID 17548)
-- Name: fn_generate_subject_code(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_generate_subject_code() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.subject_code IS NULL THEN
        NEW.subject_code := nextval('seq_subject_code');
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_generate_subject_code() OWNER TO postgres;

--
-- TOC entry 530 (class 1255 OID 17549)
-- Name: fn_generate_teacher_code(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_generate_teacher_code() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.teacher_code IS NULL THEN
        NEW.teacher_code := nextval('seq_teacher_code');
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_generate_teacher_code() OWNER TO postgres;

--
-- TOC entry 531 (class 1255 OID 17550)
-- Name: fn_log_user_login(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_log_user_login() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO activity_logs (user_type, user_id, user_name_cache, action, description)
    VALUES (
        CASE TG_TABLE_NAME
            WHEN 'admins' THEN 'admin'
            WHEN 'teachers' THEN 'teacher'
            WHEN 'students' THEN 'student'
            WHEN 'parents' THEN 'parent'
        END,
        NEW.id,
        NEW.full_name,
        'login',
        'Successful login'
    );
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_log_user_login() OWNER TO postgres;

--
-- TOC entry 532 (class 1255 OID 17551)
-- Name: fn_notify_absence(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_notify_absence() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.status = 'absent' THEN
        INSERT INTO notifications (
            recipient_parent_id,
            notification_type,
            title,
            message,
            metadata,
            recipient_name_cache
        )
        SELECT 
            p.id,
            'attendance_absent',
            'Absence notification',
            NEW.student_name_cache || ' was absent on ' || NEW.attendance_date,
            jsonb_build_object(
                'student_id', NEW.student_id,
                'date', NEW.attendance_date,
                'notes', NEW.notes
            ),
            p.full_name
        FROM parents p
        JOIN parent_students ps ON p.id = ps.parent_id
        WHERE ps.student_id = NEW.student_id;
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_notify_absence() OWNER TO postgres;

--
-- TOC entry 533 (class 1255 OID 17552)
-- Name: fn_notify_content_review(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_notify_content_review() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.status = 'approved' AND OLD.status = 'pending' THEN
        INSERT INTO notifications (
            recipient_teacher_id,
            notification_type,
            title,
            message,
            metadata
        ) VALUES (
            NEW.teacher_id,
            'content_approved',
            'Content approved',
            'Your content has been approved and published',
            jsonb_build_object('content_id', NEW.id, 'content_type', NEW.content_type)
        );
    END IF;
    
    IF NEW.status = 'rejected' AND OLD.status = 'pending' THEN
        INSERT INTO notifications (
            recipient_teacher_id,
            notification_type,
            title,
            message,
            metadata
        ) VALUES (
            NEW.teacher_id,
            'content_rejected',
            'Content rejected',
            'Content rejected. Reason: ' || COALESCE(NEW.rejection_reason, 'Not specified'),
            jsonb_build_object(
                'content_id', NEW.id, 
                'content_type', NEW.content_type,
                'reason', NEW.rejection_reason
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_notify_content_review() OWNER TO postgres;

--
-- TOC entry 534 (class 1255 OID 17553)
-- Name: fn_notify_exam_completed(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_notify_exam_completed() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    parent_rec RECORD;
BEGIN
    IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
        
        INSERT INTO notifications (
            recipient_student_id,
            notification_type,
            title,
            message,
            metadata
        ) VALUES (
            NEW.student_id,
            'exam_result',
            'Exam Result',
            'You scored ' || NEW.obtained_marks || ' out of ' || NEW.total_marks,
            jsonb_build_object(
                'exam_id', NEW.exam_id,
                'score', NEW.obtained_marks,
                'total', NEW.total_marks,
                'percentage', NEW.percentage
            )
        );
        
        FOR parent_rec IN 
            SELECT p.id, p.full_name
            FROM parents p
            JOIN parent_students ps ON p.id = ps.parent_id
            WHERE ps.student_id = NEW.student_id
        LOOP
            INSERT INTO notifications (
                recipient_parent_id,
                notification_type,
                title,
                message,
                metadata,
                recipient_name_cache
            ) VALUES (
                parent_rec.id,
                'exam_result',
                'Your child exam result',
                NEW.student_name_cache || ' scored ' || NEW.obtained_marks || ' out of ' || NEW.total_marks,
                jsonb_build_object(
                    'student_id', NEW.student_id,
                    'exam_id', NEW.exam_id,
                    'score', NEW.obtained_marks,
                    'total', NEW.total_marks,
                    'percentage', NEW.percentage
                ),
                parent_rec.full_name
            );
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_notify_exam_completed() OWNER TO postgres;

--
-- TOC entry 535 (class 1255 OID 17554)
-- Name: fn_notify_exam_published(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_notify_exam_published() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.status = 'published' AND OLD.status != 'published' THEN
        INSERT INTO notifications (
            recipient_student_id,
            notification_type,
            title,
            message,
            metadata,
            recipient_name_cache
        )
        SELECT 
            s.id,
            'exam_published',
            'New exam: ' || NEW.title,
            'A new exam has been published in ' || (SELECT name FROM subjects WHERE id = NEW.subject_id),
            jsonb_build_object('exam_id', NEW.id, 'subject_id', NEW.subject_id),
            s.full_name
        FROM students s
        WHERE s.section_id = NEW.section_id
        AND s.deleted_at IS NULL;
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_notify_exam_published() OWNER TO postgres;

--
-- TOC entry 536 (class 1255 OID 17555)
-- Name: fn_prevent_teacher_soft_delete(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_prevent_teacher_soft_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
        IF EXISTS (
            SELECT 1
            FROM section_subjects ss
            WHERE ss.teacher_id = OLD.id
            AND ss.is_active = true
        ) THEN
            RAISE EXCEPTION 'Cannot delete teacher with active subjects';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_prevent_teacher_soft_delete() OWNER TO postgres;

--
-- TOC entry 537 (class 1255 OID 17556)
-- Name: fn_refresh_all_materialized_views(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_refresh_all_materialized_views() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_student_monthly_performance;
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_weekly_activity;
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_subject_statistics;
    REFRESH MATERIALIZED VIEW mv_dashboard_stats;
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_monthly_attendance;
    
    RAISE NOTICE 'All Materialized Views have been refreshed successfully';
END;
$$;


ALTER FUNCTION public.fn_refresh_all_materialized_views() OWNER TO postgres;

--
-- TOC entry 538 (class 1255 OID 17557)
-- Name: fn_sync_student_name_cache(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_sync_student_name_cache() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE exam_results
    SET student_name_cache = NEW.full_name
    WHERE student_id = NEW.id;
    
    UPDATE attendance
    SET student_name_cache = NEW.full_name
    WHERE student_id = NEW.id;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_sync_student_name_cache() OWNER TO postgres;

--
-- TOC entry 539 (class 1255 OID 17558)
-- Name: fn_update_attendance_cache(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_update_attendance_cache() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.student_name_cache := (SELECT full_name FROM students WHERE id = NEW.student_id);
        NEW.section_name_cache := (SELECT name FROM sections WHERE id = NEW.section_id);
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_update_attendance_cache() OWNER TO postgres;

--
-- TOC entry 540 (class 1255 OID 17559)
-- Name: fn_update_exam_result_cache(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_update_exam_result_cache() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.student_name_cache := (SELECT full_name FROM students WHERE id = NEW.student_id);
        NEW.exam_title_cache := (SELECT title FROM exams WHERE id = NEW.exam_id);
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_update_exam_result_cache() OWNER TO postgres;

--
-- TOC entry 541 (class 1255 OID 17560)
-- Name: fn_update_timestamp(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_update_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_update_timestamp() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 335 (class 1259 OID 17561)
-- Name: admins; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admins (
    id integer NOT NULL,
    full_name character varying(100) NOT NULL,
    email character varying(100),
    password_hash character varying(255) NOT NULL,
    phone_number character varying(20),
    is_active boolean DEFAULT true,
    last_login_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamp with time zone,
    deleted_by integer,
    profile_image_url text,
    profile_image_storage_path text,
    CONSTRAINT chk_admin_profile_url_valid CHECK (((profile_image_url IS NULL) OR (profile_image_url ~* '^https?://'::text)))
);


ALTER TABLE public.admins OWNER TO postgres;

--
-- TOC entry 4696 (class 0 OID 0)
-- Dependencies: 335
-- Name: COLUMN admins.profile_image_url; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.admins.profile_image_url IS 'Public URL from Supabase Storage (profile-images/admins/{id}/...)';


--
-- TOC entry 4697 (class 0 OID 0)
-- Dependencies: 335
-- Name: COLUMN admins.profile_image_storage_path; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.admins.profile_image_storage_path IS 'Storage path: profile-images/admins/{admin_id}/{filename}';


--
-- TOC entry 542 (class 1255 OID 17570)
-- Name: get_admin_by_id_with_context(integer, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_admin_by_id_with_context(p_user_id integer, p_user_type text, p_admin_id integer) RETURNS SETOF public.admins
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY SELECT * FROM admins a WHERE a.id = p_admin_id AND a.deleted_at IS NULL;
END;
$$;


ALTER FUNCTION public.get_admin_by_id_with_context(p_user_id integer, p_user_type text, p_admin_id integer) OWNER TO postgres;

--
-- TOC entry 336 (class 1259 OID 17571)
-- Name: attendance; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attendance (
    id integer NOT NULL,
    student_id integer NOT NULL,
    section_id integer NOT NULL,
    attendance_date date NOT NULL,
    status public.attendance_status_enum DEFAULT 'present'::public.attendance_status_enum NOT NULL,
    notes text,
    marked_by integer NOT NULL,
    marked_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    student_name_cache character varying(100),
    section_name_cache character varying(50)
);


ALTER TABLE public.attendance OWNER TO postgres;

--
-- TOC entry 543 (class 1255 OID 17578)
-- Name: get_attendance_by_date_with_context(integer, text, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_attendance_by_date_with_context(p_user_id integer, p_user_type text, p_date date) RETURNS SETOF public.attendance
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY SELECT * FROM attendance WHERE attendance_date = p_date ORDER BY section_id;
END;
$$;


ALTER FUNCTION public.get_attendance_by_date_with_context(p_user_id integer, p_user_type text, p_date date) OWNER TO postgres;

--
-- TOC entry 544 (class 1255 OID 17579)
-- Name: get_average_grades_by_subject_with_context(integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_average_grades_by_subject_with_context(p_user_id integer, p_user_type text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  r JSONB;
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  SELECT COALESCE(jsonb_agg(row_to_json(t)::jsonb), '[]'::jsonb) INTO r
  FROM (
    SELECT
      COALESCE(s.name, 'غير معروف') AS name,
      ROUND(AVG(er.percentage)::numeric, 2)::float AS average
    FROM exam_results er
    JOIN exams e ON e.id = er.exam_id
    JOIN subjects s ON s.id = e.subject_id
    WHERE er.status = 'completed' AND er.percentage IS NOT NULL
    GROUP BY s.id, s.name
  ) t;
  RETURN COALESCE(r, '[]'::jsonb);
END;
$$;


ALTER FUNCTION public.get_average_grades_by_subject_with_context(p_user_id integer, p_user_type text) OWNER TO postgres;

--
-- TOC entry 608 (class 1255 OID 20986)
-- Name: get_chapter_topics(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_chapter_topics(p_chapter_id integer) RETURNS TABLE(id integer, title character varying, description text, order_index integer, duration_min integer, questions_count bigint)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
    -- Validate student is authenticated
    IF public.get_current_student_id() IS NULL THEN
        RAISE EXCEPTION 'Not authenticated as student';
    END IF;

    RETURN QUERY
    SELECT
        ct.id,
        ct.title,
        ct.description,
        ct.order_index,
        ct.duration_min,
        -- Chapter-level question count shared across all topics (V1)
        COUNT(q.id) AS questions_count
    FROM public.chapter_topics ct
    LEFT JOIN public.questions q
           ON q.chapter_id = ct.chapter_id
          AND q.is_active  = true
          AND q.status     = 'approved'
    WHERE ct.chapter_id = p_chapter_id
      AND ct.is_active  = true
    GROUP BY ct.id, ct.title, ct.description, ct.order_index, ct.duration_min
    ORDER BY ct.order_index;
END;
$$;


ALTER FUNCTION public.get_chapter_topics(p_chapter_id integer) OWNER TO postgres;

--
-- TOC entry 360 (class 1259 OID 17782)
-- Name: chapters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chapters (
    id integer NOT NULL,
    subject_id integer NOT NULL,
    name character varying(200) NOT NULL,
    description text,
    order_index integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.chapters OWNER TO postgres;

--
-- TOC entry 4704 (class 0 OID 0)
-- Dependencies: 360
-- Name: TABLE chapters; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.chapters IS 'Chapters per subject for curriculum structure (mobile apps)';


--
-- TOC entry 614 (class 1255 OID 22111)
-- Name: get_chapters_with_context(integer, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_chapters_with_context(p_user_id integer, p_user_type text, p_subject_id integer DEFAULT NULL::integer) RETURNS SETOF public.chapters
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  PERFORM set_config('app.user_id',   p_user_id::TEXT,   true);
  PERFORM set_config('app.user_type', p_user_type::TEXT, true);

  RETURN QUERY
  SELECT *
  FROM public.chapters
  WHERE is_active = true
    AND (p_subject_id IS NULL OR subject_id = p_subject_id)
  ORDER BY subject_id, order_index;
END;
$$;


ALTER FUNCTION public.get_chapters_with_context(p_user_id integer, p_user_type text, p_subject_id integer) OWNER TO postgres;

--
-- TOC entry 601 (class 1255 OID 18671)
-- Name: get_chapters_with_progress(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_chapters_with_progress(p_subject_id integer) RETURNS TABLE(id integer, subject_id integer, name character varying, description text, order_index integer, questions_count bigint, progress numeric, is_completed boolean)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
DECLARE
  v_student_id INTEGER;
BEGIN
  v_student_id := public.get_current_student_id();
  IF v_student_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated as student';
  END IF;

  RETURN QUERY
  WITH chapter_questions AS (
    SELECT c.id AS ch_id, COUNT(q.id) AS q_count
    FROM public.chapters c
    LEFT JOIN public.questions q ON q.chapter_id = c.id AND q.is_active = true AND q.status = 'approved'
    WHERE c.subject_id = p_subject_id AND c.is_active = true
    GROUP BY c.id
  ),
  chapter_progress AS (
    SELECT
      c.id,
      c.subject_id,
      c.name,
      c.description,
      c.order_index,
      cq.q_count AS questions_count,
      COALESCE(
        (SELECT COUNT(DISTINCT pqa.question_id)::NUMERIC / NULLIF(cq.q_count, 0)
         FROM public.practice_quiz_answers pqa
         JOIN public.practice_quiz_attempts pqa2 ON pqa2.id = pqa.attempt_id
         WHERE pqa2.student_id = v_student_id
           AND pqa.is_correct = true
           AND pqa.question_id IN (SELECT q2.id FROM public.questions q2 WHERE q2.chapter_id = c.id)
        ), 0
      ) AS progress
    FROM public.chapters c
    JOIN chapter_questions cq ON cq.ch_id = c.id
  )
  SELECT
    cp.id,
    cp.subject_id,
    cp.name,
    cp.description,
    cp.order_index,
    cp.questions_count,
    LEAST(1.0, cp.progress) AS progress,
    (cp.progress >= 1.0) AS is_completed
  FROM chapter_progress cp
  ORDER BY cp.order_index;
END;
$$;


ALTER FUNCTION public.get_chapters_with_progress(p_subject_id integer) OWNER TO postgres;

--
-- TOC entry 599 (class 1255 OID 18669)
-- Name: get_current_student_id(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_current_student_id() RETURNS integer
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $$
  SELECT app_entity_id::INTEGER
  FROM public.app_user
  WHERE auth_user_id = auth.uid()
    AND user_type = 'student'
  LIMIT 1;
$$;


ALTER FUNCTION public.get_current_student_id() OWNER TO postgres;

--
-- TOC entry 545 (class 1255 OID 17580)
-- Name: get_dashboard_stats_with_context(integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_dashboard_stats_with_context(p_user_id integer, p_user_type text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  r JSONB;
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  SELECT jsonb_build_object(
    'totalStudents', (SELECT COUNT(*)::int FROM students WHERE deleted_at IS NULL),
    'totalTeachers', (SELECT COUNT(*)::int FROM teachers WHERE deleted_at IS NULL),
    'totalSubjects', (SELECT COUNT(*)::int FROM subjects WHERE is_active = true),
    'totalQuestions', (SELECT COUNT(*)::int FROM questions WHERE is_active = true AND status = 'approved'),
    'pendingExams', (SELECT COUNT(*)::int FROM pending_content WHERE content_type = 'exam' AND status = 'pending'),
    'unreadMessages', (SELECT COUNT(*)::int FROM messages WHERE is_read = false AND sender_parent_id IS NOT NULL)
  ) INTO r;
  RETURN r;
END;
$$;


ALTER FUNCTION public.get_dashboard_stats_with_context(p_user_id integer, p_user_type text) OWNER TO postgres;

--
-- TOC entry 337 (class 1259 OID 17581)
-- Name: exam_questions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exam_questions (
    id integer NOT NULL,
    exam_id integer NOT NULL,
    question_id integer NOT NULL,
    question_order integer NOT NULL,
    marks numeric(5,2) DEFAULT 1.0 NOT NULL,
    added_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_question_marks CHECK ((marks > (0)::numeric))
);


ALTER TABLE public.exam_questions OWNER TO postgres;

--
-- TOC entry 546 (class 1255 OID 17587)
-- Name: get_exam_questions_with_context(integer, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_exam_questions_with_context(p_user_id integer, p_user_type text, p_exam_id integer) RETURNS SETOF public.exam_questions
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY SELECT * FROM exam_questions WHERE exam_id = p_exam_id ORDER BY question_order;
END;
$$;


ALTER FUNCTION public.get_exam_questions_with_context(p_user_id integer, p_user_type text, p_exam_id integer) OWNER TO postgres;

--
-- TOC entry 338 (class 1259 OID 17588)
-- Name: exams; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exams (
    id integer NOT NULL,
    title character varying(200) NOT NULL,
    description text,
    subject_id integer NOT NULL,
    grade_id integer NOT NULL,
    section_id integer NOT NULL,
    semester_id integer NOT NULL,
    total_marks integer DEFAULT 0 NOT NULL,
    passing_marks integer DEFAULT 0 NOT NULL,
    duration_minutes integer,
    difficulty_level public.difficulty_level_enum,
    pdf_content bytea,
    pdf_filename character varying(255),
    pdf_size integer,
    created_by_admin integer,
    created_by_teacher integer,
    status public.exam_status_enum DEFAULT 'draft'::public.exam_status_enum,
    scheduled_at timestamp with time zone,
    published_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    pdf_url text,
    pdf_storage_path text,
    CONSTRAINT chk_exam_creator CHECK ((((created_by_admin IS NOT NULL) AND (created_by_teacher IS NULL)) OR ((created_by_admin IS NULL) AND (created_by_teacher IS NOT NULL)))),
    CONSTRAINT chk_exam_marks CHECK ((passing_marks <= total_marks)),
    CONSTRAINT chk_pdf_url_valid CHECK (((pdf_url IS NULL) OR (pdf_url ~* '^https?://'::text)))
);


ALTER TABLE public.exams OWNER TO postgres;

--
-- TOC entry 4712 (class 0 OID 0)
-- Dependencies: 338
-- Name: COLUMN exams.pdf_url; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.exams.pdf_url IS 'Private URL from Supabase Storage (with signed URL)';


--
-- TOC entry 4713 (class 0 OID 0)
-- Dependencies: 338
-- Name: COLUMN exams.pdf_storage_path; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.exams.pdf_storage_path IS 'Storage path: exam-files/{exam_id}/{filename}';


--
-- TOC entry 547 (class 1255 OID 17601)
-- Name: get_exams_with_context(integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_exams_with_context(p_user_id integer, p_user_type text) RETURNS SETOF public.exams
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY SELECT * FROM exams ORDER BY created_at DESC;
END;
$$;


ALTER FUNCTION public.get_exams_with_context(p_user_id integer, p_user_type text) OWNER TO postgres;

--
-- TOC entry 339 (class 1259 OID 17602)
-- Name: grades; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.grades (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    grade_order integer NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.grades OWNER TO postgres;

--
-- TOC entry 548 (class 1255 OID 17610)
-- Name: get_grades_with_context(integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_grades_with_context(p_user_id integer, p_user_type text) RETURNS SETOF public.grades
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY SELECT * FROM grades WHERE is_active = true ORDER BY grade_order;
END;
$$;


ALTER FUNCTION public.get_grades_with_context(p_user_id integer, p_user_type text) OWNER TO postgres;

--
-- TOC entry 340 (class 1259 OID 17611)
-- Name: messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.messages (
    id integer NOT NULL,
    sender_admin_id integer,
    sender_parent_id integer,
    recipient_admin_id integer,
    recipient_parent_id integer,
    subject character varying(200),
    message_text text NOT NULL,
    is_read boolean DEFAULT false,
    read_at timestamp with time zone,
    sent_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    sender_teacher_id integer,
    recipient_teacher_id integer,
    CONSTRAINT chk_message_recipient CHECK ((((recipient_admin_id IS NOT NULL) AND (recipient_parent_id IS NULL)) OR ((recipient_admin_id IS NULL) AND (recipient_parent_id IS NOT NULL)))),
    CONSTRAINT chk_message_sender CHECK ((((sender_admin_id IS NOT NULL) AND (sender_parent_id IS NULL)) OR ((sender_admin_id IS NULL) AND (sender_parent_id IS NOT NULL))))
);


ALTER TABLE public.messages OWNER TO postgres;

--
-- TOC entry 549 (class 1255 OID 17620)
-- Name: get_messages_for_admin_with_context(integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_messages_for_admin_with_context(p_user_id integer, p_user_type text) RETURNS SETOF public.messages
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY SELECT * FROM messages WHERE recipient_admin_id = p_user_id OR sender_admin_id = p_user_id ORDER BY sent_at DESC;
END;
$$;


ALTER FUNCTION public.get_messages_for_admin_with_context(p_user_id integer, p_user_type text) OWNER TO postgres;

--
-- TOC entry 550 (class 1255 OID 17621)
-- Name: get_parent_students_with_context(integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_parent_students_with_context(p_user_id integer, p_user_type text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  r JSONB;
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);

  SELECT COALESCE(jsonb_agg(row_to_json(t)::jsonb), '[]'::jsonb) INTO r
  FROM (
    SELECT
      ps.id,
      ps.parent_id,
      ps.student_id,
      ps.relationship,
      ps.linked_at,
      jsonb_build_object(
        'id', p.id,
        'full_name', p.full_name,
        'phone_number', p.phone_number,
        'email', p.email
      ) AS parent,
      jsonb_build_object(
        'id', s.id,
        'student_code', s.student_code,
        'full_name', s.full_name
      ) AS student
    FROM parent_students ps
    JOIN parents p ON p.id = ps.parent_id
    JOIN students s ON s.id = ps.student_id
    ORDER BY ps.linked_at DESC NULLS LAST, ps.id DESC
  ) t;

  RETURN r;
END;
$$;


ALTER FUNCTION public.get_parent_students_with_context(p_user_id integer, p_user_type text) OWNER TO postgres;

--
-- TOC entry 341 (class 1259 OID 17622)
-- Name: parents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.parents (
    id integer NOT NULL,
    full_name character varying(100) NOT NULL,
    phone_number character varying(20) NOT NULL,
    email character varying(100),
    password_hash character varying(255) NOT NULL,
    is_active boolean DEFAULT true,
    last_login_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.parents OWNER TO postgres;

--
-- TOC entry 551 (class 1255 OID 17628)
-- Name: get_parents_by_student_with_context(integer, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_parents_by_student_with_context(p_user_id integer, p_user_type text, p_student_id integer) RETURNS SETOF public.parents
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);

  RETURN QUERY
  SELECT p.*
  FROM parents p
  JOIN parent_students ps ON ps.parent_id = p.id
  WHERE ps.student_id = p_student_id
  AND p.is_active = true
  ORDER BY p.full_name;
END;
$$;


ALTER FUNCTION public.get_parents_by_student_with_context(p_user_id integer, p_user_type text, p_student_id integer) OWNER TO postgres;

--
-- TOC entry 552 (class 1255 OID 17629)
-- Name: get_parents_with_context(integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_parents_with_context(p_user_id integer, p_user_type text) RETURNS SETOF public.parents
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY SELECT * FROM parents WHERE is_active = true ORDER BY full_name;
END;
$$;


ALTER FUNCTION public.get_parents_with_context(p_user_id integer, p_user_type text) OWNER TO postgres;

--
-- TOC entry 342 (class 1259 OID 17630)
-- Name: pending_content; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pending_content (
    id integer NOT NULL,
    content_type public.pending_content_type_enum NOT NULL,
    content_data jsonb NOT NULL,
    teacher_id integer NOT NULL,
    status public.approval_status_enum DEFAULT 'pending'::public.approval_status_enum,
    reviewed_by integer,
    reviewed_at timestamp with time zone,
    rejection_reason text,
    submitted_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_pending_rejection CHECK ((((status = 'rejected'::public.approval_status_enum) AND (rejection_reason IS NOT NULL)) OR (status <> 'rejected'::public.approval_status_enum)))
);


ALTER TABLE public.pending_content OWNER TO postgres;

--
-- TOC entry 553 (class 1255 OID 17638)
-- Name: get_pending_exams_with_context(integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_pending_exams_with_context(p_user_id integer, p_user_type text) RETURNS SETOF public.pending_content
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY SELECT * FROM pending_content WHERE content_type = 'exam' AND status = 'pending' ORDER BY submitted_at DESC;
END;
$$;


ALTER FUNCTION public.get_pending_exams_with_context(p_user_id integer, p_user_type text) OWNER TO postgres;

--
-- TOC entry 554 (class 1255 OID 17639)
-- Name: get_pending_questions_with_context(integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_pending_questions_with_context(p_user_id integer, p_user_type text) RETURNS SETOF public.pending_content
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY SELECT * FROM pending_content WHERE content_type = 'question' AND status = 'pending' ORDER BY submitted_at DESC;
END;
$$;


ALTER FUNCTION public.get_pending_questions_with_context(p_user_id integer, p_user_type text) OWNER TO postgres;

--
-- TOC entry 612 (class 1255 OID 20991)
-- Name: get_questions_for_explanation(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_questions_for_explanation(p_chapter_id integer DEFAULT NULL::integer, p_subject_id integer DEFAULT NULL::integer, p_limit integer DEFAULT 20) RETURNS TABLE(id integer, question_text text, question_type character varying, question_options jsonb, correct_answer character varying, explanation text, skill character varying, reference_page character varying, difficulty_level character varying, chapter_id integer, subject_id integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$BEGIN
    -- Validate student authentication
    IF public.get_current_student_id() IS NULL THEN
        RAISE EXCEPTION 'Not authenticated as student';
    END IF;

    RETURN QUERY
    SELECT
        q.id,
        q.question_text,
        q.question_type::VARCHAR(50),
        q.question_options,
        q.correct_answer::VARCHAR(10),
        q.explanation,
        q.skill,
        q.reference_page,
        q.difficulty_level::VARCHAR(20),
        q.chapter_id,
        q.subject_id
    FROM public.questions q
    WHERE q.is_active    = true
      AND q.status       = 'approved'
      AND q.explanation  IS NOT NULL
      AND q.explanation  != ''
      AND (p_chapter_id IS NULL OR q.chapter_id = p_chapter_id)
      AND (p_subject_id IS NULL OR q.subject_id = p_subject_id)
    ORDER BY RANDOM()
    LIMIT p_limit;
END;$$;


ALTER FUNCTION public.get_questions_for_explanation(p_chapter_id integer, p_subject_id integer, p_limit integer) OWNER TO postgres;

--
-- TOC entry 343 (class 1259 OID 17640)
-- Name: questions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.questions (
    id integer NOT NULL,
    question_text text NOT NULL,
    question_type public.question_type_enum NOT NULL,
    question_options jsonb,
    correct_answer text,
    difficulty_level public.difficulty_level_enum NOT NULL,
    subject_id integer NOT NULL,
    created_by_admin integer,
    created_by_teacher integer,
    status public.approval_status_enum DEFAULT 'approved'::public.approval_status_enum,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    pdf_url text,
    pdf_storage_path text,
    pdf_filename character varying(255),
    chapter_id integer,
    times_used integer DEFAULT 0,
    times_correct integer DEFAULT 0,
    times_incorrect integer DEFAULT 0,
    difficulty_index numeric(3,2) DEFAULT 0.50,
    discrimination_index numeric(3,2) DEFAULT 0.30,
    quality character varying(50),
    explanation text,
    skill character varying(50),
    reference_page character varying(100),
    CONSTRAINT chk_question_creator CHECK ((((created_by_admin IS NOT NULL) AND (created_by_teacher IS NULL)) OR ((created_by_admin IS NULL) AND (created_by_teacher IS NOT NULL)))),
    CONSTRAINT chk_question_options_required CHECK ((((question_type = ANY (ARRAY['multiple_choice'::public.question_type_enum, 'true_false'::public.question_type_enum])) AND (question_options IS NOT NULL)) OR (question_type = ANY (ARRAY['essay'::public.question_type_enum, 'fill_blank'::public.question_type_enum]))))
);


ALTER TABLE public.questions OWNER TO postgres;

--
-- TOC entry 4728 (class 0 OID 0)
-- Dependencies: 343
-- Name: COLUMN questions.explanation; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.questions.explanation IS 'Explanation shown after wrong answer (Student app)';


--
-- TOC entry 4729 (class 0 OID 0)
-- Dependencies: 343
-- Name: COLUMN questions.skill; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.questions.skill IS 'Bloom taxonomy: remember, understand, apply, analyze';


--
-- TOC entry 4730 (class 0 OID 0)
-- Dependencies: 343
-- Name: COLUMN questions.reference_page; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.questions.reference_page IS 'Book/page reference for study';


--
-- TOC entry 602 (class 1255 OID 18672)
-- Name: get_questions_for_quiz(integer, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_questions_for_quiz(p_chapter_id integer, p_count integer DEFAULT 10, p_difficulty text DEFAULT NULL::text) RETURNS SETOF public.questions
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM public.questions q
  WHERE q.chapter_id = p_chapter_id
    AND q.is_active = true
    AND q.status = 'approved'
    AND q.question_type IN ('multiple_choice', 'true_false')
    AND (p_difficulty IS NULL OR q.difficulty_level::TEXT = p_difficulty)
  ORDER BY RANDOM()
  LIMIT p_count;
END;
$$;


ALTER FUNCTION public.get_questions_for_quiz(p_chapter_id integer, p_count integer, p_difficulty text) OWNER TO postgres;

--
-- TOC entry 555 (class 1255 OID 17656)
-- Name: get_questions_with_context(integer, text, text, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_questions_with_context(p_user_id integer, p_user_type text, p_type text DEFAULT NULL::text, p_difficulty text DEFAULT NULL::text, p_subject_id integer DEFAULT NULL::integer) RETURNS SETOF public.questions
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY
  SELECT * FROM questions q
  WHERE q.is_active = true AND q.status = 'approved'
  AND (p_type IS NULL OR p_type = 'كل' OR q.question_type::text = p_type)
  AND (p_difficulty IS NULL OR p_difficulty = 'كل' OR q.difficulty_level::text = p_difficulty)
  AND (p_subject_id IS NULL OR q.subject_id = p_subject_id)
  ORDER BY q.created_at DESC;
END;
$$;


ALTER FUNCTION public.get_questions_with_context(p_user_id integer, p_user_type text, p_type text, p_difficulty text, p_subject_id integer) OWNER TO postgres;

--
-- TOC entry 556 (class 1255 OID 17657)
-- Name: get_reports_grades_with_context(integer, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_reports_grades_with_context(p_user_id integer, p_user_type text, p_grade_id integer DEFAULT NULL::integer) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  r JSONB;
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  SELECT COALESCE(jsonb_agg(row_to_json(t)::jsonb), '[]'::jsonb) INTO r
  FROM (
    SELECT s.id AS student_id, s.student_code, s.full_name, s.phone_number, s.email, s.section_id,
           (SELECT ROUND(AVG(er.percentage)::numeric, 2) FROM exam_results er WHERE er.student_id = s.id AND er.status = 'completed') AS average_percentage
    FROM students s
    WHERE s.deleted_at IS NULL
    AND (p_grade_id IS NULL OR s.section_id IN (SELECT id FROM sections WHERE grade_id = p_grade_id AND is_active = true))
  ) t;
  RETURN r;
END;
$$;


ALTER FUNCTION public.get_reports_grades_with_context(p_user_id integer, p_user_type text, p_grade_id integer) OWNER TO postgres;

--
-- TOC entry 344 (class 1259 OID 17658)
-- Name: reports; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reports (
    id integer NOT NULL,
    student_id integer NOT NULL,
    parent_id integer NOT NULL,
    title character varying(200) NOT NULL,
    report_text text NOT NULL,
    sent_by integer NOT NULL,
    sent_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    is_read boolean DEFAULT false,
    read_at timestamp with time zone
);


ALTER TABLE public.reports OWNER TO postgres;

--
-- TOC entry 557 (class 1255 OID 17665)
-- Name: get_reports_with_context(integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_reports_with_context(p_user_id integer, p_user_type text) RETURNS SETOF public.reports
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY SELECT * FROM reports ORDER BY sent_at DESC;
END;
$$;


ALTER FUNCTION public.get_reports_with_context(p_user_id integer, p_user_type text) OWNER TO postgres;

--
-- TOC entry 558 (class 1255 OID 17666)
-- Name: get_reports_with_names_and_context(integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_reports_with_names_and_context(p_user_id integer, p_user_type text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  r JSONB;
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);

  SELECT COALESCE(jsonb_agg(row_to_json(t)::jsonb), '[]'::jsonb) INTO r
  FROM (
    SELECT
      rep.id,
      rep.student_id,
      rep.parent_id,
      rep.title,
      rep.report_text,
      rep.sent_by,
      rep.sent_at,
      rep.is_read,
      rep.read_at,
      COALESCE(s.full_name, 'الطالب #' || rep.student_id) AS student_name,
      COALESCE(p.full_name, 'ولي الأمر #' || rep.parent_id) AS parent_name
    FROM reports rep
    LEFT JOIN students s ON s.id = rep.student_id
    LEFT JOIN parents p ON p.id = rep.parent_id
    ORDER BY rep.sent_at DESC
  ) t;

  RETURN r;
END;
$$;


ALTER FUNCTION public.get_reports_with_names_and_context(p_user_id integer, p_user_type text) OWNER TO postgres;

--
-- TOC entry 345 (class 1259 OID 17667)
-- Name: section_subjects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.section_subjects (
    id integer NOT NULL,
    section_id integer NOT NULL,
    subject_id integer NOT NULL,
    teacher_id integer NOT NULL,
    is_active boolean DEFAULT true,
    assigned_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.section_subjects OWNER TO postgres;

--
-- TOC entry 559 (class 1255 OID 17673)
-- Name: get_section_subjects_by_grade_with_context(integer, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_section_subjects_by_grade_with_context(p_user_id integer, p_user_type text, p_grade_id integer) RETURNS SETOF public.section_subjects
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY
  SELECT ss.* FROM section_subjects ss
  JOIN sections s ON s.id = ss.section_id
  WHERE s.grade_id = p_grade_id AND ss.is_active = true;
END;
$$;


ALTER FUNCTION public.get_section_subjects_by_grade_with_context(p_user_id integer, p_user_type text, p_grade_id integer) OWNER TO postgres;

--
-- TOC entry 560 (class 1255 OID 17674)
-- Name: get_section_subjects_by_teacher_with_context(integer, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_section_subjects_by_teacher_with_context(p_user_id integer, p_user_type text, p_teacher_id integer) RETURNS SETOF public.section_subjects
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY
  SELECT * FROM section_subjects
  WHERE teacher_id = p_teacher_id AND is_active = true
  ORDER BY section_id, subject_id;
END;
$$;


ALTER FUNCTION public.get_section_subjects_by_teacher_with_context(p_user_id integer, p_user_type text, p_teacher_id integer) OWNER TO postgres;

--
-- TOC entry 561 (class 1255 OID 17675)
-- Name: get_section_subjects_with_names_by_grade_with_context(integer, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_section_subjects_with_names_by_grade_with_context(p_user_id integer, p_user_type text, p_grade_id integer) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  r JSONB;
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);

  SELECT COALESCE(jsonb_agg(row_to_json(t)::jsonb), '[]'::jsonb) INTO r
  FROM (
    SELECT
      ss.id,
      ss.section_id,
      ss.subject_id,
      ss.teacher_id,
      ss.is_active,
      ss.assigned_at,
      ss.updated_at,
      COALESCE(subj.name, 'المادة #' || ss.subject_id) AS subject_name,
      COALESCE(t.full_name, 'المعلم #' || ss.teacher_id) AS teacher_name,
      sec.name AS section_name
    FROM section_subjects ss
    JOIN sections sec ON sec.id = ss.section_id AND sec.grade_id = p_grade_id
    LEFT JOIN subjects subj ON subj.id = ss.subject_id
    LEFT JOIN teachers t ON t.id = ss.teacher_id AND t.deleted_at IS NULL
    WHERE ss.is_active = true
    ORDER BY sec.name, subj.name
  ) t;

  RETURN r;
END;
$$;


ALTER FUNCTION public.get_section_subjects_with_names_by_grade_with_context(p_user_id integer, p_user_type text, p_grade_id integer) OWNER TO postgres;

--
-- TOC entry 346 (class 1259 OID 17676)
-- Name: sections; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sections (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    grade_id integer NOT NULL,
    capacity integer,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.sections OWNER TO postgres;

--
-- TOC entry 562 (class 1255 OID 17682)
-- Name: get_sections_with_context(integer, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_sections_with_context(p_user_id integer, p_user_type text, p_grade_id integer) RETURNS SETOF public.sections
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY SELECT * FROM sections WHERE grade_id = p_grade_id AND is_active = true ORDER BY name;
END;
$$;


ALTER FUNCTION public.get_sections_with_context(p_user_id integer, p_user_type text, p_grade_id integer) OWNER TO postgres;

--
-- TOC entry 347 (class 1259 OID 17683)
-- Name: semesters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.semesters (
    id integer NOT NULL,
    semester_type public.semester_type_enum NOT NULL,
    name character varying(50) NOT NULL,
    start_date date,
    end_date date,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.semesters OWNER TO postgres;

--
-- TOC entry 563 (class 1255 OID 17688)
-- Name: get_semesters_with_context(integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_semesters_with_context(p_user_id integer, p_user_type text) RETURNS SETOF public.semesters
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY SELECT * FROM semesters WHERE is_active = true ORDER BY semester_type;
END;
$$;


ALTER FUNCTION public.get_semesters_with_context(p_user_id integer, p_user_type text) OWNER TO postgres;

--
-- TOC entry 605 (class 1255 OID 18675)
-- Name: get_student_analytics(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_student_analytics() RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
DECLARE
    v_student_id INTEGER;
    r            JSONB;
BEGIN
    v_student_id := public.get_current_student_id();
    IF v_student_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated as student';
    END IF;

    SELECT jsonb_build_object(

        -- ── Core stats ──────────────────────────────────────────────────────────
        'totalQuizzes',
        (SELECT COUNT(*)
         FROM public.practice_quiz_attempts
         WHERE student_id = v_student_id),

        'averageScore',
        (SELECT ROUND(AVG(score::NUMERIC / NULLIF(total_questions, 0) * 100), 2)
         FROM public.practice_quiz_attempts
         WHERE student_id = v_student_id),

        'totalTimeSpent',
        (SELECT COALESCE(SUM(time_taken_seconds), 0)
         FROM public.practice_quiz_attempts
         WHERE student_id = v_student_id),

        -- ── streakDays ──────────────────────────────────────────────────────────
        -- Count consecutive days (backward from today) that have at least 1 attempt
        -- FIX: use (rn - 1) so row 1 maps to CURRENT_DATE, row 2 to CURRENT_DATE-1, etc.
        'streakDays',
        (WITH daily AS (
            SELECT DISTINCT (completed_at AT TIME ZONE 'UTC')::DATE AS day
            FROM   public.practice_quiz_attempts
            WHERE  student_id = v_student_id
        ),
        numbered AS (
            SELECT day,
                   ROW_NUMBER() OVER (ORDER BY day DESC) AS rn
            FROM daily
        ),
        streak AS (
            SELECT day,
                   (CURRENT_DATE - ((rn - 1) * INTERVAL '1 day'))::DATE AS expected
            FROM numbered
        )
        SELECT COALESCE(COUNT(*), 0)
        FROM streak
        WHERE day = expected),

        -- ── subjectPerformance ──────────────────────────────────────────────────
        'subjectPerformance',
        (SELECT COALESCE(
            jsonb_agg(
                row_to_json(t)::jsonb
                ORDER BY (row_to_json(t)->>'quizzes')::int DESC
            ),
            '[]'::jsonb
         )
         FROM (
             SELECT
                 s.name,
                 ROUND(AVG(pqa.score::NUMERIC / NULLIF(pqa.total_questions, 0) * 100), 2) AS score,
                 COUNT(*) AS quizzes
             FROM   public.practice_quiz_attempts pqa
             JOIN   public.subjects s ON s.id = pqa.subject_id
             WHERE  pqa.student_id = v_student_id
             GROUP  BY s.id, s.name
         ) t),

        -- ── performanceHistory (last 30 days, grouped by date) ──────────────────
        'performanceHistory',
        (SELECT COALESCE(
            jsonb_agg(
                row_to_json(t)::jsonb
                ORDER BY (row_to_json(t)->>'date') ASC
            ),
            '[]'::jsonb
         )
         FROM (
             SELECT
                 (completed_at AT TIME ZONE 'UTC')::DATE::TEXT AS date,
                 ROUND(AVG(score::NUMERIC / NULLIF(total_questions, 0) * 100), 2) AS score,
                 COUNT(*) AS quizzes
             FROM   public.practice_quiz_attempts
             WHERE  student_id  = v_student_id
               AND  completed_at >= NOW() - INTERVAL '30 days'
             GROUP  BY (completed_at AT TIME ZONE 'UTC')::DATE
         ) t),

        -- ── weakTopics ──────────────────────────────────────────────────────────
        -- Chapters where accuracy < 60% with at least 3 answer attempts
        -- FIX: added WHERE pqa.chapter_id IS NOT NULL to exclude
        --      subject-level quizzes (no chapter) from weak topic detection
        'weakTopics',
        (SELECT COALESCE(
            jsonb_agg(
                row_to_json(t)::jsonb
                ORDER BY (row_to_json(t)->>'accuracy')::numeric ASC
            ),
            '[]'::jsonb
         )
         FROM (
             SELECT
                 c.name        AS chapter,
                 s.name        AS subject,
                 pqa.chapter_id,
                 COUNT(pqans.id) AS attempts,
                 ROUND(
                     SUM(CASE WHEN pqans.is_correct THEN 1 ELSE 0 END)::NUMERIC
                     / NULLIF(COUNT(pqans.id), 0) * 100
                 , 2) AS accuracy
             FROM   public.practice_quiz_attempts  pqa
             JOIN   public.practice_quiz_answers   pqans ON pqans.attempt_id = pqa.id
             JOIN   public.chapters  c ON c.id = pqa.chapter_id
             JOIN   public.subjects  s ON s.id = pqa.subject_id
             WHERE  pqa.student_id   = v_student_id
               AND  pqa.chapter_id  IS NOT NULL   -- FIX: exclude quizzes with no chapter
             GROUP  BY c.id, c.name, s.name, pqa.chapter_id
             HAVING COUNT(pqans.id) >= 3
                AND ROUND(
                        SUM(CASE WHEN pqans.is_correct THEN 1 ELSE 0 END)::NUMERIC
                        / NULLIF(COUNT(pqans.id), 0) * 100
                    , 2) < 60
         ) t),

        -- ── masteryLevels (by Bloom skill) ──────────────────────────────────────
        'masteryLevels',
        (SELECT COALESCE(jsonb_agg(row_to_json(t)::jsonb), '[]'::jsonb)
         FROM (
             SELECT
                 COALESCE(q.skill, 'unknown') AS skill,
                 ROUND(
                     SUM(CASE WHEN pqans.is_correct THEN 1 ELSE 0 END)::NUMERIC
                     / NULLIF(COUNT(pqans.id), 0) * 100
                 , 2) AS accuracy,
                 COUNT(pqans.id) AS total_answers
             FROM   public.practice_quiz_answers  pqans
             JOIN   public.practice_quiz_attempts pqa ON pqa.id = pqans.attempt_id
             JOIN   public.questions q ON q.id = pqans.question_id
             WHERE  pqa.student_id = v_student_id
             GROUP  BY q.skill
         ) t)

    ) INTO r;

    RETURN COALESCE(r, '{}'::jsonb);
END;
$$;


ALTER FUNCTION public.get_student_analytics() OWNER TO postgres;

--
-- TOC entry 564 (class 1255 OID 17689)
-- Name: get_student_count_by_section_with_context(integer, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_student_count_by_section_with_context(p_user_id integer, p_user_type text, p_section_id integer) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_count INTEGER;
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  SELECT COUNT(*)::integer INTO v_count
  FROM students
  WHERE section_id = p_section_id AND deleted_at IS NULL;
  RETURN COALESCE(v_count, 0);
END;
$$;


ALTER FUNCTION public.get_student_count_by_section_with_context(p_user_id integer, p_user_type text, p_section_id integer) OWNER TO postgres;

--
-- TOC entry 565 (class 1255 OID 17690)
-- Name: get_student_details_with_context(integer, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_student_details_with_context(p_user_id integer, p_user_type text, p_student_id integer) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_student students%ROWTYPE;
  v_result JSONB;
  v_results JSONB := '[]'::jsonb;
  r RECORD;
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  SELECT * INTO v_student FROM students WHERE id = p_student_id AND deleted_at IS NULL;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'الطالب غير موجود';
  END IF;

  FOR r IN
    SELECT er.id AS er_id, er.student_id, er.exam_id, er.obtained_marks, er.total_marks, er.percentage, er.status, er.submitted_at, er.started_at,
           e.id AS e_id, e.title AS exam_title, e.subject_id,
           s.id AS s_id, s.name AS subject_name
    FROM exam_results er
    JOIN exams e ON e.id = er.exam_id
    JOIN subjects s ON s.id = e.subject_id
    WHERE er.student_id = p_student_id AND er.status = 'completed'
    ORDER BY er.submitted_at DESC
  LOOP
    v_results := v_results || jsonb_build_object(
      'exam', jsonb_build_object('id', r.e_id, 'title', r.exam_title, 'subject_id', r.subject_id),
      'result', jsonb_build_object('id', r.er_id, 'student_id', r.student_id, 'exam_id', r.exam_id, 'obtained_marks', r.obtained_marks, 'total_marks', r.total_marks, 'percentage', r.percentage, 'status', r.status, 'submitted_at', r.submitted_at, 'started_at', r.started_at),
      'subject', jsonb_build_object('id', r.s_id, 'name', r.subject_name)
    );
  END LOOP;

  v_result := jsonb_build_object(
    'student', to_jsonb(v_student),
    'results', v_results
  );
  RETURN v_result;
END;
$$;


ALTER FUNCTION public.get_student_details_with_context(p_user_id integer, p_user_type text, p_student_id integer) OWNER TO postgres;

--
-- TOC entry 606 (class 1255 OID 18676)
-- Name: get_student_profile(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_student_profile() RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
DECLARE
  v_student_id INTEGER;
  r JSONB;
BEGIN
  v_student_id := public.get_current_student_id();
  IF v_student_id IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT jsonb_build_object(
    'id', s.id,
    'full_name', s.full_name,
    'email', s.email,
    'profile_image_url', s.profile_image_url
  ) INTO r
  FROM public.students s
  WHERE s.id = v_student_id AND s.deleted_at IS NULL;

  RETURN r;
END;
$$;


ALTER FUNCTION public.get_student_profile() OWNER TO postgres;

--
-- TOC entry 604 (class 1255 OID 18674)
-- Name: get_student_quiz_history(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_student_quiz_history(p_limit integer DEFAULT 50) RETURNS TABLE(id integer, subject_name character varying, chapter_name character varying, score integer, total_questions integer, percentage numeric, completed_at timestamp with time zone, time_taken_seconds integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
DECLARE
  v_student_id INTEGER;
BEGIN
  v_student_id := public.get_current_student_id();
  IF v_student_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated as student';
  END IF;

  RETURN QUERY
  SELECT
    pqa.id,
    s.name AS subject_name,
    COALESCE(c.name, '') AS chapter_name,
    pqa.score,
    pqa.total_questions,
    ROUND((pqa.score::NUMERIC / NULLIF(pqa.total_questions, 0) * 100), 2) AS percentage,
    pqa.completed_at,
    pqa.time_taken_seconds
  FROM public.practice_quiz_attempts pqa
  JOIN public.subjects s ON s.id = pqa.subject_id
  LEFT JOIN public.chapters c ON c.id = pqa.chapter_id
  WHERE pqa.student_id = v_student_id
  ORDER BY pqa.completed_at DESC
  LIMIT p_limit;
END;
$$;


ALTER FUNCTION public.get_student_quiz_history(p_limit integer) OWNER TO postgres;

--
-- TOC entry 609 (class 1255 OID 20988)
-- Name: get_student_summaries(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_student_summaries(p_limit integer DEFAULT 50) RETURNS TABLE(id integer, subject_name character varying, chapter_name text, title character varying, content text, summary_type character varying, created_at timestamp with time zone, subject_id integer, chapter_id integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
DECLARE
    v_student_id INTEGER;
BEGIN
    v_student_id := public.get_current_student_id();
    IF v_student_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated as student';
    END IF;

    RETURN QUERY
    SELECT
        ss.id,
        s.name::VARCHAR(100)       AS subject_name,
        COALESCE(c.name, '')::TEXT AS chapter_name,
        ss.title,
        ss.content,
        ss.summary_type,
        ss.created_at,
        ss.subject_id,
        ss.chapter_id
    FROM public.student_summaries ss
    JOIN  public.subjects  s ON s.id = ss.subject_id
    LEFT JOIN public.chapters c ON c.id = ss.chapter_id
    WHERE ss.student_id = v_student_id
    ORDER BY ss.created_at DESC
    LIMIT p_limit;
END;
$$;


ALTER FUNCTION public.get_student_summaries(p_limit integer) OWNER TO postgres;

--
-- TOC entry 348 (class 1259 OID 17691)
-- Name: students; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.students (
    id integer NOT NULL,
    student_code integer NOT NULL,
    full_name character varying(100) NOT NULL,
    phone_number character varying(20),
    email character varying(100),
    profile_image bytea,
    profile_image_filename character varying(255),
    profile_image_mime_type character varying(50),
    profile_image_size integer,
    section_id integer,
    password_hash character varying(255) NOT NULL,
    is_active boolean DEFAULT true,
    last_login_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamp with time zone,
    deleted_by integer,
    profile_image_url text,
    profile_image_storage_path text,
    CONSTRAINT chk_profile_url_valid CHECK (((profile_image_url IS NULL) OR (profile_image_url ~* '^https?://'::text)))
);


ALTER TABLE public.students OWNER TO postgres;

--
-- TOC entry 4752 (class 0 OID 0)
-- Dependencies: 348
-- Name: COLUMN students.profile_image_url; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.students.profile_image_url IS 'Public URL from Supabase Storage';


--
-- TOC entry 4753 (class 0 OID 0)
-- Dependencies: 348
-- Name: COLUMN students.profile_image_storage_path; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.students.profile_image_storage_path IS 'Storage path: profile-images/students/{student_id}/{filename}';


--
-- TOC entry 566 (class 1255 OID 17700)
-- Name: get_students_with_context(integer, text, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_students_with_context(p_user_id integer, p_user_type text, p_search text DEFAULT NULL::text, p_grade_id integer DEFAULT NULL::integer) RETURNS SETOF public.students
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY
  SELECT s.* FROM students s
  WHERE s.deleted_at IS NULL
  AND (p_search IS NULL OR s.full_name ILIKE '%' || p_search || '%' OR s.student_code::TEXT = p_search)
  AND (p_grade_id IS NULL OR s.section_id IN (SELECT id FROM sections WHERE grade_id = p_grade_id AND is_active = true))
  ORDER BY s.created_at DESC;
END;
$$;


ALTER FUNCTION public.get_students_with_context(p_user_id integer, p_user_type text, p_search text, p_grade_id integer) OWNER TO postgres;

--
-- TOC entry 349 (class 1259 OID 17701)
-- Name: subjects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subjects (
    id integer NOT NULL,
    subject_code integer NOT NULL,
    name character varying(100) NOT NULL,
    pdf_content bytea,
    pdf_filename character varying(255),
    pdf_size integer,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    pdf_url text,
    pdf_storage_path text,
    icon character varying(10),
    color character varying(20),
    CONSTRAINT chk_pdf_url_valid CHECK (((pdf_url IS NULL) OR (pdf_url ~* '^https?://'::text)))
);


ALTER TABLE public.subjects OWNER TO postgres;

--
-- TOC entry 4756 (class 0 OID 0)
-- Dependencies: 349
-- Name: COLUMN subjects.pdf_url; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.subjects.pdf_url IS 'Public/Private URL from Supabase Storage';


--
-- TOC entry 4757 (class 0 OID 0)
-- Dependencies: 349
-- Name: COLUMN subjects.pdf_storage_path; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.subjects.pdf_storage_path IS 'Storage path: subject-materials/{subject_id}/{filename}';


--
-- TOC entry 4758 (class 0 OID 0)
-- Dependencies: 349
-- Name: COLUMN subjects.icon; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.subjects.icon IS 'Emoji or icon identifier for UI';


--
-- TOC entry 4759 (class 0 OID 0)
-- Dependencies: 349
-- Name: COLUMN subjects.color; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.subjects.color IS 'Hex color for UI (e.g. 0xFF6C63FF)';


--
-- TOC entry 600 (class 1255 OID 18670)
-- Name: get_subjects_for_student(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_subjects_for_student() RETURNS SETOF public.subjects
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
DECLARE
  v_student_id INTEGER;
  v_section_id INTEGER;
BEGIN
  v_student_id := public.get_current_student_id();
  IF v_student_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated as student';
  END IF;

  SELECT section_id INTO v_section_id
  FROM public.students
  WHERE id = v_student_id AND deleted_at IS NULL;

  IF v_section_id IS NULL THEN
    RETURN;  -- No section assigned
  END IF;

  RETURN QUERY
  SELECT s.*
  FROM public.subjects s
  JOIN public.section_subjects ss ON ss.subject_id = s.id
  WHERE ss.section_id = v_section_id
    AND ss.is_active = true
    AND s.is_active = true
  ORDER BY s.name;
END;
$$;


ALTER FUNCTION public.get_subjects_for_student() OWNER TO postgres;

--
-- TOC entry 567 (class 1255 OID 17710)
-- Name: get_subjects_with_context(integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_subjects_with_context(p_user_id integer, p_user_type text) RETURNS SETOF public.subjects
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY SELECT * FROM subjects WHERE is_active = true ORDER BY created_at DESC;
END;
$$;


ALTER FUNCTION public.get_subjects_with_context(p_user_id integer, p_user_type text) OWNER TO postgres;

--
-- TOC entry 607 (class 1255 OID 18690)
-- Name: get_subjects_with_stats(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_subjects_with_stats() RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$
DECLARE
  v_student_id INTEGER;
  v_section_id INTEGER;
  r JSONB;
BEGIN
  v_student_id := public.get_current_student_id();

  IF v_student_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated as student';
  END IF;

  SELECT section_id INTO v_section_id
  FROM public.students
  WHERE id = v_student_id AND deleted_at IS NULL;

  IF v_section_id IS NULL THEN
    SELECT COALESCE(jsonb_agg(row_to_json(t)::jsonb ORDER BY t.name), '[]'::jsonb) INTO r
    FROM (
      SELECT
        s.id,
        s.name,
        COALESCE(s.description, '') AS description,
        COALESCE(s.icon, '📚') AS icon,
        COALESCE(s.color, '0xFF6C63FF') AS color,
        COALESCE(s.pdf_url, '') AS pdf_url,
        (SELECT COUNT(*)::INT FROM public.chapters c WHERE c.subject_id = s.id AND c.is_active = true) AS chapters_count,
        0::FLOAT AS progress,
        0 AS total_quizzes,
        0::FLOAT AS average_score
      FROM public.subjects s
      WHERE s.is_active = true
    ) t;

  ELSE
    SELECT COALESCE(jsonb_agg(row_to_json(t)::jsonb ORDER BY t.name), '[]'::jsonb) INTO r
    FROM (
      SELECT
        s.id,
        s.name,
        COALESCE(s.description, '') AS description,
        COALESCE(s.icon, '📚') AS icon,
        COALESCE(s.color, '0xFF6C63FF') AS color,
        COALESCE(s.pdf_url, '') AS pdf_url,
        (SELECT COUNT(*)::INT FROM public.chapters c WHERE c.subject_id = s.id AND c.is_active = true) AS chapters_count,
        COALESCE((
          SELECT ROUND(AVG(pqa.score::NUMERIC / NULLIF(pqa.total_questions, 0)), 4)
          FROM public.practice_quiz_attempts pqa
          WHERE pqa.student_id = v_student_id AND pqa.subject_id = s.id
        ), 0)::FLOAT AS progress,
        (SELECT COUNT(*)::INT
         FROM public.practice_quiz_attempts pqa
         WHERE pqa.student_id = v_student_id AND pqa.subject_id = s.id
        ) AS total_quizzes,
        COALESCE((
          SELECT ROUND(AVG(pqa.score::NUMERIC / NULLIF(pqa.total_questions, 0) * 100), 2)
          FROM public.practice_quiz_attempts pqa
          WHERE pqa.student_id = v_student_id AND pqa.subject_id = s.id
        ), 0)::FLOAT AS average_score
      FROM public.subjects s
      JOIN public.section_subjects ss
        ON ss.subject_id = s.id
       AND ss.section_id = v_section_id
      WHERE ss.is_active = true
        AND s.is_active = true
    ) t;
  END IF;

  RETURN COALESCE(r, '[]'::jsonb);
END;
$$;


ALTER FUNCTION public.get_subjects_with_stats() OWNER TO postgres;

--
-- TOC entry 350 (class 1259 OID 17711)
-- Name: teachers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.teachers (
    id integer NOT NULL,
    teacher_code integer NOT NULL,
    full_name character varying(100) NOT NULL,
    phone_number character varying(20) NOT NULL,
    email character varying(100),
    profile_image bytea,
    profile_image_filename character varying(255),
    profile_image_mime_type character varying(50),
    profile_image_size integer,
    password_hash character varying(255) NOT NULL,
    is_active boolean DEFAULT true,
    last_login_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamp with time zone,
    deleted_by integer,
    profile_image_url text,
    profile_image_storage_path text,
    CONSTRAINT chk_profile_url_valid CHECK (((profile_image_url IS NULL) OR (profile_image_url ~* '^https?://'::text)))
);


ALTER TABLE public.teachers OWNER TO postgres;

--
-- TOC entry 4764 (class 0 OID 0)
-- Dependencies: 350
-- Name: COLUMN teachers.profile_image_url; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.teachers.profile_image_url IS 'Public URL from Supabase Storage';


--
-- TOC entry 4765 (class 0 OID 0)
-- Dependencies: 350
-- Name: COLUMN teachers.profile_image_storage_path; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.teachers.profile_image_storage_path IS 'Storage path: profile-images/teachers/{teacher_id}/{filename}';


--
-- TOC entry 568 (class 1255 OID 17720)
-- Name: get_teachers_with_context(integer, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_teachers_with_context(p_user_id integer, p_user_type text, p_search text DEFAULT NULL::text, p_sort_by text DEFAULT 'created_at'::text) RETURNS SETOF public.teachers
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY
  SELECT * FROM teachers t
  WHERE t.deleted_at IS NULL
  AND (p_search IS NULL OR t.full_name ILIKE '%' || p_search || '%' OR t.teacher_code::TEXT = p_search)
  ORDER BY
    CASE p_sort_by WHEN 'code' THEN t.teacher_code::TEXT WHEN 'name' THEN t.full_name ELSE t.created_at::TEXT END ASC,
    CASE WHEN p_sort_by NOT IN ('code','name') THEN t.created_at END DESC NULLS LAST;
END;
$$;


ALTER FUNCTION public.get_teachers_with_context(p_user_id integer, p_user_type text, p_search text, p_sort_by text) OWNER TO postgres;

--
-- TOC entry 569 (class 1255 OID 17721)
-- Name: get_weekly_activity_with_context(integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_weekly_activity_with_context(p_user_id integer, p_user_type text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  r JSONB;
  since_ts TIMESTAMPTZ;
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  since_ts := NOW() - INTERVAL '7 days';
  SELECT COALESCE(jsonb_agg(row_to_json(t)::jsonb), '[]'::jsonb) INTO r
  FROM (
    SELECT
      EXTRACT(DOW FROM created_at)::int AS day_index,
      COUNT(*) FILTER (WHERE user_type = 'student')::int AS students,
      COUNT(*) FILTER (WHERE user_type = 'teacher')::int AS teachers
    FROM activity_logs
    WHERE action = 'login' AND created_at >= since_ts
    GROUP BY EXTRACT(DOW FROM created_at)
  ) t;
  RETURN COALESCE(r, '[]'::jsonb);
END;
$$;


ALTER FUNCTION public.get_weekly_activity_with_context(p_user_id integer, p_user_type text) OWNER TO postgres;

--
-- TOC entry 570 (class 1255 OID 17722)
-- Name: hash_password(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.hash_password(p_password text) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    -- Use pgcrypto to hash password with bcrypt (12 rounds)
    RETURN crypt(p_password, gen_salt('bf', 12));
END;
$$;


ALTER FUNCTION public.hash_password(p_password text) OWNER TO postgres;

--
-- TOC entry 615 (class 1255 OID 22112)
-- Name: insert_chapter_with_context(integer, text, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_chapter_with_context(p_user_id integer, p_user_type text, p_payload jsonb) RETURNS SETOF public.chapters
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  PERFORM set_config('app.user_id',   p_user_id::TEXT,   true);
  PERFORM set_config('app.user_type', p_user_type::TEXT, true);

  RETURN QUERY
  INSERT INTO public.chapters (
    subject_id,
    name,
    description,
    order_index,
    is_active
  ) VALUES (
    (p_payload->>'subject_id')::INTEGER,
    p_payload->>'name',
    p_payload->>'description',
    COALESCE((p_payload->>'order_index')::INTEGER, 0),
    COALESCE((p_payload->>'is_active')::BOOLEAN, true)
  )
  RETURNING *;
END;
$$;


ALTER FUNCTION public.insert_chapter_with_context(p_user_id integer, p_user_type text, p_payload jsonb) OWNER TO postgres;

--
-- TOC entry 571 (class 1255 OID 17723)
-- Name: insert_exam_with_context(integer, text, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_exam_with_context(p_user_id integer, p_user_type text, p_payload jsonb) RETURNS SETOF public.exams
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_subject_id INTEGER := (NULLIF(TRIM(p_payload->>'subject_id'), ''))::INTEGER;
  v_grade_id   INTEGER := (NULLIF(TRIM(p_payload->>'grade_id'), ''))::INTEGER;
  v_section_id INTEGER := (NULLIF(TRIM(p_payload->>'section_id'), ''))::INTEGER;
  v_semester_id INTEGER := (NULLIF(TRIM(p_payload->>'semester_id'), ''))::INTEGER;
BEGIN
  IF v_subject_id IS NULL OR v_subject_id = 0 THEN
    RAISE EXCEPTION 'يجب اختيار المادة';
  END IF;
  IF v_grade_id IS NULL OR v_grade_id = 0 THEN
    RAISE EXCEPTION 'يجب اختيار الصف';
  END IF;
  IF v_section_id IS NULL OR v_section_id = 0 THEN
    RAISE EXCEPTION 'يجب اختيار الشعبة';
  END IF;
  IF v_semester_id IS NULL OR v_semester_id = 0 THEN
    RAISE EXCEPTION 'يجب اختيار الفصل الدراسي';
  END IF;

  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY
  INSERT INTO exams (
    title, description, subject_id, grade_id, section_id, semester_id,
    total_marks, passing_marks, duration_minutes, difficulty_level,
    created_by_admin, created_by_teacher, status
  )
  VALUES (
    NULLIF(TRIM(p_payload->>'title'), ''),
    NULLIF(TRIM(p_payload->>'description'), ''),
    v_subject_id,
    v_grade_id,
    v_section_id,
    v_semester_id,
    COALESCE((NULLIF(TRIM(p_payload->>'total_marks'), ''))::INTEGER, 0),
    COALESCE((NULLIF(TRIM(p_payload->>'passing_marks'), ''))::INTEGER, 0),
    (NULLIF(TRIM(p_payload->>'duration_minutes'), ''))::INTEGER,
    COALESCE(
      NULLIF(TRIM(p_payload->>'difficulty_level'), '')::difficulty_level_enum,
      'medium'::difficulty_level_enum
    ),
    (NULLIF(TRIM(p_payload->>'created_by_admin'), ''))::INTEGER,
    (NULLIF(TRIM(p_payload->>'created_by_teacher'), ''))::INTEGER,
    COALESCE(NULLIF(TRIM(p_payload->>'status'), '')::exam_status_enum, 'draft'::exam_status_enum)
  )
  RETURNING *;
END;
$$;


ALTER FUNCTION public.insert_exam_with_context(p_user_id integer, p_user_type text, p_payload jsonb) OWNER TO postgres;

--
-- TOC entry 572 (class 1255 OID 17724)
-- Name: insert_question_with_context(integer, text, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_question_with_context(p_user_id integer, p_user_type text, p_payload jsonb) RETURNS SETOF public.questions
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$-- BEGIN
--   PERFORM set_user_context(p_user_id, p_user_type);
--   RETURN QUERY
--   INSERT INTO questions (
--     question_text, question_type, question_options, correct_answer,
--     difficulty_level, subject_id, created_by_admin, created_by_teacher,
--     status, is_active, pdf_url, pdf_storage_path, pdf_filename
--   )
--   VALUES (
--     (p_payload->>'question_text'),
--     (p_payload->>'question_type')::question_type_enum,
--     (p_payload->'question_options'),
--     NULLIF(TRIM(p_payload->>'correct_answer'), ''),
--     (p_payload->>'difficulty_level')::difficulty_level_enum,
--     (p_payload->>'subject_id')::INTEGER,
--     (p_payload->>'created_by_admin')::INTEGER,
--     (p_payload->>'created_by_teacher')::INTEGER,
--     COALESCE((p_payload->>'status')::approval_status_enum, 'approved'),
--     COALESCE((p_payload->>'is_active')::boolean, true),
--     NULLIF(TRIM(p_payload->>'pdf_url'), ''),
--     NULLIF(TRIM(p_payload->>'pdf_storage_path'), ''),
--     NULLIF(TRIM(p_payload->>'pdf_filename'), '')
--   )
--   RETURNING *;
-- END;


BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY
  INSERT INTO questions (
    question_text, question_type, question_options, correct_answer,
    difficulty_level, subject_id, chapter_id,
    created_by_admin, created_by_teacher,
    status, is_active, pdf_url, pdf_storage_path, pdf_filename
  )
  VALUES (
    (p_payload->>'question_text'),
    (p_payload->>'question_type')::question_type_enum,
    (p_payload->'question_options'),
    NULLIF(TRIM(p_payload->>'correct_answer'), ''),
    (p_payload->>'difficulty_level')::difficulty_level_enum,
    (p_payload->>'subject_id')::INTEGER,
    (p_payload->>'chapter_id')::INTEGER,
    (p_payload->>'created_by_admin')::INTEGER,
    (p_payload->>'created_by_teacher')::INTEGER,
    COALESCE((p_payload->>'status')::approval_status_enum, 'approved'),
    COALESCE((p_payload->>'is_active')::boolean, true),
    NULLIF(TRIM(p_payload->>'pdf_url'), ''),
    NULLIF(TRIM(p_payload->>'pdf_storage_path'), ''),
    NULLIF(TRIM(p_payload->>'pdf_filename'), '')
  )
  RETURNING *;
END;$$;


ALTER FUNCTION public.insert_question_with_context(p_user_id integer, p_user_type text, p_payload jsonb) OWNER TO postgres;

--
-- TOC entry 573 (class 1255 OID 17725)
-- Name: insert_section_subject_with_context(integer, text, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_section_subject_with_context(p_user_id integer, p_user_type text, p_section_id integer, p_subject_id integer, p_teacher_id integer) RETURNS SETOF public.section_subjects
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  IF EXISTS (
    SELECT 1 FROM section_subjects
    WHERE section_id = p_section_id AND subject_id = p_subject_id AND is_active = true
  ) THEN
    RAISE EXCEPTION 'المادة مربوطة بالفعل في هذه الشعبة';
  END IF;
  RETURN QUERY
  INSERT INTO section_subjects (section_id, subject_id, teacher_id, is_active)
  VALUES (p_section_id, p_subject_id, p_teacher_id, true)
  RETURNING *;
END;
$$;


ALTER FUNCTION public.insert_section_subject_with_context(p_user_id integer, p_user_type text, p_section_id integer, p_subject_id integer, p_teacher_id integer) OWNER TO postgres;

--
-- TOC entry 574 (class 1255 OID 17726)
-- Name: insert_section_with_context(integer, text, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_section_with_context(p_user_id integer, p_user_type text, p_payload jsonb) RETURNS SETOF public.sections
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY
  INSERT INTO sections (
    name, grade_id, capacity, is_active
  )
  VALUES (
    (p_payload->>'name'),
    (p_payload->>'grade_id')::integer,
    (p_payload->>'capacity')::integer,
    COALESCE((p_payload->>'is_active')::boolean, true)
  )
  RETURNING *;
END;
$$;


ALTER FUNCTION public.insert_section_with_context(p_user_id integer, p_user_type text, p_payload jsonb) OWNER TO postgres;

--
-- TOC entry 575 (class 1255 OID 17727)
-- Name: insert_student_with_context(integer, text, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_student_with_context(p_user_id integer, p_user_type text, p_payload jsonb) RETURNS SETOF public.students
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY
  INSERT INTO students (
    full_name, phone_number, email, section_id, password_hash, is_active
  )
  VALUES (
    (p_payload->>'full_name'),
    NULLIF(TRIM(p_payload->>'phone_number'), ''),
    NULLIF(TRIM(p_payload->>'email'), ''),
    (p_payload->>'section_id')::integer,
    (p_payload->>'password_hash'),
    COALESCE((p_payload->>'is_active')::boolean, true)
  )
  RETURNING *;
END;
$$;


ALTER FUNCTION public.insert_student_with_context(p_user_id integer, p_user_type text, p_payload jsonb) OWNER TO postgres;

--
-- TOC entry 576 (class 1255 OID 17728)
-- Name: insert_subject_with_context(integer, text, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_subject_with_context(p_user_id integer, p_user_type text, p_payload jsonb) RETURNS SETOF public.subjects
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY
  INSERT INTO subjects (
    name, description, is_active
  )
  VALUES (
    (p_payload->>'name'),
    NULLIF(TRIM(p_payload->>'description'), ''),
    COALESCE((p_payload->>'is_active')::boolean, true)
  )
  RETURNING *;
END;
$$;


ALTER FUNCTION public.insert_subject_with_context(p_user_id integer, p_user_type text, p_payload jsonb) OWNER TO postgres;

--
-- TOC entry 577 (class 1255 OID 17729)
-- Name: insert_teacher_with_context(integer, text, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_teacher_with_context(p_user_id integer, p_user_type text, p_payload jsonb) RETURNS SETOF public.teachers
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY
  INSERT INTO teachers (
    full_name, phone_number, email, password_hash, is_active
  )
  VALUES (
    (p_payload->>'full_name'),
    COALESCE(p_payload->>'phone_number', ''),
    NULLIF(TRIM(p_payload->>'email'), ''),
    (p_payload->>'password_hash'),
    COALESCE((p_payload->>'is_active')::boolean, true)
  )
  RETURNING *;
END;
$$;


ALTER FUNCTION public.insert_teacher_with_context(p_user_id integer, p_user_type text, p_payload jsonb) OWNER TO postgres;

--
-- TOC entry 578 (class 1255 OID 17730)
-- Name: is_admin(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_admin() RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM admins a
    WHERE a.id = app_current_user_id()
    AND a.deleted_at IS NULL
  );
END;
$$;


ALTER FUNCTION public.is_admin() OWNER TO postgres;

--
-- TOC entry 579 (class 1255 OID 17731)
-- Name: is_parent(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_parent() RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM parents p
    WHERE p.id = app_current_user_id()
  );
END;
$$;


ALTER FUNCTION public.is_parent() OWNER TO postgres;

--
-- TOC entry 580 (class 1255 OID 17732)
-- Name: is_student(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_student() RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM students s
    WHERE s.id = app_current_user_id()
    AND s.deleted_at IS NULL
  );
END;
$$;


ALTER FUNCTION public.is_student() OWNER TO postgres;

--
-- TOC entry 581 (class 1255 OID 17733)
-- Name: is_teacher(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_teacher() RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM teachers t
    WHERE t.id = app_current_user_id()
    AND t.deleted_at IS NULL
  );
END;
$$;


ALTER FUNCTION public.is_teacher() OWNER TO postgres;

--
-- TOC entry 351 (class 1259 OID 17734)
-- Name: parent_students; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.parent_students (
    id integer NOT NULL,
    parent_id integer NOT NULL,
    student_id integer NOT NULL,
    relationship character varying(50),
    linked_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.parent_students OWNER TO postgres;

--
-- TOC entry 582 (class 1255 OID 17738)
-- Name: link_parent_student_with_context(integer, text, integer, integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.link_parent_student_with_context(p_user_id integer, p_user_type text, p_parent_id integer, p_student_id integer, p_relationship text DEFAULT NULL::text) RETURNS SETOF public.parent_students
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);

  RETURN QUERY
  INSERT INTO parent_students (parent_id, student_id, relationship)
  VALUES (p_parent_id, p_student_id, p_relationship)
  RETURNING *;
END;
$$;


ALTER FUNCTION public.link_parent_student_with_context(p_user_id integer, p_user_type text, p_parent_id integer, p_student_id integer, p_relationship text) OWNER TO postgres;

--
-- TOC entry 583 (class 1255 OID 17739)
-- Name: login_admin(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.login_admin(p_school_code text, p_password text) RETURNS TABLE(id integer, full_name character varying, email character varying, phone_number character varying, is_active boolean)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_admin_id INTEGER;
    v_password_hash TEXT;
    v_verified BOOLEAN;
BEGIN
    -- 1. Verify school code
    IF NOT EXISTS (
        SELECT 1 FROM school_settings WHERE admin_code = p_school_code
    ) THEN
        RAISE EXCEPTION 'رمز المدرسة غير صحيح';
    END IF;
    
    -- 2. Get first active admin (in production, you might want to add email to login)
    SELECT a.id, a.password_hash
    INTO v_admin_id, v_password_hash
    FROM admins a
    WHERE a.deleted_at IS NULL
    AND a.is_active = true
    LIMIT 1;
    
    IF v_admin_id IS NULL THEN
        RAISE EXCEPTION 'المسؤول غير موجود';
    END IF;
    
    -- 3. Verify password
    SELECT verify_password(v_password_hash, p_password) INTO v_verified;
    
    IF NOT v_verified THEN
        RAISE EXCEPTION 'كلمة السر غير صحيحة';
    END IF;
    
    -- 4. Update last_login_at
    UPDATE admins
    SET last_login_at = CURRENT_TIMESTAMP
    WHERE admins.id = v_admin_id;
    
    -- 5. Return admin data (without password_hash)
    RETURN QUERY
    SELECT 
        admins.id,
        admins.full_name,
        admins.email,
        admins.phone_number,
        admins.is_active
    FROM admins
    WHERE admins.id = v_admin_id;
END;
$$;


ALTER FUNCTION public.login_admin(p_school_code text, p_password text) OWNER TO postgres;

--
-- TOC entry 613 (class 1255 OID 22097)
-- Name: normalize_correct_answer(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.normalize_correct_answer() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.question_type = 'true_false' THEN
    CASE TRIM(NEW.correct_answer)
      WHEN 'صحيح' THEN NEW.correct_answer := 'A';
      WHEN 'خطأ'  THEN NEW.correct_answer := 'B';
      WHEN 'true' THEN NEW.correct_answer := 'A';
      WHEN 'false'THEN NEW.correct_answer := 'B';
      WHEN '1'    THEN NEW.correct_answer := 'A';
      WHEN '0'    THEN NEW.correct_answer := 'B';
      ELSE
        RAISE EXCEPTION 'Invalid true_false answer: %', NEW.correct_answer;
    END CASE;

  ELSIF NEW.question_type = 'multiple_choice' THEN
    CASE TRIM(NEW.correct_answer)
      WHEN '1' THEN NEW.correct_answer := 'A';
      WHEN '2' THEN NEW.correct_answer := 'B';
      WHEN '3' THEN NEW.correct_answer := 'C';
      WHEN '4' THEN NEW.correct_answer := 'D';
      ELSE NULL; -- already normalized
    END CASE;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.normalize_correct_answer() OWNER TO postgres;

--
-- TOC entry 617 (class 1255 OID 22114)
-- Name: normalize_question_format(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.normalize_question_format() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- ── multiple_choice ─────────────────────────────────────────
  IF NEW.question_type = 'multiple_choice' THEN

    -- تحويل من التنسيق الجديد {"options":[...]} إلى القديم {"A":...}
    IF (NEW.question_options ? 'options') AND NOT (NEW.question_options ? 'A') THEN
      NEW.question_options := jsonb_build_object(
        'A', NEW.question_options->'options'->0,
        'B', NEW.question_options->'options'->1,
        'C', NEW.question_options->'options'->2,
        'D', NEW.question_options->'options'->3
      );
      -- تحويل correct_answer من القيمة الفعلية إلى الحرف
      NEW.correct_answer := CASE
        WHEN NEW.correct_answer = (NEW.question_options->>'A') THEN 'A'
        WHEN NEW.correct_answer = (NEW.question_options->>'B') THEN 'B'
        WHEN NEW.correct_answer = (NEW.question_options->>'C') THEN 'C'
        WHEN NEW.correct_answer = (NEW.question_options->>'D') THEN 'D'
        WHEN NEW.correct_answer IN ('A','B','C','D')          THEN NEW.correct_answer
        ELSE 'A'
      END;
    END IF;

  -- ── true_false ───────────────────────────────────────────────
  ELSIF NEW.question_type = 'true_false' THEN

    -- توحيد question_options دائماً
    NEW.question_options := '{"A":"صحيح","B":"خطأ"}';

    -- توحيد correct_answer دائماً
    NEW.correct_answer := CASE
      WHEN NEW.correct_answer IN ('True','true','صحيح','A','1') THEN 'A'
      WHEN NEW.correct_answer IN ('False','false','خطأ','B','0') THEN 'B'
      ELSE 'A'
    END;

  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.normalize_question_format() OWNER TO postgres;

--
-- TOC entry 603 (class 1255 OID 18673)
-- Name: save_practice_quiz_attempt(integer, integer, integer, integer, integer, integer, integer, integer, jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.save_practice_quiz_attempt(p_subject_id integer, p_chapter_id integer, p_score integer, p_total_questions integer, p_correct_answers integer, p_wrong_answers integer, p_unanswered integer, p_time_taken_seconds integer, p_quiz_options jsonb DEFAULT '{}'::jsonb, p_answers jsonb DEFAULT '[]'::jsonb) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_student_id INTEGER;
  v_attempt_id INTEGER;
  ans JSONB;
BEGIN
  v_student_id := public.get_current_student_id();
  IF v_student_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated as student';
  END IF;

  INSERT INTO public.practice_quiz_attempts (
    student_id, subject_id, chapter_id,
    score, total_questions, correct_answers, wrong_answers, unanswered,
    time_taken_seconds, quiz_options
  ) VALUES (
    v_student_id, p_subject_id, p_chapter_id,
    p_score, p_total_questions, p_correct_answers, p_wrong_answers, p_unanswered,
    p_time_taken_seconds, p_quiz_options
  )
  RETURNING id INTO v_attempt_id;

  -- Insert individual answers
  FOR ans IN SELECT * FROM jsonb_array_elements(p_answers)
  LOOP
    INSERT INTO public.practice_quiz_answers (attempt_id, question_id, selected_answer, is_correct)
    VALUES (
      v_attempt_id,
      (ans->>'question_id')::INTEGER,
      ans->>'selected_answer',
      (ans->>'is_correct')::BOOLEAN
    );
  END LOOP;

  RETURN v_attempt_id;
END;
$$;


ALTER FUNCTION public.save_practice_quiz_attempt(p_subject_id integer, p_chapter_id integer, p_score integer, p_total_questions integer, p_correct_answers integer, p_wrong_answers integer, p_unanswered integer, p_time_taken_seconds integer, p_quiz_options jsonb, p_answers jsonb) OWNER TO postgres;

--
-- TOC entry 584 (class 1255 OID 17740)
-- Name: send_message_with_context(integer, text, integer, integer, integer, integer, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.send_message_with_context(p_user_id integer, p_user_type text, p_sender_admin_id integer DEFAULT NULL::integer, p_sender_parent_id integer DEFAULT NULL::integer, p_recipient_admin_id integer DEFAULT NULL::integer, p_recipient_parent_id integer DEFAULT NULL::integer, p_subject text DEFAULT NULL::text, p_message_text text DEFAULT ''::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    result RECORD;
BEGIN
    -- Set user context in the same connection
    PERFORM set_config('app.current_user_id', p_user_id::TEXT, true);
    PERFORM set_config('app.current_user_type', p_user_type, true);

    -- Insert the message
    INSERT INTO messages (
        sender_admin_id,
        sender_parent_id,
        recipient_admin_id,
        recipient_parent_id,
        subject,
        message_text
    ) VALUES (
        p_sender_admin_id,
        p_sender_parent_id,
        p_recipient_admin_id,
        p_recipient_parent_id,
        p_subject,
        p_message_text
    )
    RETURNING * INTO result;

    RETURN to_jsonb(result);
END;
$$;


ALTER FUNCTION public.send_message_with_context(p_user_id integer, p_user_type text, p_sender_admin_id integer, p_sender_parent_id integer, p_recipient_admin_id integer, p_recipient_parent_id integer, p_subject text, p_message_text text) OWNER TO postgres;

--
-- TOC entry 585 (class 1255 OID 17741)
-- Name: send_report_with_context(integer, text, integer, integer, text, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.send_report_with_context(p_user_id integer, p_user_type text, p_student_id integer, p_parent_id integer, p_title text, p_report_text text, p_sent_by integer) RETURNS SETOF public.reports
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);

  RETURN QUERY
  INSERT INTO reports (student_id, parent_id, title, report_text, sent_by, sent_at, is_read)
  VALUES (p_student_id, p_parent_id, p_title, p_report_text, p_sent_by, CURRENT_TIMESTAMP, false)
  RETURNING *;
END;
$$;


ALTER FUNCTION public.send_report_with_context(p_user_id integer, p_user_type text, p_student_id integer, p_parent_id integer, p_title text, p_report_text text, p_sent_by integer) OWNER TO postgres;

--
-- TOC entry 586 (class 1255 OID 17742)
-- Name: set_user_context(integer, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_user_context(p_user_id integer, p_user_type text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    PERFORM set_config('app.current_user_id', p_user_id::TEXT, true);
    PERFORM set_config('app.current_user_type', p_user_type, true);
END;
$$;


ALTER FUNCTION public.set_user_context(p_user_id integer, p_user_type text) OWNER TO postgres;

--
-- TOC entry 587 (class 1255 OID 17743)
-- Name: storage_is_admin(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.storage_is_admin() RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM admins a
        WHERE a.id = current_setting('app.current_user_id', true)::INTEGER
        AND a.deleted_at IS NULL
    );
END;
$$;


ALTER FUNCTION public.storage_is_admin() OWNER TO postgres;

--
-- TOC entry 588 (class 1255 OID 17744)
-- Name: storage_is_parent(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.storage_is_parent() RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM parents p
        WHERE p.id = current_setting('app.current_user_id', true)::INTEGER
    );
END;
$$;


ALTER FUNCTION public.storage_is_parent() OWNER TO postgres;

--
-- TOC entry 589 (class 1255 OID 17745)
-- Name: storage_is_student(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.storage_is_student() RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM students s
        WHERE s.id = current_setting('app.current_user_id', true)::INTEGER
        AND s.deleted_at IS NULL
    );
END;
$$;


ALTER FUNCTION public.storage_is_student() OWNER TO postgres;

--
-- TOC entry 590 (class 1255 OID 17746)
-- Name: storage_is_teacher(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.storage_is_teacher() RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM teachers t
        WHERE t.id = current_setting('app.current_user_id', true)::INTEGER
        AND t.deleted_at IS NULL
    );
END;
$$;


ALTER FUNCTION public.storage_is_teacher() OWNER TO postgres;

--
-- TOC entry 591 (class 1255 OID 17747)
-- Name: update_admin_profile_image_with_context(integer, text, integer, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_admin_profile_image_with_context(p_user_id integer, p_user_type text, p_admin_id integer, p_profile_image_url text, p_profile_image_storage_path text) RETURNS SETOF public.admins
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY
  UPDATE admins
  SET
    profile_image_url = NULLIF(TRIM(p_profile_image_url), ''),
    profile_image_storage_path = NULLIF(TRIM(p_profile_image_storage_path), ''),
    updated_at = CURRENT_TIMESTAMP
  WHERE id = p_admin_id AND deleted_at IS NULL
  RETURNING *;
END;
$$;


ALTER FUNCTION public.update_admin_profile_image_with_context(p_user_id integer, p_user_type text, p_admin_id integer, p_profile_image_url text, p_profile_image_storage_path text) OWNER TO postgres;

--
-- TOC entry 616 (class 1255 OID 22113)
-- Name: update_chapter_with_context(integer, text, integer, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_chapter_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) RETURNS SETOF public.chapters
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  PERFORM set_config('app.user_id',   p_user_id::TEXT,   true);
  PERFORM set_config('app.user_type', p_user_type::TEXT, true);

  RETURN QUERY
  UPDATE public.chapters SET
    name        = COALESCE(p_payload->>'name',        name),
    description = COALESCE(p_payload->>'description', description),
    order_index = COALESCE((p_payload->>'order_index')::INTEGER, order_index),
    is_active   = COALESCE((p_payload->>'is_active')::BOOLEAN,   is_active),
    updated_at  = NOW()
  WHERE id = p_id
  RETURNING *;
END;
$$;


ALTER FUNCTION public.update_chapter_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) OWNER TO postgres;

--
-- TOC entry 592 (class 1255 OID 17748)
-- Name: update_exam_with_context(integer, text, integer, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_exam_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) RETURNS SETOF public.exams
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY
  UPDATE exams
  SET
    title = COALESCE(p_payload->>'title', title),
    description = CASE WHEN p_payload ? 'description' THEN NULLIF(TRIM(p_payload->>'description'), '') ELSE description END,
    subject_id = COALESCE((p_payload->>'subject_id')::INTEGER, subject_id),
    grade_id = COALESCE((p_payload->>'grade_id')::INTEGER, grade_id),
    section_id = COALESCE((p_payload->>'section_id')::INTEGER, section_id),
    semester_id = COALESCE((p_payload->>'semester_id')::INTEGER, semester_id),
    total_marks = COALESCE((p_payload->>'total_marks')::INTEGER, total_marks),
    passing_marks = COALESCE((p_payload->>'passing_marks')::INTEGER, passing_marks),
    duration_minutes = CASE WHEN p_payload ? 'duration_minutes' THEN (p_payload->>'duration_minutes')::INTEGER ELSE duration_minutes END,
    difficulty_level = CASE WHEN p_payload ? 'difficulty_level' THEN (p_payload->>'difficulty_level')::difficulty_level_enum ELSE difficulty_level END,
    pdf_url = CASE WHEN p_payload ? 'pdf_url' THEN NULLIF(TRIM(p_payload->>'pdf_url'), '') ELSE pdf_url END,
    pdf_storage_path = CASE WHEN p_payload ? 'pdf_storage_path' THEN NULLIF(TRIM(p_payload->>'pdf_storage_path'), '') ELSE pdf_storage_path END,
    pdf_filename = CASE WHEN p_payload ? 'pdf_filename' THEN NULLIF(TRIM(p_payload->>'pdf_filename'), '') ELSE pdf_filename END,
    pdf_size = CASE WHEN p_payload ? 'pdf_size' THEN (p_payload->>'pdf_size')::INTEGER ELSE pdf_size END,
    status = CASE WHEN p_payload ? 'status' THEN (p_payload->>'status')::exam_status_enum ELSE status END,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = p_id
  RETURNING *;
END;
$$;


ALTER FUNCTION public.update_exam_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) OWNER TO postgres;

--
-- TOC entry 593 (class 1255 OID 17749)
-- Name: update_question_with_context(integer, text, integer, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_question_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) RETURNS SETOF public.questions
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY
  UPDATE questions
  SET
    question_text = COALESCE(p_payload->>'question_text', question_text),
    question_type = COALESCE((p_payload->>'question_type')::question_type_enum, question_type),
    question_options = CASE WHEN p_payload ? 'question_options' THEN (p_payload->'question_options') ELSE question_options END,
    correct_answer = CASE WHEN p_payload ? 'correct_answer' THEN NULLIF(TRIM(p_payload->>'correct_answer'), '') ELSE correct_answer END,
    difficulty_level = COALESCE((p_payload->>'difficulty_level')::difficulty_level_enum, difficulty_level),
    subject_id = COALESCE((p_payload->>'subject_id')::INTEGER, subject_id),
    is_active = CASE WHEN p_payload ? 'is_active' THEN (p_payload->>'is_active')::boolean ELSE is_active END,
    pdf_url = CASE WHEN p_payload ? 'pdf_url' THEN NULLIF(TRIM(p_payload->>'pdf_url'), '') ELSE pdf_url END,
    pdf_storage_path = CASE WHEN p_payload ? 'pdf_storage_path' THEN NULLIF(TRIM(p_payload->>'pdf_storage_path'), '') ELSE pdf_storage_path END,
    pdf_filename = CASE WHEN p_payload ? 'pdf_filename' THEN NULLIF(TRIM(p_payload->>'pdf_filename'), '') ELSE pdf_filename END,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = p_id AND is_active = true
  RETURNING *;
END;
$$;


ALTER FUNCTION public.update_question_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) OWNER TO postgres;

--
-- TOC entry 594 (class 1255 OID 17750)
-- Name: update_section_with_context(integer, text, integer, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_section_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) RETURNS SETOF public.sections
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY
  UPDATE sections
  SET
    name = COALESCE(p_payload->>'name', name),
    capacity = CASE WHEN p_payload ? 'capacity' THEN (p_payload->>'capacity')::integer ELSE capacity END,
    is_active = CASE WHEN p_payload ? 'is_active' THEN (p_payload->>'is_active')::boolean ELSE is_active END,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = p_id
  RETURNING *;
END;
$$;


ALTER FUNCTION public.update_section_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) OWNER TO postgres;

--
-- TOC entry 595 (class 1255 OID 17751)
-- Name: update_student_with_context(integer, text, integer, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_student_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) RETURNS SETOF public.students
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY
  UPDATE students
  SET
    full_name = COALESCE(p_payload->>'full_name', full_name),
    phone_number = CASE WHEN p_payload ? 'phone_number' THEN NULLIF(TRIM(p_payload->>'phone_number'), '') ELSE phone_number END,
    email = CASE WHEN p_payload ? 'email' THEN NULLIF(TRIM(p_payload->>'email'), '') ELSE email END,
    section_id = CASE WHEN p_payload ? 'section_id' THEN (p_payload->>'section_id')::integer ELSE section_id END,
    is_active = CASE WHEN p_payload ? 'is_active' THEN (p_payload->>'is_active')::boolean ELSE is_active END,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = p_id AND deleted_at IS NULL
  RETURNING *;
END;
$$;


ALTER FUNCTION public.update_student_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) OWNER TO postgres;

--
-- TOC entry 596 (class 1255 OID 17752)
-- Name: update_subject_with_context(integer, text, integer, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_subject_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) RETURNS SETOF public.subjects
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY
  UPDATE subjects
  SET
    name = COALESCE(p_payload->>'name', name),
    description = CASE WHEN p_payload ? 'description' THEN NULLIF(TRIM(p_payload->>'description'), '') ELSE description END,
    is_active = CASE WHEN p_payload ? 'is_active' THEN (p_payload->>'is_active')::boolean ELSE is_active END,
    pdf_url = CASE WHEN p_payload ? 'pdf_url' THEN NULLIF(TRIM(p_payload->>'pdf_url'), '') ELSE pdf_url END,
    pdf_storage_path = CASE WHEN p_payload ? 'pdf_storage_path' THEN NULLIF(TRIM(p_payload->>'pdf_storage_path'), '') ELSE pdf_storage_path END,
    pdf_filename = CASE WHEN p_payload ? 'pdf_filename' THEN NULLIF(TRIM(p_payload->>'pdf_filename'), '') ELSE pdf_filename END,
    pdf_size = CASE WHEN p_payload ? 'pdf_size' THEN (p_payload->>'pdf_size')::INTEGER ELSE pdf_size END,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = p_id
  RETURNING *;
END;
$$;


ALTER FUNCTION public.update_subject_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) OWNER TO postgres;

--
-- TOC entry 597 (class 1255 OID 17753)
-- Name: update_teacher_with_context(integer, text, integer, jsonb); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_teacher_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) RETURNS SETOF public.teachers
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  PERFORM set_user_context(p_user_id, p_user_type);
  RETURN QUERY
  UPDATE teachers
  SET
    full_name = COALESCE(p_payload->>'full_name', full_name),
    phone_number = COALESCE(p_payload->>'phone_number', phone_number),
    email = CASE WHEN p_payload ? 'email' THEN NULLIF(TRIM(p_payload->>'email'), '') ELSE email END,
    is_active = CASE WHEN p_payload ? 'is_active' THEN (p_payload->>'is_active')::boolean ELSE is_active END,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = p_id AND deleted_at IS NULL
  RETURNING *;
END;
$$;


ALTER FUNCTION public.update_teacher_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) OWNER TO postgres;

--
-- TOC entry 598 (class 1255 OID 17754)
-- Name: verify_password(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.verify_password(p_password_hash text, p_password text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
BEGIN
    -- Validate inputs
    IF p_password_hash IS NULL OR p_password IS NULL THEN
        RETURN false;
    END IF;
    
    -- Validate hash format (bcrypt hash starts with $2a$, $2b$, or $2y$)
    IF p_password_hash !~ '^\$2[aby]\$' THEN
        RETURN false;
    END IF;
    
    -- Use pgcrypto to verify password
    RETURN p_password_hash = crypt(p_password, p_password_hash);
EXCEPTION
    WHEN OTHERS THEN
        -- If there's any error (like invalid salt), return false
        RETURN false;
END;
$_$;


ALTER FUNCTION public.verify_password(p_password_hash text, p_password text) OWNER TO postgres;

--
-- TOC entry 352 (class 1259 OID 17756)
-- Name: activities; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.activities (
    id integer NOT NULL,
    student_id integer NOT NULL,
    title character varying(300) NOT NULL,
    description text,
    subject_id integer,
    priority integer,
    created_by_teacher_id integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    activity_type public.activity_type_enum DEFAULT 'homework'::public.activity_type_enum NOT NULL,
    status public.activity_status_enum DEFAULT 'pending'::public.activity_status_enum NOT NULL,
    due_date date,
    CONSTRAINT activities_priority_check CHECK (((priority >= 1) AND (priority <= 5)))
);


ALTER TABLE public.activities OWNER TO postgres;

--
-- TOC entry 4804 (class 0 OID 0)
-- Dependencies: 352
-- Name: TABLE activities; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.activities IS 'Homework, projects, tasks (Parent app)';


--
-- TOC entry 353 (class 1259 OID 17765)
-- Name: activities_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.activities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.activities_id_seq OWNER TO postgres;

--
-- TOC entry 4806 (class 0 OID 0)
-- Dependencies: 353
-- Name: activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.activities_id_seq OWNED BY public.activities.id;


--
-- TOC entry 354 (class 1259 OID 17766)
-- Name: activity_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.activity_logs (
    id bigint NOT NULL,
    user_type character varying(20) NOT NULL,
    user_id integer NOT NULL,
    user_name_cache character varying(100),
    action character varying(100) NOT NULL,
    description text,
    metadata jsonb,
    ip_address inet,
    user_agent text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_activity_user_type CHECK (((user_type)::text = ANY (ARRAY[('admin'::character varying)::text, ('teacher'::character varying)::text, ('student'::character varying)::text, ('parent'::character varying)::text])))
);


ALTER TABLE public.activity_logs OWNER TO postgres;

--
-- TOC entry 355 (class 1259 OID 17773)
-- Name: activity_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.activity_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.activity_logs_id_seq OWNER TO postgres;

--
-- TOC entry 4809 (class 0 OID 0)
-- Dependencies: 355
-- Name: activity_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.activity_logs_id_seq OWNED BY public.activity_logs.id;


--
-- TOC entry 356 (class 1259 OID 17774)
-- Name: admins_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admins_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.admins_id_seq OWNER TO postgres;

--
-- TOC entry 4811 (class 0 OID 0)
-- Dependencies: 356
-- Name: admins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admins_id_seq OWNED BY public.admins.id;


--
-- TOC entry 357 (class 1259 OID 17775)
-- Name: app_user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.app_user (
    id integer NOT NULL,
    auth_user_id uuid NOT NULL,
    user_type character varying(20) NOT NULL,
    app_entity_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT app_user_user_type_check CHECK (((user_type)::text = ANY (ARRAY[('admin'::character varying)::text, ('teacher'::character varying)::text, ('student'::character varying)::text, ('parent'::character varying)::text])))
);


ALTER TABLE public.app_user OWNER TO postgres;

--
-- TOC entry 4813 (class 0 OID 0)
-- Dependencies: 357
-- Name: TABLE app_user; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.app_user IS 'Maps Supabase Auth user to app role and entity id for mobile RLS';


--
-- TOC entry 358 (class 1259 OID 17780)
-- Name: app_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.app_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.app_user_id_seq OWNER TO postgres;

--
-- TOC entry 4815 (class 0 OID 0)
-- Dependencies: 358
-- Name: app_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.app_user_id_seq OWNED BY public.app_user.id;


--
-- TOC entry 359 (class 1259 OID 17781)
-- Name: attendance_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.attendance_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.attendance_id_seq OWNER TO postgres;

--
-- TOC entry 4817 (class 0 OID 0)
-- Dependencies: 359
-- Name: attendance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.attendance_id_seq OWNED BY public.attendance.id;


--
-- TOC entry 408 (class 1259 OID 20967)
-- Name: chapter_topics; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chapter_topics (
    id integer NOT NULL,
    chapter_id integer NOT NULL,
    title character varying(200) NOT NULL,
    description text,
    order_index integer DEFAULT 0 NOT NULL,
    duration_min integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.chapter_topics OWNER TO postgres;

--
-- TOC entry 4819 (class 0 OID 0)
-- Dependencies: 408
-- Name: TABLE chapter_topics; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.chapter_topics IS 'Sub-topics within a chapter — entered via web admin, displayed in student app chapter details screen';


--
-- TOC entry 4820 (class 0 OID 0)
-- Dependencies: 408
-- Name: COLUMN chapter_topics.order_index; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.chapter_topics.order_index IS 'Display order within the chapter (ascending)';


--
-- TOC entry 4821 (class 0 OID 0)
-- Dependencies: 408
-- Name: COLUMN chapter_topics.duration_min; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.chapter_topics.duration_min IS 'Estimated study time in minutes shown to student';


--
-- TOC entry 407 (class 1259 OID 20966)
-- Name: chapter_topics_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.chapter_topics_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.chapter_topics_id_seq OWNER TO postgres;

--
-- TOC entry 4823 (class 0 OID 0)
-- Dependencies: 407
-- Name: chapter_topics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.chapter_topics_id_seq OWNED BY public.chapter_topics.id;


--
-- TOC entry 361 (class 1259 OID 17791)
-- Name: chapters_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.chapters_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.chapters_id_seq OWNER TO postgres;

--
-- TOC entry 4825 (class 0 OID 0)
-- Dependencies: 361
-- Name: chapters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.chapters_id_seq OWNED BY public.chapters.id;


--
-- TOC entry 362 (class 1259 OID 17792)
-- Name: daily_summaries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.daily_summaries (
    id integer NOT NULL,
    student_id integer NOT NULL,
    summary_date date NOT NULL,
    recap text,
    participation_level character varying(50),
    behavior_level character varying(50),
    focus_level character varying(50),
    teacher_note text,
    highlight_of_day text,
    subjects_studied text[] DEFAULT '{}'::text[],
    subject_notes jsonb DEFAULT '{}'::jsonb,
    created_by_teacher_id integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.daily_summaries OWNER TO postgres;

--
-- TOC entry 4827 (class 0 OID 0)
-- Dependencies: 362
-- Name: TABLE daily_summaries; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.daily_summaries IS 'Daily recaps for students (Parent app)';


--
-- TOC entry 363 (class 1259 OID 17801)
-- Name: daily_summaries_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.daily_summaries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.daily_summaries_id_seq OWNER TO postgres;

--
-- TOC entry 4829 (class 0 OID 0)
-- Dependencies: 363
-- Name: daily_summaries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.daily_summaries_id_seq OWNED BY public.daily_summaries.id;


--
-- TOC entry 364 (class 1259 OID 17802)
-- Name: exam_questions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.exam_questions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.exam_questions_id_seq OWNER TO postgres;

--
-- TOC entry 4831 (class 0 OID 0)
-- Dependencies: 364
-- Name: exam_questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.exam_questions_id_seq OWNED BY public.exam_questions.id;


--
-- TOC entry 365 (class 1259 OID 17803)
-- Name: exam_results; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exam_results (
    id integer NOT NULL,
    student_id integer NOT NULL,
    exam_id integer NOT NULL,
    obtained_marks numeric(5,2) DEFAULT 0 NOT NULL,
    total_marks numeric(5,2) NOT NULL,
    percentage numeric(5,2) GENERATED ALWAYS AS (((obtained_marks / NULLIF(total_marks, (0)::numeric)) * (100)::numeric)) STORED,
    status public.exam_attempt_status_enum DEFAULT 'in_progress'::public.exam_attempt_status_enum,
    answers jsonb,
    requires_manual_grading boolean DEFAULT false,
    graded_by integer,
    graded_at timestamp with time zone,
    started_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    submitted_at timestamp with time zone,
    student_name_cache character varying(100),
    exam_title_cache character varying(200),
    CONSTRAINT chk_exam_result_marks CHECK ((obtained_marks <= total_marks)),
    CONSTRAINT chk_exam_result_submitted CHECK ((((status = 'completed'::public.exam_attempt_status_enum) AND (submitted_at IS NOT NULL)) OR (status <> 'completed'::public.exam_attempt_status_enum)))
);


ALTER TABLE public.exam_results OWNER TO postgres;

--
-- TOC entry 366 (class 1259 OID 17815)
-- Name: exam_results_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.exam_results_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.exam_results_id_seq OWNER TO postgres;

--
-- TOC entry 4834 (class 0 OID 0)
-- Dependencies: 366
-- Name: exam_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.exam_results_id_seq OWNED BY public.exam_results.id;


--
-- TOC entry 367 (class 1259 OID 17816)
-- Name: exams_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.exams_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.exams_id_seq OWNER TO postgres;

--
-- TOC entry 4836 (class 0 OID 0)
-- Dependencies: 367
-- Name: exams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.exams_id_seq OWNED BY public.exams.id;


--
-- TOC entry 368 (class 1259 OID 17817)
-- Name: grades_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.grades_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.grades_id_seq OWNER TO postgres;

--
-- TOC entry 4838 (class 0 OID 0)
-- Dependencies: 368
-- Name: grades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.grades_id_seq OWNED BY public.grades.id;


--
-- TOC entry 369 (class 1259 OID 17818)
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.messages_id_seq OWNER TO postgres;

--
-- TOC entry 4840 (class 0 OID 0)
-- Dependencies: 369
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- TOC entry 370 (class 1259 OID 17819)
-- Name: mv_dashboard_stats; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public.mv_dashboard_stats AS
 SELECT ( SELECT count(*) AS count
           FROM public.students
          WHERE (students.deleted_at IS NULL)) AS total_students,
    ( SELECT count(*) AS count
           FROM public.teachers
          WHERE (teachers.deleted_at IS NULL)) AS total_teachers,
    ( SELECT count(*) AS count
           FROM public.subjects
          WHERE (subjects.is_active = true)) AS total_subjects,
    ( SELECT count(*) AS count
           FROM public.questions
          WHERE (questions.is_active = true)) AS total_questions,
    ( SELECT count(*) AS count
           FROM public.pending_content
          WHERE ((pending_content.status = 'pending'::public.approval_status_enum) AND (pending_content.content_type = 'exam'::public.pending_content_type_enum))) AS pending_exams,
    ( SELECT count(*) AS count
           FROM public.pending_content
          WHERE ((pending_content.status = 'pending'::public.approval_status_enum) AND (pending_content.content_type = 'question'::public.pending_content_type_enum))) AS pending_questions,
    ( SELECT count(*) AS count
           FROM public.messages
          WHERE ((messages.recipient_admin_id IS NOT NULL) AND (messages.is_read = false))) AS unread_messages,
    ( SELECT count(*) AS count
           FROM public.exams
          WHERE (exams.status = 'published'::public.exam_status_enum)) AS active_exams,
    CURRENT_TIMESTAMP AS last_updated
  WITH NO DATA;


ALTER MATERIALIZED VIEW public.mv_dashboard_stats OWNER TO postgres;

--
-- TOC entry 371 (class 1259 OID 17824)
-- Name: mv_monthly_attendance; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public.mv_monthly_attendance AS
 SELECT s.id AS student_id,
    s.student_code,
    s.full_name AS student_name,
    g.name AS grade_name,
    sec.name AS section_name,
    date_trunc('month'::text, (a.attendance_date)::timestamp with time zone) AS month,
    count(*) AS total_days,
    count(*) FILTER (WHERE (a.status = 'present'::public.attendance_status_enum)) AS present_days,
    count(*) FILTER (WHERE (a.status = 'absent'::public.attendance_status_enum)) AS absent_days,
    count(*) FILTER (WHERE (a.status = 'late'::public.attendance_status_enum)) AS late_days,
    count(*) FILTER (WHERE (a.status = 'excused'::public.attendance_status_enum)) AS excused_days,
    (((count(*) FILTER (WHERE (a.status = 'present'::public.attendance_status_enum)))::numeric * 100.0) / (NULLIF(count(*), 0))::numeric) AS attendance_percentage
   FROM (((public.attendance a
     JOIN public.students s ON ((a.student_id = s.id)))
     JOIN public.sections sec ON ((s.section_id = sec.id)))
     JOIN public.grades g ON ((sec.grade_id = g.id)))
  WHERE ((s.deleted_at IS NULL) AND (a.attendance_date >= (CURRENT_DATE - '1 year'::interval)))
  GROUP BY s.id, s.student_code, s.full_name, g.name, sec.name, (date_trunc('month'::text, (a.attendance_date)::timestamp with time zone))
  ORDER BY s.full_name, (date_trunc('month'::text, (a.attendance_date)::timestamp with time zone)) DESC
  WITH NO DATA;


ALTER MATERIALIZED VIEW public.mv_monthly_attendance OWNER TO postgres;

--
-- TOC entry 372 (class 1259 OID 17831)
-- Name: mv_student_monthly_performance; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public.mv_student_monthly_performance AS
 SELECT s.id AS student_id,
    s.student_code,
    s.full_name AS student_name,
    date_trunc('month'::text, er.submitted_at) AS month,
    sub.id AS subject_id,
    sub.name AS subject_name,
    count(er.id) AS total_exams,
    avg(er.percentage) AS average_percentage,
    sum(er.obtained_marks) AS total_obtained_marks,
    sum(er.total_marks) AS total_possible_marks
   FROM (((public.exam_results er
     JOIN public.students s ON ((er.student_id = s.id)))
     JOIN public.exams e ON ((er.exam_id = e.id)))
     JOIN public.subjects sub ON ((e.subject_id = sub.id)))
  WHERE ((er.status = 'completed'::public.exam_attempt_status_enum) AND (s.deleted_at IS NULL))
  GROUP BY s.id, s.student_code, s.full_name, (date_trunc('month'::text, er.submitted_at)), sub.id, sub.name
  ORDER BY s.full_name, (date_trunc('month'::text, er.submitted_at)) DESC, sub.name
  WITH NO DATA;


ALTER MATERIALIZED VIEW public.mv_student_monthly_performance OWNER TO postgres;

--
-- TOC entry 373 (class 1259 OID 17838)
-- Name: mv_subject_statistics; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public.mv_subject_statistics AS
 SELECT sub.id AS subject_id,
    sub.name AS subject_name,
    count(DISTINCT q.id) AS total_questions,
    count(DISTINCT e.id) AS total_exams,
    count(DISTINCT s.id) AS enrolled_students,
    count(DISTINCT ss.teacher_id) AS total_teachers,
    avg(er.percentage) AS average_score,
    (((count(*) FILTER (WHERE (er.percentage >= 50.0)))::numeric * 100.0) / (NULLIF(count(er.id), 0))::numeric) AS pass_rate
   FROM (((((public.subjects sub
     LEFT JOIN public.questions q ON (((sub.id = q.subject_id) AND (q.is_active = true))))
     LEFT JOIN public.exams e ON (((sub.id = e.subject_id) AND (e.status = 'published'::public.exam_status_enum))))
     LEFT JOIN public.section_subjects ss ON (((sub.id = ss.subject_id) AND (ss.is_active = true))))
     LEFT JOIN public.students s ON (((s.section_id = ss.section_id) AND (s.deleted_at IS NULL))))
     LEFT JOIN public.exam_results er ON (((e.id = er.exam_id) AND (er.status = 'completed'::public.exam_attempt_status_enum))))
  WHERE (sub.is_active = true)
  GROUP BY sub.id, sub.name
  ORDER BY sub.name
  WITH NO DATA;


ALTER MATERIALIZED VIEW public.mv_subject_statistics OWNER TO postgres;

--
-- TOC entry 374 (class 1259 OID 17845)
-- Name: mv_weekly_activity; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public.mv_weekly_activity AS
 SELECT date_trunc('week'::text, created_at) AS week_start,
    count(*) FILTER (WHERE ((user_type)::text = 'student'::text)) AS student_logins,
    count(*) FILTER (WHERE ((user_type)::text = 'teacher'::text)) AS teacher_logins,
    count(*) FILTER (WHERE ((user_type)::text = 'parent'::text)) AS parent_logins,
    count(*) FILTER (WHERE ((user_type)::text = 'admin'::text)) AS admin_logins,
    count(*) AS total_activity
   FROM public.activity_logs
  WHERE (((action)::text = 'login'::text) AND (created_at >= (CURRENT_DATE - '90 days'::interval)))
  GROUP BY (date_trunc('week'::text, created_at))
  ORDER BY (date_trunc('week'::text, created_at)) DESC
  WITH NO DATA;


ALTER MATERIALIZED VIEW public.mv_weekly_activity OWNER TO postgres;

--
-- TOC entry 375 (class 1259 OID 17850)
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    id integer NOT NULL,
    recipient_admin_id integer,
    recipient_teacher_id integer,
    recipient_student_id integer,
    recipient_parent_id integer,
    notification_type public.notification_type_enum NOT NULL,
    title character varying(200) NOT NULL,
    message text NOT NULL,
    metadata jsonb,
    is_read boolean DEFAULT false,
    read_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    expires_at timestamp with time zone,
    recipient_name_cache character varying(100),
    CONSTRAINT chk_notification_recipient CHECK ((((recipient_admin_id IS NOT NULL) AND (recipient_teacher_id IS NULL) AND (recipient_student_id IS NULL) AND (recipient_parent_id IS NULL)) OR ((recipient_admin_id IS NULL) AND (recipient_teacher_id IS NOT NULL) AND (recipient_student_id IS NULL) AND (recipient_parent_id IS NULL)) OR ((recipient_admin_id IS NULL) AND (recipient_teacher_id IS NULL) AND (recipient_student_id IS NOT NULL) AND (recipient_parent_id IS NULL)) OR ((recipient_admin_id IS NULL) AND (recipient_teacher_id IS NULL) AND (recipient_student_id IS NULL) AND (recipient_parent_id IS NOT NULL))))
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- TOC entry 376 (class 1259 OID 17858)
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notifications_id_seq OWNER TO postgres;

--
-- TOC entry 4848 (class 0 OID 0)
-- Dependencies: 376
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- TOC entry 377 (class 1259 OID 17859)
-- Name: parent_students_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.parent_students_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.parent_students_id_seq OWNER TO postgres;

--
-- TOC entry 4850 (class 0 OID 0)
-- Dependencies: 377
-- Name: parent_students_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.parent_students_id_seq OWNED BY public.parent_students.id;


--
-- TOC entry 378 (class 1259 OID 17860)
-- Name: parents_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.parents_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.parents_id_seq OWNER TO postgres;

--
-- TOC entry 4852 (class 0 OID 0)
-- Dependencies: 378
-- Name: parents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.parents_id_seq OWNED BY public.parents.id;


--
-- TOC entry 379 (class 1259 OID 17861)
-- Name: pending_content_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pending_content_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pending_content_id_seq OWNER TO postgres;

--
-- TOC entry 4854 (class 0 OID 0)
-- Dependencies: 379
-- Name: pending_content_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pending_content_id_seq OWNED BY public.pending_content.id;


--
-- TOC entry 403 (class 1259 OID 18622)
-- Name: practice_quiz_answers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.practice_quiz_answers (
    id integer NOT NULL,
    attempt_id integer NOT NULL,
    question_id integer NOT NULL,
    selected_answer text,
    is_correct boolean NOT NULL,
    time_spent_seconds integer
);


ALTER TABLE public.practice_quiz_answers OWNER TO postgres;

--
-- TOC entry 4856 (class 0 OID 0)
-- Dependencies: 403
-- Name: TABLE practice_quiz_answers; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.practice_quiz_answers IS 'Per-question answers for practice quizzes (analytics, weak topics)';


--
-- TOC entry 402 (class 1259 OID 18621)
-- Name: practice_quiz_answers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.practice_quiz_answers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.practice_quiz_answers_id_seq OWNER TO postgres;

--
-- TOC entry 4858 (class 0 OID 0)
-- Dependencies: 402
-- Name: practice_quiz_answers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.practice_quiz_answers_id_seq OWNED BY public.practice_quiz_answers.id;


--
-- TOC entry 401 (class 1259 OID 18589)
-- Name: practice_quiz_attempts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.practice_quiz_attempts (
    id integer NOT NULL,
    student_id integer NOT NULL,
    subject_id integer NOT NULL,
    chapter_id integer,
    score integer NOT NULL,
    total_questions integer NOT NULL,
    correct_answers integer NOT NULL,
    wrong_answers integer NOT NULL,
    unanswered integer DEFAULT 0 NOT NULL,
    time_taken_seconds integer DEFAULT 0 NOT NULL,
    completed_at timestamp with time zone DEFAULT now() NOT NULL,
    quiz_options jsonb DEFAULT '{}'::jsonb,
    CONSTRAINT chk_practice_quiz_attempt_score CHECK ((score <= total_questions)),
    CONSTRAINT chk_practice_quiz_attempt_totals CHECK ((((correct_answers + wrong_answers) + unanswered) <= total_questions))
);


ALTER TABLE public.practice_quiz_attempts OWNER TO postgres;

--
-- TOC entry 4860 (class 0 OID 0)
-- Dependencies: 401
-- Name: TABLE practice_quiz_attempts; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.practice_quiz_attempts IS 'Student self-paced practice quiz results (not formal exams)';


--
-- TOC entry 400 (class 1259 OID 18588)
-- Name: practice_quiz_attempts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.practice_quiz_attempts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.practice_quiz_attempts_id_seq OWNER TO postgres;

--
-- TOC entry 4862 (class 0 OID 0)
-- Dependencies: 400
-- Name: practice_quiz_attempts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.practice_quiz_attempts_id_seq OWNED BY public.practice_quiz_attempts.id;


--
-- TOC entry 380 (class 1259 OID 17862)
-- Name: questions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.questions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.questions_id_seq OWNER TO postgres;

--
-- TOC entry 4864 (class 0 OID 0)
-- Dependencies: 380
-- Name: questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.questions_id_seq OWNED BY public.questions.id;


--
-- TOC entry 381 (class 1259 OID 17863)
-- Name: reports_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reports_id_seq OWNER TO postgres;

--
-- TOC entry 4866 (class 0 OID 0)
-- Dependencies: 381
-- Name: reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reports_id_seq OWNED BY public.reports.id;


--
-- TOC entry 382 (class 1259 OID 17864)
-- Name: school_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.school_settings (
    id integer NOT NULL,
    school_name character varying(200) DEFAULT 'مدرسة النموذجية'::character varying NOT NULL,
    school_logo bytea,
    school_logo_filename character varying(255),
    school_logo_mime_type character varying(50),
    school_logo_size integer,
    admin_code character varying(50) DEFAULT 'ADMIN2025'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    school_logo_url text,
    school_logo_storage_path text,
    CONSTRAINT chk_logo_url_valid CHECK (((school_logo_url IS NULL) OR (school_logo_url ~* '^https?://'::text))),
    CONSTRAINT school_settings_id_check CHECK ((id = 1))
);


ALTER TABLE public.school_settings OWNER TO postgres;

--
-- TOC entry 4868 (class 0 OID 0)
-- Dependencies: 382
-- Name: COLUMN school_settings.school_logo_url; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.school_settings.school_logo_url IS 'Public URL from Supabase Storage';


--
-- TOC entry 4869 (class 0 OID 0)
-- Dependencies: 382
-- Name: COLUMN school_settings.school_logo_storage_path; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.school_settings.school_logo_storage_path IS 'Storage path: school-settings/{filename}';


--
-- TOC entry 383 (class 1259 OID 17875)
-- Name: section_subjects_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.section_subjects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.section_subjects_id_seq OWNER TO postgres;

--
-- TOC entry 4871 (class 0 OID 0)
-- Dependencies: 383
-- Name: section_subjects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.section_subjects_id_seq OWNED BY public.section_subjects.id;


--
-- TOC entry 384 (class 1259 OID 17876)
-- Name: sections_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sections_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sections_id_seq OWNER TO postgres;

--
-- TOC entry 4873 (class 0 OID 0)
-- Dependencies: 384
-- Name: sections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sections_id_seq OWNED BY public.sections.id;


--
-- TOC entry 385 (class 1259 OID 17877)
-- Name: semesters_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.semesters_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.semesters_id_seq OWNER TO postgres;

--
-- TOC entry 4875 (class 0 OID 0)
-- Dependencies: 385
-- Name: semesters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.semesters_id_seq OWNED BY public.semesters.id;


--
-- TOC entry 386 (class 1259 OID 17878)
-- Name: seq_student_code; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.seq_student_code
    START WITH 10001
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.seq_student_code OWNER TO postgres;

--
-- TOC entry 387 (class 1259 OID 17879)
-- Name: seq_subject_code; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.seq_subject_code
    START WITH 101
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.seq_subject_code OWNER TO postgres;

--
-- TOC entry 388 (class 1259 OID 17880)
-- Name: seq_teacher_code; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.seq_teacher_code
    START WITH 1001
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.seq_teacher_code OWNER TO postgres;

--
-- TOC entry 405 (class 1259 OID 18643)
-- Name: student_summaries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student_summaries (
    id integer NOT NULL,
    student_id integer NOT NULL,
    subject_id integer NOT NULL,
    chapter_id integer,
    title character varying(200) NOT NULL,
    content text NOT NULL,
    summary_type character varying(50) DEFAULT 'summary'::character varying,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.student_summaries OWNER TO postgres;

--
-- TOC entry 4880 (class 0 OID 0)
-- Dependencies: 405
-- Name: TABLE student_summaries; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.student_summaries IS 'Student-created or AI-generated chapter summaries';


--
-- TOC entry 404 (class 1259 OID 18642)
-- Name: student_summaries_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.student_summaries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.student_summaries_id_seq OWNER TO postgres;

--
-- TOC entry 4882 (class 0 OID 0)
-- Dependencies: 404
-- Name: student_summaries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.student_summaries_id_seq OWNED BY public.student_summaries.id;


--
-- TOC entry 389 (class 1259 OID 17881)
-- Name: students_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.students_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.students_id_seq OWNER TO postgres;

--
-- TOC entry 4884 (class 0 OID 0)
-- Dependencies: 389
-- Name: students_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.students_id_seq OWNED BY public.students.id;


--
-- TOC entry 390 (class 1259 OID 17882)
-- Name: subjects_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.subjects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.subjects_id_seq OWNER TO postgres;

--
-- TOC entry 4886 (class 0 OID 0)
-- Dependencies: 390
-- Name: subjects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.subjects_id_seq OWNED BY public.subjects.id;


--
-- TOC entry 391 (class 1259 OID 17883)
-- Name: teachers_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.teachers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.teachers_id_seq OWNER TO postgres;

--
-- TOC entry 4888 (class 0 OID 0)
-- Dependencies: 391
-- Name: teachers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.teachers_id_seq OWNED BY public.teachers.id;


--
-- TOC entry 392 (class 1259 OID 17884)
-- Name: v_active_students; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_active_students AS
 SELECT s.id,
    s.student_code,
    s.full_name,
    s.phone_number,
    s.email,
    sec.id AS section_id,
    sec.name AS section_name,
    g.id AS grade_id,
    g.name AS grade_name,
    g.grade_order,
    s.created_at,
    s.last_login_at
   FROM ((public.students s
     JOIN public.sections sec ON ((s.section_id = sec.id)))
     JOIN public.grades g ON ((sec.grade_id = g.id)))
  WHERE ((s.deleted_at IS NULL) AND (sec.is_active = true))
  ORDER BY g.grade_order, sec.name, s.full_name;


ALTER VIEW public.v_active_students OWNER TO postgres;

--
-- TOC entry 393 (class 1259 OID 17889)
-- Name: v_curriculum_gaps; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_curriculum_gaps AS
 SELECT e.section_id,
    e.subject_id,
    q.chapter_id,
    c.name AS chapter_name,
    count(DISTINCT er.student_id) AS total_students,
    count(DISTINCT
        CASE
            WHEN ((er.total_marks > (0)::numeric) AND (((er.obtained_marks)::numeric / er.total_marks) < 0.6)) THEN er.student_id
            ELSE NULL::integer
        END) AS failed_students,
        CASE
            WHEN (sum(er.total_marks) > (0)::numeric) THEN (1.0 - (sum(er.obtained_marks) / sum(er.total_marks)))
            ELSE (0)::numeric
        END AS failure_rate
   FROM ((((public.exam_results er
     JOIN public.exams e ON ((e.id = er.exam_id)))
     JOIN public.exam_questions eq ON ((eq.exam_id = e.id)))
     JOIN public.questions q ON ((q.id = eq.question_id)))
     LEFT JOIN public.chapters c ON ((c.id = q.chapter_id)))
  WHERE (er.status = 'completed'::public.exam_attempt_status_enum)
  GROUP BY e.section_id, e.subject_id, q.chapter_id, c.name;


ALTER VIEW public.v_curriculum_gaps OWNER TO postgres;

--
-- TOC entry 394 (class 1259 OID 17894)
-- Name: v_pending_exams; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_pending_exams AS
 SELECT pc.id,
    (pc.content_data ->> 'title'::text) AS exam_title,
    t.full_name AS teacher_name,
    t.teacher_code,
    sub.name AS subject_name,
    pc.submitted_at,
    pc.content_data
   FROM ((public.pending_content pc
     JOIN public.teachers t ON ((pc.teacher_id = t.id)))
     LEFT JOIN public.subjects sub ON ((((pc.content_data ->> 'subject_id'::text))::integer = sub.id)))
  WHERE ((pc.content_type = 'exam'::public.pending_content_type_enum) AND (pc.status = 'pending'::public.approval_status_enum))
  ORDER BY pc.submitted_at DESC;


ALTER VIEW public.v_pending_exams OWNER TO postgres;

--
-- TOC entry 395 (class 1259 OID 17899)
-- Name: v_pending_questions; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_pending_questions AS
 SELECT pc.id,
    (pc.content_data ->> 'question_text'::text) AS question_text,
    (pc.content_data ->> 'question_type'::text) AS question_type,
    (pc.content_data ->> 'difficulty_level'::text) AS difficulty_level,
    t.full_name AS teacher_name,
    sub.name AS subject_name,
    pc.submitted_at,
    pc.content_data
   FROM ((public.pending_content pc
     JOIN public.teachers t ON ((pc.teacher_id = t.id)))
     LEFT JOIN public.subjects sub ON ((((pc.content_data ->> 'subject_id'::text))::integer = sub.id)))
  WHERE ((pc.content_type = 'question'::public.pending_content_type_enum) AND (pc.status = 'pending'::public.approval_status_enum))
  ORDER BY pc.submitted_at DESC;


ALTER VIEW public.v_pending_questions OWNER TO postgres;

--
-- TOC entry 396 (class 1259 OID 17904)
-- Name: v_student_grades; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_student_grades AS
 SELECT s.id AS student_id,
    s.student_code,
    s.full_name AS student_name,
    e.id AS exam_id,
    e.title AS exam_title,
    sub.name AS subject_name,
    er.obtained_marks,
    er.total_marks,
    er.percentage,
    er.submitted_at,
    er.status
   FROM (((public.exam_results er
     JOIN public.students s ON ((er.student_id = s.id)))
     JOIN public.exams e ON ((er.exam_id = e.id)))
     JOIN public.subjects sub ON ((e.subject_id = sub.id)))
  WHERE ((s.deleted_at IS NULL) AND (er.status = 'completed'::public.exam_attempt_status_enum))
  ORDER BY s.full_name, er.submitted_at DESC;


ALTER VIEW public.v_student_grades OWNER TO postgres;

--
-- TOC entry 397 (class 1259 OID 17909)
-- Name: v_teacher_classes; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_teacher_classes AS
 SELECT ss.section_id,
    ss.subject_id,
    ss.teacher_id,
    s.name AS section_name,
    s.grade_id,
    g.name AS grade_name,
    sub.name AS subject_name,
    ( SELECT count(*) AS count
           FROM public.students st
          WHERE ((st.section_id = ss.section_id) AND (st.deleted_at IS NULL))) AS student_count
   FROM (((public.section_subjects ss
     JOIN public.sections s ON ((s.id = ss.section_id)))
     JOIN public.grades g ON ((g.id = s.grade_id)))
     JOIN public.subjects sub ON ((sub.id = ss.subject_id)))
  WHERE (((s.is_active IS NULL) OR (s.is_active = true)) AND ((sub.is_active IS NULL) OR (sub.is_active = true)));


ALTER VIEW public.v_teacher_classes OWNER TO postgres;

--
-- TOC entry 398 (class 1259 OID 17914)
-- Name: v_teachers_with_subjects; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_teachers_with_subjects AS
 SELECT t.id AS teacher_id,
    t.teacher_code,
    t.full_name AS teacher_name,
    t.phone_number,
    t.email,
    sub.id AS subject_id,
    sub.name AS subject_name,
    g.name AS grade_name,
    sec.name AS section_name,
    ss.assigned_at
   FROM ((((public.teachers t
     JOIN public.section_subjects ss ON ((t.id = ss.teacher_id)))
     JOIN public.subjects sub ON ((ss.subject_id = sub.id)))
     JOIN public.sections sec ON ((ss.section_id = sec.id)))
     JOIN public.grades g ON ((sec.grade_id = g.id)))
  WHERE ((t.deleted_at IS NULL) AND (ss.is_active = true) AND (sec.is_active = true))
  ORDER BY t.full_name, g.grade_order, sub.name;


ALTER VIEW public.v_teachers_with_subjects OWNER TO postgres;

--
-- TOC entry 399 (class 1259 OID 17919)
-- Name: v_unread_messages_admin; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_unread_messages_admin AS
 SELECT m.id,
    m.subject,
    m.message_text,
    p.full_name AS sender_name,
    p.phone_number AS sender_phone,
    m.sent_at
   FROM (public.messages m
     JOIN public.parents p ON ((m.sender_parent_id = p.id)))
  WHERE ((m.recipient_admin_id IS NOT NULL) AND (m.is_read = false))
  ORDER BY m.sent_at DESC;


ALTER VIEW public.v_unread_messages_admin OWNER TO postgres;

--
-- TOC entry 3956 (class 2604 OID 17924)
-- Name: activities id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activities ALTER COLUMN id SET DEFAULT nextval('public.activities_id_seq'::regclass);


--
-- TOC entry 3961 (class 2604 OID 17925)
-- Name: activity_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs ALTER COLUMN id SET DEFAULT nextval('public.activity_logs_id_seq'::regclass);


--
-- TOC entry 3888 (class 2604 OID 17926)
-- Name: admins id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admins ALTER COLUMN id SET DEFAULT nextval('public.admins_id_seq'::regclass);


--
-- TOC entry 3963 (class 2604 OID 17927)
-- Name: app_user id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.app_user ALTER COLUMN id SET DEFAULT nextval('public.app_user_id_seq'::regclass);


--
-- TOC entry 3892 (class 2604 OID 17928)
-- Name: attendance id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance ALTER COLUMN id SET DEFAULT nextval('public.attendance_id_seq'::regclass);


--
-- TOC entry 3997 (class 2604 OID 20970)
-- Name: chapter_topics id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chapter_topics ALTER COLUMN id SET DEFAULT nextval('public.chapter_topics_id_seq'::regclass);


--
-- TOC entry 3965 (class 2604 OID 17929)
-- Name: chapters id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chapters ALTER COLUMN id SET DEFAULT nextval('public.chapters_id_seq'::regclass);


--
-- TOC entry 3970 (class 2604 OID 17930)
-- Name: daily_summaries id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.daily_summaries ALTER COLUMN id SET DEFAULT nextval('public.daily_summaries_id_seq'::regclass);


--
-- TOC entry 3895 (class 2604 OID 17931)
-- Name: exam_questions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_questions ALTER COLUMN id SET DEFAULT nextval('public.exam_questions_id_seq'::regclass);


--
-- TOC entry 3975 (class 2604 OID 17932)
-- Name: exam_results id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_results ALTER COLUMN id SET DEFAULT nextval('public.exam_results_id_seq'::regclass);


--
-- TOC entry 3898 (class 2604 OID 17933)
-- Name: exams id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exams ALTER COLUMN id SET DEFAULT nextval('public.exams_id_seq'::regclass);


--
-- TOC entry 3904 (class 2604 OID 17934)
-- Name: grades id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grades ALTER COLUMN id SET DEFAULT nextval('public.grades_id_seq'::regclass);


--
-- TOC entry 3908 (class 2604 OID 17935)
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- TOC entry 3981 (class 2604 OID 17936)
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- TOC entry 3954 (class 2604 OID 17937)
-- Name: parent_students id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parent_students ALTER COLUMN id SET DEFAULT nextval('public.parent_students_id_seq'::regclass);


--
-- TOC entry 3911 (class 2604 OID 17938)
-- Name: parents id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parents ALTER COLUMN id SET DEFAULT nextval('public.parents_id_seq'::regclass);


--
-- TOC entry 3915 (class 2604 OID 17939)
-- Name: pending_content id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pending_content ALTER COLUMN id SET DEFAULT nextval('public.pending_content_id_seq'::regclass);


--
-- TOC entry 3993 (class 2604 OID 18625)
-- Name: practice_quiz_answers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.practice_quiz_answers ALTER COLUMN id SET DEFAULT nextval('public.practice_quiz_answers_id_seq'::regclass);


--
-- TOC entry 3988 (class 2604 OID 18592)
-- Name: practice_quiz_attempts id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.practice_quiz_attempts ALTER COLUMN id SET DEFAULT nextval('public.practice_quiz_attempts_id_seq'::regclass);


--
-- TOC entry 3918 (class 2604 OID 17940)
-- Name: questions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questions ALTER COLUMN id SET DEFAULT nextval('public.questions_id_seq'::regclass);


--
-- TOC entry 3928 (class 2604 OID 17941)
-- Name: reports id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports ALTER COLUMN id SET DEFAULT nextval('public.reports_id_seq'::regclass);


--
-- TOC entry 3931 (class 2604 OID 17942)
-- Name: section_subjects id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.section_subjects ALTER COLUMN id SET DEFAULT nextval('public.section_subjects_id_seq'::regclass);


--
-- TOC entry 3935 (class 2604 OID 17943)
-- Name: sections id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sections ALTER COLUMN id SET DEFAULT nextval('public.sections_id_seq'::regclass);


--
-- TOC entry 3939 (class 2604 OID 17944)
-- Name: semesters id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.semesters ALTER COLUMN id SET DEFAULT nextval('public.semesters_id_seq'::regclass);


--
-- TOC entry 3994 (class 2604 OID 18646)
-- Name: student_summaries id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_summaries ALTER COLUMN id SET DEFAULT nextval('public.student_summaries_id_seq'::regclass);


--
-- TOC entry 3942 (class 2604 OID 17945)
-- Name: students id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students ALTER COLUMN id SET DEFAULT nextval('public.students_id_seq'::regclass);


--
-- TOC entry 3946 (class 2604 OID 17946)
-- Name: subjects id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subjects ALTER COLUMN id SET DEFAULT nextval('public.subjects_id_seq'::regclass);


--
-- TOC entry 3950 (class 2604 OID 17947)
-- Name: teachers id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teachers ALTER COLUMN id SET DEFAULT nextval('public.teachers_id_seq'::regclass);


--
-- TOC entry 4614 (class 0 OID 17756)
-- Dependencies: 352
-- Data for Name: activities; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.activities (id, student_id, title, description, subject_id, priority, created_by_teacher_id, created_at, updated_at, activity_type, status, due_date) FROM stdin;
\.


--
-- TOC entry 4616 (class 0 OID 17766)
-- Dependencies: 354
-- Data for Name: activity_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.activity_logs (id, user_type, user_id, user_name_cache, action, description, metadata, ip_address, user_agent, created_at) FROM stdin;
1	admin	1	General Director	login	Successful login	\N	\N	\N	2026-02-08 01:38:07.717554+00
2	admin	1	General Director	login	Successful login	\N	\N	\N	2026-02-09 00:17:33.363909+00
3	admin	1	General Director	login	Successful login	\N	\N	\N	2026-02-09 00:25:29.848002+00
4	admin	1	General Director	login	Successful login	\N	\N	\N	2026-02-09 00:27:41.161946+00
5	admin	1	General Director	login	Successful login	\N	\N	\N	2026-02-09 00:29:36.806906+00
6	admin	1	General Director	login	Successful login	\N	\N	\N	2026-02-09 00:46:26.079013+00
7	admin	1	General Director	login	Successful login	\N	\N	\N	2026-02-09 00:48:10.086228+00
8	admin	1	General Director	login	Successful login	\N	\N	\N	2026-02-09 01:39:31.774468+00
9	admin	1	General Director	login	Successful login	\N	\N	\N	2026-02-09 02:13:11.598566+00
10	admin	1	General Director	login	Successful login	\N	\N	\N	2026-02-09 02:13:22.554194+00
11	admin	1	General Director	login	Successful login	\N	\N	\N	2026-02-09 02:28:55.631531+00
12	admin	1	General Director	login	Successful login	\N	\N	\N	2026-02-09 03:29:55.397955+00
13	admin	1	General Director	login	Successful login	\N	\N	\N	2026-02-09 03:36:26.613473+00
14	admin	1	Amjed Essam	login	Successful login	\N	\N	\N	2026-02-16 01:33:54.310256+00
15	admin	1	Amjed Essam	login	Successful login	\N	\N	\N	2026-02-16 01:36:04.343115+00
16	admin	1	Amjed Essam	login	Successful login	\N	\N	\N	2026-02-16 01:47:59.923093+00
\.


--
-- TOC entry 4597 (class 0 OID 17561)
-- Dependencies: 335
-- Data for Name: admins; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.admins (id, full_name, email, password_hash, phone_number, is_active, last_login_at, created_at, updated_at, deleted_at, deleted_by, profile_image_url, profile_image_storage_path) FROM stdin;
1	Amjed Essam	admin@school.com	$2a$12$mW/IHq3rPx6TW3pPS.eh1.Y2/4Agvp29ewG41XRc8AFUw6G/JDwW.	0501234567	t	2026-02-16 01:47:59.923093+00	2026-02-08 00:24:02.260276+00	2026-02-16 01:47:59.923093+00	\N	\N	https://lgzzkkemwrukysxhxiuk.supabase.co/storage/v1/object/public/profile-images/admins/1/20250925_064637.jpg	admins/1/20250925_064637.jpg
\.


--
-- TOC entry 4619 (class 0 OID 17775)
-- Dependencies: 357
-- Data for Name: app_user; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.app_user (id, auth_user_id, user_type, app_entity_id, created_at) FROM stdin;
1	7b4031d4-d071-453e-978e-e1f5fc251555	student	1	2026-02-24 00:01:09.80636+00
2	f37dad32-fd3f-4250-be3f-97d865d55430	parent	1	2026-02-28 00:33:20.32961+00
\.


--
-- TOC entry 4598 (class 0 OID 17571)
-- Dependencies: 336
-- Data for Name: attendance; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attendance (id, student_id, section_id, attendance_date, status, notes, marked_by, marked_at, student_name_cache, section_name_cache) FROM stdin;
\.


--
-- TOC entry 4661 (class 0 OID 20967)
-- Dependencies: 408
-- Data for Name: chapter_topics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chapter_topics (id, chapter_id, title, description, order_index, duration_min, is_active, created_at) FROM stdin;
\.


--
-- TOC entry 4622 (class 0 OID 17782)
-- Dependencies: 360
-- Data for Name: chapters; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chapters (id, subject_id, name, description, order_index, is_active, created_at, updated_at) FROM stdin;
1	1	الفاتحة والبقرة	سور القرآن الكريم	1	t	2026-02-24 00:12:50.938437+00	2026-02-24 00:12:50.938437+00
2	1	سورة آل عمران	سور القرآن الكريم	2	t	2026-02-24 00:12:50.938437+00	2026-02-24 00:12:50.938437+00
3	2	النصوص الأدبية	نصوص اللغة العربية	1	t	2026-02-24 00:12:50.938437+00	2026-02-24 00:12:50.938437+00
4	2	القواعد النحوية	قواعد اللغة العربية	2	t	2026-02-24 00:12:50.938437+00	2026-02-24 00:12:50.938437+00
5	3	Unit 1	English Language	1	t	2026-02-24 00:12:50.938437+00	2026-02-24 00:12:50.938437+00
6	3	Unit 2	English Language	2	t	2026-02-24 00:12:50.938437+00	2026-02-24 00:12:50.938437+00
7	4	الوحدة الأولى	الدراسات الاجتماعية	1	t	2026-02-24 00:12:50.938437+00	2026-02-24 00:12:50.938437+00
8	5	العقيدة	التربية الإسلامية	1	t	2026-02-24 00:12:50.938437+00	2026-02-24 00:12:50.938437+00
9	9	الأحياء	علوم الأحياء	1	t	2026-02-24 00:12:50.938437+00	2026-02-24 00:12:50.938437+00
10	9	الفيزياء	علوم الفيزياء	2	t	2026-02-24 00:12:50.938437+00	2026-02-24 00:12:50.938437+00
\.


--
-- TOC entry 4624 (class 0 OID 17792)
-- Dependencies: 362
-- Data for Name: daily_summaries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.daily_summaries (id, student_id, summary_date, recap, participation_level, behavior_level, focus_level, teacher_note, highlight_of_day, subjects_studied, subject_notes, created_by_teacher_id, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 4599 (class 0 OID 17581)
-- Dependencies: 337
-- Data for Name: exam_questions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.exam_questions (id, exam_id, question_id, question_order, marks, added_at) FROM stdin;
\.


--
-- TOC entry 4627 (class 0 OID 17803)
-- Dependencies: 365
-- Data for Name: exam_results; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.exam_results (id, student_id, exam_id, obtained_marks, total_marks, status, answers, requires_manual_grading, graded_by, graded_at, started_at, submitted_at, student_name_cache, exam_title_cache) FROM stdin;
\.


--
-- TOC entry 4600 (class 0 OID 17588)
-- Dependencies: 338
-- Data for Name: exams; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.exams (id, title, description, subject_id, grade_id, section_id, semester_id, total_marks, passing_marks, duration_minutes, difficulty_level, pdf_content, pdf_filename, pdf_size, created_by_admin, created_by_teacher, status, scheduled_at, published_at, created_at, updated_at, pdf_url, pdf_storage_path) FROM stdin;
13	سهل	يسيط	9	1	1	1	0	0	60	medium	\N	ID3 COMPLETE EXAMPLE_lecture 5-2.pdf	164916	1	\N	draft	\N	\N	2026-02-16 01:15:57.095206+00	2026-02-16 01:16:26.140777+00	https://lgzzkkemwrukysxhxiuk.supabase.co/storage/v1/object/public/exam-files/13/ID3_COMPLETE_EXAMPLE_lecture_5-2.pdf	13/ID3_COMPLETE_EXAMPLE_lecture_5-2.pdf
\.


--
-- TOC entry 4601 (class 0 OID 17602)
-- Dependencies: 339
-- Data for Name: grades; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.grades (id, name, grade_order, description, is_active, created_at, updated_at) FROM stdin;
1	First Grade	1	First Grade	t	2026-02-08 00:24:02.260276+00	2026-02-08 00:24:02.260276+00
2	Second Grade	2	Second Grade	t	2026-02-08 00:24:02.260276+00	2026-02-08 00:24:02.260276+00
3	Third Grade	3	Third Grade	t	2026-02-08 00:24:02.260276+00	2026-02-08 00:24:02.260276+00
4	Fourth Grade	4	Fourth Grade	t	2026-02-08 00:24:02.260276+00	2026-02-08 00:24:02.260276+00
5	Fifth Grade	5	Fifth Grade	t	2026-02-08 00:24:02.260276+00	2026-02-08 00:24:02.260276+00
6	Sixth Grade	6	Sixth Grade	t	2026-02-08 00:24:02.260276+00	2026-02-08 00:24:02.260276+00
\.


--
-- TOC entry 4602 (class 0 OID 17611)
-- Dependencies: 340
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.messages (id, sender_admin_id, sender_parent_id, recipient_admin_id, recipient_parent_id, subject, message_text, is_read, read_at, sent_at, sender_teacher_id, recipient_teacher_id) FROM stdin;
3	1	\N	\N	1	\N	هلا كيفك 	f	\N	2026-02-16 23:40:39.08626+00	\N	\N
4	1	\N	\N	1	\N	اخبارك امورك كيف 	f	\N	2026-02-16 23:41:11.098306+00	\N	\N
5	1	\N	\N	1	\N	اخبارك كيف	f	\N	2026-02-16 23:47:05.031908+00	\N	\N
6	1	\N	\N	2	\N	كيفك 	f	\N	2026-02-17 00:55:39.153976+00	\N	\N
7	1	\N	\N	1	\N	مرحبا	f	\N	2026-02-20 00:11:00.82881+00	\N	\N
\.


--
-- TOC entry 4637 (class 0 OID 17850)
-- Dependencies: 375
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notifications (id, recipient_admin_id, recipient_teacher_id, recipient_student_id, recipient_parent_id, notification_type, title, message, metadata, is_read, read_at, created_at, expires_at, recipient_name_cache) FROM stdin;
\.


--
-- TOC entry 4613 (class 0 OID 17734)
-- Dependencies: 351
-- Data for Name: parent_students; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.parent_students (id, parent_id, student_id, relationship, linked_at) FROM stdin;
21	1	1	أب	2026-03-01 21:22:50.634474+00
\.


--
-- TOC entry 4603 (class 0 OID 17622)
-- Dependencies: 341
-- Data for Name: parents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.parents (id, full_name, phone_number, email, password_hash, is_active, last_login_at, created_at, updated_at) FROM stdin;
1	Abdullah Mohammed	0502222222	parent@school.com	$2a$12$AnDlrE3bcPZzb49HjbjUcet.LhSMkwaqd7nVIWyb.ojcZo2Qy3C0a	t	\N	2026-02-08 00:24:02.260276+00	2026-02-08 00:24:02.260276+00
2	عصام مشرح	774353045	essam@gmail.com	2004	t	\N	2026-02-16 23:49:32.319478+00	2026-02-16 23:49:32.319478+00
\.


--
-- TOC entry 4604 (class 0 OID 17630)
-- Dependencies: 342
-- Data for Name: pending_content; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pending_content (id, content_type, content_data, teacher_id, status, reviewed_by, reviewed_at, rejection_reason, submitted_at) FROM stdin;
\.


--
-- TOC entry 4657 (class 0 OID 18622)
-- Dependencies: 403
-- Data for Name: practice_quiz_answers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.practice_quiz_answers (id, attempt_id, question_id, selected_answer, is_correct, time_spent_seconds) FROM stdin;
1	1	4	options	f	\N
2	2	3	options	f	\N
3	3	4	options	f	\N
4	4	3	\N	f	\N
5	5	4	options	f	\N
6	6	4	options	f	\N
7	7	4	\N	f	\N
8	8	4	options	f	\N
9	9	4	A	f	\N
10	10	4	A	t	\N
11	11	4	A	t	\N
12	12	3	A	t	\N
13	13	4	\N	f	\N
14	14	4	A	f	\N
15	15	4	B	t	\N
16	15	7	C	f	\N
17	15	8	A	t	\N
18	15	9	A	t	\N
19	16	11	B	t	\N
\.


--
-- TOC entry 4655 (class 0 OID 18589)
-- Dependencies: 401
-- Data for Name: practice_quiz_attempts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.practice_quiz_attempts (id, student_id, subject_id, chapter_id, score, total_questions, correct_answers, wrong_answers, unanswered, time_taken_seconds, completed_at, quiz_options) FROM stdin;
1	1	9	9	0	1	0	1	0	3	2026-02-24 00:28:41.842759+00	{"difficulty": "mixed"}
2	1	1	1	0	1	0	1	0	5	2026-02-24 00:29:31.793106+00	{"difficulty": "mixed"}
3	1	9	9	0	1	0	1	0	10	2026-02-24 23:22:38.117763+00	{"difficulty": "mixed"}
4	1	1	1	0	1	0	0	1	2	2026-02-24 23:35:05.529797+00	{"difficulty": "mixed"}
5	1	9	9	0	1	0	1	0	3	2026-02-24 23:37:22.315734+00	{"difficulty": "mixed"}
6	1	9	9	0	1	0	1	0	2	2026-02-24 23:41:21.176931+00	{"difficulty": "mixed"}
7	1	9	9	0	1	0	0	1	7	2026-02-25 00:35:32.259846+00	{"difficulty": "mixed"}
8	1	9	9	0	1	0	1	0	3	2026-02-26 00:38:39.013766+00	{"difficulty": "mixed"}
9	1	9	9	0	1	0	1	0	34	2026-02-26 21:06:24.579337+00	{"difficulty": "mixed"}
10	1	9	9	1	1	1	0	0	7	2026-02-26 21:10:27.110854+00	{"difficulty": "mixed"}
11	1	9	9	1	1	1	0	0	138	2026-02-26 21:14:12.733945+00	{"difficulty": "mixed"}
12	1	1	1	1	1	1	0	0	7	2026-02-26 22:40:49.658341+00	{"difficulty": "mixed"}
13	1	9	9	0	1	0	0	1	600	2026-02-26 22:52:26.702382+00	{"difficulty": "mixed"}
14	1	9	9	0	1	0	1	0	3	2026-02-26 23:00:38.607662+00	{"difficulty": "mixed"}
15	1	9	9	3	4	3	1	0	16	2026-02-27 00:14:53.273514+00	{"difficulty": "mixed"}
16	1	9	10	1	1	1	0	0	2	2026-02-27 00:15:25.296984+00	{"difficulty": "mixed"}
\.


--
-- TOC entry 4605 (class 0 OID 17640)
-- Dependencies: 343
-- Data for Name: questions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.questions (id, question_text, question_type, question_options, correct_answer, difficulty_level, subject_id, created_by_admin, created_by_teacher, status, is_active, created_at, updated_at, pdf_url, pdf_storage_path, pdf_filename, chapter_id, times_used, times_correct, times_incorrect, difficulty_index, discrimination_index, quality, explanation, skill, reference_page) FROM stdin;
2	عرف معنى العشق 	essay	null	\N	easy	4	1	\N	approved	t	2026-02-16 00:32:43.737243+00	2026-02-26 20:54:14.556807+00	\N	\N	\N	7	0	0	0	0.50	0.30	\N	\N	remember	\N
6	هل الاسلام يعتبر دين مهم للحياة	true_false	{"A": "صحيح", "B": "خطأ"}	A	easy	1	1	\N	approved	t	2026-02-25 00:18:10.040991+00	2026-02-26 21:09:22.502433+00	\N	\N	\N	\N	0	0	0	0.50	0.30	\N	\N	understand	\N
3	ملف pdf	multiple_choice	{"A": "1", "B": "2", "C": "3", "D": "4"}	A	medium	1	1	\N	approved	t	2026-02-16 00:34:25.577582+00	2026-02-26 21:09:22.502433+00	https://lgzzkkemwrukysxhxiuk.supabase.co/storage/v1/object/public/subject-materials/questions/3/preprocessing_lecture2.pdf	questions/3/preprocessing_lecture2.pdf	preprocessing_lecture2.pdf	1	0	0	0	0.50	0.30	\N	\N	remember	\N
4	هل تحب ريال مدريد	true_false	{"A": "صحيح", "B": "خطأ"}	B	easy	9	1	\N	approved	t	2026-02-16 00:58:20.754161+00	2026-02-26 22:58:01.576139+00	\N	\N	\N	9	0	0	0	0.50	0.30	\N	\N	apply	\N
7	كم عمرك	multiple_choice	{"A": "12", "B": "15", "C": "22", "D": "24"}	A	easy	9	1	\N	approved	t	2026-02-26 21:17:09.807148+00	2026-02-27 00:00:17.6784+00	\N	\N	\N	9	0	0	0	0.50	0.30	\N	\N	\N	\N
8	كم تحب امجد	multiple_choice	{"A": "خيرات", "B": "قوي ", "C": "شوية", "D": "ماحبه"}	A	easy	9	1	\N	approved	t	2026-02-26 23:02:50.618663+00	2026-02-27 00:00:17.6784+00	\N	\N	\N	9	0	0	0	0.50	0.30	\N	\N	\N	\N
9	تحب امجد	true_false	{"A": "صحيح", "B": "خطأ"}	A	easy	9	1	\N	approved	t	2026-02-26 23:05:10.819296+00	2026-02-27 00:02:19.082083+00	\N	\N	\N	9	0	0	0	0.50	0.30	\N	\N	\N	\N
10	ماذا تاكل	multiple_choice	{"A": "احذي", "B": "سراويل", "C": "صنادل", "D": "ولاشي"}	D	easy	9	1	\N	approved	t	2026-02-27 00:03:19.064275+00	2026-02-27 00:12:29.373995+00	\N	\N	\N	\N	0	0	0	0.50	0.30	\N	\N	\N	\N
11	وينك	true_false	{"A": "صحيح", "B": "خطأ"}	B	easy	9	1	\N	approved	t	2026-02-27 00:13:28.253997+00	2026-02-27 00:13:28.253997+00	\N	\N	\N	10	0	0	0	0.50	0.30	\N	\N	\N	\N
\.


--
-- TOC entry 4606 (class 0 OID 17658)
-- Dependencies: 344
-- Data for Name: reports; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reports (id, student_id, parent_id, title, report_text, sent_by, sent_at, is_read, read_at) FROM stdin;
2	1	1	الطالب منخفظ مستواه	لازم من ان يجتهد	1	2026-02-17 00:51:43.660655+00	f	\N
\.


--
-- TOC entry 4644 (class 0 OID 17864)
-- Dependencies: 382
-- Data for Name: school_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.school_settings (id, school_name, school_logo, school_logo_filename, school_logo_mime_type, school_logo_size, admin_code, created_at, updated_at, school_logo_url, school_logo_storage_path) FROM stdin;
1	مدرسة النموذجية	\N	\N	\N	\N	ADMIN2025	2026-02-08 00:23:01.656065+00	2026-02-08 00:23:01.656065+00	\N	\N
\.


--
-- TOC entry 4607 (class 0 OID 17667)
-- Dependencies: 345
-- Data for Name: section_subjects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.section_subjects (id, section_id, subject_id, teacher_id, is_active, assigned_at, updated_at) FROM stdin;
4	1	3	8	t	2026-02-09 03:07:08.836987+00	2026-02-09 03:07:08.836987+00
5	6	4	9	t	2026-02-17 01:02:21.018346+00	2026-02-17 01:02:21.018346+00
6	1	9	7	t	2026-02-20 23:50:33.489967+00	2026-02-20 23:50:33.489967+00
7	1	4	8	t	2026-02-21 23:49:14.274106+00	2026-02-21 23:49:14.274106+00
3	4	4	7	f	2026-02-09 02:54:30.806141+00	2026-02-21 23:49:23.961324+00
8	1	1	9	t	2026-02-21 23:49:35.556621+00	2026-02-21 23:49:35.556621+00
9	1	6	8	t	2026-02-25 00:20:46.001368+00	2026-02-25 00:20:46.001368+00
10	1	5	7	t	2026-02-26 18:03:53.532204+00	2026-02-26 18:03:53.532204+00
\.


--
-- TOC entry 4608 (class 0 OID 17676)
-- Dependencies: 346
-- Data for Name: sections; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sections (id, name, grade_id, capacity, is_active, created_at, updated_at) FROM stdin;
1	Section A	1	\N	t	2026-02-08 00:24:02.260276+00	2026-02-08 00:24:02.260276+00
2	Section B	1	\N	t	2026-02-08 00:24:02.260276+00	2026-02-08 00:24:02.260276+00
4	ا	1	\N	t	2026-02-09 02:30:36.211289+00	2026-02-09 02:30:36.211289+00
5	ف	1	\N	t	2026-02-09 02:31:09.319025+00	2026-02-09 02:31:09.319025+00
6	غ	2	\N	t	2026-02-09 02:31:24.214365+00	2026-02-09 02:31:24.214365+00
\.


--
-- TOC entry 4609 (class 0 OID 17683)
-- Dependencies: 347
-- Data for Name: semesters; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.semesters (id, semester_type, name, start_date, end_date, is_active, created_at) FROM stdin;
1	first	First Semester	\N	\N	t	2026-02-08 00:23:01.656065+00
2	second	Second Semester	\N	\N	t	2026-02-08 00:23:01.656065+00
\.


--
-- TOC entry 4659 (class 0 OID 18643)
-- Dependencies: 405
-- Data for Name: student_summaries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.student_summaries (id, student_id, subject_id, chapter_id, title, content, summary_type, created_at) FROM stdin;
1	1	4	7	ملخص: الوحدة الأولى	# الوحدة الأولى\n\n## النقاط الرئيسية:\n\n• النقطة الأولى: شرح مفصل للمفهوم الأول...\n• النقطة الثانية: شرح مفصل للمفهوم الثاني...\n• النقطة الثالثة: شرح مفصل للمفهوم الثالث...\n\n## الأمثلة المهمة:\n\nمثال 1: ...\nمثال 2: ...\n\n## ملاحظات مهمة:\n\n⚠️ تذكر أن...\n💡 نصيحة: ...\n\n---\nهذا الملخص تم إنشاؤه بواسطة AI\n	summary	2026-02-26 00:39:19.635114+00
2	1	4	7	ملخص: الوحدة الأولى	# الوحدة الأولى\n\n## النقاط الرئيسية:\n\n• النقطة الأولى: شرح مفصل للمفهوم الأول...\n• النقطة الثانية: شرح مفصل للمفهوم الثاني...\n• النقطة الثالثة: شرح مفصل للمفهوم الثالث...\n\n## الأمثلة المهمة:\n\nمثال 1: ...\nمثال 2: ...\n\n## ملاحظات مهمة:\n\n⚠️ تذكر أن...\n💡 نصيحة: ...\n\n---\nهذا الملخص تم إنشاؤه بواسطة AI\n	summary	2026-02-26 00:40:44.130179+00
3	1	4	7	ملخص: الوحدة الأولى	# الوحدة الأولى\n\n## النقاط الرئيسية:\n\n• النقطة الأولى: شرح مفصل للمفهوم الأول...\n• النقطة الثانية: شرح مفصل للمفهوم الثاني...\n• النقطة الثالثة: شرح مفصل للمفهوم الثالث...\n\n## الأمثلة المهمة:\n\nمثال 1: ...\nمثال 2: ...\n\n## ملاحظات مهمة:\n\n⚠️ تذكر أن...\n💡 نصيحة: ...\n\n---\nهذا الملخص تم إنشاؤه بواسطة AI\n	summary	2026-02-26 01:03:16.287792+00
\.


--
-- TOC entry 4610 (class 0 OID 17691)
-- Dependencies: 348
-- Data for Name: students; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.students (id, student_code, full_name, phone_number, email, profile_image, profile_image_filename, profile_image_mime_type, profile_image_size, section_id, password_hash, is_active, last_login_at, created_at, updated_at, deleted_at, deleted_by, profile_image_url, profile_image_storage_path) FROM stdin;
1	10001	amjed Ahmed	0501111111	student@school.com	\N	\N	\N	\N	1	$2a$12$Y2BOO6jLj9PDxBUEvcrjlOSW7jI2.UNrU4r5vmDQPWOj3rWoFvA0W	t	\N	2026-02-08 00:24:02.260276+00	2026-02-09 02:28:49.747993+00	\N	\N	\N	\N
3	10003	نوور	77745	\N	\N	\N	\N	\N	4	$2a$12$njSMg8BrNuEinXOhEvlPuOrzDrzXAI2d1JqzLu6rtUttDJgT/2ePm	t	\N	2026-02-09 02:30:13.500461+00	2026-02-09 02:47:16.151031+00	\N	\N	\N	\N
32	10032	علي محمد 	445522	\N	\N	\N	\N	\N	5	$2a$12$t49SbMEz29GmAzYcZuglYujITOucQyMPB7IPgKz6qJFEFreTfh9Xy	t	\N	2026-02-18 00:29:59.663195+00	2026-02-18 00:29:59.663195+00	\N	\N	\N	\N
33	10033	عبدالوهاب	4520	\N	\N	\N	\N	\N	5	$2a$12$XnhAKa.pq0n.BISPbvThout/UzM7loN/Piv3RlHINLBLIs60049wu	t	\N	2026-02-20 23:17:10.222139+00	2026-02-23 21:47:08.438345+00	\N	\N	\N	\N
\.


--
-- TOC entry 4611 (class 0 OID 17701)
-- Dependencies: 349
-- Data for Name: subjects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.subjects (id, subject_code, name, pdf_content, pdf_filename, pdf_size, description, is_active, created_at, updated_at, pdf_url, pdf_storage_path, icon, color) FROM stdin;
9	109	علوم	\N	تحليل نظم_260205_005711.pdf	415776	\N	t	2026-02-09 03:24:09.220167+00	2026-02-09 03:24:15.396697+00	https://lgzzkkemwrukysxhxiuk.supabase.co/storage/v1/object/public/subject-materials/9/__________260205_005711.pdf	9/__________260205_005711.pdf	\N	\N
2	102	لغه عربيه	\N	مواضيع خاصة 4.pdf	367646	Arabic Language subject	t	2026-02-08 00:24:02.260276+00	2026-02-21 23:44:21.294302+00	https://lgzzkkemwrukysxhxiuk.supabase.co/storage/v1/object/public/subject-materials/2/____________4.pdf	2/____________4.pdf	\N	\N
3	103	لغه انجليزيه	\N	ممتاز  _20251002_015253_٠٠٠٠.pdf	116270	English Language subject	t	2026-02-08 00:24:02.260276+00	2026-02-21 23:45:06.367644+00	https://lgzzkkemwrukysxhxiuk.supabase.co/storage/v1/object/public/subject-materials/3/________20251002_015253_____.pdf	3/________20251002_015253_____.pdf	\N	\N
4	104	اجتماعيات	\N	ممتاز جدا  _20251003_010026_٠٠٠٠.pdf	143157	Science subject	t	2026-02-08 00:24:02.260276+00	2026-02-21 23:45:55.843993+00	https://lgzzkkemwrukysxhxiuk.supabase.co/storage/v1/object/public/subject-materials/4/____________20251003_010026_____.pdf	4/____________20251003_010026_____.pdf	\N	\N
1	101	قران	\N	ID3 COMPLETE EXAMPLE_lecture 5-2.pdf	164916	Mathematics subject	t	2026-02-08 00:24:02.260276+00	2026-02-21 23:46:41.952563+00	https://lgzzkkemwrukysxhxiuk.supabase.co/storage/v1/object/public/subject-materials/1/ID3_COMPLETE_EXAMPLE_lecture_5-2.pdf	1/ID3_COMPLETE_EXAMPLE_lecture_5-2.pdf	\N	\N
5	105	اسلامية	\N	data-mining-system-and-applications-a-review-sluv0a6ey3.pdf	144239	Islamic Education subject	t	2026-02-08 00:24:02.260276+00	2026-02-21 23:47:19.783646+00	https://lgzzkkemwrukysxhxiuk.supabase.co/storage/v1/object/public/subject-materials/5/data-mining-system-and-applications-a-review-sluv0a6ey3.pdf	5/data-mining-system-and-applications-a-review-sluv0a6ey3.pdf	\N	\N
6	106	فنية	\N	data-mining-system-and-applications-a-review-sluv0a6ey3.pdf	144239	Social Studies subject	t	2026-02-08 00:24:02.260276+00	2026-02-21 23:48:18.156102+00	https://lgzzkkemwrukysxhxiuk.supabase.co/storage/v1/object/public/subject-materials/6/data-mining-system-and-applications-a-review-sluv0a6ey3.pdf	6/data-mining-system-and-applications-a-review-sluv0a6ey3.pdf	\N	\N
\.


--
-- TOC entry 4612 (class 0 OID 17711)
-- Dependencies: 350
-- Data for Name: teachers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.teachers (id, teacher_code, full_name, phone_number, email, profile_image, profile_image_filename, profile_image_mime_type, profile_image_size, password_hash, is_active, last_login_at, created_at, updated_at, deleted_at, deleted_by, profile_image_url, profile_image_storage_path) FROM stdin;
1	1001	Ahmed Mohammed	0509876543	teacher@school.com	\N	\N	\N	\N	$2a$12$Pn8HrU3n5SC2I4et4FQSt.RN/VEjUd.6T8S6VDWtHHD1VLpzc.zNy	t	\N	2026-02-08 00:24:02.260276+00	2026-02-08 00:24:02.260276+00	\N	\N	\N	\N
7	1007	امجد عصام	774353045	\N	\N	\N	\N	\N	$2a$12$rNIchLLGSnZ.ggV/wiLEQe.3vOmVCJAXHv7Ji12M5lVvlwJkWsmqm	t	\N	2026-02-09 02:29:17.413556+00	2026-02-09 02:29:17.413556+00	\N	\N	\N	\N
8	1008	الياس 	774505	\N	\N	\N	\N	\N	$2a$12$m/frc7rb09ox5xh/6F.3O.ASNqR7T4WOR4LboEpvulXpoFCmQLzeC	t	\N	2026-02-09 03:06:58.833554+00	2026-02-09 03:06:58.833554+00	\N	\N	\N	\N
9	1009	علي حيدر	ADMIN2025	\N	\N	\N	\N	\N	$2a$12$O1LBpbsayPIvwJlKjrhdv.bqFpiEp9zpi3FM099SQciegeTFK.gf6	t	\N	2026-02-17 01:02:00.050256+00	2026-02-17 01:02:00.050256+00	\N	\N	\N	\N
\.


--
-- TOC entry 4898 (class 0 OID 0)
-- Dependencies: 353
-- Name: activities_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.activities_id_seq', 1, false);


--
-- TOC entry 4899 (class 0 OID 0)
-- Dependencies: 355
-- Name: activity_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.activity_logs_id_seq', 16, true);


--
-- TOC entry 4900 (class 0 OID 0)
-- Dependencies: 356
-- Name: admins_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.admins_id_seq', 1, true);


--
-- TOC entry 4901 (class 0 OID 0)
-- Dependencies: 358
-- Name: app_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.app_user_id_seq', 2, true);


--
-- TOC entry 4902 (class 0 OID 0)
-- Dependencies: 359
-- Name: attendance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.attendance_id_seq', 1, false);


--
-- TOC entry 4903 (class 0 OID 0)
-- Dependencies: 407
-- Name: chapter_topics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.chapter_topics_id_seq', 1, false);


--
-- TOC entry 4904 (class 0 OID 0)
-- Dependencies: 361
-- Name: chapters_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.chapters_id_seq', 10, true);


--
-- TOC entry 4905 (class 0 OID 0)
-- Dependencies: 363
-- Name: daily_summaries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.daily_summaries_id_seq', 1, false);


--
-- TOC entry 4906 (class 0 OID 0)
-- Dependencies: 364
-- Name: exam_questions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.exam_questions_id_seq', 1, false);


--
-- TOC entry 4907 (class 0 OID 0)
-- Dependencies: 366
-- Name: exam_results_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.exam_results_id_seq', 1, false);


--
-- TOC entry 4908 (class 0 OID 0)
-- Dependencies: 367
-- Name: exams_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.exams_id_seq', 14, true);


--
-- TOC entry 4909 (class 0 OID 0)
-- Dependencies: 368
-- Name: grades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.grades_id_seq', 6, true);


--
-- TOC entry 4910 (class 0 OID 0)
-- Dependencies: 369
-- Name: messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.messages_id_seq', 7, true);


--
-- TOC entry 4911 (class 0 OID 0)
-- Dependencies: 376
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notifications_id_seq', 1, false);


--
-- TOC entry 4912 (class 0 OID 0)
-- Dependencies: 377
-- Name: parent_students_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.parent_students_id_seq', 21, true);


--
-- TOC entry 4913 (class 0 OID 0)
-- Dependencies: 378
-- Name: parents_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.parents_id_seq', 2, true);


--
-- TOC entry 4914 (class 0 OID 0)
-- Dependencies: 379
-- Name: pending_content_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pending_content_id_seq', 1, false);


--
-- TOC entry 4915 (class 0 OID 0)
-- Dependencies: 402
-- Name: practice_quiz_answers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.practice_quiz_answers_id_seq', 19, true);


--
-- TOC entry 4916 (class 0 OID 0)
-- Dependencies: 400
-- Name: practice_quiz_attempts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.practice_quiz_attempts_id_seq', 16, true);


--
-- TOC entry 4917 (class 0 OID 0)
-- Dependencies: 380
-- Name: questions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.questions_id_seq', 11, true);


--
-- TOC entry 4918 (class 0 OID 0)
-- Dependencies: 381
-- Name: reports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reports_id_seq', 2, true);


--
-- TOC entry 4919 (class 0 OID 0)
-- Dependencies: 383
-- Name: section_subjects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.section_subjects_id_seq', 10, true);


--
-- TOC entry 4920 (class 0 OID 0)
-- Dependencies: 384
-- Name: sections_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sections_id_seq', 6, true);


--
-- TOC entry 4921 (class 0 OID 0)
-- Dependencies: 385
-- Name: semesters_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.semesters_id_seq', 2, true);


--
-- TOC entry 4922 (class 0 OID 0)
-- Dependencies: 386
-- Name: seq_student_code; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.seq_student_code', 10033, true);


--
-- TOC entry 4923 (class 0 OID 0)
-- Dependencies: 387
-- Name: seq_subject_code; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.seq_subject_code', 109, true);


--
-- TOC entry 4924 (class 0 OID 0)
-- Dependencies: 388
-- Name: seq_teacher_code; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.seq_teacher_code', 1009, true);


--
-- TOC entry 4925 (class 0 OID 0)
-- Dependencies: 404
-- Name: student_summaries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.student_summaries_id_seq', 3, true);


--
-- TOC entry 4926 (class 0 OID 0)
-- Dependencies: 389
-- Name: students_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.students_id_seq', 33, true);


--
-- TOC entry 4927 (class 0 OID 0)
-- Dependencies: 390
-- Name: subjects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.subjects_id_seq', 9, true);


--
-- TOC entry 4928 (class 0 OID 0)
-- Dependencies: 391
-- Name: teachers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.teachers_id_seq', 9, true);


--
-- TOC entry 4153 (class 2606 OID 17950)
-- Name: activities activities_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_pkey PRIMARY KEY (id);


--
-- TOC entry 4160 (class 2606 OID 17952)
-- Name: activity_logs activity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 4026 (class 2606 OID 17954)
-- Name: admins admins_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_email_key UNIQUE (email);


--
-- TOC entry 4028 (class 2606 OID 17956)
-- Name: admins admins_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);


--
-- TOC entry 4165 (class 2606 OID 17958)
-- Name: app_user app_user_auth_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_auth_user_id_key UNIQUE (auth_user_id);


--
-- TOC entry 4167 (class 2606 OID 17960)
-- Name: app_user app_user_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_pkey PRIMARY KEY (id);


--
-- TOC entry 4032 (class 2606 OID 17962)
-- Name: attendance attendance_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_pkey PRIMARY KEY (id);


--
-- TOC entry 4223 (class 2606 OID 20978)
-- Name: chapter_topics chapter_topics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chapter_topics
    ADD CONSTRAINT chapter_topics_pkey PRIMARY KEY (id);


--
-- TOC entry 4171 (class 2606 OID 17964)
-- Name: chapters chapters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chapters
    ADD CONSTRAINT chapters_pkey PRIMARY KEY (id);


--
-- TOC entry 4175 (class 2606 OID 17966)
-- Name: daily_summaries daily_summaries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.daily_summaries
    ADD CONSTRAINT daily_summaries_pkey PRIMARY KEY (id);


--
-- TOC entry 4177 (class 2606 OID 17968)
-- Name: daily_summaries daily_summaries_student_id_summary_date_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.daily_summaries
    ADD CONSTRAINT daily_summaries_student_id_summary_date_key UNIQUE (student_id, summary_date);


--
-- TOC entry 4040 (class 2606 OID 17970)
-- Name: exam_questions exam_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_questions
    ADD CONSTRAINT exam_questions_pkey PRIMARY KEY (id);


--
-- TOC entry 4182 (class 2606 OID 17972)
-- Name: exam_results exam_results_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_results
    ADD CONSTRAINT exam_results_pkey PRIMARY KEY (id);


--
-- TOC entry 4049 (class 2606 OID 17974)
-- Name: exams exams_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exams
    ADD CONSTRAINT exams_pkey PRIMARY KEY (id);


--
-- TOC entry 4057 (class 2606 OID 17976)
-- Name: grades grades_grade_order_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grades
    ADD CONSTRAINT grades_grade_order_key UNIQUE (grade_order);


--
-- TOC entry 4059 (class 2606 OID 17978)
-- Name: grades grades_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grades
    ADD CONSTRAINT grades_name_key UNIQUE (name);


--
-- TOC entry 4061 (class 2606 OID 17980)
-- Name: grades grades_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grades
    ADD CONSTRAINT grades_pkey PRIMARY KEY (id);


--
-- TOC entry 4071 (class 2606 OID 17982)
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- TOC entry 4205 (class 2606 OID 17984)
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- TOC entry 4149 (class 2606 OID 17986)
-- Name: parent_students parent_students_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parent_students
    ADD CONSTRAINT parent_students_pkey PRIMARY KEY (id);


--
-- TOC entry 4075 (class 2606 OID 17988)
-- Name: parents parents_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parents
    ADD CONSTRAINT parents_email_key UNIQUE (email);


--
-- TOC entry 4077 (class 2606 OID 17990)
-- Name: parents parents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parents
    ADD CONSTRAINT parents_pkey PRIMARY KEY (id);


--
-- TOC entry 4083 (class 2606 OID 17992)
-- Name: pending_content pending_content_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pending_content
    ADD CONSTRAINT pending_content_pkey PRIMARY KEY (id);


--
-- TOC entry 4218 (class 2606 OID 18629)
-- Name: practice_quiz_answers practice_quiz_answers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.practice_quiz_answers
    ADD CONSTRAINT practice_quiz_answers_pkey PRIMARY KEY (id);


--
-- TOC entry 4214 (class 2606 OID 18602)
-- Name: practice_quiz_attempts practice_quiz_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.practice_quiz_attempts
    ADD CONSTRAINT practice_quiz_attempts_pkey PRIMARY KEY (id);


--
-- TOC entry 4092 (class 2606 OID 17994)
-- Name: questions questions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_pkey PRIMARY KEY (id);


--
-- TOC entry 4099 (class 2606 OID 17996)
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- TOC entry 4207 (class 2606 OID 17998)
-- Name: school_settings school_settings_admin_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.school_settings
    ADD CONSTRAINT school_settings_admin_code_key UNIQUE (admin_code);


--
-- TOC entry 4209 (class 2606 OID 18000)
-- Name: school_settings school_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.school_settings
    ADD CONSTRAINT school_settings_pkey PRIMARY KEY (id);


--
-- TOC entry 4105 (class 2606 OID 18002)
-- Name: section_subjects section_subjects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.section_subjects
    ADD CONSTRAINT section_subjects_pkey PRIMARY KEY (id);


--
-- TOC entry 4111 (class 2606 OID 18004)
-- Name: sections sections_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sections
    ADD CONSTRAINT sections_pkey PRIMARY KEY (id);


--
-- TOC entry 4115 (class 2606 OID 18006)
-- Name: semesters semesters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.semesters
    ADD CONSTRAINT semesters_pkey PRIMARY KEY (id);


--
-- TOC entry 4117 (class 2606 OID 18008)
-- Name: semesters semesters_semester_type_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.semesters
    ADD CONSTRAINT semesters_semester_type_key UNIQUE (semester_type);


--
-- TOC entry 4221 (class 2606 OID 18652)
-- Name: student_summaries student_summaries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_summaries
    ADD CONSTRAINT student_summaries_pkey PRIMARY KEY (id);


--
-- TOC entry 4123 (class 2606 OID 18010)
-- Name: students students_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_email_key UNIQUE (email);


--
-- TOC entry 4125 (class 2606 OID 18012)
-- Name: students students_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_pkey PRIMARY KEY (id);


--
-- TOC entry 4127 (class 2606 OID 18014)
-- Name: students students_student_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_student_code_key UNIQUE (student_code);


--
-- TOC entry 4132 (class 2606 OID 18016)
-- Name: subjects subjects_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subjects
    ADD CONSTRAINT subjects_name_key UNIQUE (name);


--
-- TOC entry 4134 (class 2606 OID 18018)
-- Name: subjects subjects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subjects
    ADD CONSTRAINT subjects_pkey PRIMARY KEY (id);


--
-- TOC entry 4136 (class 2606 OID 18020)
-- Name: subjects subjects_subject_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subjects
    ADD CONSTRAINT subjects_subject_code_key UNIQUE (subject_code);


--
-- TOC entry 4141 (class 2606 OID 18022)
-- Name: teachers teachers_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teachers
    ADD CONSTRAINT teachers_email_key UNIQUE (email);


--
-- TOC entry 4143 (class 2606 OID 18024)
-- Name: teachers teachers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teachers
    ADD CONSTRAINT teachers_pkey PRIMARY KEY (id);


--
-- TOC entry 4145 (class 2606 OID 18026)
-- Name: teachers teachers_teacher_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teachers
    ADD CONSTRAINT teachers_teacher_code_key UNIQUE (teacher_code);


--
-- TOC entry 4045 (class 2606 OID 18028)
-- Name: exam_questions uq_exam_question; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_questions
    ADD CONSTRAINT uq_exam_question UNIQUE (exam_id, question_id);


--
-- TOC entry 4047 (class 2606 OID 18030)
-- Name: exam_questions uq_exam_question_order; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_questions
    ADD CONSTRAINT uq_exam_question_order UNIQUE (exam_id, question_order);


--
-- TOC entry 4151 (class 2606 OID 18032)
-- Name: parent_students uq_parent_student; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parent_students
    ADD CONSTRAINT uq_parent_student UNIQUE (parent_id, student_id);


--
-- TOC entry 4113 (class 2606 OID 18034)
-- Name: sections uq_section_grade_name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sections
    ADD CONSTRAINT uq_section_grade_name UNIQUE (grade_id, name);


--
-- TOC entry 4107 (class 2606 OID 18036)
-- Name: section_subjects uq_section_subject; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.section_subjects
    ADD CONSTRAINT uq_section_subject UNIQUE (section_id, subject_id);


--
-- TOC entry 4038 (class 2606 OID 18038)
-- Name: attendance uq_student_date; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT uq_student_date UNIQUE (student_id, attendance_date);


--
-- TOC entry 4189 (class 2606 OID 18040)
-- Name: exam_results uq_student_exam; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_results
    ADD CONSTRAINT uq_student_exam UNIQUE (student_id, exam_id);


--
-- TOC entry 4154 (class 1259 OID 23249)
-- Name: idx_activities_due_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activities_due_date ON public.activities USING btree (due_date);


--
-- TOC entry 4155 (class 1259 OID 23248)
-- Name: idx_activities_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activities_status ON public.activities USING btree (status);


--
-- TOC entry 4156 (class 1259 OID 18043)
-- Name: idx_activities_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activities_student ON public.activities USING btree (student_id);


--
-- TOC entry 4157 (class 1259 OID 23250)
-- Name: idx_activities_student_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activities_student_status ON public.activities USING btree (student_id, status);


--
-- TOC entry 4158 (class 1259 OID 23247)
-- Name: idx_activities_student_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activities_student_type ON public.activities USING btree (student_id, activity_type);


--
-- TOC entry 4161 (class 1259 OID 18045)
-- Name: idx_activity_logs_action; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_logs_action ON public.activity_logs USING btree (action);


--
-- TOC entry 4162 (class 1259 OID 18046)
-- Name: idx_activity_logs_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_logs_created ON public.activity_logs USING btree (created_at DESC);


--
-- TOC entry 4163 (class 1259 OID 18047)
-- Name: idx_activity_logs_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_logs_user ON public.activity_logs USING btree (user_type, user_id);


--
-- TOC entry 4029 (class 1259 OID 18048)
-- Name: idx_admins_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_admins_active ON public.admins USING btree (id) WHERE (deleted_at IS NULL);


--
-- TOC entry 4030 (class 1259 OID 18049)
-- Name: idx_admins_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_admins_email ON public.admins USING btree (email) WHERE (deleted_at IS NULL);


--
-- TOC entry 4168 (class 1259 OID 18050)
-- Name: idx_app_user_auth; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_app_user_auth ON public.app_user USING btree (auth_user_id);


--
-- TOC entry 4169 (class 1259 OID 18051)
-- Name: idx_app_user_entity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_app_user_entity ON public.app_user USING btree (user_type, app_entity_id);


--
-- TOC entry 4033 (class 1259 OID 18052)
-- Name: idx_attendance_absent; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attendance_absent ON public.attendance USING btree (student_id) WHERE (status = 'absent'::public.attendance_status_enum);


--
-- TOC entry 4034 (class 1259 OID 18053)
-- Name: idx_attendance_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attendance_date ON public.attendance USING btree (attendance_date);


--
-- TOC entry 4035 (class 1259 OID 18054)
-- Name: idx_attendance_section_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attendance_section_date ON public.attendance USING btree (section_id, attendance_date);


--
-- TOC entry 4036 (class 1259 OID 18055)
-- Name: idx_attendance_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attendance_student ON public.attendance USING btree (student_id);


--
-- TOC entry 4224 (class 1259 OID 20984)
-- Name: idx_chapter_topics_chapter; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chapter_topics_chapter ON public.chapter_topics USING btree (chapter_id, order_index);


--
-- TOC entry 4172 (class 1259 OID 18056)
-- Name: idx_chapters_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chapters_order ON public.chapters USING btree (subject_id, order_index);


--
-- TOC entry 4173 (class 1259 OID 18057)
-- Name: idx_chapters_subject; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chapters_subject ON public.chapters USING btree (subject_id);


--
-- TOC entry 4178 (class 1259 OID 18058)
-- Name: idx_daily_summaries_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_daily_summaries_date ON public.daily_summaries USING btree (summary_date);


--
-- TOC entry 4179 (class 1259 OID 18059)
-- Name: idx_daily_summaries_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_daily_summaries_student ON public.daily_summaries USING btree (student_id);


--
-- TOC entry 4180 (class 1259 OID 18060)
-- Name: idx_daily_summaries_student_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_daily_summaries_student_date ON public.daily_summaries USING btree (student_id, summary_date);


--
-- TOC entry 4041 (class 1259 OID 18061)
-- Name: idx_exam_questions_exam; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_exam_questions_exam ON public.exam_questions USING btree (exam_id);


--
-- TOC entry 4042 (class 1259 OID 18062)
-- Name: idx_exam_questions_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_exam_questions_order ON public.exam_questions USING btree (exam_id, question_order);


--
-- TOC entry 4043 (class 1259 OID 18063)
-- Name: idx_exam_questions_question; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_exam_questions_question ON public.exam_questions USING btree (question_id);


--
-- TOC entry 4183 (class 1259 OID 18064)
-- Name: idx_exam_results_exam; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_exam_results_exam ON public.exam_results USING btree (exam_id);


--
-- TOC entry 4184 (class 1259 OID 18065)
-- Name: idx_exam_results_pending_grading; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_exam_results_pending_grading ON public.exam_results USING btree (id) WHERE (status = 'pending_manual_grading'::public.exam_attempt_status_enum);


--
-- TOC entry 4185 (class 1259 OID 18066)
-- Name: idx_exam_results_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_exam_results_status ON public.exam_results USING btree (status);


--
-- TOC entry 4186 (class 1259 OID 18067)
-- Name: idx_exam_results_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_exam_results_student ON public.exam_results USING btree (student_id);


--
-- TOC entry 4187 (class 1259 OID 18068)
-- Name: idx_exam_results_submitted; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_exam_results_submitted ON public.exam_results USING btree (submitted_at);


--
-- TOC entry 4050 (class 1259 OID 18069)
-- Name: idx_exams_creator_teacher; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_exams_creator_teacher ON public.exams USING btree (created_by_teacher);


--
-- TOC entry 4051 (class 1259 OID 18070)
-- Name: idx_exams_grade_section; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_exams_grade_section ON public.exams USING btree (grade_id, section_id);


--
-- TOC entry 4052 (class 1259 OID 18071)
-- Name: idx_exams_scheduled; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_exams_scheduled ON public.exams USING btree (scheduled_at) WHERE (status = 'published'::public.exam_status_enum);


--
-- TOC entry 4053 (class 1259 OID 18072)
-- Name: idx_exams_semester; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_exams_semester ON public.exams USING btree (semester_id);


--
-- TOC entry 4054 (class 1259 OID 18073)
-- Name: idx_exams_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_exams_status ON public.exams USING btree (status);


--
-- TOC entry 4055 (class 1259 OID 18074)
-- Name: idx_exams_subject; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_exams_subject ON public.exams USING btree (subject_id);


--
-- TOC entry 4062 (class 1259 OID 18075)
-- Name: idx_grades_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_grades_active ON public.grades USING btree (id) WHERE (is_active = true);


--
-- TOC entry 4063 (class 1259 OID 18076)
-- Name: idx_grades_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_grades_order ON public.grades USING btree (grade_order);


--
-- TOC entry 4064 (class 1259 OID 18077)
-- Name: idx_messages_recipient_admin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_messages_recipient_admin ON public.messages USING btree (recipient_admin_id);


--
-- TOC entry 4065 (class 1259 OID 18078)
-- Name: idx_messages_recipient_parent; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_messages_recipient_parent ON public.messages USING btree (recipient_parent_id);


--
-- TOC entry 4066 (class 1259 OID 18079)
-- Name: idx_messages_sender_admin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_messages_sender_admin ON public.messages USING btree (sender_admin_id);


--
-- TOC entry 4067 (class 1259 OID 18080)
-- Name: idx_messages_sender_parent; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_messages_sender_parent ON public.messages USING btree (sender_parent_id);


--
-- TOC entry 4068 (class 1259 OID 18081)
-- Name: idx_messages_sent_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_messages_sent_at ON public.messages USING btree (sent_at DESC);


--
-- TOC entry 4069 (class 1259 OID 18082)
-- Name: idx_messages_unread; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_messages_unread ON public.messages USING btree (recipient_admin_id) WHERE (is_read = false);


--
-- TOC entry 4190 (class 1259 OID 18083)
-- Name: idx_mv_attendance_month; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mv_attendance_month ON public.mv_monthly_attendance USING btree (month);


--
-- TOC entry 4191 (class 1259 OID 18084)
-- Name: idx_mv_attendance_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mv_attendance_student ON public.mv_monthly_attendance USING btree (student_id);


--
-- TOC entry 4192 (class 1259 OID 18085)
-- Name: idx_mv_student_performance_month; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mv_student_performance_month ON public.mv_student_monthly_performance USING btree (month);


--
-- TOC entry 4193 (class 1259 OID 18086)
-- Name: idx_mv_student_performance_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mv_student_performance_student ON public.mv_student_monthly_performance USING btree (student_id);


--
-- TOC entry 4194 (class 1259 OID 18087)
-- Name: idx_mv_student_performance_subject; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mv_student_performance_subject ON public.mv_student_monthly_performance USING btree (subject_id);


--
-- TOC entry 4195 (class 1259 OID 18088)
-- Name: idx_mv_subject_stats_subject; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mv_subject_stats_subject ON public.mv_subject_statistics USING btree (subject_id);


--
-- TOC entry 4196 (class 1259 OID 18089)
-- Name: idx_mv_weekly_activity_week; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mv_weekly_activity_week ON public.mv_weekly_activity USING btree (week_start);


--
-- TOC entry 4197 (class 1259 OID 18090)
-- Name: idx_notifications_admin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_admin ON public.notifications USING btree (recipient_admin_id) WHERE (is_read = false);


--
-- TOC entry 4198 (class 1259 OID 18091)
-- Name: idx_notifications_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_created ON public.notifications USING btree (created_at DESC);


--
-- TOC entry 4199 (class 1259 OID 18092)
-- Name: idx_notifications_expires; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_expires ON public.notifications USING btree (expires_at) WHERE (expires_at IS NOT NULL);


--
-- TOC entry 4200 (class 1259 OID 18093)
-- Name: idx_notifications_parent; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_parent ON public.notifications USING btree (recipient_parent_id) WHERE (is_read = false);


--
-- TOC entry 4201 (class 1259 OID 18094)
-- Name: idx_notifications_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_student ON public.notifications USING btree (recipient_student_id) WHERE (is_read = false);


--
-- TOC entry 4202 (class 1259 OID 18095)
-- Name: idx_notifications_teacher; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_teacher ON public.notifications USING btree (recipient_teacher_id) WHERE (is_read = false);


--
-- TOC entry 4203 (class 1259 OID 18096)
-- Name: idx_notifications_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_type ON public.notifications USING btree (notification_type);


--
-- TOC entry 4146 (class 1259 OID 18097)
-- Name: idx_parent_students_parent; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_parent_students_parent ON public.parent_students USING btree (parent_id);


--
-- TOC entry 4147 (class 1259 OID 18098)
-- Name: idx_parent_students_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_parent_students_student ON public.parent_students USING btree (student_id);


--
-- TOC entry 4072 (class 1259 OID 18099)
-- Name: idx_parents_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_parents_email ON public.parents USING btree (email);


--
-- TOC entry 4073 (class 1259 OID 18100)
-- Name: idx_parents_phone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_parents_phone ON public.parents USING btree (phone_number);


--
-- TOC entry 4078 (class 1259 OID 18101)
-- Name: idx_pending_content_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pending_content_status ON public.pending_content USING btree (status);


--
-- TOC entry 4079 (class 1259 OID 18102)
-- Name: idx_pending_content_submitted; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pending_content_submitted ON public.pending_content USING btree (submitted_at DESC);


--
-- TOC entry 4080 (class 1259 OID 18103)
-- Name: idx_pending_content_teacher; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pending_content_teacher ON public.pending_content USING btree (teacher_id);


--
-- TOC entry 4081 (class 1259 OID 18104)
-- Name: idx_pending_content_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pending_content_type ON public.pending_content USING btree (content_type);


--
-- TOC entry 4215 (class 1259 OID 18640)
-- Name: idx_practice_quiz_answers_attempt; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_practice_quiz_answers_attempt ON public.practice_quiz_answers USING btree (attempt_id);


--
-- TOC entry 4216 (class 1259 OID 18641)
-- Name: idx_practice_quiz_answers_question; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_practice_quiz_answers_question ON public.practice_quiz_answers USING btree (question_id);


--
-- TOC entry 4210 (class 1259 OID 18619)
-- Name: idx_practice_quiz_attempts_completed; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_practice_quiz_attempts_completed ON public.practice_quiz_attempts USING btree (completed_at DESC);


--
-- TOC entry 4211 (class 1259 OID 18618)
-- Name: idx_practice_quiz_attempts_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_practice_quiz_attempts_student ON public.practice_quiz_attempts USING btree (student_id);


--
-- TOC entry 4212 (class 1259 OID 18620)
-- Name: idx_practice_quiz_attempts_subject; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_practice_quiz_attempts_subject ON public.practice_quiz_attempts USING btree (subject_id);


--
-- TOC entry 4084 (class 1259 OID 18105)
-- Name: idx_questions_creator_teacher; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_questions_creator_teacher ON public.questions USING btree (created_by_teacher);


--
-- TOC entry 4085 (class 1259 OID 18106)
-- Name: idx_questions_difficulty; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_questions_difficulty ON public.questions USING btree (difficulty_level);


--
-- TOC entry 4086 (class 1259 OID 18107)
-- Name: idx_questions_fulltext; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_questions_fulltext ON public.questions USING gin (to_tsvector('arabic'::regconfig, question_text));


--
-- TOC entry 4087 (class 1259 OID 18108)
-- Name: idx_questions_options; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_questions_options ON public.questions USING gin (question_options);


--
-- TOC entry 4088 (class 1259 OID 18110)
-- Name: idx_questions_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_questions_status ON public.questions USING btree (status) WHERE (is_active = true);


--
-- TOC entry 4089 (class 1259 OID 18111)
-- Name: idx_questions_subject; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_questions_subject ON public.questions USING btree (subject_id);


--
-- TOC entry 4090 (class 1259 OID 18112)
-- Name: idx_questions_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_questions_type ON public.questions USING btree (question_type);


--
-- TOC entry 4093 (class 1259 OID 18113)
-- Name: idx_reports_parent; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reports_parent ON public.reports USING btree (parent_id);


--
-- TOC entry 4094 (class 1259 OID 18114)
-- Name: idx_reports_sent_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reports_sent_at ON public.reports USING btree (sent_at DESC);


--
-- TOC entry 4095 (class 1259 OID 18115)
-- Name: idx_reports_sent_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reports_sent_by ON public.reports USING btree (sent_by);


--
-- TOC entry 4096 (class 1259 OID 18116)
-- Name: idx_reports_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reports_student ON public.reports USING btree (student_id);


--
-- TOC entry 4097 (class 1259 OID 18117)
-- Name: idx_reports_unread; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reports_unread ON public.reports USING btree (parent_id) WHERE (is_read = false);


--
-- TOC entry 4100 (class 1259 OID 18118)
-- Name: idx_section_subjects_section; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_section_subjects_section ON public.section_subjects USING btree (section_id);


--
-- TOC entry 4101 (class 1259 OID 18119)
-- Name: idx_section_subjects_subject; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_section_subjects_subject ON public.section_subjects USING btree (subject_id);


--
-- TOC entry 4102 (class 1259 OID 18120)
-- Name: idx_section_subjects_teacher; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_section_subjects_teacher ON public.section_subjects USING btree (teacher_id);


--
-- TOC entry 4103 (class 1259 OID 18121)
-- Name: idx_section_subjects_teacher_subject; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_section_subjects_teacher_subject ON public.section_subjects USING btree (teacher_id, subject_id);


--
-- TOC entry 4108 (class 1259 OID 18122)
-- Name: idx_sections_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sections_active ON public.sections USING btree (id) WHERE (is_active = true);


--
-- TOC entry 4109 (class 1259 OID 18123)
-- Name: idx_sections_grade; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sections_grade ON public.sections USING btree (grade_id);


--
-- TOC entry 4219 (class 1259 OID 18668)
-- Name: idx_student_summaries_student; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_student_summaries_student ON public.student_summaries USING btree (student_id);


--
-- TOC entry 4118 (class 1259 OID 18124)
-- Name: idx_students_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_students_active ON public.students USING btree (id) WHERE (deleted_at IS NULL);


--
-- TOC entry 4119 (class 1259 OID 18125)
-- Name: idx_students_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_students_code ON public.students USING btree (student_code) WHERE (deleted_at IS NULL);


--
-- TOC entry 4120 (class 1259 OID 18126)
-- Name: idx_students_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_students_name ON public.students USING btree (full_name) WHERE (deleted_at IS NULL);


--
-- TOC entry 4121 (class 1259 OID 18127)
-- Name: idx_students_section; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_students_section ON public.students USING btree (section_id) WHERE (deleted_at IS NULL);


--
-- TOC entry 4128 (class 1259 OID 18128)
-- Name: idx_subjects_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_subjects_active ON public.subjects USING btree (id) WHERE (is_active = true);


--
-- TOC entry 4129 (class 1259 OID 18129)
-- Name: idx_subjects_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_subjects_code ON public.subjects USING btree (subject_code);


--
-- TOC entry 4130 (class 1259 OID 18130)
-- Name: idx_subjects_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_subjects_name ON public.subjects USING btree (name);


--
-- TOC entry 4137 (class 1259 OID 18131)
-- Name: idx_teachers_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teachers_active ON public.teachers USING btree (id) WHERE (deleted_at IS NULL);


--
-- TOC entry 4138 (class 1259 OID 18132)
-- Name: idx_teachers_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teachers_code ON public.teachers USING btree (teacher_code) WHERE (deleted_at IS NULL);


--
-- TOC entry 4139 (class 1259 OID 18133)
-- Name: idx_teachers_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teachers_name ON public.teachers USING btree (full_name) WHERE (deleted_at IS NULL);


--
-- TOC entry 4313 (class 2620 OID 18134)
-- Name: activities trg_activities_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_activities_updated_at BEFORE UPDATE ON public.activities FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();


--
-- TOC entry 4288 (class 2620 OID 18135)
-- Name: exam_questions trg_after_delete_exam_question; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_after_delete_exam_question AFTER DELETE ON public.exam_questions FOR EACH ROW EXECUTE FUNCTION public.fn_calculate_exam_total_marks();


--
-- TOC entry 4286 (class 2620 OID 18136)
-- Name: attendance trg_after_insert_attendance; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_after_insert_attendance AFTER INSERT ON public.attendance FOR EACH ROW EXECUTE FUNCTION public.fn_notify_absence();


--
-- TOC entry 4289 (class 2620 OID 18137)
-- Name: exam_questions trg_after_insert_exam_question; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_after_insert_exam_question AFTER INSERT ON public.exam_questions FOR EACH ROW EXECUTE FUNCTION public.fn_calculate_exam_total_marks();


--
-- TOC entry 4290 (class 2620 OID 18138)
-- Name: exam_questions trg_after_update_exam_question; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_after_update_exam_question AFTER UPDATE ON public.exam_questions FOR EACH ROW EXECUTE FUNCTION public.fn_calculate_exam_total_marks();


--
-- TOC entry 4316 (class 2620 OID 18139)
-- Name: exam_results trg_after_update_exam_result; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_after_update_exam_result AFTER UPDATE OF status ON public.exam_results FOR EACH ROW EXECUTE FUNCTION public.fn_notify_exam_completed();


--
-- TOC entry 4291 (class 2620 OID 18140)
-- Name: exams trg_after_update_exam_status; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_after_update_exam_status AFTER UPDATE OF status ON public.exams FOR EACH ROW EXECUTE FUNCTION public.fn_notify_exam_published();


--
-- TOC entry 4296 (class 2620 OID 18141)
-- Name: pending_content trg_after_update_pending_content; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_after_update_pending_content AFTER UPDATE OF status ON public.pending_content FOR EACH ROW EXECUTE FUNCTION public.fn_notify_content_review();


--
-- TOC entry 4303 (class 2620 OID 18142)
-- Name: students trg_after_update_student_name; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_after_update_student_name AFTER UPDATE OF full_name ON public.students FOR EACH ROW EXECUTE FUNCTION public.fn_sync_student_name_cache();


--
-- TOC entry 4287 (class 2620 OID 18143)
-- Name: attendance trg_before_insert_attendance_cache; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_before_insert_attendance_cache BEFORE INSERT ON public.attendance FOR EACH ROW EXECUTE FUNCTION public.fn_update_attendance_cache();


--
-- TOC entry 4317 (class 2620 OID 18144)
-- Name: exam_results trg_before_insert_exam_result_cache; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_before_insert_exam_result_cache BEFORE INSERT ON public.exam_results FOR EACH ROW EXECUTE FUNCTION public.fn_update_exam_result_cache();


--
-- TOC entry 4304 (class 2620 OID 18145)
-- Name: students trg_before_insert_student_code; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_before_insert_student_code BEFORE INSERT ON public.students FOR EACH ROW EXECUTE FUNCTION public.fn_generate_student_code();


--
-- TOC entry 4307 (class 2620 OID 18146)
-- Name: subjects trg_before_insert_subject_code; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_before_insert_subject_code BEFORE INSERT ON public.subjects FOR EACH ROW EXECUTE FUNCTION public.fn_generate_subject_code();


--
-- TOC entry 4309 (class 2620 OID 18147)
-- Name: teachers trg_before_insert_teacher_code; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_before_insert_teacher_code BEFORE INSERT ON public.teachers FOR EACH ROW EXECUTE FUNCTION public.fn_generate_teacher_code();


--
-- TOC entry 4314 (class 2620 OID 18148)
-- Name: chapters trg_chapters_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_chapters_updated_at BEFORE UPDATE ON public.chapters FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();


--
-- TOC entry 4315 (class 2620 OID 18149)
-- Name: daily_summaries trg_daily_summaries_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_daily_summaries_updated_at BEFORE UPDATE ON public.daily_summaries FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();


--
-- TOC entry 4284 (class 2620 OID 18150)
-- Name: admins trg_log_admin_login; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_log_admin_login AFTER UPDATE OF last_login_at ON public.admins FOR EACH ROW WHEN ((new.last_login_at IS DISTINCT FROM old.last_login_at)) EXECUTE FUNCTION public.fn_log_user_login();


--
-- TOC entry 4295 (class 2620 OID 18151)
-- Name: parents trg_log_parent_login; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_log_parent_login AFTER UPDATE OF last_login_at ON public.parents FOR EACH ROW WHEN ((new.last_login_at IS DISTINCT FROM old.last_login_at)) EXECUTE FUNCTION public.fn_log_user_login();


--
-- TOC entry 4305 (class 2620 OID 18152)
-- Name: students trg_log_student_login; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_log_student_login AFTER UPDATE OF last_login_at ON public.students FOR EACH ROW WHEN ((new.last_login_at IS DISTINCT FROM old.last_login_at)) EXECUTE FUNCTION public.fn_log_user_login();


--
-- TOC entry 4310 (class 2620 OID 18153)
-- Name: teachers trg_log_teacher_login; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_log_teacher_login AFTER UPDATE OF last_login_at ON public.teachers FOR EACH ROW WHEN ((new.last_login_at IS DISTINCT FROM old.last_login_at)) EXECUTE FUNCTION public.fn_log_user_login();


--
-- TOC entry 4298 (class 2620 OID 22115)
-- Name: questions trg_normalize_question_format; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_normalize_question_format BEFORE INSERT OR UPDATE ON public.questions FOR EACH ROW EXECUTE FUNCTION public.normalize_question_format();


--
-- TOC entry 4311 (class 2620 OID 18154)
-- Name: teachers trg_prevent_teacher_deletion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_prevent_teacher_deletion BEFORE UPDATE ON public.teachers FOR EACH ROW EXECUTE FUNCTION public.fn_prevent_teacher_soft_delete();


--
-- TOC entry 4285 (class 2620 OID 18155)
-- Name: admins trg_update_admins_timestamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_update_admins_timestamp BEFORE UPDATE ON public.admins FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();


--
-- TOC entry 4292 (class 2620 OID 18156)
-- Name: exams trg_update_exams_timestamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_update_exams_timestamp BEFORE UPDATE ON public.exams FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();


--
-- TOC entry 4294 (class 2620 OID 18157)
-- Name: grades trg_update_grades_timestamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_update_grades_timestamp BEFORE UPDATE ON public.grades FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();


--
-- TOC entry 4299 (class 2620 OID 18158)
-- Name: questions trg_update_questions_timestamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_update_questions_timestamp BEFORE UPDATE ON public.questions FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();


--
-- TOC entry 4318 (class 2620 OID 18159)
-- Name: school_settings trg_update_school_settings_timestamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_update_school_settings_timestamp BEFORE UPDATE ON public.school_settings FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();


--
-- TOC entry 4301 (class 2620 OID 18160)
-- Name: section_subjects trg_update_section_subjects_timestamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_update_section_subjects_timestamp BEFORE UPDATE ON public.section_subjects FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();


--
-- TOC entry 4302 (class 2620 OID 18161)
-- Name: sections trg_update_sections_timestamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_update_sections_timestamp BEFORE UPDATE ON public.sections FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();


--
-- TOC entry 4306 (class 2620 OID 18162)
-- Name: students trg_update_students_timestamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_update_students_timestamp BEFORE UPDATE ON public.students FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();


--
-- TOC entry 4308 (class 2620 OID 18163)
-- Name: subjects trg_update_subjects_timestamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_update_subjects_timestamp BEFORE UPDATE ON public.subjects FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();


--
-- TOC entry 4312 (class 2620 OID 18164)
-- Name: teachers trg_update_teachers_timestamp; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_update_teachers_timestamp BEFORE UPDATE ON public.teachers FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();


--
-- TOC entry 4293 (class 2620 OID 18165)
-- Name: exams trg_validate_teacher_exam; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_validate_teacher_exam BEFORE INSERT ON public.exams FOR EACH ROW EXECUTE FUNCTION public.fn_check_teacher_subject_access();


--
-- TOC entry 4297 (class 2620 OID 18166)
-- Name: pending_content trg_validate_teacher_pending_content; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_validate_teacher_pending_content BEFORE INSERT ON public.pending_content FOR EACH ROW EXECUTE FUNCTION public.fn_check_teacher_subject_access();


--
-- TOC entry 4300 (class 2620 OID 18167)
-- Name: questions trg_validate_teacher_question; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_validate_teacher_question BEFORE INSERT ON public.questions FOR EACH ROW EXECUTE FUNCTION public.fn_check_teacher_subject_access();


--
-- TOC entry 4261 (class 2606 OID 18168)
-- Name: activities activities_created_by_teacher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_created_by_teacher_id_fkey FOREIGN KEY (created_by_teacher_id) REFERENCES public.teachers(id) ON DELETE SET NULL;


--
-- TOC entry 4262 (class 2606 OID 18173)
-- Name: activities activities_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- TOC entry 4263 (class 2606 OID 18178)
-- Name: activities activities_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE SET NULL;


--
-- TOC entry 4225 (class 2606 OID 18183)
-- Name: admins admins_deleted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.admins(id);


--
-- TOC entry 4264 (class 2606 OID 18188)
-- Name: app_user app_user_auth_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_auth_user_id_fkey FOREIGN KEY (auth_user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- TOC entry 4226 (class 2606 OID 18193)
-- Name: attendance attendance_marked_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_marked_by_fkey FOREIGN KEY (marked_by) REFERENCES public.teachers(id);


--
-- TOC entry 4227 (class 2606 OID 18198)
-- Name: attendance attendance_section_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_section_id_fkey FOREIGN KEY (section_id) REFERENCES public.sections(id) ON DELETE CASCADE;


--
-- TOC entry 4228 (class 2606 OID 18203)
-- Name: attendance attendance_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- TOC entry 4283 (class 2606 OID 20979)
-- Name: chapter_topics chapter_topics_chapter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chapter_topics
    ADD CONSTRAINT chapter_topics_chapter_id_fkey FOREIGN KEY (chapter_id) REFERENCES public.chapters(id) ON DELETE CASCADE;


--
-- TOC entry 4265 (class 2606 OID 18208)
-- Name: chapters chapters_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chapters
    ADD CONSTRAINT chapters_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE CASCADE;


--
-- TOC entry 4266 (class 2606 OID 18213)
-- Name: daily_summaries daily_summaries_created_by_teacher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.daily_summaries
    ADD CONSTRAINT daily_summaries_created_by_teacher_id_fkey FOREIGN KEY (created_by_teacher_id) REFERENCES public.teachers(id) ON DELETE SET NULL;


--
-- TOC entry 4267 (class 2606 OID 18218)
-- Name: daily_summaries daily_summaries_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.daily_summaries
    ADD CONSTRAINT daily_summaries_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- TOC entry 4229 (class 2606 OID 18223)
-- Name: exam_questions exam_questions_exam_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_questions
    ADD CONSTRAINT exam_questions_exam_id_fkey FOREIGN KEY (exam_id) REFERENCES public.exams(id) ON DELETE CASCADE;


--
-- TOC entry 4230 (class 2606 OID 18228)
-- Name: exam_questions exam_questions_question_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_questions
    ADD CONSTRAINT exam_questions_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.questions(id) ON DELETE RESTRICT;


--
-- TOC entry 4268 (class 2606 OID 18233)
-- Name: exam_results exam_results_exam_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_results
    ADD CONSTRAINT exam_results_exam_id_fkey FOREIGN KEY (exam_id) REFERENCES public.exams(id) ON DELETE CASCADE;


--
-- TOC entry 4269 (class 2606 OID 18238)
-- Name: exam_results exam_results_graded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_results
    ADD CONSTRAINT exam_results_graded_by_fkey FOREIGN KEY (graded_by) REFERENCES public.teachers(id);


--
-- TOC entry 4270 (class 2606 OID 18243)
-- Name: exam_results exam_results_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_results
    ADD CONSTRAINT exam_results_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- TOC entry 4231 (class 2606 OID 18248)
-- Name: exams exams_created_by_admin_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exams
    ADD CONSTRAINT exams_created_by_admin_fkey FOREIGN KEY (created_by_admin) REFERENCES public.admins(id);


--
-- TOC entry 4232 (class 2606 OID 18253)
-- Name: exams exams_created_by_teacher_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exams
    ADD CONSTRAINT exams_created_by_teacher_fkey FOREIGN KEY (created_by_teacher) REFERENCES public.teachers(id);


--
-- TOC entry 4233 (class 2606 OID 18258)
-- Name: exams exams_grade_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exams
    ADD CONSTRAINT exams_grade_id_fkey FOREIGN KEY (grade_id) REFERENCES public.grades(id) ON DELETE RESTRICT;


--
-- TOC entry 4234 (class 2606 OID 18263)
-- Name: exams exams_section_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exams
    ADD CONSTRAINT exams_section_id_fkey FOREIGN KEY (section_id) REFERENCES public.sections(id) ON DELETE RESTRICT;


--
-- TOC entry 4235 (class 2606 OID 18268)
-- Name: exams exams_semester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exams
    ADD CONSTRAINT exams_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES public.semesters(id) ON DELETE RESTRICT;


--
-- TOC entry 4236 (class 2606 OID 18273)
-- Name: exams exams_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exams
    ADD CONSTRAINT exams_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE RESTRICT;


--
-- TOC entry 4256 (class 2606 OID 18278)
-- Name: students fk_students_section; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT fk_students_section FOREIGN KEY (section_id) REFERENCES public.sections(id) ON DELETE RESTRICT;


--
-- TOC entry 4237 (class 2606 OID 18283)
-- Name: messages messages_recipient_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_recipient_admin_id_fkey FOREIGN KEY (recipient_admin_id) REFERENCES public.admins(id) ON DELETE SET NULL;


--
-- TOC entry 4238 (class 2606 OID 18288)
-- Name: messages messages_recipient_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_recipient_parent_id_fkey FOREIGN KEY (recipient_parent_id) REFERENCES public.parents(id) ON DELETE SET NULL;


--
-- TOC entry 4239 (class 2606 OID 18293)
-- Name: messages messages_recipient_teacher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_recipient_teacher_id_fkey FOREIGN KEY (recipient_teacher_id) REFERENCES public.teachers(id) ON DELETE SET NULL;


--
-- TOC entry 4240 (class 2606 OID 18298)
-- Name: messages messages_sender_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_sender_admin_id_fkey FOREIGN KEY (sender_admin_id) REFERENCES public.admins(id) ON DELETE SET NULL;


--
-- TOC entry 4241 (class 2606 OID 18303)
-- Name: messages messages_sender_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_sender_parent_id_fkey FOREIGN KEY (sender_parent_id) REFERENCES public.parents(id) ON DELETE SET NULL;


--
-- TOC entry 4242 (class 2606 OID 18308)
-- Name: messages messages_sender_teacher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_sender_teacher_id_fkey FOREIGN KEY (sender_teacher_id) REFERENCES public.teachers(id) ON DELETE SET NULL;


--
-- TOC entry 4271 (class 2606 OID 18313)
-- Name: notifications notifications_recipient_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_recipient_admin_id_fkey FOREIGN KEY (recipient_admin_id) REFERENCES public.admins(id) ON DELETE CASCADE;


--
-- TOC entry 4272 (class 2606 OID 18318)
-- Name: notifications notifications_recipient_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_recipient_parent_id_fkey FOREIGN KEY (recipient_parent_id) REFERENCES public.parents(id) ON DELETE CASCADE;


--
-- TOC entry 4273 (class 2606 OID 18323)
-- Name: notifications notifications_recipient_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_recipient_student_id_fkey FOREIGN KEY (recipient_student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- TOC entry 4274 (class 2606 OID 18328)
-- Name: notifications notifications_recipient_teacher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_recipient_teacher_id_fkey FOREIGN KEY (recipient_teacher_id) REFERENCES public.teachers(id) ON DELETE CASCADE;


--
-- TOC entry 4259 (class 2606 OID 18333)
-- Name: parent_students parent_students_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parent_students
    ADD CONSTRAINT parent_students_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.parents(id) ON DELETE CASCADE;


--
-- TOC entry 4260 (class 2606 OID 18338)
-- Name: parent_students parent_students_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parent_students
    ADD CONSTRAINT parent_students_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- TOC entry 4243 (class 2606 OID 18343)
-- Name: pending_content pending_content_reviewed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pending_content
    ADD CONSTRAINT pending_content_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.admins(id);


--
-- TOC entry 4244 (class 2606 OID 18348)
-- Name: pending_content pending_content_teacher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pending_content
    ADD CONSTRAINT pending_content_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id) ON DELETE CASCADE;


--
-- TOC entry 4278 (class 2606 OID 18630)
-- Name: practice_quiz_answers practice_quiz_answers_attempt_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.practice_quiz_answers
    ADD CONSTRAINT practice_quiz_answers_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.practice_quiz_attempts(id) ON DELETE CASCADE;


--
-- TOC entry 4279 (class 2606 OID 18635)
-- Name: practice_quiz_answers practice_quiz_answers_question_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.practice_quiz_answers
    ADD CONSTRAINT practice_quiz_answers_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.questions(id) ON DELETE CASCADE;


--
-- TOC entry 4275 (class 2606 OID 18613)
-- Name: practice_quiz_attempts practice_quiz_attempts_chapter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.practice_quiz_attempts
    ADD CONSTRAINT practice_quiz_attempts_chapter_id_fkey FOREIGN KEY (chapter_id) REFERENCES public.chapters(id) ON DELETE SET NULL;


--
-- TOC entry 4276 (class 2606 OID 18603)
-- Name: practice_quiz_attempts practice_quiz_attempts_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.practice_quiz_attempts
    ADD CONSTRAINT practice_quiz_attempts_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- TOC entry 4277 (class 2606 OID 18608)
-- Name: practice_quiz_attempts practice_quiz_attempts_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.practice_quiz_attempts
    ADD CONSTRAINT practice_quiz_attempts_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE CASCADE;


--
-- TOC entry 4245 (class 2606 OID 18353)
-- Name: questions questions_chapter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_chapter_id_fkey FOREIGN KEY (chapter_id) REFERENCES public.chapters(id) ON DELETE SET NULL;


--
-- TOC entry 4246 (class 2606 OID 18358)
-- Name: questions questions_created_by_admin_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_created_by_admin_fkey FOREIGN KEY (created_by_admin) REFERENCES public.admins(id);


--
-- TOC entry 4247 (class 2606 OID 18363)
-- Name: questions questions_created_by_teacher_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_created_by_teacher_fkey FOREIGN KEY (created_by_teacher) REFERENCES public.teachers(id);


--
-- TOC entry 4248 (class 2606 OID 18368)
-- Name: questions questions_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.questions
    ADD CONSTRAINT questions_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE RESTRICT;


--
-- TOC entry 4249 (class 2606 OID 18373)
-- Name: reports reports_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.parents(id) ON DELETE CASCADE;


--
-- TOC entry 4250 (class 2606 OID 18378)
-- Name: reports reports_sent_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_sent_by_fkey FOREIGN KEY (sent_by) REFERENCES public.admins(id);


--
-- TOC entry 4251 (class 2606 OID 18383)
-- Name: reports reports_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- TOC entry 4252 (class 2606 OID 18388)
-- Name: section_subjects section_subjects_section_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.section_subjects
    ADD CONSTRAINT section_subjects_section_id_fkey FOREIGN KEY (section_id) REFERENCES public.sections(id) ON DELETE CASCADE;


--
-- TOC entry 4253 (class 2606 OID 18393)
-- Name: section_subjects section_subjects_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.section_subjects
    ADD CONSTRAINT section_subjects_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE RESTRICT;


--
-- TOC entry 4254 (class 2606 OID 18398)
-- Name: section_subjects section_subjects_teacher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.section_subjects
    ADD CONSTRAINT section_subjects_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id) ON DELETE RESTRICT;


--
-- TOC entry 4255 (class 2606 OID 18403)
-- Name: sections sections_grade_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sections
    ADD CONSTRAINT sections_grade_id_fkey FOREIGN KEY (grade_id) REFERENCES public.grades(id) ON DELETE RESTRICT;


--
-- TOC entry 4280 (class 2606 OID 18663)
-- Name: student_summaries student_summaries_chapter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_summaries
    ADD CONSTRAINT student_summaries_chapter_id_fkey FOREIGN KEY (chapter_id) REFERENCES public.chapters(id) ON DELETE SET NULL;


--
-- TOC entry 4281 (class 2606 OID 18653)
-- Name: student_summaries student_summaries_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_summaries
    ADD CONSTRAINT student_summaries_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- TOC entry 4282 (class 2606 OID 18658)
-- Name: student_summaries student_summaries_subject_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_summaries
    ADD CONSTRAINT student_summaries_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id) ON DELETE CASCADE;


--
-- TOC entry 4257 (class 2606 OID 18408)
-- Name: students students_deleted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.admins(id);


--
-- TOC entry 4258 (class 2606 OID 18413)
-- Name: teachers teachers_deleted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teachers
    ADD CONSTRAINT teachers_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.admins(id);


--
-- TOC entry 4509 (class 3256 OID 18418)
-- Name: admins Admins can delete admins; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can delete admins" ON public.admins FOR UPDATE USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- TOC entry 4510 (class 3256 OID 18419)
-- Name: admins Admins can insert admins; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can insert admins" ON public.admins FOR INSERT WITH CHECK (public.is_admin());


--
-- TOC entry 4511 (class 3256 OID 18420)
-- Name: exam_questions Admins can manage exam questions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can manage exam questions" ON public.exam_questions USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- TOC entry 4512 (class 3256 OID 18421)
-- Name: exams Admins can manage exams; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can manage exams" ON public.exams USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- TOC entry 4513 (class 3256 OID 18422)
-- Name: grades Admins can manage grades; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can manage grades" ON public.grades USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- TOC entry 4514 (class 3256 OID 18423)
-- Name: parent_students Admins can manage parent students; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can manage parent students" ON public.parent_students USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- TOC entry 4515 (class 3256 OID 18424)
-- Name: pending_content Admins can manage pending content; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can manage pending content" ON public.pending_content USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- TOC entry 4516 (class 3256 OID 18425)
-- Name: questions Admins can manage questions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can manage questions" ON public.questions USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- TOC entry 4517 (class 3256 OID 18426)
-- Name: reports Admins can manage reports; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can manage reports" ON public.reports USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- TOC entry 4518 (class 3256 OID 18427)
-- Name: section_subjects Admins can manage section subjects; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can manage section subjects" ON public.section_subjects USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- TOC entry 4519 (class 3256 OID 18428)
-- Name: sections Admins can manage sections; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can manage sections" ON public.sections USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- TOC entry 4520 (class 3256 OID 18429)
-- Name: semesters Admins can manage semesters; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can manage semesters" ON public.semesters USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- TOC entry 4521 (class 3256 OID 18430)
-- Name: students Admins can manage students; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can manage students" ON public.students USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- TOC entry 4522 (class 3256 OID 18431)
-- Name: subjects Admins can manage subjects; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can manage subjects" ON public.subjects USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- TOC entry 4523 (class 3256 OID 18432)
-- Name: teachers Admins can manage teachers; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can manage teachers" ON public.teachers USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- TOC entry 4524 (class 3256 OID 18433)
-- Name: admins Admins can update own profile; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can update own profile" ON public.admins FOR UPDATE USING ((id = public.app_current_user_id()));


--
-- TOC entry 4525 (class 3256 OID 18434)
-- Name: school_settings Admins can update school settings; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can update school settings" ON public.school_settings FOR UPDATE USING (public.is_admin()) WITH CHECK (public.is_admin());


--
-- TOC entry 4526 (class 3256 OID 18435)
-- Name: activity_logs Admins can view activity logs; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can view activity logs" ON public.activity_logs FOR SELECT USING (public.is_admin());


--
-- TOC entry 4527 (class 3256 OID 18436)
-- Name: admins Admins can view all admins; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can view all admins" ON public.admins FOR SELECT USING (public.is_admin());


--
-- TOC entry 4528 (class 3256 OID 18437)
-- Name: attendance Admins can view all attendance; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can view all attendance" ON public.attendance FOR SELECT USING (public.is_admin());


--
-- TOC entry 4529 (class 3256 OID 18438)
-- Name: exam_results Admins can view all exam results; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can view all exam results" ON public.exam_results FOR SELECT USING (public.is_admin());


--
-- TOC entry 4530 (class 3256 OID 18439)
-- Name: parents Admins can view all parents; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can view all parents" ON public.parents FOR SELECT USING (public.is_admin());


--
-- TOC entry 4531 (class 3256 OID 18440)
-- Name: students Admins can view all students; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can view all students" ON public.students FOR SELECT USING (public.is_admin());


--
-- TOC entry 4532 (class 3256 OID 18441)
-- Name: admins Admins can view own profile for login; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can view own profile for login" ON public.admins FOR SELECT USING (((id = public.app_current_user_id()) OR public.is_admin()));


--
-- TOC entry 4595 (class 3256 OID 25536)
-- Name: parent_students Parents can insert own links; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Parents can insert own links" ON public.parent_students FOR INSERT TO authenticated WITH CHECK ((parent_id = ( SELECT app_user.app_entity_id
   FROM public.app_user
  WHERE ((app_user.auth_user_id = auth.uid()) AND ((app_user.user_type)::text = 'parent'::text)))));


--
-- TOC entry 4591 (class 3256 OID 25521)
-- Name: students Parents can search students by code; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Parents can search students by code" ON public.students FOR SELECT TO authenticated USING (((deleted_at IS NULL) AND (is_active = true) AND (EXISTS ( SELECT 1
   FROM public.app_user
  WHERE ((app_user.auth_user_id = auth.uid()) AND ((app_user.user_type)::text = 'parent'::text))))));


--
-- TOC entry 4593 (class 3256 OID 25534)
-- Name: parents Parents can update own profile; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Parents can update own profile" ON public.parents FOR UPDATE TO authenticated USING ((id = ( SELECT app_user.app_entity_id
   FROM public.app_user
  WHERE ((app_user.auth_user_id = auth.uid()) AND ((app_user.user_type)::text = 'parent'::text)))));


--
-- TOC entry 4592 (class 3256 OID 25533)
-- Name: parents Parents can view own profile; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Parents can view own profile" ON public.parents FOR SELECT TO authenticated USING ((id = ( SELECT app_user.app_entity_id
   FROM public.app_user
  WHERE ((app_user.auth_user_id = auth.uid()) AND ((app_user.user_type)::text = 'parent'::text)))));


--
-- TOC entry 4594 (class 3256 OID 25535)
-- Name: parent_students Parents can view own relationships; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Parents can view own relationships" ON public.parent_students FOR SELECT TO authenticated USING ((parent_id = ( SELECT app_user.app_entity_id
   FROM public.app_user
  WHERE ((app_user.auth_user_id = auth.uid()) AND ((app_user.user_type)::text = 'parent'::text)))));


--
-- TOC entry 4533 (class 3256 OID 18445)
-- Name: students Parents can view their children; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Parents can view their children" ON public.students FOR SELECT USING (((EXISTS ( SELECT 1
   FROM public.parent_students ps
  WHERE ((ps.parent_id = public.app_current_user_id()) AND (ps.student_id = students.id)))) AND (deleted_at IS NULL)));


--
-- TOC entry 4534 (class 3256 OID 18446)
-- Name: reports Parents can view their children reports; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Parents can view their children reports" ON public.reports FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.parent_students ps
  WHERE ((ps.parent_id = public.app_current_user_id()) AND (ps.student_id = reports.student_id)))));


--
-- TOC entry 4535 (class 3256 OID 18447)
-- Name: grades Public can view active grades; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public can view active grades" ON public.grades FOR SELECT USING ((is_active = true));


--
-- TOC entry 4536 (class 3256 OID 18448)
-- Name: section_subjects Public can view active section subjects; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public can view active section subjects" ON public.section_subjects FOR SELECT USING ((is_active = true));


--
-- TOC entry 4537 (class 3256 OID 18449)
-- Name: sections Public can view active sections; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public can view active sections" ON public.sections FOR SELECT USING ((is_active = true));


--
-- TOC entry 4538 (class 3256 OID 18450)
-- Name: semesters Public can view active semesters; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public can view active semesters" ON public.semesters FOR SELECT USING ((is_active = true));


--
-- TOC entry 4539 (class 3256 OID 18451)
-- Name: subjects Public can view active subjects; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public can view active subjects" ON public.subjects FOR SELECT USING ((is_active = true));


--
-- TOC entry 4540 (class 3256 OID 18452)
-- Name: questions Public can view approved questions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public can view approved questions" ON public.questions FOR SELECT USING (((status = 'approved'::public.approval_status_enum) AND (is_active = true)));


--
-- TOC entry 4541 (class 3256 OID 18453)
-- Name: exam_questions Public can view exam questions for published exams; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public can view exam questions for published exams" ON public.exam_questions FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.exams e
  WHERE ((e.id = exam_questions.exam_id) AND (e.status = 'published'::public.exam_status_enum)))));


--
-- TOC entry 4542 (class 3256 OID 18454)
-- Name: school_settings Public can view school settings; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public can view school settings" ON public.school_settings FOR SELECT USING (true);


--
-- TOC entry 4543 (class 3256 OID 18455)
-- Name: exam_results Students can manage own exam results; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Students can manage own exam results" ON public.exam_results USING ((student_id = public.app_current_user_id())) WITH CHECK ((student_id = public.app_current_user_id()));


--
-- TOC entry 4584 (class 3256 OID 20985)
-- Name: chapter_topics Students can read active chapter topics; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Students can read active chapter topics" ON public.chapter_topics FOR SELECT TO authenticated USING ((is_active = true));


--
-- TOC entry 4544 (class 3256 OID 18456)
-- Name: students Students can update own profile; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Students can update own profile" ON public.students FOR UPDATE USING ((id = public.app_current_user_id()));


--
-- TOC entry 4545 (class 3256 OID 18457)
-- Name: attendance Students can view own attendance; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Students can view own attendance" ON public.attendance FOR SELECT USING ((student_id = public.app_current_user_id()));


--
-- TOC entry 4546 (class 3256 OID 18458)
-- Name: students Students can view own data; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Students can view own data" ON public.students FOR SELECT USING (((id = public.app_current_user_id()) AND (deleted_at IS NULL)));


--
-- TOC entry 4547 (class 3256 OID 18459)
-- Name: exam_results Students can view own exam results; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Students can view own exam results" ON public.exam_results FOR SELECT USING ((student_id = public.app_current_user_id()));


--
-- TOC entry 4549 (class 3256 OID 18460)
-- Name: exams Students can view published exams; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Students can view published exams" ON public.exams FOR SELECT USING (((status = 'published'::public.exam_status_enum) AND (EXISTS ( SELECT 1
   FROM public.students s
  WHERE ((s.id = public.app_current_user_id()) AND (s.section_id = exams.section_id) AND (s.deleted_at IS NULL))))));


--
-- TOC entry 4550 (class 3256 OID 18461)
-- Name: activity_logs System can insert activity logs; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "System can insert activity logs" ON public.activity_logs FOR INSERT WITH CHECK (true);


--
-- TOC entry 4551 (class 3256 OID 18462)
-- Name: exams Teachers can create exams; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Teachers can create exams" ON public.exams FOR INSERT WITH CHECK (((created_by_teacher = public.app_current_user_id()) AND (EXISTS ( SELECT 1
   FROM public.section_subjects ss
  WHERE ((ss.teacher_id = public.app_current_user_id()) AND (ss.section_id = exams.section_id) AND (ss.subject_id = exams.subject_id) AND (ss.is_active = true))))));


--
-- TOC entry 4552 (class 3256 OID 18463)
-- Name: pending_content Teachers can create pending content; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Teachers can create pending content" ON public.pending_content FOR INSERT WITH CHECK ((teacher_id = public.app_current_user_id()));


--
-- TOC entry 4553 (class 3256 OID 18464)
-- Name: questions Teachers can create questions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Teachers can create questions" ON public.questions FOR INSERT WITH CHECK (((created_by_teacher = public.app_current_user_id()) AND (EXISTS ( SELECT 1
   FROM public.section_subjects ss
  WHERE ((ss.teacher_id = public.app_current_user_id()) AND (ss.subject_id = questions.subject_id) AND (ss.is_active = true))))));


--
-- TOC entry 4554 (class 3256 OID 18465)
-- Name: exam_results Teachers can grade exam results; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Teachers can grade exam results" ON public.exam_results FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM (public.exams e
     JOIN public.section_subjects ss ON (((e.section_id = ss.section_id) AND (e.subject_id = ss.subject_id))))
  WHERE ((e.id = exam_results.exam_id) AND (ss.teacher_id = public.app_current_user_id()) AND (ss.is_active = true)))));


--
-- TOC entry 4555 (class 3256 OID 18467)
-- Name: exam_questions Teachers can manage own exam questions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Teachers can manage own exam questions" ON public.exam_questions USING ((EXISTS ( SELECT 1
   FROM public.exams e
  WHERE ((e.id = exam_questions.exam_id) AND (e.created_by_teacher = public.app_current_user_id())))));


--
-- TOC entry 4556 (class 3256 OID 18468)
-- Name: attendance Teachers can mark attendance; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Teachers can mark attendance" ON public.attendance FOR INSERT WITH CHECK (((marked_by = public.app_current_user_id()) AND (EXISTS ( SELECT 1
   FROM public.section_subjects ss
  WHERE ((ss.teacher_id = public.app_current_user_id()) AND (ss.section_id = attendance.section_id) AND (ss.is_active = true))))));


--
-- TOC entry 4557 (class 3256 OID 18469)
-- Name: teachers Teachers can update own profile; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Teachers can update own profile" ON public.teachers FOR UPDATE USING ((id = public.app_current_user_id()));


--
-- TOC entry 4558 (class 3256 OID 18470)
-- Name: teachers Teachers can view active teachers; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Teachers can view active teachers" ON public.teachers FOR SELECT USING ((deleted_at IS NULL));


--
-- TOC entry 4559 (class 3256 OID 18471)
-- Name: exams Teachers can view own exams; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Teachers can view own exams" ON public.exams FOR SELECT USING ((created_by_teacher = public.app_current_user_id()));


--
-- TOC entry 4560 (class 3256 OID 18472)
-- Name: pending_content Teachers can view own pending content; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Teachers can view own pending content" ON public.pending_content FOR SELECT USING ((teacher_id = public.app_current_user_id()));


--
-- TOC entry 4561 (class 3256 OID 18473)
-- Name: teachers Teachers can view own profile; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Teachers can view own profile" ON public.teachers FOR SELECT USING (((id = public.app_current_user_id()) OR (deleted_at IS NULL)));


--
-- TOC entry 4562 (class 3256 OID 18474)
-- Name: questions Teachers can view own questions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Teachers can view own questions" ON public.questions FOR SELECT USING ((created_by_teacher = public.app_current_user_id()));


--
-- TOC entry 4563 (class 3256 OID 18475)
-- Name: exam_results Teachers can view their exam results; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Teachers can view their exam results" ON public.exam_results FOR SELECT USING ((EXISTS ( SELECT 1
   FROM (public.exams e
     JOIN public.section_subjects ss ON (((e.section_id = ss.section_id) AND (e.subject_id = ss.subject_id))))
  WHERE ((e.id = exam_results.exam_id) AND (ss.teacher_id = public.app_current_user_id()) AND (ss.is_active = true)))));


--
-- TOC entry 4564 (class 3256 OID 18477)
-- Name: attendance Teachers can view their section attendance; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Teachers can view their section attendance" ON public.attendance FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.section_subjects ss
  WHERE ((ss.teacher_id = public.app_current_user_id()) AND (ss.section_id = attendance.section_id) AND (ss.is_active = true)))));


--
-- TOC entry 4565 (class 3256 OID 18478)
-- Name: students Teachers can view their students; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Teachers can view their students" ON public.students FOR SELECT USING (((EXISTS ( SELECT 1
   FROM public.section_subjects ss
  WHERE ((ss.teacher_id = public.app_current_user_id()) AND (ss.section_id = students.section_id) AND (ss.is_active = true)))) AND (deleted_at IS NULL)));


--
-- TOC entry 4497 (class 0 OID 17756)
-- Dependencies: 352
-- Name: activities; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4566 (class 3256 OID 18484)
-- Name: activities activities_admin; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY activities_admin ON public.activities TO authenticated USING ((public.effective_user_type() = 'admin'::text)) WITH CHECK ((public.effective_user_type() = 'admin'::text));


--
-- TOC entry 4567 (class 3256 OID 18485)
-- Name: activities activities_modify_teacher; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY activities_modify_teacher ON public.activities TO authenticated USING (((public.effective_user_type() = 'teacher'::text) AND (EXISTS ( SELECT 1
   FROM (public.students st
     JOIN public.section_subjects ss ON ((ss.section_id = st.section_id)))
  WHERE ((st.id = activities.student_id) AND (ss.teacher_id = public.effective_app_user_id())))))) WITH CHECK (((public.effective_user_type() = 'teacher'::text) AND (EXISTS ( SELECT 1
   FROM (public.students st
     JOIN public.section_subjects ss ON ((ss.section_id = st.section_id)))
  WHERE ((st.id = activities.student_id) AND (ss.teacher_id = public.effective_app_user_id()))))));


--
-- TOC entry 4568 (class 3256 OID 18488)
-- Name: activities activities_select_parent; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY activities_select_parent ON public.activities FOR SELECT TO authenticated USING (((public.effective_user_type() = 'parent'::text) AND (EXISTS ( SELECT 1
   FROM public.parent_students ps
  WHERE ((ps.student_id = activities.student_id) AND (ps.parent_id = public.effective_app_user_id()))))));


--
-- TOC entry 4569 (class 3256 OID 18489)
-- Name: activities activities_select_teacher; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY activities_select_teacher ON public.activities FOR SELECT TO authenticated USING (((public.effective_user_type() = 'teacher'::text) AND (EXISTS ( SELECT 1
   FROM (public.students st
     JOIN public.section_subjects ss ON ((ss.section_id = st.section_id)))
  WHERE ((st.id = activities.student_id) AND (ss.teacher_id = public.effective_app_user_id()))))));


--
-- TOC entry 4498 (class 0 OID 17766)
-- Dependencies: 354
-- Name: activity_logs; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4480 (class 0 OID 17561)
-- Dependencies: 335
-- Name: admins; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.admins ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4499 (class 0 OID 17775)
-- Dependencies: 357
-- Name: app_user; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.app_user ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4548 (class 3256 OID 18491)
-- Name: app_user app_user_select_own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY app_user_select_own ON public.app_user FOR SELECT TO authenticated USING ((auth_user_id = auth.uid()));


--
-- TOC entry 4481 (class 0 OID 17571)
-- Dependencies: 336
-- Name: attendance; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4508 (class 0 OID 20967)
-- Dependencies: 408
-- Name: chapter_topics; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.chapter_topics ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4500 (class 0 OID 17782)
-- Dependencies: 360
-- Name: chapters; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.chapters ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4570 (class 3256 OID 18492)
-- Name: chapters chapters_admin; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY chapters_admin ON public.chapters TO authenticated USING ((public.effective_user_type() = 'admin'::text)) WITH CHECK ((public.effective_user_type() = 'admin'::text));


--
-- TOC entry 4571 (class 3256 OID 18493)
-- Name: chapters chapters_modify_teacher; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY chapters_modify_teacher ON public.chapters TO authenticated USING (((public.effective_user_type() = 'teacher'::text) AND (EXISTS ( SELECT 1
   FROM public.section_subjects ss
  WHERE ((ss.subject_id = chapters.subject_id) AND (ss.teacher_id = public.effective_app_user_id())))))) WITH CHECK (((public.effective_user_type() = 'teacher'::text) AND (EXISTS ( SELECT 1
   FROM public.section_subjects ss
  WHERE ((ss.subject_id = chapters.subject_id) AND (ss.teacher_id = public.effective_app_user_id()))))));


--
-- TOC entry 4572 (class 3256 OID 18495)
-- Name: chapters chapters_select_student; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY chapters_select_student ON public.chapters FOR SELECT TO authenticated USING (((public.effective_user_type() = 'student'::text) AND (EXISTS ( SELECT 1
   FROM (public.students s
     JOIN public.section_subjects ss ON (((ss.section_id = s.section_id) AND (ss.subject_id = chapters.subject_id))))
  WHERE ((s.id = public.effective_app_user_id()) AND (s.deleted_at IS NULL))))));


--
-- TOC entry 4573 (class 3256 OID 18497)
-- Name: chapters chapters_select_teacher; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY chapters_select_teacher ON public.chapters FOR SELECT TO authenticated USING (((public.effective_user_type() = 'teacher'::text) AND (EXISTS ( SELECT 1
   FROM public.section_subjects ss
  WHERE ((ss.subject_id = chapters.subject_id) AND (ss.teacher_id = public.effective_app_user_id()))))));


--
-- TOC entry 4501 (class 0 OID 17792)
-- Dependencies: 362
-- Name: daily_summaries; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.daily_summaries ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4574 (class 3256 OID 18498)
-- Name: daily_summaries daily_summaries_admin; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY daily_summaries_admin ON public.daily_summaries TO authenticated USING ((public.effective_user_type() = 'admin'::text)) WITH CHECK ((public.effective_user_type() = 'admin'::text));


--
-- TOC entry 4575 (class 3256 OID 18499)
-- Name: daily_summaries daily_summaries_modify_teacher; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY daily_summaries_modify_teacher ON public.daily_summaries TO authenticated USING (((public.effective_user_type() = 'teacher'::text) AND (EXISTS ( SELECT 1
   FROM (public.students st
     JOIN public.section_subjects ss ON ((ss.section_id = st.section_id)))
  WHERE ((st.id = daily_summaries.student_id) AND (ss.teacher_id = public.effective_app_user_id())))))) WITH CHECK (((public.effective_user_type() = 'teacher'::text) AND (EXISTS ( SELECT 1
   FROM (public.students st
     JOIN public.section_subjects ss ON ((ss.section_id = st.section_id)))
  WHERE ((st.id = daily_summaries.student_id) AND (ss.teacher_id = public.effective_app_user_id()))))));


--
-- TOC entry 4576 (class 3256 OID 18502)
-- Name: daily_summaries daily_summaries_select_parent; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY daily_summaries_select_parent ON public.daily_summaries FOR SELECT TO authenticated USING (((public.effective_user_type() = 'parent'::text) AND (EXISTS ( SELECT 1
   FROM public.parent_students ps
  WHERE ((ps.student_id = daily_summaries.student_id) AND (ps.parent_id = public.effective_app_user_id()))))));


--
-- TOC entry 4577 (class 3256 OID 18503)
-- Name: daily_summaries daily_summaries_select_teacher; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY daily_summaries_select_teacher ON public.daily_summaries FOR SELECT TO authenticated USING (((public.effective_user_type() = 'teacher'::text) AND (EXISTS ( SELECT 1
   FROM (public.students st
     JOIN public.section_subjects ss ON ((ss.section_id = st.section_id)))
  WHERE ((st.id = daily_summaries.student_id) AND (ss.teacher_id = public.effective_app_user_id()))))));


--
-- TOC entry 4482 (class 0 OID 17581)
-- Dependencies: 337
-- Name: exam_questions; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.exam_questions ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4502 (class 0 OID 17803)
-- Dependencies: 365
-- Name: exam_results; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.exam_results ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4483 (class 0 OID 17588)
-- Dependencies: 338
-- Name: exams; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.exams ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4484 (class 0 OID 17602)
-- Dependencies: 339
-- Name: grades; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.grades ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4485 (class 0 OID 17611)
-- Dependencies: 340
-- Name: messages; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4578 (class 3256 OID 18505)
-- Name: messages messages_parent_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY messages_parent_insert ON public.messages FOR INSERT TO authenticated WITH CHECK (((public.effective_user_type() = 'parent'::text) AND (sender_parent_id = public.effective_app_user_id())));


--
-- TOC entry 4579 (class 3256 OID 18506)
-- Name: messages messages_parent_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY messages_parent_select ON public.messages FOR SELECT TO authenticated USING (((public.effective_user_type() = 'parent'::text) AND ((recipient_parent_id = public.effective_app_user_id()) OR (sender_parent_id = public.effective_app_user_id()))));


--
-- TOC entry 4580 (class 3256 OID 18507)
-- Name: messages messages_parent_update_read; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY messages_parent_update_read ON public.messages FOR UPDATE TO authenticated USING (((public.effective_user_type() = 'parent'::text) AND (recipient_parent_id = public.effective_app_user_id()))) WITH CHECK (((public.effective_user_type() = 'parent'::text) AND (recipient_parent_id = public.effective_app_user_id())));


--
-- TOC entry 4581 (class 3256 OID 18508)
-- Name: messages messages_teacher_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY messages_teacher_insert ON public.messages FOR INSERT TO authenticated WITH CHECK (((public.effective_user_type() = 'teacher'::text) AND (sender_teacher_id = public.effective_app_user_id())));


--
-- TOC entry 4582 (class 3256 OID 18509)
-- Name: messages messages_teacher_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY messages_teacher_select ON public.messages FOR SELECT TO authenticated USING (((public.effective_user_type() = 'teacher'::text) AND ((sender_teacher_id = public.effective_app_user_id()) OR (recipient_teacher_id = public.effective_app_user_id()))));


--
-- TOC entry 4583 (class 3256 OID 18510)
-- Name: messages messages_teacher_update_read; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY messages_teacher_update_read ON public.messages FOR UPDATE TO authenticated USING (((public.effective_user_type() = 'teacher'::text) AND (recipient_teacher_id = public.effective_app_user_id()))) WITH CHECK (((public.effective_user_type() = 'teacher'::text) AND (recipient_teacher_id = public.effective_app_user_id())));


--
-- TOC entry 4503 (class 0 OID 17850)
-- Dependencies: 375
-- Name: notifications; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4590 (class 3256 OID 23256)
-- Name: notifications notifications_admin; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY notifications_admin ON public.notifications TO authenticated USING ((public.effective_user_type() = 'admin'::text));


--
-- TOC entry 4585 (class 3256 OID 23251)
-- Name: notifications notifications_parent_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY notifications_parent_select ON public.notifications FOR SELECT TO authenticated USING (((public.effective_user_type() = 'parent'::text) AND (recipient_parent_id = public.effective_app_user_id())));


--
-- TOC entry 4586 (class 3256 OID 23252)
-- Name: notifications notifications_parent_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY notifications_parent_update ON public.notifications FOR UPDATE TO authenticated USING (((public.effective_user_type() = 'parent'::text) AND (recipient_parent_id = public.effective_app_user_id()))) WITH CHECK (((public.effective_user_type() = 'parent'::text) AND (recipient_parent_id = public.effective_app_user_id())));


--
-- TOC entry 4589 (class 3256 OID 23255)
-- Name: notifications notifications_student_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY notifications_student_select ON public.notifications FOR SELECT TO authenticated USING (((public.effective_user_type() = 'student'::text) AND (recipient_student_id = public.effective_app_user_id())));


--
-- TOC entry 4587 (class 3256 OID 23253)
-- Name: notifications notifications_teacher_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY notifications_teacher_select ON public.notifications FOR SELECT TO authenticated USING (((public.effective_user_type() = 'teacher'::text) AND (recipient_teacher_id = public.effective_app_user_id())));


--
-- TOC entry 4588 (class 3256 OID 23254)
-- Name: notifications notifications_teacher_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY notifications_teacher_update ON public.notifications FOR UPDATE TO authenticated USING (((public.effective_user_type() = 'teacher'::text) AND (recipient_teacher_id = public.effective_app_user_id()))) WITH CHECK (((public.effective_user_type() = 'teacher'::text) AND (recipient_teacher_id = public.effective_app_user_id())));


--
-- TOC entry 4496 (class 0 OID 17734)
-- Dependencies: 351
-- Name: parent_students; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.parent_students ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4486 (class 0 OID 17622)
-- Dependencies: 341
-- Name: parents; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.parents ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4487 (class 0 OID 17630)
-- Dependencies: 342
-- Name: pending_content; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.pending_content ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4506 (class 0 OID 18622)
-- Dependencies: 403
-- Name: practice_quiz_answers; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.practice_quiz_answers ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4505 (class 0 OID 18589)
-- Dependencies: 401
-- Name: practice_quiz_attempts; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.practice_quiz_attempts ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4488 (class 0 OID 17640)
-- Dependencies: 343
-- Name: questions; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4489 (class 0 OID 17658)
-- Dependencies: 344
-- Name: reports; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4504 (class 0 OID 17864)
-- Dependencies: 382
-- Name: school_settings; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.school_settings ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4490 (class 0 OID 17667)
-- Dependencies: 345
-- Name: section_subjects; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.section_subjects ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4491 (class 0 OID 17676)
-- Dependencies: 346
-- Name: sections; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.sections ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4492 (class 0 OID 17683)
-- Dependencies: 347
-- Name: semesters; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.semesters ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4507 (class 0 OID 18643)
-- Dependencies: 405
-- Name: student_summaries; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.student_summaries ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4493 (class 0 OID 17691)
-- Dependencies: 348
-- Name: students; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4494 (class 0 OID 17701)
-- Dependencies: 349
-- Name: subjects; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4495 (class 0 OID 17711)
-- Dependencies: 350
-- Name: teachers; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.teachers ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4668 (class 0 OID 0)
-- Dependencies: 30
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;
GRANT USAGE ON SCHEMA public TO supabase_auth_admin;


--
-- TOC entry 4671 (class 0 OID 0)
-- Dependencies: 520
-- Name: FUNCTION app_current_user_id(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.app_current_user_id() TO anon;
GRANT ALL ON FUNCTION public.app_current_user_id() TO authenticated;
GRANT ALL ON FUNCTION public.app_current_user_id() TO service_role;


--
-- TOC entry 4672 (class 0 OID 0)
-- Dependencies: 610
-- Name: FUNCTION create_student_summary(p_subject_id integer, p_chapter_id integer, p_title character varying, p_content text, p_summary_type character varying); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.create_student_summary(p_subject_id integer, p_chapter_id integer, p_title character varying, p_content text, p_summary_type character varying) TO anon;
GRANT ALL ON FUNCTION public.create_student_summary(p_subject_id integer, p_chapter_id integer, p_title character varying, p_content text, p_summary_type character varying) TO authenticated;
GRANT ALL ON FUNCTION public.create_student_summary(p_subject_id integer, p_chapter_id integer, p_title character varying, p_content text, p_summary_type character varying) TO service_role;


--
-- TOC entry 4674 (class 0 OID 0)
-- Dependencies: 521
-- Name: FUNCTION custom_access_token_claims(event jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.custom_access_token_claims(event jsonb) TO anon;
GRANT ALL ON FUNCTION public.custom_access_token_claims(event jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.custom_access_token_claims(event jsonb) TO service_role;
GRANT ALL ON FUNCTION public.custom_access_token_claims(event jsonb) TO supabase_auth_admin;


--
-- TOC entry 4675 (class 0 OID 0)
-- Dependencies: 522
-- Name: FUNCTION deactivate_section_subject_with_context(p_user_id integer, p_user_type text, p_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.deactivate_section_subject_with_context(p_user_id integer, p_user_type text, p_id integer) TO anon;
GRANT ALL ON FUNCTION public.deactivate_section_subject_with_context(p_user_id integer, p_user_type text, p_id integer) TO authenticated;
GRANT ALL ON FUNCTION public.deactivate_section_subject_with_context(p_user_id integer, p_user_type text, p_id integer) TO service_role;


--
-- TOC entry 4676 (class 0 OID 0)
-- Dependencies: 523
-- Name: FUNCTION delete_parent_student_link_with_context(p_user_id integer, p_user_type text, p_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.delete_parent_student_link_with_context(p_user_id integer, p_user_type text, p_id integer) TO anon;
GRANT ALL ON FUNCTION public.delete_parent_student_link_with_context(p_user_id integer, p_user_type text, p_id integer) TO authenticated;
GRANT ALL ON FUNCTION public.delete_parent_student_link_with_context(p_user_id integer, p_user_type text, p_id integer) TO service_role;


--
-- TOC entry 4677 (class 0 OID 0)
-- Dependencies: 611
-- Name: FUNCTION delete_student_summary(p_summary_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.delete_student_summary(p_summary_id integer) TO anon;
GRANT ALL ON FUNCTION public.delete_student_summary(p_summary_id integer) TO authenticated;
GRANT ALL ON FUNCTION public.delete_student_summary(p_summary_id integer) TO service_role;


--
-- TOC entry 4678 (class 0 OID 0)
-- Dependencies: 524
-- Name: FUNCTION effective_app_user_id(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.effective_app_user_id() TO anon;
GRANT ALL ON FUNCTION public.effective_app_user_id() TO authenticated;
GRANT ALL ON FUNCTION public.effective_app_user_id() TO service_role;


--
-- TOC entry 4679 (class 0 OID 0)
-- Dependencies: 525
-- Name: FUNCTION effective_user_type(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.effective_user_type() TO anon;
GRANT ALL ON FUNCTION public.effective_user_type() TO authenticated;
GRANT ALL ON FUNCTION public.effective_user_type() TO service_role;


--
-- TOC entry 4680 (class 0 OID 0)
-- Dependencies: 526
-- Name: FUNCTION fn_calculate_exam_total_marks(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_calculate_exam_total_marks() TO anon;
GRANT ALL ON FUNCTION public.fn_calculate_exam_total_marks() TO authenticated;
GRANT ALL ON FUNCTION public.fn_calculate_exam_total_marks() TO service_role;


--
-- TOC entry 4681 (class 0 OID 0)
-- Dependencies: 527
-- Name: FUNCTION fn_check_teacher_subject_access(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_check_teacher_subject_access() TO anon;
GRANT ALL ON FUNCTION public.fn_check_teacher_subject_access() TO authenticated;
GRANT ALL ON FUNCTION public.fn_check_teacher_subject_access() TO service_role;


--
-- TOC entry 4682 (class 0 OID 0)
-- Dependencies: 528
-- Name: FUNCTION fn_generate_student_code(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_generate_student_code() TO anon;
GRANT ALL ON FUNCTION public.fn_generate_student_code() TO authenticated;
GRANT ALL ON FUNCTION public.fn_generate_student_code() TO service_role;


--
-- TOC entry 4683 (class 0 OID 0)
-- Dependencies: 529
-- Name: FUNCTION fn_generate_subject_code(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_generate_subject_code() TO anon;
GRANT ALL ON FUNCTION public.fn_generate_subject_code() TO authenticated;
GRANT ALL ON FUNCTION public.fn_generate_subject_code() TO service_role;


--
-- TOC entry 4684 (class 0 OID 0)
-- Dependencies: 530
-- Name: FUNCTION fn_generate_teacher_code(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_generate_teacher_code() TO anon;
GRANT ALL ON FUNCTION public.fn_generate_teacher_code() TO authenticated;
GRANT ALL ON FUNCTION public.fn_generate_teacher_code() TO service_role;


--
-- TOC entry 4685 (class 0 OID 0)
-- Dependencies: 531
-- Name: FUNCTION fn_log_user_login(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_log_user_login() TO anon;
GRANT ALL ON FUNCTION public.fn_log_user_login() TO authenticated;
GRANT ALL ON FUNCTION public.fn_log_user_login() TO service_role;


--
-- TOC entry 4686 (class 0 OID 0)
-- Dependencies: 532
-- Name: FUNCTION fn_notify_absence(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_notify_absence() TO anon;
GRANT ALL ON FUNCTION public.fn_notify_absence() TO authenticated;
GRANT ALL ON FUNCTION public.fn_notify_absence() TO service_role;


--
-- TOC entry 4687 (class 0 OID 0)
-- Dependencies: 533
-- Name: FUNCTION fn_notify_content_review(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_notify_content_review() TO anon;
GRANT ALL ON FUNCTION public.fn_notify_content_review() TO authenticated;
GRANT ALL ON FUNCTION public.fn_notify_content_review() TO service_role;


--
-- TOC entry 4688 (class 0 OID 0)
-- Dependencies: 534
-- Name: FUNCTION fn_notify_exam_completed(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_notify_exam_completed() TO anon;
GRANT ALL ON FUNCTION public.fn_notify_exam_completed() TO authenticated;
GRANT ALL ON FUNCTION public.fn_notify_exam_completed() TO service_role;


--
-- TOC entry 4689 (class 0 OID 0)
-- Dependencies: 535
-- Name: FUNCTION fn_notify_exam_published(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_notify_exam_published() TO anon;
GRANT ALL ON FUNCTION public.fn_notify_exam_published() TO authenticated;
GRANT ALL ON FUNCTION public.fn_notify_exam_published() TO service_role;


--
-- TOC entry 4690 (class 0 OID 0)
-- Dependencies: 536
-- Name: FUNCTION fn_prevent_teacher_soft_delete(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_prevent_teacher_soft_delete() TO anon;
GRANT ALL ON FUNCTION public.fn_prevent_teacher_soft_delete() TO authenticated;
GRANT ALL ON FUNCTION public.fn_prevent_teacher_soft_delete() TO service_role;


--
-- TOC entry 4691 (class 0 OID 0)
-- Dependencies: 537
-- Name: FUNCTION fn_refresh_all_materialized_views(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_refresh_all_materialized_views() TO anon;
GRANT ALL ON FUNCTION public.fn_refresh_all_materialized_views() TO authenticated;
GRANT ALL ON FUNCTION public.fn_refresh_all_materialized_views() TO service_role;


--
-- TOC entry 4692 (class 0 OID 0)
-- Dependencies: 538
-- Name: FUNCTION fn_sync_student_name_cache(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_sync_student_name_cache() TO anon;
GRANT ALL ON FUNCTION public.fn_sync_student_name_cache() TO authenticated;
GRANT ALL ON FUNCTION public.fn_sync_student_name_cache() TO service_role;


--
-- TOC entry 4693 (class 0 OID 0)
-- Dependencies: 539
-- Name: FUNCTION fn_update_attendance_cache(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_update_attendance_cache() TO anon;
GRANT ALL ON FUNCTION public.fn_update_attendance_cache() TO authenticated;
GRANT ALL ON FUNCTION public.fn_update_attendance_cache() TO service_role;


--
-- TOC entry 4694 (class 0 OID 0)
-- Dependencies: 540
-- Name: FUNCTION fn_update_exam_result_cache(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_update_exam_result_cache() TO anon;
GRANT ALL ON FUNCTION public.fn_update_exam_result_cache() TO authenticated;
GRANT ALL ON FUNCTION public.fn_update_exam_result_cache() TO service_role;


--
-- TOC entry 4695 (class 0 OID 0)
-- Dependencies: 541
-- Name: FUNCTION fn_update_timestamp(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fn_update_timestamp() TO anon;
GRANT ALL ON FUNCTION public.fn_update_timestamp() TO authenticated;
GRANT ALL ON FUNCTION public.fn_update_timestamp() TO service_role;


--
-- TOC entry 4698 (class 0 OID 0)
-- Dependencies: 335
-- Name: TABLE admins; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.admins TO anon;
GRANT ALL ON TABLE public.admins TO authenticated;
GRANT ALL ON TABLE public.admins TO service_role;


--
-- TOC entry 4699 (class 0 OID 0)
-- Dependencies: 542
-- Name: FUNCTION get_admin_by_id_with_context(p_user_id integer, p_user_type text, p_admin_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_admin_by_id_with_context(p_user_id integer, p_user_type text, p_admin_id integer) TO anon;
GRANT ALL ON FUNCTION public.get_admin_by_id_with_context(p_user_id integer, p_user_type text, p_admin_id integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_admin_by_id_with_context(p_user_id integer, p_user_type text, p_admin_id integer) TO service_role;


--
-- TOC entry 4700 (class 0 OID 0)
-- Dependencies: 336
-- Name: TABLE attendance; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.attendance TO anon;
GRANT ALL ON TABLE public.attendance TO authenticated;
GRANT ALL ON TABLE public.attendance TO service_role;


--
-- TOC entry 4701 (class 0 OID 0)
-- Dependencies: 543
-- Name: FUNCTION get_attendance_by_date_with_context(p_user_id integer, p_user_type text, p_date date); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_attendance_by_date_with_context(p_user_id integer, p_user_type text, p_date date) TO anon;
GRANT ALL ON FUNCTION public.get_attendance_by_date_with_context(p_user_id integer, p_user_type text, p_date date) TO authenticated;
GRANT ALL ON FUNCTION public.get_attendance_by_date_with_context(p_user_id integer, p_user_type text, p_date date) TO service_role;


--
-- TOC entry 4702 (class 0 OID 0)
-- Dependencies: 544
-- Name: FUNCTION get_average_grades_by_subject_with_context(p_user_id integer, p_user_type text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_average_grades_by_subject_with_context(p_user_id integer, p_user_type text) TO anon;
GRANT ALL ON FUNCTION public.get_average_grades_by_subject_with_context(p_user_id integer, p_user_type text) TO authenticated;
GRANT ALL ON FUNCTION public.get_average_grades_by_subject_with_context(p_user_id integer, p_user_type text) TO service_role;


--
-- TOC entry 4703 (class 0 OID 0)
-- Dependencies: 608
-- Name: FUNCTION get_chapter_topics(p_chapter_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_chapter_topics(p_chapter_id integer) TO anon;
GRANT ALL ON FUNCTION public.get_chapter_topics(p_chapter_id integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_chapter_topics(p_chapter_id integer) TO service_role;


--
-- TOC entry 4705 (class 0 OID 0)
-- Dependencies: 360
-- Name: TABLE chapters; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.chapters TO anon;
GRANT ALL ON TABLE public.chapters TO authenticated;
GRANT ALL ON TABLE public.chapters TO service_role;


--
-- TOC entry 4706 (class 0 OID 0)
-- Dependencies: 614
-- Name: FUNCTION get_chapters_with_context(p_user_id integer, p_user_type text, p_subject_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_chapters_with_context(p_user_id integer, p_user_type text, p_subject_id integer) TO anon;
GRANT ALL ON FUNCTION public.get_chapters_with_context(p_user_id integer, p_user_type text, p_subject_id integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_chapters_with_context(p_user_id integer, p_user_type text, p_subject_id integer) TO service_role;


--
-- TOC entry 4707 (class 0 OID 0)
-- Dependencies: 601
-- Name: FUNCTION get_chapters_with_progress(p_subject_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_chapters_with_progress(p_subject_id integer) TO anon;
GRANT ALL ON FUNCTION public.get_chapters_with_progress(p_subject_id integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_chapters_with_progress(p_subject_id integer) TO service_role;


--
-- TOC entry 4708 (class 0 OID 0)
-- Dependencies: 599
-- Name: FUNCTION get_current_student_id(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_current_student_id() TO anon;
GRANT ALL ON FUNCTION public.get_current_student_id() TO authenticated;
GRANT ALL ON FUNCTION public.get_current_student_id() TO service_role;


--
-- TOC entry 4709 (class 0 OID 0)
-- Dependencies: 545
-- Name: FUNCTION get_dashboard_stats_with_context(p_user_id integer, p_user_type text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_dashboard_stats_with_context(p_user_id integer, p_user_type text) TO anon;
GRANT ALL ON FUNCTION public.get_dashboard_stats_with_context(p_user_id integer, p_user_type text) TO authenticated;
GRANT ALL ON FUNCTION public.get_dashboard_stats_with_context(p_user_id integer, p_user_type text) TO service_role;


--
-- TOC entry 4710 (class 0 OID 0)
-- Dependencies: 337
-- Name: TABLE exam_questions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.exam_questions TO anon;
GRANT ALL ON TABLE public.exam_questions TO authenticated;
GRANT ALL ON TABLE public.exam_questions TO service_role;


--
-- TOC entry 4711 (class 0 OID 0)
-- Dependencies: 546
-- Name: FUNCTION get_exam_questions_with_context(p_user_id integer, p_user_type text, p_exam_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_exam_questions_with_context(p_user_id integer, p_user_type text, p_exam_id integer) TO anon;
GRANT ALL ON FUNCTION public.get_exam_questions_with_context(p_user_id integer, p_user_type text, p_exam_id integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_exam_questions_with_context(p_user_id integer, p_user_type text, p_exam_id integer) TO service_role;


--
-- TOC entry 4714 (class 0 OID 0)
-- Dependencies: 338
-- Name: TABLE exams; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.exams TO anon;
GRANT ALL ON TABLE public.exams TO authenticated;
GRANT ALL ON TABLE public.exams TO service_role;


--
-- TOC entry 4715 (class 0 OID 0)
-- Dependencies: 547
-- Name: FUNCTION get_exams_with_context(p_user_id integer, p_user_type text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_exams_with_context(p_user_id integer, p_user_type text) TO anon;
GRANT ALL ON FUNCTION public.get_exams_with_context(p_user_id integer, p_user_type text) TO authenticated;
GRANT ALL ON FUNCTION public.get_exams_with_context(p_user_id integer, p_user_type text) TO service_role;


--
-- TOC entry 4716 (class 0 OID 0)
-- Dependencies: 339
-- Name: TABLE grades; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.grades TO anon;
GRANT ALL ON TABLE public.grades TO authenticated;
GRANT ALL ON TABLE public.grades TO service_role;


--
-- TOC entry 4717 (class 0 OID 0)
-- Dependencies: 548
-- Name: FUNCTION get_grades_with_context(p_user_id integer, p_user_type text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_grades_with_context(p_user_id integer, p_user_type text) TO anon;
GRANT ALL ON FUNCTION public.get_grades_with_context(p_user_id integer, p_user_type text) TO authenticated;
GRANT ALL ON FUNCTION public.get_grades_with_context(p_user_id integer, p_user_type text) TO service_role;


--
-- TOC entry 4718 (class 0 OID 0)
-- Dependencies: 340
-- Name: TABLE messages; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.messages TO anon;
GRANT ALL ON TABLE public.messages TO authenticated;
GRANT ALL ON TABLE public.messages TO service_role;


--
-- TOC entry 4719 (class 0 OID 0)
-- Dependencies: 549
-- Name: FUNCTION get_messages_for_admin_with_context(p_user_id integer, p_user_type text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_messages_for_admin_with_context(p_user_id integer, p_user_type text) TO anon;
GRANT ALL ON FUNCTION public.get_messages_for_admin_with_context(p_user_id integer, p_user_type text) TO authenticated;
GRANT ALL ON FUNCTION public.get_messages_for_admin_with_context(p_user_id integer, p_user_type text) TO service_role;


--
-- TOC entry 4720 (class 0 OID 0)
-- Dependencies: 550
-- Name: FUNCTION get_parent_students_with_context(p_user_id integer, p_user_type text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_parent_students_with_context(p_user_id integer, p_user_type text) TO anon;
GRANT ALL ON FUNCTION public.get_parent_students_with_context(p_user_id integer, p_user_type text) TO authenticated;
GRANT ALL ON FUNCTION public.get_parent_students_with_context(p_user_id integer, p_user_type text) TO service_role;


--
-- TOC entry 4721 (class 0 OID 0)
-- Dependencies: 341
-- Name: TABLE parents; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.parents TO anon;
GRANT ALL ON TABLE public.parents TO authenticated;
GRANT ALL ON TABLE public.parents TO service_role;


--
-- TOC entry 4722 (class 0 OID 0)
-- Dependencies: 551
-- Name: FUNCTION get_parents_by_student_with_context(p_user_id integer, p_user_type text, p_student_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_parents_by_student_with_context(p_user_id integer, p_user_type text, p_student_id integer) TO anon;
GRANT ALL ON FUNCTION public.get_parents_by_student_with_context(p_user_id integer, p_user_type text, p_student_id integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_parents_by_student_with_context(p_user_id integer, p_user_type text, p_student_id integer) TO service_role;


--
-- TOC entry 4723 (class 0 OID 0)
-- Dependencies: 552
-- Name: FUNCTION get_parents_with_context(p_user_id integer, p_user_type text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_parents_with_context(p_user_id integer, p_user_type text) TO anon;
GRANT ALL ON FUNCTION public.get_parents_with_context(p_user_id integer, p_user_type text) TO authenticated;
GRANT ALL ON FUNCTION public.get_parents_with_context(p_user_id integer, p_user_type text) TO service_role;


--
-- TOC entry 4724 (class 0 OID 0)
-- Dependencies: 342
-- Name: TABLE pending_content; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.pending_content TO anon;
GRANT ALL ON TABLE public.pending_content TO authenticated;
GRANT ALL ON TABLE public.pending_content TO service_role;


--
-- TOC entry 4725 (class 0 OID 0)
-- Dependencies: 553
-- Name: FUNCTION get_pending_exams_with_context(p_user_id integer, p_user_type text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_pending_exams_with_context(p_user_id integer, p_user_type text) TO anon;
GRANT ALL ON FUNCTION public.get_pending_exams_with_context(p_user_id integer, p_user_type text) TO authenticated;
GRANT ALL ON FUNCTION public.get_pending_exams_with_context(p_user_id integer, p_user_type text) TO service_role;


--
-- TOC entry 4726 (class 0 OID 0)
-- Dependencies: 554
-- Name: FUNCTION get_pending_questions_with_context(p_user_id integer, p_user_type text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_pending_questions_with_context(p_user_id integer, p_user_type text) TO anon;
GRANT ALL ON FUNCTION public.get_pending_questions_with_context(p_user_id integer, p_user_type text) TO authenticated;
GRANT ALL ON FUNCTION public.get_pending_questions_with_context(p_user_id integer, p_user_type text) TO service_role;


--
-- TOC entry 4727 (class 0 OID 0)
-- Dependencies: 612
-- Name: FUNCTION get_questions_for_explanation(p_chapter_id integer, p_subject_id integer, p_limit integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_questions_for_explanation(p_chapter_id integer, p_subject_id integer, p_limit integer) TO anon;
GRANT ALL ON FUNCTION public.get_questions_for_explanation(p_chapter_id integer, p_subject_id integer, p_limit integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_questions_for_explanation(p_chapter_id integer, p_subject_id integer, p_limit integer) TO service_role;


--
-- TOC entry 4731 (class 0 OID 0)
-- Dependencies: 343
-- Name: TABLE questions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.questions TO anon;
GRANT ALL ON TABLE public.questions TO authenticated;
GRANT ALL ON TABLE public.questions TO service_role;


--
-- TOC entry 4732 (class 0 OID 0)
-- Dependencies: 602
-- Name: FUNCTION get_questions_for_quiz(p_chapter_id integer, p_count integer, p_difficulty text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_questions_for_quiz(p_chapter_id integer, p_count integer, p_difficulty text) TO anon;
GRANT ALL ON FUNCTION public.get_questions_for_quiz(p_chapter_id integer, p_count integer, p_difficulty text) TO authenticated;
GRANT ALL ON FUNCTION public.get_questions_for_quiz(p_chapter_id integer, p_count integer, p_difficulty text) TO service_role;


--
-- TOC entry 4733 (class 0 OID 0)
-- Dependencies: 555
-- Name: FUNCTION get_questions_with_context(p_user_id integer, p_user_type text, p_type text, p_difficulty text, p_subject_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_questions_with_context(p_user_id integer, p_user_type text, p_type text, p_difficulty text, p_subject_id integer) TO anon;
GRANT ALL ON FUNCTION public.get_questions_with_context(p_user_id integer, p_user_type text, p_type text, p_difficulty text, p_subject_id integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_questions_with_context(p_user_id integer, p_user_type text, p_type text, p_difficulty text, p_subject_id integer) TO service_role;


--
-- TOC entry 4734 (class 0 OID 0)
-- Dependencies: 556
-- Name: FUNCTION get_reports_grades_with_context(p_user_id integer, p_user_type text, p_grade_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_reports_grades_with_context(p_user_id integer, p_user_type text, p_grade_id integer) TO anon;
GRANT ALL ON FUNCTION public.get_reports_grades_with_context(p_user_id integer, p_user_type text, p_grade_id integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_reports_grades_with_context(p_user_id integer, p_user_type text, p_grade_id integer) TO service_role;


--
-- TOC entry 4735 (class 0 OID 0)
-- Dependencies: 344
-- Name: TABLE reports; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.reports TO anon;
GRANT ALL ON TABLE public.reports TO authenticated;
GRANT ALL ON TABLE public.reports TO service_role;


--
-- TOC entry 4736 (class 0 OID 0)
-- Dependencies: 557
-- Name: FUNCTION get_reports_with_context(p_user_id integer, p_user_type text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_reports_with_context(p_user_id integer, p_user_type text) TO anon;
GRANT ALL ON FUNCTION public.get_reports_with_context(p_user_id integer, p_user_type text) TO authenticated;
GRANT ALL ON FUNCTION public.get_reports_with_context(p_user_id integer, p_user_type text) TO service_role;


--
-- TOC entry 4737 (class 0 OID 0)
-- Dependencies: 558
-- Name: FUNCTION get_reports_with_names_and_context(p_user_id integer, p_user_type text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_reports_with_names_and_context(p_user_id integer, p_user_type text) TO anon;
GRANT ALL ON FUNCTION public.get_reports_with_names_and_context(p_user_id integer, p_user_type text) TO authenticated;
GRANT ALL ON FUNCTION public.get_reports_with_names_and_context(p_user_id integer, p_user_type text) TO service_role;


--
-- TOC entry 4738 (class 0 OID 0)
-- Dependencies: 345
-- Name: TABLE section_subjects; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.section_subjects TO anon;
GRANT ALL ON TABLE public.section_subjects TO authenticated;
GRANT ALL ON TABLE public.section_subjects TO service_role;


--
-- TOC entry 4739 (class 0 OID 0)
-- Dependencies: 559
-- Name: FUNCTION get_section_subjects_by_grade_with_context(p_user_id integer, p_user_type text, p_grade_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_section_subjects_by_grade_with_context(p_user_id integer, p_user_type text, p_grade_id integer) TO anon;
GRANT ALL ON FUNCTION public.get_section_subjects_by_grade_with_context(p_user_id integer, p_user_type text, p_grade_id integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_section_subjects_by_grade_with_context(p_user_id integer, p_user_type text, p_grade_id integer) TO service_role;


--
-- TOC entry 4740 (class 0 OID 0)
-- Dependencies: 560
-- Name: FUNCTION get_section_subjects_by_teacher_with_context(p_user_id integer, p_user_type text, p_teacher_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_section_subjects_by_teacher_with_context(p_user_id integer, p_user_type text, p_teacher_id integer) TO anon;
GRANT ALL ON FUNCTION public.get_section_subjects_by_teacher_with_context(p_user_id integer, p_user_type text, p_teacher_id integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_section_subjects_by_teacher_with_context(p_user_id integer, p_user_type text, p_teacher_id integer) TO service_role;


--
-- TOC entry 4741 (class 0 OID 0)
-- Dependencies: 561
-- Name: FUNCTION get_section_subjects_with_names_by_grade_with_context(p_user_id integer, p_user_type text, p_grade_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_section_subjects_with_names_by_grade_with_context(p_user_id integer, p_user_type text, p_grade_id integer) TO anon;
GRANT ALL ON FUNCTION public.get_section_subjects_with_names_by_grade_with_context(p_user_id integer, p_user_type text, p_grade_id integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_section_subjects_with_names_by_grade_with_context(p_user_id integer, p_user_type text, p_grade_id integer) TO service_role;


--
-- TOC entry 4742 (class 0 OID 0)
-- Dependencies: 346
-- Name: TABLE sections; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.sections TO anon;
GRANT ALL ON TABLE public.sections TO authenticated;
GRANT ALL ON TABLE public.sections TO service_role;


--
-- TOC entry 4743 (class 0 OID 0)
-- Dependencies: 562
-- Name: FUNCTION get_sections_with_context(p_user_id integer, p_user_type text, p_grade_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_sections_with_context(p_user_id integer, p_user_type text, p_grade_id integer) TO anon;
GRANT ALL ON FUNCTION public.get_sections_with_context(p_user_id integer, p_user_type text, p_grade_id integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_sections_with_context(p_user_id integer, p_user_type text, p_grade_id integer) TO service_role;


--
-- TOC entry 4744 (class 0 OID 0)
-- Dependencies: 347
-- Name: TABLE semesters; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.semesters TO anon;
GRANT ALL ON TABLE public.semesters TO authenticated;
GRANT ALL ON TABLE public.semesters TO service_role;


--
-- TOC entry 4745 (class 0 OID 0)
-- Dependencies: 563
-- Name: FUNCTION get_semesters_with_context(p_user_id integer, p_user_type text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_semesters_with_context(p_user_id integer, p_user_type text) TO anon;
GRANT ALL ON FUNCTION public.get_semesters_with_context(p_user_id integer, p_user_type text) TO authenticated;
GRANT ALL ON FUNCTION public.get_semesters_with_context(p_user_id integer, p_user_type text) TO service_role;


--
-- TOC entry 4746 (class 0 OID 0)
-- Dependencies: 605
-- Name: FUNCTION get_student_analytics(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_student_analytics() TO anon;
GRANT ALL ON FUNCTION public.get_student_analytics() TO authenticated;
GRANT ALL ON FUNCTION public.get_student_analytics() TO service_role;


--
-- TOC entry 4747 (class 0 OID 0)
-- Dependencies: 564
-- Name: FUNCTION get_student_count_by_section_with_context(p_user_id integer, p_user_type text, p_section_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_student_count_by_section_with_context(p_user_id integer, p_user_type text, p_section_id integer) TO anon;
GRANT ALL ON FUNCTION public.get_student_count_by_section_with_context(p_user_id integer, p_user_type text, p_section_id integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_student_count_by_section_with_context(p_user_id integer, p_user_type text, p_section_id integer) TO service_role;


--
-- TOC entry 4748 (class 0 OID 0)
-- Dependencies: 565
-- Name: FUNCTION get_student_details_with_context(p_user_id integer, p_user_type text, p_student_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_student_details_with_context(p_user_id integer, p_user_type text, p_student_id integer) TO anon;
GRANT ALL ON FUNCTION public.get_student_details_with_context(p_user_id integer, p_user_type text, p_student_id integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_student_details_with_context(p_user_id integer, p_user_type text, p_student_id integer) TO service_role;


--
-- TOC entry 4749 (class 0 OID 0)
-- Dependencies: 606
-- Name: FUNCTION get_student_profile(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_student_profile() TO anon;
GRANT ALL ON FUNCTION public.get_student_profile() TO authenticated;
GRANT ALL ON FUNCTION public.get_student_profile() TO service_role;


--
-- TOC entry 4750 (class 0 OID 0)
-- Dependencies: 604
-- Name: FUNCTION get_student_quiz_history(p_limit integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_student_quiz_history(p_limit integer) TO anon;
GRANT ALL ON FUNCTION public.get_student_quiz_history(p_limit integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_student_quiz_history(p_limit integer) TO service_role;


--
-- TOC entry 4751 (class 0 OID 0)
-- Dependencies: 609
-- Name: FUNCTION get_student_summaries(p_limit integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_student_summaries(p_limit integer) TO anon;
GRANT ALL ON FUNCTION public.get_student_summaries(p_limit integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_student_summaries(p_limit integer) TO service_role;


--
-- TOC entry 4754 (class 0 OID 0)
-- Dependencies: 348
-- Name: TABLE students; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.students TO anon;
GRANT ALL ON TABLE public.students TO authenticated;
GRANT ALL ON TABLE public.students TO service_role;


--
-- TOC entry 4755 (class 0 OID 0)
-- Dependencies: 566
-- Name: FUNCTION get_students_with_context(p_user_id integer, p_user_type text, p_search text, p_grade_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_students_with_context(p_user_id integer, p_user_type text, p_search text, p_grade_id integer) TO anon;
GRANT ALL ON FUNCTION public.get_students_with_context(p_user_id integer, p_user_type text, p_search text, p_grade_id integer) TO authenticated;
GRANT ALL ON FUNCTION public.get_students_with_context(p_user_id integer, p_user_type text, p_search text, p_grade_id integer) TO service_role;


--
-- TOC entry 4760 (class 0 OID 0)
-- Dependencies: 349
-- Name: TABLE subjects; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.subjects TO anon;
GRANT ALL ON TABLE public.subjects TO authenticated;
GRANT ALL ON TABLE public.subjects TO service_role;


--
-- TOC entry 4761 (class 0 OID 0)
-- Dependencies: 600
-- Name: FUNCTION get_subjects_for_student(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_subjects_for_student() TO anon;
GRANT ALL ON FUNCTION public.get_subjects_for_student() TO authenticated;
GRANT ALL ON FUNCTION public.get_subjects_for_student() TO service_role;


--
-- TOC entry 4762 (class 0 OID 0)
-- Dependencies: 567
-- Name: FUNCTION get_subjects_with_context(p_user_id integer, p_user_type text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_subjects_with_context(p_user_id integer, p_user_type text) TO anon;
GRANT ALL ON FUNCTION public.get_subjects_with_context(p_user_id integer, p_user_type text) TO authenticated;
GRANT ALL ON FUNCTION public.get_subjects_with_context(p_user_id integer, p_user_type text) TO service_role;


--
-- TOC entry 4763 (class 0 OID 0)
-- Dependencies: 607
-- Name: FUNCTION get_subjects_with_stats(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_subjects_with_stats() TO anon;
GRANT ALL ON FUNCTION public.get_subjects_with_stats() TO authenticated;
GRANT ALL ON FUNCTION public.get_subjects_with_stats() TO service_role;


--
-- TOC entry 4766 (class 0 OID 0)
-- Dependencies: 350
-- Name: TABLE teachers; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.teachers TO anon;
GRANT ALL ON TABLE public.teachers TO authenticated;
GRANT ALL ON TABLE public.teachers TO service_role;


--
-- TOC entry 4767 (class 0 OID 0)
-- Dependencies: 568
-- Name: FUNCTION get_teachers_with_context(p_user_id integer, p_user_type text, p_search text, p_sort_by text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_teachers_with_context(p_user_id integer, p_user_type text, p_search text, p_sort_by text) TO anon;
GRANT ALL ON FUNCTION public.get_teachers_with_context(p_user_id integer, p_user_type text, p_search text, p_sort_by text) TO authenticated;
GRANT ALL ON FUNCTION public.get_teachers_with_context(p_user_id integer, p_user_type text, p_search text, p_sort_by text) TO service_role;


--
-- TOC entry 4768 (class 0 OID 0)
-- Dependencies: 569
-- Name: FUNCTION get_weekly_activity_with_context(p_user_id integer, p_user_type text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_weekly_activity_with_context(p_user_id integer, p_user_type text) TO anon;
GRANT ALL ON FUNCTION public.get_weekly_activity_with_context(p_user_id integer, p_user_type text) TO authenticated;
GRANT ALL ON FUNCTION public.get_weekly_activity_with_context(p_user_id integer, p_user_type text) TO service_role;


--
-- TOC entry 4769 (class 0 OID 0)
-- Dependencies: 570
-- Name: FUNCTION hash_password(p_password text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.hash_password(p_password text) TO anon;
GRANT ALL ON FUNCTION public.hash_password(p_password text) TO authenticated;
GRANT ALL ON FUNCTION public.hash_password(p_password text) TO service_role;


--
-- TOC entry 4770 (class 0 OID 0)
-- Dependencies: 615
-- Name: FUNCTION insert_chapter_with_context(p_user_id integer, p_user_type text, p_payload jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.insert_chapter_with_context(p_user_id integer, p_user_type text, p_payload jsonb) TO anon;
GRANT ALL ON FUNCTION public.insert_chapter_with_context(p_user_id integer, p_user_type text, p_payload jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.insert_chapter_with_context(p_user_id integer, p_user_type text, p_payload jsonb) TO service_role;


--
-- TOC entry 4771 (class 0 OID 0)
-- Dependencies: 571
-- Name: FUNCTION insert_exam_with_context(p_user_id integer, p_user_type text, p_payload jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.insert_exam_with_context(p_user_id integer, p_user_type text, p_payload jsonb) TO anon;
GRANT ALL ON FUNCTION public.insert_exam_with_context(p_user_id integer, p_user_type text, p_payload jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.insert_exam_with_context(p_user_id integer, p_user_type text, p_payload jsonb) TO service_role;


--
-- TOC entry 4772 (class 0 OID 0)
-- Dependencies: 572
-- Name: FUNCTION insert_question_with_context(p_user_id integer, p_user_type text, p_payload jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.insert_question_with_context(p_user_id integer, p_user_type text, p_payload jsonb) TO anon;
GRANT ALL ON FUNCTION public.insert_question_with_context(p_user_id integer, p_user_type text, p_payload jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.insert_question_with_context(p_user_id integer, p_user_type text, p_payload jsonb) TO service_role;


--
-- TOC entry 4773 (class 0 OID 0)
-- Dependencies: 573
-- Name: FUNCTION insert_section_subject_with_context(p_user_id integer, p_user_type text, p_section_id integer, p_subject_id integer, p_teacher_id integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.insert_section_subject_with_context(p_user_id integer, p_user_type text, p_section_id integer, p_subject_id integer, p_teacher_id integer) TO anon;
GRANT ALL ON FUNCTION public.insert_section_subject_with_context(p_user_id integer, p_user_type text, p_section_id integer, p_subject_id integer, p_teacher_id integer) TO authenticated;
GRANT ALL ON FUNCTION public.insert_section_subject_with_context(p_user_id integer, p_user_type text, p_section_id integer, p_subject_id integer, p_teacher_id integer) TO service_role;


--
-- TOC entry 4774 (class 0 OID 0)
-- Dependencies: 574
-- Name: FUNCTION insert_section_with_context(p_user_id integer, p_user_type text, p_payload jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.insert_section_with_context(p_user_id integer, p_user_type text, p_payload jsonb) TO anon;
GRANT ALL ON FUNCTION public.insert_section_with_context(p_user_id integer, p_user_type text, p_payload jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.insert_section_with_context(p_user_id integer, p_user_type text, p_payload jsonb) TO service_role;


--
-- TOC entry 4775 (class 0 OID 0)
-- Dependencies: 575
-- Name: FUNCTION insert_student_with_context(p_user_id integer, p_user_type text, p_payload jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.insert_student_with_context(p_user_id integer, p_user_type text, p_payload jsonb) TO anon;
GRANT ALL ON FUNCTION public.insert_student_with_context(p_user_id integer, p_user_type text, p_payload jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.insert_student_with_context(p_user_id integer, p_user_type text, p_payload jsonb) TO service_role;


--
-- TOC entry 4776 (class 0 OID 0)
-- Dependencies: 576
-- Name: FUNCTION insert_subject_with_context(p_user_id integer, p_user_type text, p_payload jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.insert_subject_with_context(p_user_id integer, p_user_type text, p_payload jsonb) TO anon;
GRANT ALL ON FUNCTION public.insert_subject_with_context(p_user_id integer, p_user_type text, p_payload jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.insert_subject_with_context(p_user_id integer, p_user_type text, p_payload jsonb) TO service_role;


--
-- TOC entry 4777 (class 0 OID 0)
-- Dependencies: 577
-- Name: FUNCTION insert_teacher_with_context(p_user_id integer, p_user_type text, p_payload jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.insert_teacher_with_context(p_user_id integer, p_user_type text, p_payload jsonb) TO anon;
GRANT ALL ON FUNCTION public.insert_teacher_with_context(p_user_id integer, p_user_type text, p_payload jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.insert_teacher_with_context(p_user_id integer, p_user_type text, p_payload jsonb) TO service_role;


--
-- TOC entry 4778 (class 0 OID 0)
-- Dependencies: 578
-- Name: FUNCTION is_admin(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.is_admin() TO anon;
GRANT ALL ON FUNCTION public.is_admin() TO authenticated;
GRANT ALL ON FUNCTION public.is_admin() TO service_role;


--
-- TOC entry 4779 (class 0 OID 0)
-- Dependencies: 579
-- Name: FUNCTION is_parent(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.is_parent() TO anon;
GRANT ALL ON FUNCTION public.is_parent() TO authenticated;
GRANT ALL ON FUNCTION public.is_parent() TO service_role;


--
-- TOC entry 4780 (class 0 OID 0)
-- Dependencies: 580
-- Name: FUNCTION is_student(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.is_student() TO anon;
GRANT ALL ON FUNCTION public.is_student() TO authenticated;
GRANT ALL ON FUNCTION public.is_student() TO service_role;


--
-- TOC entry 4781 (class 0 OID 0)
-- Dependencies: 581
-- Name: FUNCTION is_teacher(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.is_teacher() TO anon;
GRANT ALL ON FUNCTION public.is_teacher() TO authenticated;
GRANT ALL ON FUNCTION public.is_teacher() TO service_role;


--
-- TOC entry 4782 (class 0 OID 0)
-- Dependencies: 351
-- Name: TABLE parent_students; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.parent_students TO anon;
GRANT ALL ON TABLE public.parent_students TO authenticated;
GRANT ALL ON TABLE public.parent_students TO service_role;


--
-- TOC entry 4783 (class 0 OID 0)
-- Dependencies: 582
-- Name: FUNCTION link_parent_student_with_context(p_user_id integer, p_user_type text, p_parent_id integer, p_student_id integer, p_relationship text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.link_parent_student_with_context(p_user_id integer, p_user_type text, p_parent_id integer, p_student_id integer, p_relationship text) TO anon;
GRANT ALL ON FUNCTION public.link_parent_student_with_context(p_user_id integer, p_user_type text, p_parent_id integer, p_student_id integer, p_relationship text) TO authenticated;
GRANT ALL ON FUNCTION public.link_parent_student_with_context(p_user_id integer, p_user_type text, p_parent_id integer, p_student_id integer, p_relationship text) TO service_role;


--
-- TOC entry 4784 (class 0 OID 0)
-- Dependencies: 583
-- Name: FUNCTION login_admin(p_school_code text, p_password text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.login_admin(p_school_code text, p_password text) TO anon;
GRANT ALL ON FUNCTION public.login_admin(p_school_code text, p_password text) TO authenticated;
GRANT ALL ON FUNCTION public.login_admin(p_school_code text, p_password text) TO service_role;


--
-- TOC entry 4785 (class 0 OID 0)
-- Dependencies: 613
-- Name: FUNCTION normalize_correct_answer(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.normalize_correct_answer() TO anon;
GRANT ALL ON FUNCTION public.normalize_correct_answer() TO authenticated;
GRANT ALL ON FUNCTION public.normalize_correct_answer() TO service_role;


--
-- TOC entry 4786 (class 0 OID 0)
-- Dependencies: 617
-- Name: FUNCTION normalize_question_format(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.normalize_question_format() TO anon;
GRANT ALL ON FUNCTION public.normalize_question_format() TO authenticated;
GRANT ALL ON FUNCTION public.normalize_question_format() TO service_role;


--
-- TOC entry 4787 (class 0 OID 0)
-- Dependencies: 603
-- Name: FUNCTION save_practice_quiz_attempt(p_subject_id integer, p_chapter_id integer, p_score integer, p_total_questions integer, p_correct_answers integer, p_wrong_answers integer, p_unanswered integer, p_time_taken_seconds integer, p_quiz_options jsonb, p_answers jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.save_practice_quiz_attempt(p_subject_id integer, p_chapter_id integer, p_score integer, p_total_questions integer, p_correct_answers integer, p_wrong_answers integer, p_unanswered integer, p_time_taken_seconds integer, p_quiz_options jsonb, p_answers jsonb) TO anon;
GRANT ALL ON FUNCTION public.save_practice_quiz_attempt(p_subject_id integer, p_chapter_id integer, p_score integer, p_total_questions integer, p_correct_answers integer, p_wrong_answers integer, p_unanswered integer, p_time_taken_seconds integer, p_quiz_options jsonb, p_answers jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.save_practice_quiz_attempt(p_subject_id integer, p_chapter_id integer, p_score integer, p_total_questions integer, p_correct_answers integer, p_wrong_answers integer, p_unanswered integer, p_time_taken_seconds integer, p_quiz_options jsonb, p_answers jsonb) TO service_role;


--
-- TOC entry 4788 (class 0 OID 0)
-- Dependencies: 584
-- Name: FUNCTION send_message_with_context(p_user_id integer, p_user_type text, p_sender_admin_id integer, p_sender_parent_id integer, p_recipient_admin_id integer, p_recipient_parent_id integer, p_subject text, p_message_text text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.send_message_with_context(p_user_id integer, p_user_type text, p_sender_admin_id integer, p_sender_parent_id integer, p_recipient_admin_id integer, p_recipient_parent_id integer, p_subject text, p_message_text text) TO anon;
GRANT ALL ON FUNCTION public.send_message_with_context(p_user_id integer, p_user_type text, p_sender_admin_id integer, p_sender_parent_id integer, p_recipient_admin_id integer, p_recipient_parent_id integer, p_subject text, p_message_text text) TO authenticated;
GRANT ALL ON FUNCTION public.send_message_with_context(p_user_id integer, p_user_type text, p_sender_admin_id integer, p_sender_parent_id integer, p_recipient_admin_id integer, p_recipient_parent_id integer, p_subject text, p_message_text text) TO service_role;


--
-- TOC entry 4789 (class 0 OID 0)
-- Dependencies: 585
-- Name: FUNCTION send_report_with_context(p_user_id integer, p_user_type text, p_student_id integer, p_parent_id integer, p_title text, p_report_text text, p_sent_by integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.send_report_with_context(p_user_id integer, p_user_type text, p_student_id integer, p_parent_id integer, p_title text, p_report_text text, p_sent_by integer) TO anon;
GRANT ALL ON FUNCTION public.send_report_with_context(p_user_id integer, p_user_type text, p_student_id integer, p_parent_id integer, p_title text, p_report_text text, p_sent_by integer) TO authenticated;
GRANT ALL ON FUNCTION public.send_report_with_context(p_user_id integer, p_user_type text, p_student_id integer, p_parent_id integer, p_title text, p_report_text text, p_sent_by integer) TO service_role;


--
-- TOC entry 4790 (class 0 OID 0)
-- Dependencies: 586
-- Name: FUNCTION set_user_context(p_user_id integer, p_user_type text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.set_user_context(p_user_id integer, p_user_type text) TO anon;
GRANT ALL ON FUNCTION public.set_user_context(p_user_id integer, p_user_type text) TO authenticated;
GRANT ALL ON FUNCTION public.set_user_context(p_user_id integer, p_user_type text) TO service_role;


--
-- TOC entry 4791 (class 0 OID 0)
-- Dependencies: 587
-- Name: FUNCTION storage_is_admin(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.storage_is_admin() TO anon;
GRANT ALL ON FUNCTION public.storage_is_admin() TO authenticated;
GRANT ALL ON FUNCTION public.storage_is_admin() TO service_role;


--
-- TOC entry 4792 (class 0 OID 0)
-- Dependencies: 588
-- Name: FUNCTION storage_is_parent(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.storage_is_parent() TO anon;
GRANT ALL ON FUNCTION public.storage_is_parent() TO authenticated;
GRANT ALL ON FUNCTION public.storage_is_parent() TO service_role;


--
-- TOC entry 4793 (class 0 OID 0)
-- Dependencies: 589
-- Name: FUNCTION storage_is_student(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.storage_is_student() TO anon;
GRANT ALL ON FUNCTION public.storage_is_student() TO authenticated;
GRANT ALL ON FUNCTION public.storage_is_student() TO service_role;


--
-- TOC entry 4794 (class 0 OID 0)
-- Dependencies: 590
-- Name: FUNCTION storage_is_teacher(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.storage_is_teacher() TO anon;
GRANT ALL ON FUNCTION public.storage_is_teacher() TO authenticated;
GRANT ALL ON FUNCTION public.storage_is_teacher() TO service_role;


--
-- TOC entry 4795 (class 0 OID 0)
-- Dependencies: 591
-- Name: FUNCTION update_admin_profile_image_with_context(p_user_id integer, p_user_type text, p_admin_id integer, p_profile_image_url text, p_profile_image_storage_path text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_admin_profile_image_with_context(p_user_id integer, p_user_type text, p_admin_id integer, p_profile_image_url text, p_profile_image_storage_path text) TO anon;
GRANT ALL ON FUNCTION public.update_admin_profile_image_with_context(p_user_id integer, p_user_type text, p_admin_id integer, p_profile_image_url text, p_profile_image_storage_path text) TO authenticated;
GRANT ALL ON FUNCTION public.update_admin_profile_image_with_context(p_user_id integer, p_user_type text, p_admin_id integer, p_profile_image_url text, p_profile_image_storage_path text) TO service_role;


--
-- TOC entry 4796 (class 0 OID 0)
-- Dependencies: 616
-- Name: FUNCTION update_chapter_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_chapter_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) TO anon;
GRANT ALL ON FUNCTION public.update_chapter_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.update_chapter_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) TO service_role;


--
-- TOC entry 4797 (class 0 OID 0)
-- Dependencies: 592
-- Name: FUNCTION update_exam_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_exam_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) TO anon;
GRANT ALL ON FUNCTION public.update_exam_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.update_exam_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) TO service_role;


--
-- TOC entry 4798 (class 0 OID 0)
-- Dependencies: 593
-- Name: FUNCTION update_question_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_question_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) TO anon;
GRANT ALL ON FUNCTION public.update_question_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.update_question_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) TO service_role;


--
-- TOC entry 4799 (class 0 OID 0)
-- Dependencies: 594
-- Name: FUNCTION update_section_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_section_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) TO anon;
GRANT ALL ON FUNCTION public.update_section_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.update_section_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) TO service_role;


--
-- TOC entry 4800 (class 0 OID 0)
-- Dependencies: 595
-- Name: FUNCTION update_student_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_student_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) TO anon;
GRANT ALL ON FUNCTION public.update_student_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.update_student_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) TO service_role;


--
-- TOC entry 4801 (class 0 OID 0)
-- Dependencies: 596
-- Name: FUNCTION update_subject_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_subject_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) TO anon;
GRANT ALL ON FUNCTION public.update_subject_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.update_subject_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) TO service_role;


--
-- TOC entry 4802 (class 0 OID 0)
-- Dependencies: 597
-- Name: FUNCTION update_teacher_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_teacher_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) TO anon;
GRANT ALL ON FUNCTION public.update_teacher_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.update_teacher_with_context(p_user_id integer, p_user_type text, p_id integer, p_payload jsonb) TO service_role;


--
-- TOC entry 4803 (class 0 OID 0)
-- Dependencies: 598
-- Name: FUNCTION verify_password(p_password_hash text, p_password text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.verify_password(p_password_hash text, p_password text) TO anon;
GRANT ALL ON FUNCTION public.verify_password(p_password_hash text, p_password text) TO authenticated;
GRANT ALL ON FUNCTION public.verify_password(p_password_hash text, p_password text) TO service_role;


--
-- TOC entry 4805 (class 0 OID 0)
-- Dependencies: 352
-- Name: TABLE activities; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.activities TO anon;
GRANT ALL ON TABLE public.activities TO authenticated;
GRANT ALL ON TABLE public.activities TO service_role;


--
-- TOC entry 4807 (class 0 OID 0)
-- Dependencies: 353
-- Name: SEQUENCE activities_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.activities_id_seq TO anon;
GRANT ALL ON SEQUENCE public.activities_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.activities_id_seq TO service_role;


--
-- TOC entry 4808 (class 0 OID 0)
-- Dependencies: 354
-- Name: TABLE activity_logs; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.activity_logs TO anon;
GRANT ALL ON TABLE public.activity_logs TO authenticated;
GRANT ALL ON TABLE public.activity_logs TO service_role;


--
-- TOC entry 4810 (class 0 OID 0)
-- Dependencies: 355
-- Name: SEQUENCE activity_logs_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.activity_logs_id_seq TO anon;
GRANT ALL ON SEQUENCE public.activity_logs_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.activity_logs_id_seq TO service_role;


--
-- TOC entry 4812 (class 0 OID 0)
-- Dependencies: 356
-- Name: SEQUENCE admins_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.admins_id_seq TO anon;
GRANT ALL ON SEQUENCE public.admins_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.admins_id_seq TO service_role;


--
-- TOC entry 4814 (class 0 OID 0)
-- Dependencies: 357
-- Name: TABLE app_user; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.app_user TO anon;
GRANT ALL ON TABLE public.app_user TO authenticated;
GRANT ALL ON TABLE public.app_user TO service_role;


--
-- TOC entry 4816 (class 0 OID 0)
-- Dependencies: 358
-- Name: SEQUENCE app_user_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.app_user_id_seq TO anon;
GRANT ALL ON SEQUENCE public.app_user_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.app_user_id_seq TO service_role;


--
-- TOC entry 4818 (class 0 OID 0)
-- Dependencies: 359
-- Name: SEQUENCE attendance_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.attendance_id_seq TO anon;
GRANT ALL ON SEQUENCE public.attendance_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.attendance_id_seq TO service_role;


--
-- TOC entry 4822 (class 0 OID 0)
-- Dependencies: 408
-- Name: TABLE chapter_topics; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.chapter_topics TO anon;
GRANT ALL ON TABLE public.chapter_topics TO authenticated;
GRANT ALL ON TABLE public.chapter_topics TO service_role;


--
-- TOC entry 4824 (class 0 OID 0)
-- Dependencies: 407
-- Name: SEQUENCE chapter_topics_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.chapter_topics_id_seq TO anon;
GRANT ALL ON SEQUENCE public.chapter_topics_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.chapter_topics_id_seq TO service_role;


--
-- TOC entry 4826 (class 0 OID 0)
-- Dependencies: 361
-- Name: SEQUENCE chapters_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.chapters_id_seq TO anon;
GRANT ALL ON SEQUENCE public.chapters_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.chapters_id_seq TO service_role;


--
-- TOC entry 4828 (class 0 OID 0)
-- Dependencies: 362
-- Name: TABLE daily_summaries; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.daily_summaries TO anon;
GRANT ALL ON TABLE public.daily_summaries TO authenticated;
GRANT ALL ON TABLE public.daily_summaries TO service_role;


--
-- TOC entry 4830 (class 0 OID 0)
-- Dependencies: 363
-- Name: SEQUENCE daily_summaries_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.daily_summaries_id_seq TO anon;
GRANT ALL ON SEQUENCE public.daily_summaries_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.daily_summaries_id_seq TO service_role;


--
-- TOC entry 4832 (class 0 OID 0)
-- Dependencies: 364
-- Name: SEQUENCE exam_questions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.exam_questions_id_seq TO anon;
GRANT ALL ON SEQUENCE public.exam_questions_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.exam_questions_id_seq TO service_role;


--
-- TOC entry 4833 (class 0 OID 0)
-- Dependencies: 365
-- Name: TABLE exam_results; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.exam_results TO anon;
GRANT ALL ON TABLE public.exam_results TO authenticated;
GRANT ALL ON TABLE public.exam_results TO service_role;


--
-- TOC entry 4835 (class 0 OID 0)
-- Dependencies: 366
-- Name: SEQUENCE exam_results_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.exam_results_id_seq TO anon;
GRANT ALL ON SEQUENCE public.exam_results_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.exam_results_id_seq TO service_role;


--
-- TOC entry 4837 (class 0 OID 0)
-- Dependencies: 367
-- Name: SEQUENCE exams_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.exams_id_seq TO anon;
GRANT ALL ON SEQUENCE public.exams_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.exams_id_seq TO service_role;


--
-- TOC entry 4839 (class 0 OID 0)
-- Dependencies: 368
-- Name: SEQUENCE grades_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.grades_id_seq TO anon;
GRANT ALL ON SEQUENCE public.grades_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.grades_id_seq TO service_role;


--
-- TOC entry 4841 (class 0 OID 0)
-- Dependencies: 369
-- Name: SEQUENCE messages_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.messages_id_seq TO anon;
GRANT ALL ON SEQUENCE public.messages_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.messages_id_seq TO service_role;


--
-- TOC entry 4842 (class 0 OID 0)
-- Dependencies: 370
-- Name: TABLE mv_dashboard_stats; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.mv_dashboard_stats TO anon;
GRANT ALL ON TABLE public.mv_dashboard_stats TO authenticated;
GRANT ALL ON TABLE public.mv_dashboard_stats TO service_role;


--
-- TOC entry 4843 (class 0 OID 0)
-- Dependencies: 371
-- Name: TABLE mv_monthly_attendance; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.mv_monthly_attendance TO anon;
GRANT ALL ON TABLE public.mv_monthly_attendance TO authenticated;
GRANT ALL ON TABLE public.mv_monthly_attendance TO service_role;


--
-- TOC entry 4844 (class 0 OID 0)
-- Dependencies: 372
-- Name: TABLE mv_student_monthly_performance; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.mv_student_monthly_performance TO anon;
GRANT ALL ON TABLE public.mv_student_monthly_performance TO authenticated;
GRANT ALL ON TABLE public.mv_student_monthly_performance TO service_role;


--
-- TOC entry 4845 (class 0 OID 0)
-- Dependencies: 373
-- Name: TABLE mv_subject_statistics; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.mv_subject_statistics TO anon;
GRANT ALL ON TABLE public.mv_subject_statistics TO authenticated;
GRANT ALL ON TABLE public.mv_subject_statistics TO service_role;


--
-- TOC entry 4846 (class 0 OID 0)
-- Dependencies: 374
-- Name: TABLE mv_weekly_activity; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.mv_weekly_activity TO anon;
GRANT ALL ON TABLE public.mv_weekly_activity TO authenticated;
GRANT ALL ON TABLE public.mv_weekly_activity TO service_role;


--
-- TOC entry 4847 (class 0 OID 0)
-- Dependencies: 375
-- Name: TABLE notifications; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.notifications TO anon;
GRANT ALL ON TABLE public.notifications TO authenticated;
GRANT ALL ON TABLE public.notifications TO service_role;


--
-- TOC entry 4849 (class 0 OID 0)
-- Dependencies: 376
-- Name: SEQUENCE notifications_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.notifications_id_seq TO anon;
GRANT ALL ON SEQUENCE public.notifications_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.notifications_id_seq TO service_role;


--
-- TOC entry 4851 (class 0 OID 0)
-- Dependencies: 377
-- Name: SEQUENCE parent_students_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.parent_students_id_seq TO anon;
GRANT ALL ON SEQUENCE public.parent_students_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.parent_students_id_seq TO service_role;


--
-- TOC entry 4853 (class 0 OID 0)
-- Dependencies: 378
-- Name: SEQUENCE parents_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.parents_id_seq TO anon;
GRANT ALL ON SEQUENCE public.parents_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.parents_id_seq TO service_role;


--
-- TOC entry 4855 (class 0 OID 0)
-- Dependencies: 379
-- Name: SEQUENCE pending_content_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.pending_content_id_seq TO anon;
GRANT ALL ON SEQUENCE public.pending_content_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.pending_content_id_seq TO service_role;


--
-- TOC entry 4857 (class 0 OID 0)
-- Dependencies: 403
-- Name: TABLE practice_quiz_answers; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.practice_quiz_answers TO anon;
GRANT ALL ON TABLE public.practice_quiz_answers TO authenticated;
GRANT ALL ON TABLE public.practice_quiz_answers TO service_role;


--
-- TOC entry 4859 (class 0 OID 0)
-- Dependencies: 402
-- Name: SEQUENCE practice_quiz_answers_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.practice_quiz_answers_id_seq TO anon;
GRANT ALL ON SEQUENCE public.practice_quiz_answers_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.practice_quiz_answers_id_seq TO service_role;


--
-- TOC entry 4861 (class 0 OID 0)
-- Dependencies: 401
-- Name: TABLE practice_quiz_attempts; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.practice_quiz_attempts TO anon;
GRANT ALL ON TABLE public.practice_quiz_attempts TO authenticated;
GRANT ALL ON TABLE public.practice_quiz_attempts TO service_role;


--
-- TOC entry 4863 (class 0 OID 0)
-- Dependencies: 400
-- Name: SEQUENCE practice_quiz_attempts_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.practice_quiz_attempts_id_seq TO anon;
GRANT ALL ON SEQUENCE public.practice_quiz_attempts_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.practice_quiz_attempts_id_seq TO service_role;


--
-- TOC entry 4865 (class 0 OID 0)
-- Dependencies: 380
-- Name: SEQUENCE questions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.questions_id_seq TO anon;
GRANT ALL ON SEQUENCE public.questions_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.questions_id_seq TO service_role;


--
-- TOC entry 4867 (class 0 OID 0)
-- Dependencies: 381
-- Name: SEQUENCE reports_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.reports_id_seq TO anon;
GRANT ALL ON SEQUENCE public.reports_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.reports_id_seq TO service_role;


--
-- TOC entry 4870 (class 0 OID 0)
-- Dependencies: 382
-- Name: TABLE school_settings; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.school_settings TO anon;
GRANT ALL ON TABLE public.school_settings TO authenticated;
GRANT ALL ON TABLE public.school_settings TO service_role;


--
-- TOC entry 4872 (class 0 OID 0)
-- Dependencies: 383
-- Name: SEQUENCE section_subjects_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.section_subjects_id_seq TO anon;
GRANT ALL ON SEQUENCE public.section_subjects_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.section_subjects_id_seq TO service_role;


--
-- TOC entry 4874 (class 0 OID 0)
-- Dependencies: 384
-- Name: SEQUENCE sections_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.sections_id_seq TO anon;
GRANT ALL ON SEQUENCE public.sections_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.sections_id_seq TO service_role;


--
-- TOC entry 4876 (class 0 OID 0)
-- Dependencies: 385
-- Name: SEQUENCE semesters_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.semesters_id_seq TO anon;
GRANT ALL ON SEQUENCE public.semesters_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.semesters_id_seq TO service_role;


--
-- TOC entry 4877 (class 0 OID 0)
-- Dependencies: 386
-- Name: SEQUENCE seq_student_code; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.seq_student_code TO anon;
GRANT ALL ON SEQUENCE public.seq_student_code TO authenticated;
GRANT ALL ON SEQUENCE public.seq_student_code TO service_role;


--
-- TOC entry 4878 (class 0 OID 0)
-- Dependencies: 387
-- Name: SEQUENCE seq_subject_code; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.seq_subject_code TO anon;
GRANT ALL ON SEQUENCE public.seq_subject_code TO authenticated;
GRANT ALL ON SEQUENCE public.seq_subject_code TO service_role;


--
-- TOC entry 4879 (class 0 OID 0)
-- Dependencies: 388
-- Name: SEQUENCE seq_teacher_code; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.seq_teacher_code TO anon;
GRANT ALL ON SEQUENCE public.seq_teacher_code TO authenticated;
GRANT ALL ON SEQUENCE public.seq_teacher_code TO service_role;


--
-- TOC entry 4881 (class 0 OID 0)
-- Dependencies: 405
-- Name: TABLE student_summaries; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.student_summaries TO anon;
GRANT ALL ON TABLE public.student_summaries TO authenticated;
GRANT ALL ON TABLE public.student_summaries TO service_role;


--
-- TOC entry 4883 (class 0 OID 0)
-- Dependencies: 404
-- Name: SEQUENCE student_summaries_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.student_summaries_id_seq TO anon;
GRANT ALL ON SEQUENCE public.student_summaries_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.student_summaries_id_seq TO service_role;


--
-- TOC entry 4885 (class 0 OID 0)
-- Dependencies: 389
-- Name: SEQUENCE students_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.students_id_seq TO anon;
GRANT ALL ON SEQUENCE public.students_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.students_id_seq TO service_role;


--
-- TOC entry 4887 (class 0 OID 0)
-- Dependencies: 390
-- Name: SEQUENCE subjects_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.subjects_id_seq TO anon;
GRANT ALL ON SEQUENCE public.subjects_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.subjects_id_seq TO service_role;


--
-- TOC entry 4889 (class 0 OID 0)
-- Dependencies: 391
-- Name: SEQUENCE teachers_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.teachers_id_seq TO anon;
GRANT ALL ON SEQUENCE public.teachers_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.teachers_id_seq TO service_role;


--
-- TOC entry 4890 (class 0 OID 0)
-- Dependencies: 392
-- Name: TABLE v_active_students; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.v_active_students TO anon;
GRANT ALL ON TABLE public.v_active_students TO authenticated;
GRANT ALL ON TABLE public.v_active_students TO service_role;


--
-- TOC entry 4891 (class 0 OID 0)
-- Dependencies: 393
-- Name: TABLE v_curriculum_gaps; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.v_curriculum_gaps TO anon;
GRANT ALL ON TABLE public.v_curriculum_gaps TO authenticated;
GRANT ALL ON TABLE public.v_curriculum_gaps TO service_role;


--
-- TOC entry 4892 (class 0 OID 0)
-- Dependencies: 394
-- Name: TABLE v_pending_exams; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.v_pending_exams TO anon;
GRANT ALL ON TABLE public.v_pending_exams TO authenticated;
GRANT ALL ON TABLE public.v_pending_exams TO service_role;


--
-- TOC entry 4893 (class 0 OID 0)
-- Dependencies: 395
-- Name: TABLE v_pending_questions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.v_pending_questions TO anon;
GRANT ALL ON TABLE public.v_pending_questions TO authenticated;
GRANT ALL ON TABLE public.v_pending_questions TO service_role;


--
-- TOC entry 4894 (class 0 OID 0)
-- Dependencies: 396
-- Name: TABLE v_student_grades; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.v_student_grades TO anon;
GRANT ALL ON TABLE public.v_student_grades TO authenticated;
GRANT ALL ON TABLE public.v_student_grades TO service_role;


--
-- TOC entry 4895 (class 0 OID 0)
-- Dependencies: 397
-- Name: TABLE v_teacher_classes; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.v_teacher_classes TO anon;
GRANT ALL ON TABLE public.v_teacher_classes TO authenticated;
GRANT ALL ON TABLE public.v_teacher_classes TO service_role;


--
-- TOC entry 4896 (class 0 OID 0)
-- Dependencies: 398
-- Name: TABLE v_teachers_with_subjects; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.v_teachers_with_subjects TO anon;
GRANT ALL ON TABLE public.v_teachers_with_subjects TO authenticated;
GRANT ALL ON TABLE public.v_teachers_with_subjects TO service_role;


--
-- TOC entry 4897 (class 0 OID 0)
-- Dependencies: 399
-- Name: TABLE v_unread_messages_admin; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.v_unread_messages_admin TO anon;
GRANT ALL ON TABLE public.v_unread_messages_admin TO authenticated;
GRANT ALL ON TABLE public.v_unread_messages_admin TO service_role;


--
-- TOC entry 2708 (class 826 OID 16490)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- TOC entry 2690 (class 826 OID 16491)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- TOC entry 2709 (class 826 OID 16489)
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- TOC entry 2692 (class 826 OID 16493)
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- TOC entry 2710 (class 826 OID 16488)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO service_role;


--
-- TOC entry 2691 (class 826 OID 16492)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO service_role;


--
-- TOC entry 4632 (class 0 OID 17819)
-- Dependencies: 370 4663
-- Name: mv_dashboard_stats; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: postgres
--

REFRESH MATERIALIZED VIEW public.mv_dashboard_stats;


--
-- TOC entry 4633 (class 0 OID 17824)
-- Dependencies: 371 4663
-- Name: mv_monthly_attendance; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: postgres
--

REFRESH MATERIALIZED VIEW public.mv_monthly_attendance;


--
-- TOC entry 4634 (class 0 OID 17831)
-- Dependencies: 372 4663
-- Name: mv_student_monthly_performance; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: postgres
--

REFRESH MATERIALIZED VIEW public.mv_student_monthly_performance;


--
-- TOC entry 4635 (class 0 OID 17838)
-- Dependencies: 373 4663
-- Name: mv_subject_statistics; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: postgres
--

REFRESH MATERIALIZED VIEW public.mv_subject_statistics;


--
-- TOC entry 4636 (class 0 OID 17845)
-- Dependencies: 374 4663
-- Name: mv_weekly_activity; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: postgres
--

REFRESH MATERIALIZED VIEW public.mv_weekly_activity;


-- Completed on 2026-03-02 00:34:13

--
-- PostgreSQL database dump complete
--

\unrestrict QpEtDPVDYAV3SWhX82fWyN4sYs8iZlna2ichpagRFoCz3pcrJj6kO6bcVLqZS6I

