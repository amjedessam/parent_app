// Worker: يقرأ notification_jobs ويرسل FCM
// Database Webhook: Header يجب أن يكون Bearer + service_role من Settings → API (ليس anon ولا JWT مستخدم)
// المهلة في Webhook: 5000–10000 ms (لا تضع 0)
//
// Deploy: supabase functions deploy process-exam-notification-job

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { initializeApp, cert, getApps } from "npm:firebase-admin/app";
import { getMessaging } from "npm:firebase-admin/messaging";
const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function initFirebase() {
  if (getApps().length > 0) return;

  const jsonRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  if (jsonRaw) {
    initializeApp({ credential: cert(JSON.parse(jsonRaw)) });
    return;
  }

  const projectId = Deno.env.get("FIREBASE_PROJECT_ID");
  const clientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL");
  let privateKey = Deno.env.get("FIREBASE_PRIVATE_KEY");
  if (!projectId || !clientEmail || !privateKey) {
    throw new Error(
      "Firebase: FIREBASE_SERVICE_ACCOUNT_JSON أو FIREBASE_PROJECT_ID + CLIENT_EMAIL + PRIVATE_KEY",
    );
  }
  privateKey = privateKey.replace(/\\n/g, "\n").trim();
  if (privateKey.startsWith('"') && privateKey.endsWith('"')) {
    privateKey = privateKey.slice(1, -1).replace(/\\n/g, "\n");
  }
  initializeApp({
    credential: cert({ projectId, clientEmail, privateKey }),
  });
}

function normalizeSecret(s: string): string {
  return s
    .trim()
    .replace(/^\uFEFF/, "")
    .replace(/^["']|["']$/g, "")
    .replace(/\r\n|\n|\r/g, "");
}

function stripBearer(value: string): string {
  let v = normalizeSecret(value);
  while (v.toLowerCase().startsWith("bearer ")) {
    v = normalizeSecret(v.slice(7));
  }
  return v;
}

/** يأخذ المفتاح من Authorization و/أو apikey (بعض Webhooks ترسل apikey فقط). */
function incomingServiceToken(req: Request): string {
  const authHeader = req.headers.get("Authorization") ?? "";
  const apikeyHeader = req.headers.get("apikey") ?? "";
  const fromAuth = stripBearer(authHeader);
  if (fromAuth.length > 0) return fromAuth;
  return normalizeSecret(apikeyHeader);
}

function authFailureHint(wrongToken: string): string {
  try {
    const parts = wrongToken.trim().split(".");
    if (parts.length < 2) {
      return "انسخ المفتاح كاملًا: Project Settings → API → service_role (secret).";
    }
    let b64 = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    const pad = b64.length % 4;
    if (pad) b64 += "=".repeat(4 - pad);
    const payload = JSON.parse(atob(b64)) as { role?: string };
    if (payload.role === "anon") {
      return "أنت تستخدم anon. استبدله بـ service_role (secret) من نفس الصفحة.";
    }
    if (payload.role === "authenticated") {
      return "JWT مستخدم مرفوض. Webhook يحتاج service_role فقط.";
    }
    if (payload.role === "service_role") {
      return "المفتاح يبدو service_role لكنه لا يطابق سر الدالة. انسخ من Project Settings → API وليس من مكان آخر.";
    }
  } catch {
    /* ignore */
  }
  return "المفتاح لا يطابق SUPABASE_SERVICE_ROLE_KEY في بيئة الدالة. تحقق من اللصق والمسافات.";
}

/** مطابقة مع سر الخدمة في بيئة Edge Function (نفس قيمة لوحة المشروع). */
function requireServiceRole(req: Request): Response | null {
  const expected = normalizeSecret(Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "");
  const raw = incomingServiceToken(req);
  if (!expected) {
    console.error("process-exam-notification-job: missing SUPABASE_SERVICE_ROLE_KEY in env");
    return new Response(
      JSON.stringify({ error: "Server misconfigured" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
  if (raw !== expected) {
    console.warn(
      "401 auth mismatch",
      JSON.stringify({
        gotLen: raw.length,
        expLen: expected.length,
        gotPrefix: raw.slice(0, 12),
        expPrefix: expected.slice(0, 12),
      }),
    );
    const hint = raw ? authFailureHint(raw) : "أضف Authorization: Bearer <service_role> أو header اسمه apikey بنفس القيمة";
    return new Response(
      JSON.stringify({ error: "Unauthorized", hint }),
      {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
  return null;
}

/** حمولة Database Webhook: { type, record: { id, ... } } */
function extractJobId(body: Record<string, unknown>): string | undefined {
  const j = body.job_id;
  if (typeof j === "string" && j.length > 0) return j;

  const rec = body.record as Record<string, unknown> | undefined;
  if (rec?.id != null) return String(rec.id);

  const payload = body.payload as Record<string, unknown> | undefined;
  if (payload && typeof payload === "object") {
    const nested = extractJobId(payload as Record<string, unknown>);
    if (nested) return nested;
  }
  return undefined;
}

async function sendFcmForStudent(
  admin: ReturnType<typeof createClient>,
  examId: number,
  assignmentId: number,
  studentId: number,
  examTitle: string,
): Promise<{ sent: number; skipReason?: string }> {
  const { data: studentAu } = await admin
    .from("app_user")
    .select("auth_user_id")
    .eq("user_type", "student")
    .eq("app_entity_id", studentId)
    .maybeSingle();

  if (!studentAu?.auth_user_id) {
    return { sent: 0, skipReason: "no app_user for student" };
  }

  const { data: devices } = await admin
    .from("user_devices")
    .select("fcm_token")
    .eq("auth_user_id", studentAu.auth_user_id)
    .eq("is_active", true);

  const tokens = (devices ?? [])
    .map((d) => d.fcm_token as string)
    .filter((t) => t && t.length > 0);

  if (tokens.length === 0) return { sent: 0, skipReason: "no tokens" };

  initFirebase();
  const messaging = getMessaging();

  const res = await messaging.sendEachForMulticast({
    tokens,
    notification: {
      title: "اختبار جديد من المعلم",
      body: examTitle,
    },
    data: {
      type: "exam_assigned",
      exam_id: String(examId),
      assignment_id: String(assignmentId),
      student_id: String(studentId),
    },
    android: { priority: "high" as const },
    apns: { payload: { aps: { sound: "default" } } },
  });

  for (let i = 0; i < res.responses.length; i++) {
    const r = res.responses[i];
    if (
      !r.success &&
      (r.error?.code === "messaging/registration-token-not-registered" ||
        r.error?.code === "messaging/invalid-registration-token")
    ) {
      const bad = tokens[i];
      await admin.from("user_devices").update({ is_active: false }).eq(
        "fcm_token",
        bad,
      );
    }
  }

  return { sent: res.successCount };
}

async function processOneJob(
  admin: ReturnType<typeof createClient>,
  jobId: string,
): Promise<{ ok: boolean; sent?: number; error?: string; skipped?: boolean }> {
  const { data: job, error: fetchErr } = await admin
    .from("notification_jobs")
    .select("*")
    .eq("id", jobId)
    .maybeSingle();

  if (fetchErr || !job) {
    return { ok: false, error: "job not found" };
  }
  if (job.status !== "pending") {
    return { ok: true, skipped: true };
  }

  await admin
    .from("notification_jobs")
    .update({ status: "processing", attempts: (job.attempts as number) + 1 })
    .eq("id", jobId);

  const examId = job.exam_id as number;
  const assignmentId = job.assignment_id as number;
  const studentId = job.student_id as number;

  try {
    const { data: exam, error: examErr } = await admin
      .from("exams")
      .select("id, title")
      .eq("id", examId)
      .maybeSingle();

    if (examErr || !exam) {
      await admin
        .from("notification_jobs")
        .update({
          status: "failed",
          last_error: "exam not found",
          processed_at: new Date().toISOString(),
        })
        .eq("id", jobId);
      return { ok: false, error: "exam not found" };
    }

    const examTitle = (exam.title as string) ?? "اختبار جديد";
    const { sent, skipReason } = await sendFcmForStudent(
      admin,
      examId,
      assignmentId,
      studentId,
      examTitle,
    );

    await admin
      .from("notification_jobs")
      .update({
        status: "completed",
        processed_at: new Date().toISOString(),
        last_error: sent === 0 ? (skipReason ?? "no FCM sent") : null,
      })
      .eq("id", jobId);

    return { ok: true, sent };
  } catch (e) {
    const msg = String(e);
    await admin
      .from("notification_jobs")
      .update({
        status: "failed",
        last_error: msg.slice(0, 2000),
        processed_at: new Date().toISOString(),
      })
      .eq("id", jobId);
    return { ok: false, error: msg };
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const denied = requireServiceRole(req);
  if (denied) return denied;

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const admin = createClient(supabaseUrl, serviceKey);

    const body = (await req.json()) as Record<string, unknown>;
    const processPending = body.process_pending === true;
    const limit =
      typeof body.limit === "number" ? body.limit : undefined;

    const jobId = extractJobId(body);
    console.log(
      "process-exam-notification-job:",
      JSON.stringify({
        jobId: jobId ?? null,
        processPending,
        keys: Object.keys(body),
      }),
    );

    if (jobId) {
      const r = await processOneJob(admin, jobId);
      console.log("job result:", JSON.stringify(r));
      return new Response(JSON.stringify(r), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (processPending) {
      const lim = Math.min(Math.max(limit ?? 50, 1), 200);
      const { data: rows, error } = await admin
        .from("notification_jobs")
        .select("id")
        .eq("status", "pending")
        .order("created_at", { ascending: true })
        .limit(lim);

      if (error) {
        return new Response(JSON.stringify({ error: error.message }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const results: unknown[] = [];
      for (const row of rows ?? []) {
        const r = await processOneJob(admin, row.id as string);
        results.push({ id: row.id, ...r });
      }
      return new Response(JSON.stringify({ ok: true, results }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(
      JSON.stringify({
        error: "Body must include job_id or process_pending:true",
      }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (e) {
    console.error(e);
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
