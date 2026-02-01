import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generateStudentBulletin({
    required Map<String, dynamic> student,
    required List<Map<String, dynamic>> grades,
  }) async {
    final pdf = pw.Document();

    final double moyenneGenerale = _calculateMoyenneGenerale(grades);
    final String mention = _getMention(moyenneGenerale);
    final bool admis = moyenneGenerale >= 12;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _header(),
          pw.SizedBox(height: 20),
          _studentInfo(student),
          pw.SizedBox(height: 20),
          _gradesTable(grades),
          pw.SizedBox(height: 20),
          _finalResult(moyenneGenerale, mention, admis),
          pw.SizedBox(height: 30),
          _footer(),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // ================= CALCULATIONS =================
  static double _calculateMoyenneGenerale(List<Map<String, dynamic>> grades) {
    if (grades.isEmpty) return 0;
    double sum = 0;
    int count = 0;

    for (var g in grades) {
      if (g['moyenne'] != null) {
        sum += (g['moyenne'] as num).toDouble();
        count++;
      }
    }
    return count == 0 ? 0 : sum / count;
  }

  static String _getMention(double m) {
    if (m >= 16) return 'Très Bien';
    if (m >= 14) return 'Bien';
    if (m >= 12) return 'Assez Bien';
    return 'Ajourné';
  }

  // ================= HEADER =================
  static pw.Widget _header() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text('ENIAD',
            style:
                pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.Text(
            'École Nationale d Intelligence Artificielle et Digitale',
            style: pw.TextStyle(fontSize: 12)),
        pw.Text('BERKANE', style: pw.TextStyle(fontSize: 12)),
        pw.Divider(thickness: 2),
      ],
    );
  }

  // ================= STUDENT INFO =================
  static pw.Widget _studentInfo(Map<String, dynamic> s) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Relevé de Notes Annuel',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _line('Nom & Prénom', '${s['nom']} ${s['prenom']}'),
          _line('Massar', s['massar'] ?? ''),
          _line('Niveau', s['niveau'] ?? ''),
          _line('Filière', s['nom_filiere'] ?? ''),
        ],
      ),
    );
  }

  static pw.Widget _line(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Expanded(
              flex: 2,
              child: pw.Text(label,
                  style:
                      pw.TextStyle(fontWeight: pw.FontWeight.bold))),
          pw.Expanded(flex: 3, child: pw.Text(value)),
        ],
      ),
    );
  }

  // ================= GRADES TABLE =================
  static pw.Widget _gradesTable(List<Map<String, dynamic>> grades) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1),
        4: pw.FlexColumnWidth(1),
        5: pw.FlexColumnWidth(1),
      },
      children: [
        _tableHeader(),
        ...grades.map(_tableRow),
      ],
    );
  }

  static pw.TableRow _tableHeader() {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      children: [
        _cell('Module', bold: true),
        _cell('Ctl'),
        _cell('TP'),
        _cell('Proj'),
        _cell('Exam'),
        _cell('Moy'),
      ],
    );
  }

  static pw.TableRow _tableRow(Map<String, dynamic> g) {
    return pw.TableRow(children: [
      _cell(g['nom_module']),
      _cell(g['controle']),
      _cell(g['tp']),
      _cell(g['projet']),
      _cell(g['examen']),
      _cell(
        (g['moyenne'] ?? 0).toStringAsFixed(2),
        bold: true,
      ),
    ]);
  }

  static pw.Widget _cell(dynamic text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text?.toString() ?? '-',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
            fontSize: 10,
            fontWeight:
                bold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }

  // ================= FINAL RESULT =================
  static pw.Widget _finalResult(
    double moyenne, String mention, bool admis) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(width: 2),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(
            'Moyenne Générale Pondérée : ${moyenne.toStringAsFixed(2)}',
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            'Mention : $mention',
            style: pw.TextStyle(fontSize: 12),
          ),
        ]),
        pw.Text(
          admis ? 'ADMIS' : 'AJOURNÉ',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: admis ? PdfColors.green : PdfColors.red,
          ),
        ),
      ],
    ),
  );
}


  // ================= FOOTER =================
  static pw.Widget _footer() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [

        pw.Text('Signature de D administration',
            style: pw.TextStyle(fontSize: 10)),
        
      ],
    );
  }
}
