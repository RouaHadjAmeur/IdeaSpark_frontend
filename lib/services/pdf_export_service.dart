import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/plan.dart';

class PdfExportService {
  static Future<void> exportPlan(Plan plan) async {
    final pdf = pw.Document();
    final totalPosts = plan.phases.fold<int>(0, (s, p) => s + p.contentBlocks.length);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(plan),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildOverview(plan, totalPosts),
          pw.SizedBox(height: 20),
          _buildStats(plan, totalPosts),
          pw.SizedBox(height: 20),
          ...plan.phases.map((phase) => _buildPhase(phase)),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Plan_${plan.name.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _buildHeader(Plan plan) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 12),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.blue, width: 2),
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'IdeaSpark',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue,
              ),
            ),
            pw.Text(
              plan.name,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  static pw.Widget _buildFooter(pw.Context context) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 8),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: PdfColors.grey300),
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Généré par IdeaSpark',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
            pw.Text('Page ${context.pageNumber} / ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
          ],
        ),
      );

  static pw.Widget _buildOverview(Plan plan, int totalPosts) => pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.blue50,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '${plan.objective.emoji} ${plan.name}',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Objectif : ${plan.objective.label}',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Période : ${_formatDate(plan.startDate)} → ${_formatDate(plan.endDate)}',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
          ],
        ),
      );

  static pw.Widget _buildStats(Plan plan, int totalPosts) => pw.Row(
        children: [
          _statBox('${plan.phases.length}', 'Phases', PdfColors.blue),
          pw.SizedBox(width: 12),
          _statBox('$totalPosts', 'Publications', PdfColors.green),
          pw.SizedBox(width: 12),
          _statBox('${plan.durationWeeks}w', 'Durée', PdfColors.orange),
          pw.SizedBox(width: 12),
          _statBox('${plan.postingFrequency}/wk', 'Fréquence', PdfColors.purple),
        ],
      );

  static pw.Widget _statBox(String value, String label, PdfColor color) =>
      pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: color),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              pw.Text(value,
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold, color: color)),
              pw.Text(label,
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            ],
          ),
        ),
      );

  static pw.Widget _buildPhase(Phase phase) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  'Semaine ${phase.weekNumber} - ${phase.name}',
                  style: pw.TextStyle(
                      fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                ),
                pw.Spacer(),
                pw.Text(
                  '${phase.contentBlocks.length} posts',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.blue700),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          ...phase.contentBlocks.map((block) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6, left: 8),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        block.format.label,
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Text(
                        block.title,
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ),
                    pw.Text(
                      block.pillar,
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    ),
                  ],
                ),
              )),
          pw.SizedBox(height: 16),
        ],
      );

  static String _formatDate(DateTime d) {
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
                    'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
