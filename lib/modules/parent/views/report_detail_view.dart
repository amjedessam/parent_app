import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw; // ← as pw مهم
import 'package:printing/printing.dart';
import 'package:parent/modules/parent/models/notification_model.dart';
import 'package:parent/modules/parent/services/parent_supabase_service.dart';

import 'dart:ui' as ui;

class ReportDetailView extends StatefulWidget {
  final NotificationModel notification;
  const ReportDetailView({super.key, required this.notification});

  @override
  State<ReportDetailView> createState() => _ReportDetailViewState();
}

class _ReportDetailViewState extends State<ReportDetailView> {
  final ParentSupabaseService _service = Get.find<ParentSupabaseService>();

  List<Map<String, dynamic>> _grades = [];
  bool _loadingGrades = true;

  String get studentName =>
      widget.notification.metadata?['student_name']?.toString() ?? 'الطالب';
  String get reportText =>
      widget.notification.metadata?['report_text']?.toString() ?? '';
  String get reportTitle => widget.notification.title;
  int? get studentId => widget.notification.metadata?['student_id'] as int?;
  String get formattedDate =>
      DateFormat('dd/MM/yyyy – HH:mm').format(widget.notification.timestamp);

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    if (studentId == null) {
      setState(() => _loadingGrades = false);
      return;
    }
    try {
      final data = await _service.loadChildExamResults(studentId!);
      setState(() {
        _grades = data;
        _loadingGrades = false;
      });
    } catch (_) {
      setState(() => _loadingGrades = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      // textDirection: TextDirection.rtl,
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFBFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0EA5E9),
          title: const Text('تفاصيل التقرير'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded),
            onPressed: () => Get.back(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              onPressed: () => _exportPdf(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              _buildHeader(),
              const SizedBox(height: 20),

              // ── نص التقرير ──
              _buildSection(
                title: 'نص التقرير',
                icon: Icons.description_rounded,
                child: Text(
                  reportText.isNotEmpty ? reportText : '—',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF334155),
                    height: 1.8,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── جدول الدرجات ──
              _buildSection(
                title: 'درجات الطالب',
                icon: Icons.bar_chart_rounded,
                child: _loadingGrades
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _grades.isEmpty
                    ? const Text(
                        'لا توجد درجات مسجلة',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      )
                    : _buildGradesTable(),
              ),
              const SizedBox(height: 24),

              // ── Buttons ──
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.copy_rounded,
                      label: 'نسخ النص',
                      color: const Color(0xFF64748B),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: reportText));
                        Get.snackbar(
                          'تم',
                          'تم نسخ نص التقرير',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: const Color(0xFF1E293B),
                          colorText: Colors.white,
                          borderRadius: 12,
                          margin: const EdgeInsets.all(16),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.picture_as_pdf_rounded,
                      label: 'تصدير PDF',
                      color: const Color(0xFF0EA5E9),
                      onTap: () => _exportPdf(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header Card ──
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  reportTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(Icons.person_rounded, 'الطالب', studentName),
          const SizedBox(height: 6),
          _infoRow(Icons.access_time_rounded, 'التاريخ', formattedDate),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, color: Colors.white70, size: 16),
      const SizedBox(width: 6),
      Text(
        '$label: ',
        style: const TextStyle(color: Colors.white70, fontSize: 13),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );

  // ── Section Wrapper ──
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF0EA5E9), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  // ── جدول الدرجات ──
  Widget _buildGradesTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2), // المادة
        1: FlexColumnWidth(2), // الاختبار
        2: FlexColumnWidth(1), // المحصلة
        3: FlexColumnWidth(1), // الكاملة
        4: FlexColumnWidth(1.5), // النسبة
      },
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          children: ['المادة', 'الاختبار', 'المحصلة', 'الكاملة', 'النسبة']
              .map(
                (h) => Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  child: Text(
                    h,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              )
              .toList(),
        ),

        // Rows
        ..._grades.map((r) {
          final exam = r['exams'] as Map<String, dynamic>?;
          final subject = exam?['subjects'] as Map<String, dynamic>?;
          final pct = (r['percentage'] as num?)?.toDouble() ?? 0;
          final color = pct >= 70
              ? const Color(0xFF22C55E)
              : pct >= 50
              ? const Color(0xFFF59E0B)
              : const Color(0xFFEF4444);

          return TableRow(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            children: [
              _tableCell(subject?['name']?.toString() ?? '—'),
              _tableCell(exam?['title']?.toString() ?? '—'),
              _tableCell(r['obtained_marks']?.toString() ?? '—'),
              _tableCell(r['total_marks']?.toString() ?? '—'),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 4,
                ),
                child: Text(
                  '${pct.toStringAsFixed(1)}%',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _tableCell(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
    ),
  );

  // ── تصدير PDF يشمل الدرجات ──
  Future<void> _exportPdf(BuildContext context) async {
    final pdf = pw.Document();
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context ctx) => pw.Padding(
          padding: const pw.EdgeInsets.all(32),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#0EA5E9'),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      reportTitle,
                      style: pw.TextStyle(
                        font: arabicFontBold,
                        fontSize: 20,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'الطالب: $studentName',
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontSize: 13,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      'التاريخ: $formattedDate',
                      style: pw.TextStyle(
                        font: arabicFont,
                        fontSize: 13,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // نص التقرير
              pw.Text(
                'نص التقرير',
                style: pw.TextStyle(font: arabicFontBold, fontSize: 15),
              ),
              pw.Divider(),
              pw.Text(
                reportText,
                style: pw.TextStyle(
                  font: arabicFont,
                  fontSize: 13,
                  lineSpacing: 5,
                ),
              ),

              pw.SizedBox(height: 20),

              // جدول الدرجات
              if (_grades.isNotEmpty) ...[
                pw.Text(
                  'درجات الطالب',
                  style: pw.TextStyle(font: arabicFontBold, fontSize: 15),
                ),
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColor.fromHex('#E2E8F0'),
                    width: 0.5,
                  ),
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#F1F5F9'),
                      ),
                      children:
                          ['المادة', 'الاختبار', 'المحصلة', 'الكاملة', 'النسبة']
                              .map(
                                (h) => pw.Padding(
                                  padding: const pw.EdgeInsets.all(6),
                                  child: pw.Text(
                                    h,
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(
                                      font: arabicFontBold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    // Data rows
                    ..._grades.map((r) {
                      final exam = r['exams'] as Map<String, dynamic>?;
                      final subject =
                          exam?['subjects'] as Map<String, dynamic>?;
                      final pct = (r['percentage'] as num?)?.toDouble() ?? 0;
                      return pw.TableRow(
                        children: [
                          _pdfCell(subject?['name'] ?? '—', arabicFont),
                          _pdfCell(exam?['title'] ?? '—', arabicFont),
                          _pdfCell(
                            r['obtained_marks']?.toString() ?? '—',
                            arabicFont,
                          ),
                          _pdfCell(
                            r['total_marks']?.toString() ?? '—',
                            arabicFont,
                          ),
                          _pdfCell(
                            '${pct.toStringAsFixed(1)}%',
                            arabicFontBold,
                            color: pct >= 70
                                ? PdfColor.fromHex('#22C55E')
                                : pct >= 50
                                ? PdfColor.fromHex('#F59E0B')
                                : PdfColor.fromHex('#EF4444'),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'تقرير_$studentName.pdf',
    );
  }

  pw.Widget _pdfCell(String text, pw.Font font, {PdfColor? color}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            font: font,
            fontSize: 10,
            color: color ?? PdfColor.fromHex('#334155'),
          ),
        ),
      );
}

// ── Action Button ──
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
