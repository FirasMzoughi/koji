import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For consolidateHttpClientResponseBytes
import 'package:go_router/go_router.dart';
import 'package:koji/core/theme.dart';
import 'package:koji/core/responsive_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data'; // For Uint8List
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:koji/core/supabase_config.dart'; // For Supabase directly
import 'package:supabase_flutter/supabase_flutter.dart';

class QuoteSuccessScreen extends StatefulWidget {
  final String quoteId;
  final Map<String, dynamic> quoteData;

  const QuoteSuccessScreen({
    super.key,
    required this.quoteId,
    required this.quoteData,
  });

  @override
  State<QuoteSuccessScreen> createState() => _QuoteSuccessScreenState();
}

class _QuoteSuccessScreenState extends State<QuoteSuccessScreen> {
  bool _isGenerating = true;
  String? _logoPath;
  String? _logoUrl;
  Uint8List? _logoBytes;
  String? _signatureUrl;
  Uint8List? _signatureBytes;
  bool _isSendingEmail = false;

  String get _quoteNumber => widget.quoteData['quoteNumber'] ?? 'D-XXXX';

  @override
  void initState() {
    super.initState();
    _initPdfGeneration();
  }

  Future<void> _initPdfGeneration() async {
    // Generate PDF in background
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('business_logo_path');
    if (path != null && File(path).existsSync()) {
      _logoPath = path;
    }

    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        final res = await Supabase.instance.client
            .from('users')
            .select('signature_url, logo_url')
            .eq('id', uid)
            .maybeSingle();
        _signatureUrl = res?['signature_url'] as String?;
        _logoUrl = res?['logo_url'] as String?;

        if (_signatureUrl != null) {
          final response = await HttpClient().getUrl(Uri.parse(_signatureUrl!));
          final imageResponse = await response.close();
          final bytes = await consolidateHttpClientResponseBytes(imageResponse);
          _signatureBytes = bytes;
        }

        if (_logoUrl != null) {
          final response = await HttpClient().getUrl(Uri.parse(_logoUrl!));
          final imageResponse = await response.close();
          final bytes = await consolidateHttpClientResponseBytes(imageResponse);
          _logoBytes = bytes;
        }
      }
    } catch (e) {
      debugPrint("Could not fetch user signature or logo: $e");
    }

    await Future.delayed(const Duration(seconds: 1)); // UX delay
    if (mounted) {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<pw.Document> _generatePdf(
      {PdfPageFormat format = PdfPageFormat.a4}) async {
    final pdf = pw.Document();

    // Extract Data
    final company = widget.quoteData['company'] ?? {};
    final client = widget.quoteData['client'] ?? {};
    final totals = widget.quoteData['totals'] ?? {};
    final expenses =
        widget.quoteData['expenses'] as Map<String, dynamic>? ?? {};

    // Load fonts and colors
    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    final colorNavy = PdfColor.fromInt(0xFF0F172A); // AppTheme.darkNavy approx
    final colorCream = PdfColor.fromInt(0xFFFFF7ED); // Light background approx
    final colorAccent = PdfColor.fromInt(0xFFA18B73); // Gold/Brown accent

    pdf.addPage(pw.MultiPage(
        pageFormat: format,
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (context) {
          return [
            // Header Card
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: PdfColors.grey200),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Company Logo
                      pw.Container(
                        width: 40,
                        height: 40,
                        decoration: pw.BoxDecoration(
                          color:
                              (_logoBytes != null || _logoPath != null) ? PdfColors.white : colorNavy,
                          borderRadius: pw.BorderRadius.circular(8),
                          image: _logoBytes != null
                              ? pw.DecorationImage(
                                  image: pw.MemoryImage(_logoBytes!),
                                  fit: pw.BoxFit.cover,
                                )
                              : _logoPath != null
                                  ? pw.DecorationImage(
                                      image: pw.MemoryImage(
                                        File(_logoPath!).readAsBytesSync(),
                                      ),
                                      fit: pw.BoxFit.cover,
                                    )
                                  : null,
                        ),
                        child: (_logoBytes == null && _logoPath == null)
                            ? pw.Center(
                                child: pw.PdfLogo(color: PdfColors.white))
                            : null,
                      ),
                      pw.SizedBox(width: 12),
                      // Company Details
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(company['name'] ?? 'Koji ',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 14,
                                    color: colorNavy)),
                            pw.Text(company['address'] ?? '',
                                style: const pw.TextStyle(
                                    fontSize: 9, color: PdfColors.grey600)),
                            pw.Text(company['phone'] ?? '',
                                style: const pw.TextStyle(
                                    fontSize: 9, color: PdfColors.grey600)),
                            pw.Text(company['email'] ?? '',
                                style: const pw.TextStyle(
                                    fontSize: 9, color: PdfColors.grey600)),
                          ],
                        ),
                      ),
                      // Quote Number Box
                      pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: pw.BoxDecoration(
                              color: colorCream,
                              borderRadius: pw.BorderRadius.circular(6)),
                          child: pw.Column(children: [
                            pw.Text("DEVIS N°",
                                style: pw.TextStyle(
                                    fontSize: 8, color: colorAccent)),
                            pw.Text(_quoteNumber,
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10,
                                    color: colorNavy)),
                          ]))
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(color: PdfColors.grey100),
                  pw.SizedBox(height: 20),

                  // Client & Date Row
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(children: [
                                pw.Container(
                                    width: 4,
                                    height: 4,
                                    decoration: pw.BoxDecoration(
                                        color: colorAccent,
                                        shape: pw.BoxShape.circle)),
                                pw.SizedBox(width: 4),
                                pw.Text("CLIENT",
                                    style: pw.TextStyle(
                                        fontSize: 8,
                                        fontWeight: pw.FontWeight.bold,
                                        color: colorAccent)),
                              ]),
                              pw.SizedBox(height: 6),
                              pw.Row(children: [
                                pw.Container(
                                    width: 24,
                                    height: 24,
                                    decoration: pw.BoxDecoration(
                                        color: colorCream,
                                        shape: pw.BoxShape.circle),
                                    child: pw.Center(
                                        child: pw.Text("C",
                                            style: pw.TextStyle(
                                                color: colorAccent,
                                                fontSize: 10,
                                                fontWeight:
                                                    pw.FontWeight.bold)))),
                                pw.SizedBox(width: 8),
                                pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(client['name'] ?? 'Client',
                                          style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold,
                                              fontSize: 12,
                                              color: colorNavy)),
                                      pw.Text(client['address'] ?? '',
                                          style: const pw.TextStyle(
                                              fontSize: 9,
                                              color: PdfColors.grey600)),
                                    ])
                              ])
                            ]),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text("DATE",
                                  style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                      color: colorAccent)),
                              pw.Text(widget.quoteData['date'] ?? '',
                                  style: pw.TextStyle(
                                      fontSize: 10, color: colorNavy)),
                              pw.SizedBox(height: 6),
                              pw.Text("VALIDITE",
                                  style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                      color: colorAccent)),
                              pw.Text(widget.quoteData['validity'] ?? '',
                                  style: pw.TextStyle(
                                      fontSize: 10, color: colorNavy)),
                            ])
                      ]),
                  pw.SizedBox(height: 15),
                  // Location
                  pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                          color: PdfColors.grey50,
                          borderRadius: pw.BorderRadius.circular(6),
                          border: pw.Border.all(color: PdfColors.grey200)),
                      child: pw.Row(children: [
                        pw.Container(
                            width: 20,
                            height: 20,
                            decoration: pw.BoxDecoration(
                                color: PdfColors.white,
                                borderRadius: pw.BorderRadius.circular(4))),
                        pw.SizedBox(width: 8),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text("Lieu du chantier",
                                  style: pw.TextStyle(
                                      fontSize: 8, color: colorAccent)),
                              pw.Text(widget.quoteData['siteAddress'] ?? '',
                                  style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold,
                                      color: colorNavy)),
                            ])
                      ]))
                ],
              ),
            ),
            pw.SizedBox(height: 25),

            pw.Text("Détails du chantier",
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: colorNavy)),
            pw.SizedBox(height: 10),

            // Room Lists
            ...expenses.entries.map((entry) {
              final roomName = entry.key;
              final items = (entry.value as List).cast<Map<String, dynamic>>();

              // Calculate Room Total
              double roomTotal = 0;
              for (var i in items) {
                roomTotal += ((i['quantity'] ?? 0) * (i['laborCost'] ?? 0) +
                    (i['quantity'] ?? 0) * (i['materialCost'] ?? 0));
              }

              return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 15),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(12),
                    border: pw.Border.all(color: PdfColors.grey200),
                  ),
                  child: pw.Column(children: [
                    // Room Header
                    pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey50, // slightly darker header
                          borderRadius: pw.BorderRadius.vertical(
                              top: pw.Radius.circular(12)),
                        ),
                        child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(roomName,
                                        style: pw.TextStyle(
                                            fontWeight: pw.FontWeight.bold,
                                            fontSize: 12,
                                            color: colorNavy)),
                                    pw.Text("${items.length} prestations",
                                        style: const pw.TextStyle(
                                            fontSize: 8,
                                            color: PdfColors.grey600)),
                                  ]),
                              pw.Text("${roomTotal.toStringAsFixed(2)} €",
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 12,
                                      color: colorNavy)),
                            ])),
                    pw.Divider(height: 1, color: PdfColors.grey200),
                    // Tasks
                    ...items.map((item) {
                      final totalItem =
                          ((item['quantity'] ?? 0) * (item['laborCost'] ?? 0) +
                              (item['quantity'] ?? 0) *
                                  (item['materialCost'] ?? 0));
                      final unitPrice = (item['laborCost'] ?? 0) +
                          (item['materialCost'] ?? 0);

                      return pw.Container(
                          padding: const pw.EdgeInsets.all(12),
                          decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                  bottom:
                                      pw.BorderSide(color: PdfColors.grey100))),
                          child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text(item['title'] ?? 'Prestation',
                                          style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold,
                                              fontSize: 10,
                                              color: colorNavy)),
                                      pw.Text(
                                          "${totalItem.toStringAsFixed(2)} €",
                                          style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold,
                                              fontSize: 10,
                                              color: colorNavy)),
                                    ]),
                                pw.SizedBox(height: 4),
                                pw.Container(
                                    padding: const pw.EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: pw.BoxDecoration(
                                        color: PdfColors.grey100,
                                        borderRadius:
                                            pw.BorderRadius.circular(4)),
                                    child: pw.Text("Murs",
                                        style: const pw.TextStyle(
                                            fontSize: 8,
                                            color: PdfColors.grey700))),
                                pw.SizedBox(height: 8),

                                // Detail Row
                                pw.Row(children: [
                                  pw.Expanded(
                                      flex: 3,
                                      child: pw.Text("ELEMENT",
                                          style: const pw.TextStyle(
                                              fontSize: 7,
                                              color: PdfColors.grey500))),
                                  pw.Expanded(
                                      flex: 1,
                                      child: pw.Text("QTE",
                                          style: const pw.TextStyle(
                                              fontSize: 7,
                                              color: PdfColors.grey500))),
                                  pw.Expanded(
                                      flex: 1,
                                      child: pw.Text("P.UNIT",
                                          style: const pw.TextStyle(
                                              fontSize: 7,
                                              color: PdfColors.grey500))),
                                  pw.Expanded(
                                      flex: 1,
                                      child: pw.Text("TOTAL",
                                          style: const pw.TextStyle(
                                              fontSize: 7,
                                              color: PdfColors.grey500),
                                          textAlign: pw.TextAlign.right)),
                                ]),
                                pw.SizedBox(height: 4),
                                pw.Row(children: [
                                  pw.Expanded(
                                      flex: 3,
                                      child: pw.Row(children: [
                                        pw.Container(
                                            width: 4,
                                            height: 4,
                                            margin: const pw.EdgeInsets.only(
                                                right: 4),
                                            decoration: pw.BoxDecoration(
                                                color: PdfColors.green500,
                                                shape: pw.BoxShape.circle)),
                                        pw.Text("Matériel & Main d'oeuvre",
                                            style: const pw.TextStyle(
                                                fontSize: 8,
                                                color: PdfColors.grey800))
                                      ])),
                                  pw.Expanded(
                                      flex: 1,
                                      child: pw.Text("${item['quantity']} m²",
                                          style: const pw.TextStyle(
                                              fontSize: 8,
                                              color: PdfColors.grey800))),
                                  pw.Expanded(
                                      flex: 1,
                                      child: pw.Text(
                                          "${unitPrice.toStringAsFixed(2)} €",
                                          style: const pw.TextStyle(
                                              fontSize: 8,
                                              color: PdfColors.grey800))),
                                  pw.Expanded(
                                      flex: 1,
                                      child: pw.Text(
                                          "${totalItem.toStringAsFixed(2)} €",
                                          style: pw.TextStyle(
                                              fontSize: 8,
                                              fontWeight: pw.FontWeight.bold,
                                              color: colorNavy),
                                          textAlign: pw.TextAlign.right)),
                                ])
                              ]));
                    }).toList(),
                  ]));
            }).toList(),

            pw.SizedBox(height: 20),

            // Financial Recap
            pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: colorAccent),
                  borderRadius: pw.BorderRadius.circular(12),
                  color: PdfColors.white,
                ),
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("RECAPULATIF FINANCIER",
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                              color: colorNavy)),
                      pw.SizedBox(height: 10),
                      pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("Total HT",
                                style: const pw.TextStyle(
                                    fontSize: 10, color: PdfColors.grey700)),
                            pw.Text(
                                "${(totals['ht'] ?? 0).toStringAsFixed(2)} €",
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: colorNavy)),
                          ]),
                      pw.SizedBox(height: 5),
                      pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("TVA (10%)",
                                style: const pw.TextStyle(
                                    fontSize: 10, color: PdfColors.grey700)),
                            pw.Text(
                                "${(totals['tva'] ?? 0).toStringAsFixed(2)} €",
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: colorNavy)),
                          ]),
                      pw.SizedBox(height: 10),
                      pw.Divider(color: PdfColors.grey200),
                      pw.SizedBox(height: 10),
                      pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("Total TTC",
                                style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                    color: colorNavy)),
                            pw.Text(
                                "${(totals['ttc'] ?? 0).toStringAsFixed(2)} €",
                                style: pw.TextStyle(
                                    fontSize: 14,
                                    fontWeight: pw.FontWeight.bold,
                                    color: colorNavy)),
                          ]),
                      pw.Text("Payable à la commande",
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey500)),
                    ])),

            pw.SizedBox(height: 30),

            // Signature Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text("Signature de l'entreprise",
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: colorNavy)),
                    pw.SizedBox(height: 10),
                    if (_signatureBytes != null)
                      pw.Container(
                        height: 60,
                        width: 100,
                        child: pw.Image(
                          pw.MemoryImage(_signatureBytes!),
                          fit: pw.BoxFit.contain,
                        ),
                      )
                    else
                      pw.SizedBox(height: 60), // Space if no signature exists
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 30),

            // Footer
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
              pw.Text(
                  "Ce devis est valable 30 jours. Merci pour votre confiance.",
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey500)),
            ])
          ];
        }));
    return pdf;
  }

  Future<pw.Document> _generateFourniturePdf(
      {PdfPageFormat format = PdfPageFormat.a4}) async {
    final pdf = pw.Document();

    final company = widget.quoteData['company'] ?? {};
    final client = widget.quoteData['client'] ?? {};
    final expenses = widget.quoteData['expenses'] as Map<String, dynamic>? ?? {};
    final tasks = widget.quoteData['tasks'] as Map<String, dynamic>? ?? {};

    // Load fonts and colors
    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    final colorNavy = PdfColor.fromInt(0xFF0F172A);
    final colorCream = PdfColor.fromInt(0xFFFFF7ED);
    final colorAccent = PdfColor.fromInt(0xFFA18B73);

    final Map<String, List<Map<String, dynamic>>> fournituresByGroup = {};
    double totalMaterialCost = 0.0;
    int totalItemsCount = 0;

    if (tasks.isNotEmpty) {
      tasks.forEach((roomId, roomTasksData) {
        if (roomTasksData is! Map) return;
        final roomTasks = roomTasksData as Map<String, dynamic>;
        roomTasks.forEach((_, taskData) {
          if (taskData is! Map) return;
          final selectedFournitures =
              taskData['selectedFournitures'] as Map<String, dynamic>? ?? {};
          selectedFournitures.forEach((__, itemData) {
            if (itemData is! Map) return;
            final qty = (itemData['quantity'] as num?)?.toDouble() ?? 1;
            final unitPrice = (itemData['unitPrice'] as num?)?.toDouble() ?? 0;
            final fournisseur =
                (itemData['fournisseur'] ?? 'Sans fournisseur').toString();
            final title = (itemData['name'] ?? 'Article').toString();
            final totalLine = qty * unitPrice;
            fournituresByGroup.putIfAbsent(fournisseur, () => []);
            fournituresByGroup[fournisseur]!.add({
              'title': title,
              'quantity': qty,
              'unitPrice': unitPrice,
              'total': totalLine,
              'room': roomId,
            });
            totalMaterialCost += totalLine;
            totalItemsCount++;
          });
        });
      });
    }

    if (fournituresByGroup.isEmpty) {
      expenses.forEach((roomId, items) {
        if (items is List) {
          final List<Map<String, dynamic>> roomFournitures = [];
          for (var item in items) {
            final qty = ((item['quantity'] ?? 0) as num).toDouble();
            final materialUnitPrice =
                ((item['materialCost'] ?? 0) as num).toDouble();

            if (materialUnitPrice > 0) {
              final totalLine = qty * materialUnitPrice;
              roomFournitures.add({
                'title': item['title'] ?? 'Article',
                'quantity': qty,
                'unitPrice': materialUnitPrice,
                'total': totalLine,
              });
              totalMaterialCost += totalLine;
              totalItemsCount++;
            }
          }
          if (roomFournitures.isNotEmpty) {
            fournituresByGroup[roomId] = roomFournitures;
          }
        }
      });
    }

    pdf.addPage(pw.MultiPage(
        pageFormat: format,
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (context) {
          return [
            // Header Card
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: PdfColors.grey200),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Company Logo
                      pw.Container(
                        width: 40,
                        height: 40,
                        decoration: pw.BoxDecoration(
                          color:
                              (_logoBytes != null || _logoPath != null) ? PdfColors.white : colorNavy,
                          borderRadius: pw.BorderRadius.circular(8),
                          image: _logoBytes != null
                              ? pw.DecorationImage(
                                  image: pw.MemoryImage(_logoBytes!),
                                  fit: pw.BoxFit.cover,
                                )
                              : _logoPath != null
                                  ? pw.DecorationImage(
                                      image: pw.MemoryImage(
                                        File(_logoPath!).readAsBytesSync(),
                                      ),
                                      fit: pw.BoxFit.cover,
                                    )
                                  : null,
                        ),
                        child: (_logoBytes == null && _logoPath == null)
                            ? pw.Center(
                                child: pw.PdfLogo(color: PdfColors.white))
                            : null,
                      ),
                      pw.SizedBox(width: 12),
                      // Company Details
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(company['name'] ?? 'Koji ',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 14,
                                    color: colorNavy)),
                            pw.Text(company['address'] ?? '',
                                style: const pw.TextStyle(
                                    fontSize: 9, color: PdfColors.grey600)),
                          ],
                        ),
                      ),
                      // Document Title
                      pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: pw.BoxDecoration(
                              color: colorCream,
                              borderRadius: pw.BorderRadius.circular(6)),
                          child: pw.Column(children: [
                            pw.Text("LISTE DE",
                                style: pw.TextStyle(
                                    fontSize: 8, color: colorAccent)),
                            pw.Text("FOURNITURES",
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10,
                                    color: colorNavy)),
                          ]))
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(color: PdfColors.grey100),
                  pw.SizedBox(height: 20),
                  // Client Row
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(children: [
                                pw.Container(
                                    width: 4,
                                    height: 4,
                                    decoration: pw.BoxDecoration(
                                        color: colorAccent,
                                        shape: pw.BoxShape.circle)),
                                pw.SizedBox(width: 4),
                                pw.Text("POUR LE DEVIS N°",
                                    style: pw.TextStyle(
                                        fontSize: 8,
                                        fontWeight: pw.FontWeight.bold,
                                        color: colorAccent)),
                              ]),
                              pw.SizedBox(height: 6),
                              pw.Text(_quoteNumber,
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 12,
                                      color: colorNavy)),
                            ]),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text("CLIENT",
                                  style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                      color: colorAccent)),
                              pw.Text(client['name'] ?? '',
                                  style: pw.TextStyle(
                                      fontSize: 10, color: colorNavy)),
                            ])
                      ]),
                ],
              ),
            ),
            pw.SizedBox(height: 25),

            pw.Text("Liste des fournitures par fournisseur",
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: colorNavy)),
            pw.SizedBox(height: 10),

            // Group Lists
            if (fournituresByGroup.isEmpty)
              pw.Text("Aucune fourniture nécessaire.",
                  style: const pw.TextStyle(
                      fontSize: 12, color: PdfColors.grey600))
            else
              ...fournituresByGroup.entries.map((entry) {
                final groupName = entry.key;
                final items = entry.value;

                return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 15),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(12),
                      border: pw.Border.all(color: PdfColors.grey200),
                    ),
                    child: pw.Column(children: [
                      // Group Header
                      pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.grey50,
                            borderRadius: pw.BorderRadius.vertical(
                                top: pw.Radius.circular(12)),
                          ),
                          child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(groupName,
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 12,
                                        color: colorNavy)),
                                pw.Text("${items.length} articles",
                                    style: const pw.TextStyle(
                                        fontSize: 10,
                                        color: PdfColors.grey600)),
                              ])),
                      pw.Divider(height: 1, color: PdfColors.grey200),
                      // Fournitures items
                      ...items.map((item) {
                        return pw.Container(
                            padding: const pw.EdgeInsets.all(12),
                            decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                    bottom: pw.BorderSide(
                                        color: PdfColors.grey100))),
                            child: pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Expanded(
                                      flex: 3,
                                      child: pw.Text(item['title'] ?? '',
                                          style: pw.TextStyle(
                                              fontSize: 10, color: colorNavy))),
                                  pw.Expanded(
                                      flex: 2,
                                      child: pw.Text(
                                          "${item['quantity']} × ${(item['unitPrice'] as double).toStringAsFixed(2)} €",
                                          style: const pw.TextStyle(
                                              fontSize: 10,
                                              color: PdfColors.grey600))),
                                  pw.Expanded(
                                      flex: 1,
                                      child: pw.Text(
                                          "${(item['total'] as double).toStringAsFixed(2)} €",
                                          style: pw.TextStyle(
                                              fontSize: 10,
                                              fontWeight: pw.FontWeight.bold,
                                              color: colorNavy),
                                          textAlign: pw.TextAlign.right)),
                                ]));
                      }).toList(),
                    ]));
              }).toList(),

            pw.SizedBox(height: 20),

            // Total Recap
            pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: colorAccent),
                  borderRadius: pw.BorderRadius.circular(12),
                  color: PdfColors.white,
                ),
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("TOTAL DES MATÉRIAUX",
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10,
                                    color: colorNavy)),
                            pw.Text("$totalItemsCount éléments au total",
                                style: const pw.TextStyle(
                                    fontSize: 8, color: PdfColors.grey500)),
                          ]),
                      pw.Text("${totalMaterialCost.toStringAsFixed(2)} €",
                          style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: colorNavy)),
                    ])),
          ];
        }));
    return pdf;
  }

  Future<void> _openPdf(bool isDevis) async {
    final pdf = isDevis ? await _generatePdf() : await _generateFourniturePdf();
    final name = isDevis ? 'Devis_${_quoteNumber}.pdf' : 'Fournitures_${_quoteNumber}.pdf';
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: name,
    );
  }

  Future<void> _downloadPdf(bool isDevis) async {
    try {
      final pdf = isDevis ? await _generatePdf() : await _generateFourniturePdf();
      final name = isDevis ? 'Devis_${_quoteNumber}.pdf' : 'Fournitures_${_quoteNumber}.pdf';
      final bytes = await pdf.save();

      String? savedPath;

      if (Platform.isAndroid) {
        // Try saving to public Downloads folder directly
        try {
          final downloadDir = Directory('/storage/emulated/0/Download');
          if (await downloadDir.exists()) {
            final file = File('${downloadDir.path}/$name');
            await file.writeAsBytes(bytes);
            savedPath = file.path;
          }
        } catch (e) {
          debugPrint("Primary Android download failed: $e");
        }
      }

      if (savedPath != null) {
        // Success - Native Download
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("✅ PDF téléchargé : $savedPath"),
            backgroundColor: const Color(0xFF22C55E),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
                label: "Ouvrir", textColor: Colors.white, onPressed: () => _openPdf(isDevis)),
          ));
        }
      } else {
        // Fallback: App Documents + Share/Save Intent
        final output = await getApplicationDocumentsDirectory();
        final file = File('${output.path}/$name');
        await file.writeAsBytes(bytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                "⚠️ Sauvegarde directe impossible. Veuillez choisir 'Enregistrer' dans le menu."),
            backgroundColor: Color(0xFFA18B73),
            duration: Duration(seconds: 3),
          ));
          await Printing.sharePdf(bytes: bytes, filename: name);
        }
      }
    } catch (e) {
      debugPrint("Error downloading: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erreur lors du téléchargement")));
      }
    }
  }

  Future<void> _sharePdf(bool isDevis) async {
    final pdf = isDevis ? await _generatePdf() : await _generateFourniturePdf();
    final name = isDevis ? 'Devis_${_quoteNumber}.pdf' : 'Fournitures_${_quoteNumber}.pdf';
    await Printing.sharePdf(
        bytes: await pdf.save(), filename: name);
  }

  Future<void> _shareSignatureLink() async {
    try {
      final client = widget.quoteData['client'] as Map<String, dynamic>? ?? {};
      final totals = widget.quoteData['totals'] as Map<String, dynamic>? ?? {};
      final quoteId = widget.quoteId;

      final clientEmail = client['email'] as String? ?? '';
      final clientName = client['name'] as String? ?? 'Client';
      final totalAmount = (totals['ttc'] as num?)?.toDouble() ?? 0.0;

      // Generate signature URL
      final signatureUrl =
          'https://koji-signature.vercel.app/?quoteId=$quoteId&email=${Uri.encodeComponent(clientEmail)}';

      // Create share message
      final shareMessage = '''
Bonjour $clientName,

Votre devis #$_quoteNumber est prêt pour signature.

📋 Montant total: ${totalAmount.toStringAsFixed(2)} €

Pour consulter et signer votre devis, cliquez sur le lien ci-dessous:
$signatureUrl

Ce devis est valable 30 jours.

Merci pour votre confiance,
Koji Rénovation
''';

      // Show dialog with sharing options
      if (mounted) {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).dialogBackgroundColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Color(0xFFA18B73),
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Envoyer le Lien',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppTheme.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choisissez comment envoyer le lien de signature',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SMS Option
                    _buildShareOption(
                      icon: Icons.message_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      backgroundColor: const Color(0xFFEFF6FF),
                      title: 'SMS',
                      subtitle: 'Envoyer par message',
                      onTap: () async {
                        Navigator.pop(context);
                        try {
                          final phoneNumber = client['phone'] as String? ?? '';
                          final smsUrl = Platform.isAndroid
                              ? 'sms:$phoneNumber?body=${Uri.encodeComponent(shareMessage)}'
                              : 'sms:$phoneNumber&body=${Uri.encodeComponent(shareMessage)}';

                          await launchUrl(
                            Uri.parse(smsUrl),
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (e) {
                          debugPrint('Error launching SMS: $e');
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "❌ Impossible d'ouvrir l'application SMS"),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // WhatsApp Option
                    _buildShareOption(
                      icon: Icons.chat_bubble_rounded,
                      iconColor: const Color(0xFF22C55E),
                      backgroundColor: const Color(0xFFF0FDF4),
                      title: 'WhatsApp',
                      subtitle: 'Envoyer via WhatsApp',
                      onTap: () async {
                        Navigator.pop(context);
                        try {
                          final phoneNumber = (client['phone'] as String? ?? '')
                              .replaceAll(RegExp(r'[^\d+]'), '');
                          final whatsappUrl =
                              'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(shareMessage)}';

                          await launchUrl(
                            Uri.parse(whatsappUrl),
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (e) {
                          debugPrint('Error launching WhatsApp: $e');
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "❌ WhatsApp n'est pas installé ou impossible à ouvrir"),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Email/Gmail Option
                    _buildShareOption(
                      icon: Icons.email_rounded,
                      iconColor: const Color(0xFFEF4444),
                      backgroundColor: const Color(0xFFFEF2F2),
                      title: 'Email',
                      subtitle: 'Envoyer par email',
                      onTap: () async {
                        Navigator.pop(context);
                        try {
                          final emailSubject = Uri.encodeComponent(
                              'Devis #$_quoteNumber - Signature requise');
                          final emailBody = Uri.encodeComponent(shareMessage);
                          final emailUrl =
                              'mailto:$clientEmail?subject=$emailSubject&body=$emailBody';

                          await launchUrl(
                            Uri.parse(emailUrl),
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (e) {
                          debugPrint('Error launching Email: $e');
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "❌ Impossible d'ouvrir l'application email"),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Cancel Button
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: Text(
                        'Annuler',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      debugPrint("Error sharing link: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Erreur: ${e.toString()}"),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Widget _buildShareOption({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : AppTheme.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).primaryColor, size: 20),
            onPressed: () => context.go('/home'),
          ),
        ),
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'Détails de la Pièce(s)',
              style: AppTheme.headingStyle(context).copyWith(fontSize: 18),
            ),
            Text(
              'Etape 5/5',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(responsive.width(5)),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Success Card
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Check Icon
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFF22C55E), width: 3),
                            ),
                            child: const Center(
                              child: Icon(Icons.check,
                                  color: Color(0xFF22C55E), size: 50),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4)
                                ]),
                            child: const Icon(Icons.description_outlined,
                                size: 16, color: Color(0xFF6B7280)),
                          )
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Devis prêt !",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkNavy,
                        ),
                      ),
                      const SizedBox(height: 12),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF6B7280)),
                          children: [
                            const TextSpan(text: "Le devis "),
                            TextSpan(
                              text: "#${_quoteNumber}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkNavy),
                            ),
                            const TextSpan(text: " a été généré avec succès."),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Progress Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("PROGRESSION",
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFA18B73))),
                          Text(_isGenerating ? "90%" : "100%",
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF22C55E))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _isGenerating ? 0.9 : 1.0,
                        backgroundColor: const Color(0xFFE5E7EB),
                        color: const Color(0xFF22C55E),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // PDF Preview Card
                // Devis PDF Section
                if (!_isGenerating) ...[
                  const SizedBox(height: 16),
                  _buildPdfCard(
                    title: "Devis_Final_${_quoteNumber}.pdf",
                    subtitle: "PDF Devis (A4)",
                    icon: Icons.picture_as_pdf,
                    iconColor: const Color(0xFFEF4444),
                    onOpen: () => _openPdf(true),
                    onDownload: () => _downloadPdf(true),
                    onShare: () => _sharePdf(true),
                  ),

                  const SizedBox(height: 24),
                  
                  // Fournitures PDF Section
                  _buildPdfCard(
                    title: "Fournitures_${_quoteNumber}.pdf",
                    subtitle: "Liste de Matériaux (A4)",
                    icon: Icons.inventory_2_outlined,
                    iconColor: const Color(0xFF3B82F6),
                    onOpen: () => _openPdf(false),
                    onDownload: () => _downloadPdf(false),
                    onShare: () => _sharePdf(false),
                  ),
                ],

                const SizedBox(height: 32),

                // Share Signature Link Button
                ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _shareSignatureLink,
                  icon: const Icon(Icons.send_outlined, size: 20),
                  label: const Text("Envoyer le Lien de Signature"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA18B73),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPdfCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onOpen,
    required VoidCallback onDownload,
    required VoidCallback onShare,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: iconColor.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppTheme.darkNavy,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_red_eye_outlined,
                    color: Color(0xFF6B7280)),
                onPressed: onOpen,
              )
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text("Télécharger"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkNavy,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share, size: 18),
                label: const Text("Partager"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.darkNavy,
                  side: const BorderSide(color: AppTheme.darkNavy),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

