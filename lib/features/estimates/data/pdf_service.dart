import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:koji/features/estimates/data/models/estimate_model.dart';

class PdfService {
  static Future<String> generateAndSaveEstimatePdf(
    ClientInfo? client,
    String description,
    double surface,
    double pricePerSqMeter,
    double laborCost,
    List<SupplyItem> supplies,
    double suppliesCost,
    double totalCost,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'DEVIS',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo900,
                    ),
                  ),
                  pw.Text(
                    DateFormat('dd/MM/yyyy').format(DateTime.now()),
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),

              // Client Info
              pw.Text(
                'CLIENT :',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                  fontSize: 10,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                client?.name ?? 'Nom du client',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              pw.Text(client?.address ?? ''),
              pw.Text(client?.phone ?? ''),
              pw.SizedBox(height: 24),

              // Description
              pw.Text(
                'DESCRIPTION :',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                  fontSize: 10,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(description.isNotEmpty ? description : 'Aucune description'),
              pw.SizedBox(height: 24),

              // Labor Section
              pw.Text(
                'MAIN D\'ŒUVRE',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo900,
                  fontSize: 12,
                ),
              ),
              pw.SizedBox(height: 8),
              _buildLineItem(
                'Surface ${surface}m² x ${pricePerSqMeter}€',
                laborCost,
              ),
              pw.SizedBox(height: 16),

              // Supplies Section
              pw.Text(
                'FOURNITURES',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo900,
                  fontSize: 12,
                ),
              ),
              pw.SizedBox(height: 8),
              ...supplies.map((s) => _buildLineItem(
                    '${s.name} (x${s.quantity})',
                    s.totalPrice,
                  )),
              pw.SizedBox(height: 24),

              pw.Divider(thickness: 2),
              pw.SizedBox(height: 16),

              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'TOTAL TTC',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        NumberFormat.simpleCurrency(locale: 'fr_FR').format(totalCost),
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final fileName = 'devis_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

    // Save to Downloads folder on Android, Documents on iOS
    if (Platform.isAndroid) {
      // For Android, save to Downloads
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } else {
      // For iOS, use app documents directory and share
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      
      // Share on iOS
      await Printing.sharePdf(bytes: bytes, filename: fileName);
      return file.path;
    }
  }

  static pw.Widget _buildLineItem(String label, double price) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(
            NumberFormat.simpleCurrency(locale: 'fr_FR').format(price),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
