// lib/services/prescription_pdf_service.dart

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/prescription.dart';

class PrescriptionPdfService {
  static Future<void> generateAndPrint(Prescription prescription) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.portrait,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => _buildHeader(),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildPrescriptionContent(prescription),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  static Future<void> generateAndDownload(Prescription prescription) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.portrait,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => _buildHeader(),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildPrescriptionContent(prescription),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'prescription_${prescription.prescriptionId}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildHeader() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        children: [
          pw.Text(
            'His Grace Drugshop',
            style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700),
          ),
          pw.Text(
            'Prescription Document',
            style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        children: [
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated on ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                'Page ${context.pageNumber}',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPrescriptionContent(Prescription prescription) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Prescription Info
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Column(
            children: [
              _buildInfoRow('Prescription ID', prescription.prescriptionId),
              _buildInfoRow('Status', prescription.statusDisplay),
              _buildInfoRow('Issue Date',
                  DateFormat('dd/MM/yyyy').format(prescription.issueDate)),
              _buildInfoRow('Expiry Date',
                  DateFormat('dd/MM/yyyy').format(prescription.expiryDate)),
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        // Patient Info
        pw.Text('Patient Information',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Column(
            children: [
              _buildInfoRow('Patient Name', prescription.patientName),
              if (prescription.patientAge != null)
                _buildInfoRow('Age', '${prescription.patientAge}'),
              if (prescription.patientPhone.isNotEmpty)
                _buildInfoRow('Phone', prescription.patientPhone),
              if (prescription.diagnosis.isNotEmpty)
                _buildInfoRow('Diagnosis', prescription.diagnosis),
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        // Doctor Info
        pw.Text('Doctor Information',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Column(
            children: [
              _buildInfoRow('Doctor Name', prescription.doctorName),
              if (prescription.doctorLicense.isNotEmpty)
                _buildInfoRow('License', prescription.doctorLicense),
              if (prescription.hospital.isNotEmpty)
                _buildInfoRow('Hospital', prescription.hospital),
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        // Medicines
        pw.Text('Prescribed Medicines',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),

        _buildMedicinesTable(prescription.items),

        if (prescription.notes.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          pw.Text('Notes',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Text(prescription.notes),
          ),
        ],

        pw.SizedBox(height: 40),

        // Signature lines
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              children: [
                pw.Text('Pharmacist Signature',
                    style:
                        pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                pw.SizedBox(height: 30),
                pw.Container(width: 150, height: 1, color: PdfColors.black),
              ],
            ),
            pw.Column(
              children: [
                pw.Text('Patient Signature',
                    style:
                        pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                pw.SizedBox(height: 30),
                pw.Container(width: 150, height: 1, color: PdfColors.black),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(label,
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          ),
          pw.Text(': $value', style: pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  static pw.Widget _buildMedicinesTable(List<PrescriptionItem> items) {
    final rows = items
        .map((item) => [
              item.medicineName,
              '${item.prescribedQuantity}',
              '${item.filledQuantity}/${item.prescribedQuantity}',
              item.dosageInstructions,
            ])
        .toList();

    return pw.TableHelper.fromTextArray(
      headers: ['Medicine', 'Qty', 'Filled', 'Dosage'],
      data: rows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
      cellStyle: pw.TextStyle(fontSize: 10),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
      cellPadding: const pw.EdgeInsets.all(6),
    );
  }
}
