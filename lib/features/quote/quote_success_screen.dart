import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For consolidateHttpClientResponseBytes
import 'package:flutter/services.dart' show rootBundle; // For bundled Koji logo
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
  // Bundled Koji logo bytes, reused for the watermark and the footer mark.
  Uint8List? _kojiLogoBytes;

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

    final company = widget.quoteData['company'] ?? {};
    final client = widget.quoteData['client'] ?? {};
    final totals = widget.quoteData['totals'] ?? {};
    final expenses =
        widget.quoteData['expenses'] as Map<String, dynamic>? ?? {};

    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    final colorNavy = PdfColor.fromInt(0xFF0F172A);
    final colorAccent = PdfColor.fromInt(0xFFA18B73);

    // Bundled Koji logo, used as a faint background watermark on every page
    // and as a small mark in the footer.
    pw.MemoryImage? kojiWatermark;
    try {
      _kojiLogoBytes ??= (await rootBundle.load('assets/icons/LOGO.png')).buffer.asUint8List();
      kojiWatermark = pw.MemoryImage(_kojiLogoBytes!);
    } catch (e) {
      debugPrint('Could not load Koji watermark: $e');
    }

    final siteAddress = (widget.quoteData['siteAddress'] as String?) ?? '';
    final travauxLieu = siteAddress.isNotEmpty
        ? siteAddress
        : (client['address']?.toString() ?? '');
    final travauxStart = (widget.quoteData['travauxStart'] as String?) ?? '';
    final travauxDuration = (widget.quoteData['travauxDuration'] as String?) ?? '';

    pdf.addPage(pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: format,
          theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
          // Faint Koji logo watermark, centered behind the content on every page.
          buildBackground: (context) => kojiWatermark == null
              ? pw.SizedBox()
              : pw.Center(
                  child: pw.Opacity(
                    opacity: 0.04,
                    child: pw.Image(kojiWatermark, width: 320, height: 320),
                  ),
                ),
        ),
        // Legal footer (pied de page) repeated on every page, like classic
        // French devis: company identification in small print, plus "Créé par Koji".
        footer: (context) => _buildLegalFooter(context, company, colorAccent),
        build: (context) {
          return [
            // ── Header ─────────────────────────────────────────────────────
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 50,
                  height: 50,
                  decoration: pw.BoxDecoration(
                    color: (_logoBytes != null || _logoPath != null) ? PdfColors.white : colorNavy,
                    borderRadius: pw.BorderRadius.circular(8),
                    image: _logoBytes != null
                        ? pw.DecorationImage(
                            image: pw.MemoryImage(_logoBytes!), fit: pw.BoxFit.cover)
                        : _logoPath != null
                            ? pw.DecorationImage(
                                image: pw.MemoryImage(File(_logoPath!).readAsBytesSync()),
                                fit: pw.BoxFit.cover)
                            : null,
                  ),
                  child: (_logoBytes == null && _logoPath == null)
                      ? pw.Center(child: pw.PdfLogo(color: PdfColors.white))
                      : null,
                ),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(company['name'] ?? 'Koji',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: colorNavy)),
                      pw.Text(company['address'] ?? '', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.Text(company['phone'] ?? '', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.Text(company['email'] ?? '', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    ],
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFFFF7ED),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("DEVIS N°", style: pw.TextStyle(fontSize: 8, color: colorAccent)),
                      pw.Text(_quoteNumber,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: colorNavy)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 16),

            // ── Client & Date ───────────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("CLIENT", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: colorAccent)),
                    pw.SizedBox(height: 4),
                    pw.Text(client['name'] ?? 'Client',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: colorNavy)),
                    pw.Text(client['address'] ?? '', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("DATE", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: colorAccent)),
                    pw.Text(widget.quoteData['date'] ?? '', style: pw.TextStyle(fontSize: 11, color: colorNavy)),
                    pw.SizedBox(height: 4),
                    pw.Text("VALIDITÉ", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: colorAccent)),
                    pw.Text(widget.quoteData['validity'] ?? '', style: pw.TextStyle(fontSize: 11, color: colorNavy)),
                  ],
                ),
              ],
            ),
            if ((widget.quoteData['siteAddress'] as String?)?.isNotEmpty ?? false) ...[
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey200),
                ),
                child: pw.Row(children: [
                  pw.Text("Lieu : ", style: pw.TextStyle(fontSize: 9, color: colorAccent)),
                  pw.Text(widget.quoteData['siteAddress'] ?? '',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: colorNavy)),
                ]),
              ),
            ],

            pw.SizedBox(height: 20),

            // ── Table Header ────────────────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: pw.BoxDecoration(color: colorNavy, borderRadius: pw.BorderRadius.circular(6)),
              child: pw.Row(children: [
                pw.Expanded(flex: 4, child: pw.Text("DÉSIGNATION", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                pw.Expanded(flex: 1, child: pw.Text("QTÉ", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white), textAlign: pw.TextAlign.center)),
                pw.Expanded(flex: 1, child: pw.Text("P.UNIT", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white), textAlign: pw.TextAlign.center)),
                pw.Expanded(flex: 1, child: pw.Text("TOTAL HT", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white), textAlign: pw.TextAlign.right)),
              ]),
            ),

            // ── Room Sections ───────────────────────────────────────────────
            ...expenses.entries.map((entry) {
              final roomName = entry.key;
              final items = (entry.value as List).cast<Map<String, dynamic>>();

              double roomTotal = 0;
              for (var i in items) {
                roomTotal += ((i['quantity'] ?? 0) * (i['laborCost'] ?? 0) +
                    (i['quantity'] ?? 0) * (i['materialCost'] ?? 0));
              }

              return pw.Column(children: [
                pw.SizedBox(height: 12),
                pw.Text(roomName.toUpperCase(),
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: colorAccent)),
                pw.SizedBox(height: 6),
                ...items.map((item) {
                  final totalItem = ((item['quantity'] ?? 0) * (item['laborCost'] ?? 0) +
                      (item['quantity'] ?? 0) * (item['materialCost'] ?? 0));
                  final unitPrice = (item['laborCost'] ?? 0) + (item['materialCost'] ?? 0);
                  final qty = item['quantity'] ?? 0;

                  return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
                    child: pw.Row(children: [
                      pw.Expanded(flex: 4, child: pw.Text(item['title'] ?? 'Prestation',
                          style: pw.TextStyle(fontSize: 10, color: colorNavy))),
                      pw.Expanded(flex: 1, child: pw.Text("$qty",
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700), textAlign: pw.TextAlign.center)),
                      pw.Expanded(flex: 1, child: pw.Text("${unitPrice.toStringAsFixed(2)} €",
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700), textAlign: pw.TextAlign.center)),
                      pw.Expanded(flex: 1, child: pw.Text("${totalItem.toStringAsFixed(2)} €",
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: colorNavy),
                          textAlign: pw.TextAlign.right)),
                    ]),
                  );
                }).toList(),
                // Room subtotal
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(color: PdfColors.grey50, borderRadius: pw.BorderRadius.circular(4)),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Sous-total $roomName",
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: colorNavy)),
                      pw.Text("${roomTotal.toStringAsFixed(2)} €",
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: colorNavy)),
                    ],
                  ),
                ),
              ]);
            }).toList(),

            pw.SizedBox(height: 20),

            // ── Mentions obligatoires (lieu / dates / durée) ─────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("MENTIONS LÉGALES DU CHANTIER",
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: colorAccent)),
                  pw.SizedBox(height: 4),
                  pw.Text("Lieu d'exécution des travaux : ${travauxLieu.isNotEmpty ? travauxLieu : '____________________'}",
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                  pw.SizedBox(height: 2),
                  pw.Text("Date de début des travaux : ${travauxStart.isNotEmpty ? travauxStart : '____________________'}",
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                  pw.SizedBox(height: 2),
                  pw.Text("Durée des travaux : ${travauxDuration.isNotEmpty ? travauxDuration : '____________________'}",
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // ── Financial Summary ───────────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: colorAccent),
                borderRadius: pw.BorderRadius.circular(8),
                color: PdfColors.white,
              ),
              child: pw.Column(children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Total HT", style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                    pw.Text("${(totals['ht'] ?? 0).toStringAsFixed(2)} €",
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: colorNavy)),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("TVA 20%", style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                    pw.Text("${(totals['tva'] ?? 0).toStringAsFixed(2)} €",
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: colorNavy)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Total TTC",
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: colorNavy)),
                    pw.Text("${(totals['ttc'] ?? 0).toStringAsFixed(2)} €",
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: colorNavy)),
                  ],
                ),
              ]),
            ),

            pw.SizedBox(height: 20),

            // ── Conditions de règlement (échéancier / mode / RIB) ────────────
            _buildPaymentTerms(company, totals, colorNavy, colorAccent),

            pw.SizedBox(height: 20),

            // ── Signatures (entreprise + client avec mention manuscrite) ─────
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // Client side: Fait à / le + mention "Lu et approuvé, bon pour accord"
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Signature du client",
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: colorNavy)),
                      pw.SizedBox(height: 4),
                      pw.Text("Fait à ______________  le ____________",
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      pw.SizedBox(height: 4),
                      pw.Text("Mention manuscrite obligatoire :",
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      pw.Text("« Lu et approuvé, bon pour accord »",
                          style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, fontWeight: pw.FontWeight.bold, color: colorNavy)),
                      pw.SizedBox(height: 40),
                    ],
                  ),
                ),
                pw.SizedBox(width: 24),
                // Company side
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text("Signature de l'entreprise",
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: colorNavy)),
                    pw.SizedBox(height: 8),
                    if (_signatureBytes != null)
                      pw.Container(height: 50, width: 90,
                          child: pw.Image(pw.MemoryImage(_signatureBytes!), fit: pw.BoxFit.contain))
                    else
                      pw.SizedBox(height: 50),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Text("Ce devis est valable 30 jours. Merci pour votre confiance.",
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
            ),
          ];
        }));
    return pdf;
  }

  // ── Conditions de règlement (échéancier de paiement) ─────────────────────────
  // States in writing how the payment is split: 30% à la signature, 50% en
  // cours de chantier, 20% à la réception (réserves). Amounts computed from TTC.
  pw.Widget _buildPaymentTerms(
      Map<dynamic, dynamic> company, Map<dynamic, dynamic> totals, PdfColor colorNavy, PdfColor colorAccent) {
    final ttc = (totals['ttc'] as num?)?.toDouble() ?? 0.0;
    String money(double v) => '${v.toStringAsFixed(2)} €';

    final schedule = <List<String>>[
      ['Acompte à la signature', '30 %', money(ttc * 0.30)],
      ['En cours de chantier', '50 %', money(ttc * 0.50)],
      ['Solde à la réception (réserves levées)', '20 %', money(ttc * 0.20)],
    ];

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("CONDITIONS DE RÈGLEMENT",
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: colorAccent)),
          pw.SizedBox(height: 6),
          // Échéancier rows
          ...schedule.map((row) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Row(
                  children: [
                    pw.Expanded(flex: 5, child: pw.Text(row[0],
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800))),
                    pw.Expanded(flex: 1, child: pw.Text(row[1],
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: colorNavy),
                        textAlign: pw.TextAlign.center)),
                    pw.Expanded(flex: 2, child: pw.Text(row[2],
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: colorNavy),
                        textAlign: pw.TextAlign.right)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Legal footer (pied de page) — company identification in small print ──────
  pw.Widget _buildLegalFooter(
      pw.Context context, Map<dynamic, dynamic> company, PdfColor colorAccent) {
    final parts = <String>[];
    final name = company['name']?.toString() ?? '';
    final legalForm = company['formeJuridique']?.toString() ?? '';
    final address = company['address']?.toString() ?? '';
    final siret = company['siret']?.toString() ?? '';
    final rcs = company['rcs']?.toString() ?? '';
    final tva = company['tva']?.toString() ?? '';

    if (name.isNotEmpty) parts.add(legalForm.isNotEmpty ? '$name ($legalForm)' : name);
    if (address.isNotEmpty) parts.add('Siège : $address');
    if (siret.isNotEmpty) parts.add('SIRET : $siret');
    if (rcs.isNotEmpty) parts.add('RCS/SIREN : $rcs');
    if (tva.isNotEmpty) parts.add('TVA : $tva');

    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            parts.join('  •  '),
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 2),
          // Page number (left) and the small "Créé par Kôji" mark (right side).
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Page ${context.pageNumber} / ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
                ),
              ),
              pw.Text(
                'Créé par ',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
              ),
              if (_kojiLogoBytes != null) ...[
                pw.Image(pw.MemoryImage(_kojiLogoBytes!), width: 8, height: 8),
                pw.SizedBox(width: 2),
              ],
              pw.Text(
                'Kôji',
                style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: colorAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<pw.Document> _generateFourniturePdf(
      {PdfPageFormat format = PdfPageFormat.a4}) async {
    final pdf = pw.Document();

    final company = widget.quoteData['company'] ?? {};
    final client = widget.quoteData['client'] ?? {};
    final expenses = widget.quoteData['expenses'] as Map<String, dynamic>? ?? {};
    final tasks = widget.quoteData['tasks'] as Map<String, dynamic>? ?? {};

    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    final colorNavy = PdfColor.fromInt(0xFF0F172A);
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
        footer: (context) => _buildLegalFooter(context, company, colorAccent),
        build: (context) {
          return [
            // ─ Header ─────────────────────────────────────────────────────
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 50,
                  height: 50,
                  decoration: pw.BoxDecoration(
                    color: (_logoBytes != null || _logoPath != null) ? PdfColors.white : colorNavy,
                    borderRadius: pw.BorderRadius.circular(8),
                    image: _logoBytes != null
                        ? pw.DecorationImage(
                            image: pw.MemoryImage(_logoBytes!), fit: pw.BoxFit.cover)
                        : _logoPath != null
                            ? pw.DecorationImage(
                                image: pw.MemoryImage(File(_logoPath!).readAsBytesSync()),
                                fit: pw.BoxFit.cover)
                            : null,
                  ),
                  child: (_logoBytes == null && _logoPath == null)
                      ? pw.Center(child: pw.PdfLogo(color: PdfColors.white))
                      : null,
                ),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(company['name'] ?? 'Koji',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: colorNavy)),
                      pw.Text(company['address'] ?? '', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    ],
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFFFF7ED),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("LISTE DE", style: pw.TextStyle(fontSize: 8, color: colorAccent)),
                      pw.Text("FOURNITURES",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: colorNavy)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 16),

            // ── Quote Info ──────────────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("DEVIS N°", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: colorAccent)),
                    pw.Text(_quoteNumber,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: colorNavy)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("CLIENT", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: colorAccent)),
                    pw.Text(client['name'] ?? '', style: pw.TextStyle(fontSize: 11, color: colorNavy)),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // ─ Table Header ────────────────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: pw.BoxDecoration(color: colorNavy, borderRadius: pw.BorderRadius.circular(6)),
              child: pw.Row(children: [
                pw.Expanded(flex: 4, child: pw.Text("FOURNITURE", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                pw.Expanded(flex: 2, child: pw.Text("QTÉ × P.UNIT", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white), textAlign: pw.TextAlign.center)),
                pw.Expanded(flex: 1, child: pw.Text("TOTAL HT", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white), textAlign: pw.TextAlign.right)),
              ]),
            ),

            // ─ Group Lists ─────────────────────────────────────────────────
            if (fournituresByGroup.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.all(20),
                child: pw.Center(
                  child: pw.Text("Aucune fourniture nécessaire.",
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                ),
              )
            else
              ...fournituresByGroup.entries.map((entry) {
                final groupName = entry.key;
                final items = entry.value;

                return pw.Column(children: [
                  pw.SizedBox(height: 12),
                  pw.Text(groupName.toUpperCase(),
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: colorAccent)),
                  pw.SizedBox(height: 6),
                  ...items.map((item) {
                    return pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
                      child: pw.Row(children: [
                        pw.Expanded(flex: 4, child: pw.Text(item['title'] ?? '',
                            style: pw.TextStyle(fontSize: 10, color: colorNavy))),
                        pw.Expanded(flex: 2, child: pw.Text(
                            "${item['quantity']} × ${(item['unitPrice'] as double).toStringAsFixed(2)} €",
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700), textAlign: pw.TextAlign.center)),
                        pw.Expanded(flex: 1, child: pw.Text(
                            "${(item['total'] as double).toStringAsFixed(2)} €",
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: colorNavy),
                            textAlign: pw.TextAlign.right)),
                      ]),
                    );
                  }).toList(),
                ]);
              }).toList(),

            pw.SizedBox(height: 20),

            // ── Total ───────────────────────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: colorAccent),
                borderRadius: pw.BorderRadius.circular(8),
                color: PdfColors.white,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("TOTAL DES MATÉRIAUX",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: colorNavy)),
                      pw.Text("$totalItemsCount éléments",
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
                    ],
                  ),
                  pw.Text("${totalMaterialCost.toStringAsFixed(2)} €",
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: colorNavy)),
                ],
              ),
            ),
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

  String _generateWordHtml(bool isDevis) {
    final company = widget.quoteData['company'] ?? {};
    final client = widget.quoteData['client'] ?? {};
    final totals = widget.quoteData['totals'] ?? {};
    final expenses = widget.quoteData['expenses'] as Map<String, dynamic>? ?? {};

    final sb = StringBuffer();
    sb.write('''
<html xmlns:o="urn:schemas-microsoft-com:office:office"
      xmlns:w="urn:schemas-microsoft-com:office:word"
      xmlns="http://www.w3.org/TR/REC-html40">
<head><meta charset="utf-8">
<style>
  body { font-family: Arial, sans-serif; font-size: 11pt; color: #0F172A; margin: 40px; }
  .header { display: flex; justify-content: space-between; margin-bottom: 20px; }
  .company { font-size: 14pt; font-weight: bold; }
  .company-detail { font-size: 9pt; color: #6B7280; }
  .quote-box { background: #FFF7ED; padding: 8px 16px; border-radius: 6px; text-align: right; }
  .quote-label { font-size: 8pt; color: #A18B73; }
  .quote-number { font-size: 12pt; font-weight: bold; }
  .divider { border-bottom: 1px solid #E5E7EB; margin: 16px 0; }
  .client-row { display: flex; justify-content: space-between; margin-bottom: 16px; }
  .section-label { font-size: 8pt; font-weight: bold; color: #A18B73; }
  .client-name { font-size: 12pt; font-weight: bold; }
  .date-text { font-size: 11pt; }
  table { width: 100%; border-collapse: collapse; margin-top: 16px; }
  th { background: #0F172A; color: white; padding: 8px 12px; font-size: 9pt; text-align: left; }
  td { padding: 8px 12px; border-bottom: 1px solid #E5E7EB; font-size: 10pt; }
  .room-title { font-size: 10pt; font-weight: bold; color: #A18B73; margin-top: 16px; }
  .subtotal { background: #F9FAFB; font-weight: bold; }
  .totals-box { border: 1px solid #A18B73; border-radius: 8px; padding: 16px; margin-top: 20px; }
  .total-row { display: flex; justify-content: space-between; margin-bottom: 6px; }
  .total-ht { font-size: 11pt; }
  .total-ttc { font-size: 14pt; font-weight: bold; border-top: 1px solid #E5E7EB; padding-top: 8px; margin-top: 8px; }
  .footer { text-align: center; font-size: 8pt; color: #9CA3AF; margin-top: 30px; }
</style>
</head><body>
''');

    if (isDevis) {
      sb.write('''
<div class="header">
  <div>
    <div class="company">${company['name'] ?? 'Koji'}</div>
    <div class="company-detail">${company['address'] ?? ''}</div>
    <div class="company-detail">${company['phone'] ?? ''}</div>
    <div class="company-detail">${company['email'] ?? ''}</div>
  </div>
  <div class="quote-box">
    <div class="quote-label">DEVIS N°</div>
    <div class="quote-number">$_quoteNumber</div>
  </div>
</div>
<div class="divider"></div>
<div class="client-row">
  <div>
    <div class="section-label">CLIENT</div>
    <div class="client-name">${client['name'] ?? 'Client'}</div>
    <div class="company-detail">${client['address'] ?? ''}</div>
  </div>
  <div style="text-align:right;">
    <div class="section-label">DATE</div>
    <div class="date-text">${widget.quoteData['date'] ?? ''}</div>
    <div class="section-label" style="margin-top:4px;">VALIDITÉ</div>
    <div class="date-text">${widget.quoteData['validity'] ?? ''}</div>
  </div>
</div>
<table>
  <tr><th>DÉSIGNATION</th><th style="text-align:center;">QTÉ</th><th style="text-align:center;">P.UNIT</th><th style="text-align:right;">TOTAL HT</th></tr>
''');

      expenses.forEach((roomName, items) {
        if (items is List) {
          double roomTotal = 0;
          for (var item in items) {
            roomTotal += ((item['quantity'] ?? 0) * (item['laborCost'] ?? 0) +
                (item['quantity'] ?? 0) * (item['materialCost'] ?? 0));
          }
          sb.write('<tr><td colspan="4" class="room-title">$roomName</td></tr>');
          for (var item in items) {
            final totalItem = ((item['quantity'] ?? 0) * (item['laborCost'] ?? 0) +
                (item['quantity'] ?? 0) * (item['materialCost'] ?? 0));
            final unitPrice = (item['laborCost'] ?? 0) + (item['materialCost'] ?? 0);
            final qty = item['quantity'] ?? 0;
            sb.write('<tr><td>${item['title'] ?? 'Prestation'}</td><td style="text-align:center;">$qty</td><td style="text-align:center;">${unitPrice.toStringAsFixed(2)} €</td><td style="text-align:right;font-weight:bold;">${totalItem.toStringAsFixed(2)} €</td></tr>');
          }
          sb.write('<tr class="subtotal"><td colspan="3">Sous-total</td><td style="text-align:right;">${roomTotal.toStringAsFixed(2)} €</td></tr>');
        }
      });

      sb.write('</table>');
      sb.write('''
<div class="totals-box">
  <div class="total-row"><span>Total HT</span><span>${(totals['ht'] ?? 0).toStringAsFixed(2)} €</span></div>
  <div class="total-row"><span>TVA 20%</span><span>${(totals['tva'] ?? 0).toStringAsFixed(2)} €</span></div>
  <div class="total-row total-ttc"><span>Total TTC</span><span>${(totals['ttc'] ?? 0).toStringAsFixed(2)} €</span></div>
</div>
''');
    } else {
      final tasks = widget.quoteData['tasks'] as Map<String, dynamic>? ?? {};
      final Map<String, List<Map<String, dynamic>>> byGroup = {};
      double totalCost = 0;
      int totalCount = 0;

      if (tasks.isNotEmpty) {
        tasks.forEach((roomId, roomData) {
          if (roomData is Map) {
            roomData.forEach((_, taskData) {
              if (taskData is Map) {
                final sf = taskData['selectedFournitures'] as Map<String, dynamic>? ?? {};
                sf.forEach((__, itemData) {
                  if (itemData is Map) {
                    final qty = (itemData['quantity'] as num?)?.toDouble() ?? 1;
                    final price = (itemData['unitPrice'] as num?)?.toDouble() ?? 0;
                    final fournisseur = (itemData['fournisseur'] ?? 'Divers').toString();
                    final totalLine = qty * price;
                    byGroup.putIfAbsent(fournisseur, () => []);
                    byGroup[fournisseur]!.add({'title': itemData['name'] ?? 'Article', 'quantity': qty, 'unitPrice': price, 'total': totalLine});
                    totalCost += totalLine;
                    totalCount++;
                  }
                });
              }
            });
          }
        });
      }

      sb.write('''
<div class="header">
  <div>
    <div class="company">${company['name'] ?? 'Koji'}</div>
    <div class="company-detail">${company['address'] ?? ''}</div>
  </div>
  <div class="quote-box">
    <div class="quote-label">LISTE DE</div>
    <div class="quote-number">FOURNITURES</div>
  </div>
</div>
<div class="divider"></div>
<div class="client-row">
  <div>
    <div class="section-label">DEVIS N°</div>
    <div class="client-name">$_quoteNumber</div>
  </div>
  <div style="text-align:right;">
    <div class="section-label">CLIENT</div>
    <div class="date-text">${client['name'] ?? ''}</div>
  </div>
</div>
<table>
  <tr><th>FOURNITURE</th><th style="text-align:center;">QTÉ × P.UNIT</th><th style="text-align:right;">TOTAL HT</th></tr>
''');

      byGroup.forEach((groupName, items) {
        sb.write('<tr><td colspan="3" class="room-title">$groupName</td></tr>');
        for (var item in items) {
          sb.write('<tr><td>${item['title']}</td><td style="text-align:center;">${item['quantity']} × ${(item['unitPrice'] as double).toStringAsFixed(2)} €</td><td style="text-align:right;font-weight:bold;">${(item['total'] as double).toStringAsFixed(2)} €</td></tr>');
        }
      });

      sb.write('</table>');
      sb.write('''
<div class="totals-box">
  <div class="total-row"><span>Total des matériaux ($totalCount éléments)</span><span>${totalCost.toStringAsFixed(2)} €</span></div>
</div>
''');
    }

    sb.write('<div class="footer">Ce devis est valable 30 jours. Merci pour votre confiance.</div>');
    sb.write('</body></html>');
    return sb.toString();
  }

  Future<void> _downloadWord(bool isDevis) async {
    try {
      final html = _generateWordHtml(isDevis);
      final bytes = html.codeUnits;
      final name = isDevis ? 'Devis_$_quoteNumber.doc' : 'Fournitures_$_quoteNumber.doc';

      String? savedPath;
      if (Platform.isAndroid) {
        try {
          final downloadDir = Directory('/storage/emulated/0/Download');
          if (await downloadDir.exists()) {
            final file = File('${downloadDir.path}/$name');
            await file.writeAsBytes(Uint8List.fromList(bytes));
            savedPath = file.path;
          }
        } catch (e) {
          debugPrint("Primary Android download failed: $e");
        }
      }

      if (savedPath != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("✅ Word téléchargé : $savedPath"),
            backgroundColor: const Color(0xFF22C55E),
            duration: const Duration(seconds: 5),
          ));
        }
      } else {
        final output = await getApplicationDocumentsDirectory();
        final file = File('${output.path}/$name');
        await file.writeAsBytes(Uint8List.fromList(bytes));
        if (mounted) {
          await Printing.sharePdf(bytes: Uint8List.fromList(bytes), filename: name);
        }
      }
    } catch (e) {
      debugPrint("Error downloading Word: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erreur lors du téléchargement Word")));
      }
    }
  }

  Future<void> _shareWord(bool isDevis) async {
    final html = _generateWordHtml(isDevis);
    final name = isDevis ? 'Devis_$_quoteNumber.doc' : 'Fournitures_$_quoteNumber.doc';
    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/$name');
    await file.writeAsBytes(Uint8List.fromList(html.codeUnits));
    await Printing.sharePdf(bytes: Uint8List.fromList(html.codeUnits), filename: name);
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
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
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
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
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
                                color: Theme.of(context).colorScheme.surface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
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
                  _buildDocumentCard(
                    title: "Devis_Final_${_quoteNumber}.pdf",
                    subtitle: "PDF Devis (A4)",
                    icon: Icons.picture_as_pdf,
                    iconColor: const Color(0xFFEF4444),
                    onOpen: () => _openPdf(true),
                    onDownload: () => _downloadPdf(true),
                    onShare: () => _sharePdf(true),
                    onDownloadWord: () => _downloadWord(true),
                    onShareWord: () => _shareWord(true),
                  ),

                  const SizedBox(height: 24),
                  
                  // Fournitures PDF Section
                  _buildDocumentCard(
                    title: "Fournitures_${_quoteNumber}.pdf",
                    subtitle: "Liste de Matériaux (A4)",
                    icon: Icons.inventory_2_outlined,
                    iconColor: const Color(0xFF3B82F6),
                    onOpen: () => _openPdf(false),
                    onDownload: () => _downloadPdf(false),
                    onShare: () => _sharePdf(false),
                    onDownloadWord: () => _downloadWord(false),
                    onShareWord: () => _shareWord(false),
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

                const SizedBox(height: 12),

                // Discussion with the client (shared thread with the signature
                // web app). Available once the devis exists (it always does on
                // this success screen).
                OutlinedButton.icon(
                  onPressed: () {
                    final client = widget.quoteData['client']
                            as Map<String, dynamic>? ??
                        {};
                    context.push('/quote/messages', extra: {
                      'quoteId': widget.quoteId,
                      'clientName': client['name'] as String?,
                    });
                  },
                  icon: const Icon(Icons.forum_outlined, size: 20),
                  label: const Text("Discussion avec le client"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.darkNavy,
                    side: const BorderSide(color: Color(0xFFA18B73)),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildDocumentCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onOpen,
    required VoidCallback onDownload,
    required VoidCallback onShare,
    required VoidCallback onDownloadWord,
    required VoidCallback onShareWord,
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
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
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text("PDF"),
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
                onPressed: onDownloadWord,
                icon: const Icon(Icons.description, size: 18),
                label: const Text("Word"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2B579A),
                  side: const BorderSide(color: Color(0xFF2B579A)),
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
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share, size: 16),
                label: const Text("Partager PDF", style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.darkNavy,
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextButton.icon(
                onPressed: onShareWord,
                icon: const Icon(Icons.share, size: 16),
                label: const Text("Partager Word", style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2B579A),
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

