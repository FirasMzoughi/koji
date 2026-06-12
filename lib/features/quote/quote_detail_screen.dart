import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koji/features/auth/provider/auth_provider.dart';
import 'package:koji/features/auth/repository/user_repository.dart';
import 'package:koji/features/quote/repository/quote_repository.dart';
import 'package:koji/features/quote/providers/quote_task_provider.dart';
import 'package:koji/features/quote/providers/quote_creation_provider.dart';
import 'package:intl/intl.dart';

// ─── Data model for one editable line ─────────────────────────────────────────
class _DevisLine {
  String taskId;
  String label;
  String code;
  String famille;
  String unite;

  // Parent ouvrage id when this line is a sous-ouvrage. The recap groups such
  // lines under their parent and shows a summed "Total ouvrage".
  String parentTaskId;

  double qty; // editable
  double tempsHU; // editable – temps h/u
  double tauxHoraire; // from profile
  double conditionCoeff;

  double fournituresQty; // editable – separate fourniture count
  double fournituresUnitPrice; // editable – fournitures €/u

  // Forfait (flat price) — when enabled the line is billed at a single fixed
  // price and the qty/temps/fournitures breakdown is ignored.
  bool forfaitEnabled;
  double forfaitPrice;

  // When true, fournitures are NOT itemised in the client devis/facture. The
  // line total still includes their cost; only the "Fnt : …" detail is hidden.
  bool hideFournitures;

  // Line type, matching the professional devis layout:
  //   'normal'  → billed normally (MO + fournitures count toward the total)
  //   'charge'  → "Fourniture à votre charge": shown to the client but NOT
  //               billed (client supplies it), so it adds 0 to every total
  //   'attente' → "En attente de votre décision": shown but unpriced (0)
  String lineType;

  bool get isCharge => lineType == 'charge';
  bool get isAttente => lineType == 'attente';
  bool get isBillable => lineType == 'normal';

  // A standalone fourniture (material-only) line. Added via
  // _addStandaloneFourniture, its taskId is prefixed with "fourniture_".
  // Such a line has NO main d'œuvre: its total is simply quantité × prix unitaire.
  bool get isFourniture => taskId.startsWith('fourniture_');

  // derived
  // Fournitures carry no labour, so their MO unit price is always 0 — even if a
  // temps value was somehow entered/saved on the line.
  double get moUnitPrice =>
      isFourniture ? 0.0 : tempsHU * tauxHoraire * conditionCoeff;
  // A forfait line carries its whole price in MO so it flows into the totals;
  // fournitures are folded into the flat price, so they're zero here.
  // "À votre charge" / "En attente" lines are never billed → 0.
  double get totalMO =>
      isBillable ? (forfaitEnabled ? forfaitPrice : moUnitPrice * qty) : 0.0;
  // Fournitures = the products the user explicitly added to this line. For a
  // normal ouvrage, their count is independent from the ouvrage qty/surface.
  // A standalone fourniture still uses the line qty because that line is only
  // the product.
  double get billedFournituresQty => isFourniture ? qty : fournituresQty;
  double get totalFournitures => (isBillable && !forfaitEnabled)
      ? fournituresUnitPrice * billedFournituresQty
      : 0.0;
  double get totalLigne => totalMO + totalFournitures;

  _DevisLine({
    required this.taskId,
    required this.label,
    this.code = '',
    this.famille = '',
    this.unite = 'u',
    this.parentTaskId = '',
    this.qty = 1.0,
    this.tempsHU = 0.0,
    this.tauxHoraire = 0.0,
    this.conditionCoeff = 1.0,
    this.fournituresQty = 0.0,
    this.fournituresUnitPrice = 0.0,
    this.forfaitEnabled = false,
    this.forfaitPrice = 0.0,
    this.hideFournitures = false,
    this.lineType = 'normal',
  });
}

// ─── Screen ────────────────────────────────────────────────────────────────────
class _FournituresSummary {
  final double qty;
  final double total;

  const _FournituresSummary({
    required this.qty,
    required this.total,
  });

  double get unitPrice => qty > 0 ? total / qty : 0.0;
}

class QuoteDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;

  const QuoteDetailScreen({super.key, required this.data});

  @override
  ConsumerState<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends ConsumerState<QuoteDetailScreen> {
  bool _isSaving = false;
  bool _isLoadingDetails = false;

  // Header
  String _companyName = 'Koji';
  String _companyAddress = '8 Av. des artisans, Paris';
  String _companyPhone = '01 42 55 000 77';
  String _companyEmail = 'Contact@Koji.fr';
  String _clientName = 'Client';
  String _clientAddress = '';
  String _clientEmail = '';
  String _quoteNumber = '';
  String _quoteDate = '';
  String _quoteValidity = '30 Jours';
  String _siteAddress = '';
  String? _logoPath;
  double _hourlyRate = 0.0;

  // Legal identification (shown in the devis footer / pied de page)
  String _companySiret = '';
  String _companyRcs = '';
  String _companyTva = '';
  String _companyLegalForm = '';

  // Mandatory work info (lieu = siteAddress; dates editable here)
  String _travauxStart = ''; // date de début des travaux
  String _travauxDuration = ''; // durée des travaux
  final _startCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();

  // Free-form notes / mentions the entrepreneur can edit per devis (conditions
  // de paiement, mentions légales, réserves techniques…). Prefilled with a
  // sensible default; persisted in quote metadata and rendered on the PDF.
  static const String _defaultMentions =
      'Modalités de paiement : 30 % à la signature, solde à la réception.\n'
      'Délai d\'exécution : à convenir avec le client.\n'
      'Devis valable 30 jours. TVA applicable selon la réglementation en vigueur.';
  final _mentionsCtrl = TextEditingController(text: _defaultMentions);

  @override
  void dispose() {
    _startCtrl.dispose();
    _durationCtrl.dispose();
    _mentionsCtrl.dispose();
    super.dispose();
  }

  // KOJI devis lines grouped by room
  // Map<roomId, List<_DevisLine>>
  final Map<String, List<_DevisLine>> _linesByRoom = {};
  final List<String> _roomOrder = [];

  // ─── Récapitulatif (professional "LOT" devis) ──────────────────────────────
  // Each room is rendered as a LOT. Per-devis global percentages applied on the
  // sum of the lot totals, then a selectable TVA rate. Persisted in metadata.
  double _coordPct = 10; // Coordination de chantier
  double _aleasPct = 5; // Provision aléas de chantier
  double _decennalePct = 8; // Assurance décennale
  int _tvaRate = 10; // 10 % rénovation (Art. 279-0 bis CGI) or 20 %
  // Per-lot label override: roomId → {'number': int, 'title': String}.
  final Map<String, Map<String, dynamic>> _lotMeta = {};

  @override
  void initState() {
    super.initState();
    // Provisional number until the backend assigns the real sequential one.
    // Format matches the final "YYYY-NNNN" shape (e.g. 2026-0001).
    _quoteNumber = '${DateTime.now().year}-0001';
    _quoteDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // Two ways the recap can be opened with an `id`:
    //   1. Direct deep-link from the quotes list (no fresh tasks map) — must
    //      load room/task rows from the database.
    //   2. Re-entry via the edit-flow seeded from a saved quote — `tasks` is
    //      already populated with the user's edits, and pulling from the DB
    //      again would clobber those edits.
    final tasksMap = widget.data['tasks'];
    final hasFreshTasks = tasksMap is Map && tasksMap.isNotEmpty;
    if (widget.data.containsKey('id') && !hasFreshTasks) {
      _loadExistingQuote();
    } else {
      _initFromProvider();
      // Reuse the number when editing an existing quote; otherwise assign a
      // fresh sequential DEVIS-YYYY-NNNN number from the backend.
      final existingNumber = widget.data['quoteNumber'] as String?;
      if (existingNumber != null && existingNumber.isNotEmpty) {
        _quoteNumber = existingNumber;
      } else {
        _assignAutoNumber();
      }
    }
    _fetchBusinessInfo();
  }

  Future<void> _assignAutoNumber() async {
    final user = ref.read(authProvider).value;
    if (user == null) return;
    try {
      final number = await ref
          .read(quoteRepositoryProvider)
          .generateNextQuoteNumber(user.id);
      if (mounted) setState(() => _quoteNumber = number);
    } catch (_) {/* keep the timestamp fallback already set */}
  }

  // ── Initialize from new quote flow ──────────────────────────────────────────
  _FournituresSummary _summarizeFournitures(dynamic raw) {
    double qty = 0.0;
    double total = 0.0;

    if (raw is Map) {
      raw.forEach((_, value) {
        if (value is Map) {
          final itemQty = (value['quantity'] as num?)?.toDouble() ?? 1.0;
          final unitPrice = (value['unitPrice'] as num?)?.toDouble() ?? 0.0;
          if (itemQty > 0) {
            qty += itemQty;
            total += itemQty * unitPrice;
          }
        }
      });
    }

    return _FournituresSummary(qty: qty, total: total);
  }

  _FournituresSummary _storedFournituresSummary({
    required Map<String, dynamic> inputs,
    required double taskQty,
    required double storedMaterialUnit,
  }) {
    final selected = _summarizeFournitures(inputs['selectedFournitures']);
    if (selected.total > 0) return selected;

    final storedQty = (inputs['fournituresQty'] as num?)?.toDouble();
    final storedTotal = (inputs['fournituresTotal'] as num?)?.toDouble();
    if (storedQty != null && storedQty > 0) {
      return _FournituresSummary(
        qty: storedQty,
        total: storedTotal ?? storedQty * storedMaterialUnit,
      );
    }

    // Legacy quotes stored a material unit price multiplied by the ouvrage qty.
    final legacyTotal = storedMaterialUnit * taskQty;
    return _FournituresSummary(qty: taskQty, total: legacyTotal);
  }

  void _initFromProvider() {
    final tasks = widget.data['tasks'] as Map<String, dynamic>?;
    if (tasks == null) return;

    final client = widget.data['client'] as Map<String, dynamic>?;
    if (client != null) {
      _clientName = client['name'] ?? _clientName;
      _clientAddress = client['address'] ?? _clientAddress;
      _clientEmail = client['email'] ?? _clientEmail;
    }
    _siteAddress = widget.data['siteAddress'] ?? '';

    tasks.forEach((roomId, roomTasksRaw) {
      if (roomTasksRaw is! Map) return;
      final roomTasks = roomTasksRaw as Map<String, dynamic>;
      final lines = <_DevisLine>[];

      roomTasks.forEach((_, taskDataRaw) {
        if (taskDataRaw is! Map) return;
        final td = taskDataRaw as Map<String, dynamic>;

        final qty = (td['quantity'] as num?)?.toDouble() ?? 1.0;
        final inputs = (td['inputs'] is Map)
            ? Map<String, dynamic>.from(td['inputs'] as Map)
            : <String, dynamic>{};
        final selectedFournitures =
            _summarizeFournitures(td['selectedFournitures']);
        final storedFournitures = _storedFournituresSummary(
          inputs: {
            ...inputs,
            if (td['fournituresQty'] != null)
              'fournituresQty': td['fournituresQty'],
            if (td['fournituresTotal'] != null)
              'fournituresTotal': td['fournituresTotal'],
          },
          taskQty: qty,
          storedMaterialUnit:
              (td['fournituresUnitPrice'] as num?)?.toDouble() ?? 0.0,
        );
        final fournitures = selectedFournitures.total > 0
            ? selectedFournitures
            : storedFournitures;

        final forfaitEnabled = td['forfaitEnabled'] == true;
        final forfaitPrice = (td['forfaitPrice'] as num?)?.toDouble() ?? 0.0;

        lines.add(_DevisLine(
          taskId: td['taskId']?.toString() ?? '',
          label: td['label']?.toString() ?? '',
          code: td['code']?.toString() ?? '',
          famille: td['famille']?.toString() ?? '',
          unite: td['unite']?.toString() ?? 'u',
          parentTaskId: td['parentTaskId']?.toString() ?? '',
          qty: qty,
          tempsHU: (td['hours'] as num?)?.toDouble() ?? 0.0,
          tauxHoraire: (td['tauxHoraire'] as num?)?.toDouble() ?? _hourlyRate,
          conditionCoeff: (td['conditionCoeff'] as num?)?.toDouble() ?? 1.0,
          fournituresQty: fournitures.qty,
          fournituresUnitPrice: fournitures.unitPrice,
          forfaitEnabled: forfaitEnabled,
          forfaitPrice: forfaitPrice,
          hideFournitures: td['hideFournitures'] == true,
          lineType: td['lineType']?.toString() ?? 'normal',
        ));
      });

      if (lines.isNotEmpty) {
        _linesByRoom[roomId] = lines;
        _roomOrder.add(roomId);
      }
    });
  }

  // ── Load existing saved quote ────────────────────────────────────────────────
  void _loadExistingQuote() {
    final d = widget.data;
    _quoteNumber = d['quoteNumber'] ?? _quoteNumber;
    _quoteDate = d['date'] ?? _quoteDate;
    _quoteValidity = d['validity'] ?? _quoteValidity;
    final savedMentions = d['mentions'] as String?;
    if (savedMentions != null && savedMentions.trim().isNotEmpty) {
      _mentionsCtrl.text = savedMentions;
    }

    Map<String, dynamic> safe(dynamic v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
      return {};
    }

    final client = safe(d['client']);
    _clientName = client['name'] ?? '';
    _clientAddress = client['address'] ?? '';
    _clientEmail = client['email'] ?? '';

    final company = safe(d['company']);
    _companyName = company['name'] ?? _companyName;
    _companyAddress = company['address'] ?? _companyAddress;
    _companyPhone = company['phone'] ?? _companyPhone;
    _companyEmail = company['email'] ?? _companyEmail;
    _companySiret = company['siret'] ?? _companySiret;
    _companyRcs = company['rcs'] ?? _companyRcs;
    _companyTva = company['tva'] ?? _companyTva;
    _companyLegalForm = company['formeJuridique'] ?? _companyLegalForm;
    _siteAddress = d['siteAddress'] ?? '';
    _travauxStart = d['travauxStart'] ?? '';
    _travauxDuration = d['travauxDuration'] ?? '';
    _startCtrl.text = _travauxStart;
    _durationCtrl.text = _travauxDuration;

    // Récapitulatif config (global % + TVA + per-lot labels) from metadata.
    final recap = safe(d['recap']);
    _coordPct = (recap['coordPct'] as num?)?.toDouble() ?? _coordPct;
    _aleasPct = (recap['aleasPct'] as num?)?.toDouble() ?? _aleasPct;
    _decennalePct =
        (recap['decennalePct'] as num?)?.toDouble() ?? _decennalePct;
    _tvaRate = (recap['tvaRate'] as num?)?.toInt() ?? _tvaRate;
    final lots = safe(d['lots']);
    lots.forEach((roomId, meta) {
      _lotMeta[roomId] = safe(meta);
    });

    setState(() => _isLoadingDetails = true);
    _fetchDetails(d['id'] as String);
  }

  Future<void> _fetchDetails(String quoteId) async {
    try {
      final repo = ref.read(quoteTaskRepositoryProvider);
      final roomsData = await repo.getQuoteRooms(quoteId);

      for (final r in roomsData) {
        final roomId = r['name'] as String;
        _roomOrder.add(roomId);
        _linesByRoom[roomId] = [];

        final tasksData = await repo.getQuoteTasks(r['id'] as String);
        for (final t in tasksData) {
          // The `inputs` JSON keeps the editable fields the user originally
          // entered (qty, tempsHU, tauxHoraire, code, famille, unite). Without
          // it the recap would silently reset every line to qty:1, hiding the
          // user's edits and making "Mettre à jour" look like a no-op.
          final inputs = (t['inputs'] is Map)
              ? Map<String, dynamic>.from(t['inputs'] as Map)
              : <String, dynamic>{};

          final qty = (inputs['quantity'] as num?)?.toDouble() ?? 1.0;
          final moUnit = (t['unit_price_ht'] as num?)?.toDouble() ?? 0.0;
          final fournUnit = (t['total_price_ht'] as num?)?.toDouble() ?? 0.0;
          final fournitures = _storedFournituresSummary(
            inputs: inputs,
            taskQty: qty,
            storedMaterialUnit: fournUnit,
          );
          final tauxHoraire = (inputs['tauxHoraire'] as num?)?.toDouble() ??
              (_hourlyRate > 0 ? _hourlyRate : 0.0);
          final forfaitEnabled = inputs['forfaitEnabled'] == true;
          // On a forfait line the flat price was saved into unit_price_ht (moUnit).
          final forfaitPrice = (inputs['forfaitPrice'] as num?)?.toDouble() ??
              (forfaitEnabled ? moUnit : 0.0);

          double tempsHU = (inputs['tempsHU'] as num?)?.toDouble() ?? 0.0;
          if (!forfaitEnabled && tempsHU == 0 && tauxHoraire > 0) {
            tempsHU = moUnit / tauxHoraire;
          }

          _linesByRoom[roomId]!.add(_DevisLine(
            taskId: t['task_id']?.toString() ?? '',
            label: t['label']?.toString() ?? '',
            code: inputs['code']?.toString() ?? '',
            famille: inputs['famille']?.toString() ?? '',
            unite: inputs['unite']?.toString() ?? 'u',
            parentTaskId: inputs['parentTaskId']?.toString() ?? '',
            qty: qty,
            tempsHU: tempsHU,
            tauxHoraire: tauxHoraire,
            fournituresQty: forfaitEnabled ? 0.0 : fournitures.qty,
            fournituresUnitPrice: forfaitEnabled ? 0.0 : fournitures.unitPrice,
            forfaitEnabled: forfaitEnabled,
            forfaitPrice: forfaitPrice,
            hideFournitures: inputs['hideFournitures'] == true,
            lineType: inputs['lineType']?.toString() ?? 'normal',
          ));
        }
      }
    } catch (e) {
      debugPrint('Error loading quote: $e');
    } finally {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  Future<void> _fetchBusinessInfo() async {
    final user = ref.read(authProvider).value;
    if (user == null) return;
    final userData = await ref.read(userRepositoryProvider).getUser(user.id);
    if (userData == null || !mounted) return;

    final logoUrl = userData['logo_url'] as String?;
    final biz = userData['business_info'] as Map<String, dynamic>?;

    setState(() {
      _logoPath = logoUrl;
      if (biz != null) {
        _companyName = biz['raisonSociale'] ?? _companyName;
        _companyAddress = biz['address'] ?? _companyAddress;
        _companyPhone = biz['phone'] ?? _companyPhone;
        _companyEmail = biz['emailPro'] ?? _companyEmail;
        _companySiret = biz['siret'] ?? _companySiret;
        _companyRcs = biz['rcs'] ?? _companyRcs;
        _companyTva = biz['tva'] ?? _companyTva;
        _companyLegalForm = biz['formeJuridique'] ?? _companyLegalForm;
        final daily = (biz['dailyRate'] as num?)?.toDouble() ?? 0.0;
        final hpd = (biz['hoursPerDay'] as num?)?.toDouble() ?? 8.0;
        if (daily > 0 && hpd > 0) {
          _hourlyRate = daily / hpd;
          // Backfill tauxHoraire on lines that still have 0
          for (final lines in _linesByRoom.values) {
            for (final l in lines) {
              if (l.tauxHoraire == 0) l.tauxHoraire = _hourlyRate;
            }
          }
        }
      }
    });
  }

  // ── Totals ───────────────────────────────────────────────────────────────────
  double get _grandTotalMO =>
      _linesByRoom.values.expand((l) => l).fold(0.0, (s, l) => s + l.totalMO);

  double get _grandTotalFournitures => _linesByRoom.values
      .expand((l) => l)
      .fold(0.0, (s, l) => s + l.totalFournitures);

  /// HT of a single lot (room) = its MO + billed fournitures (charge/attente
  /// lines contribute 0 via the line getters).
  double _lotTotalHT(String roomId) =>
      (_linesByRoom[roomId] ?? const []).fold(0.0, (s, l) => s + l.totalLigne);

  /// Sum of all lot totals (before global %).
  double get _subtotalLots => _grandTotalMO + _grandTotalFournitures;

  // Global provisions, computed on the lot subtotal (editable percentages).
  double get _coordAmount => _subtotalLots * _coordPct / 100;
  double get _aleasAmount => _subtotalLots * _aleasPct / 100;
  double get _decennaleAmount => _subtotalLots * _decennalePct / 100;

  /// TOTAL GÉNÉRAL H.T. = lots + the three provisions.
  double get _grandTotalGeneralHT =>
      _subtotalLots + _coordAmount + _aleasAmount + _decennaleAmount;

  double get _tvaAmount => _grandTotalGeneralHT * _tvaRate / 100;
  double get _grandTotalTTC => _grandTotalGeneralHT + _tvaAmount;

  // ── Save ─────────────────────────────────────────────────────────────────────
  Future<void> _generateQuote() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final user = ref.read(authProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur non connecté')));
      setState(() => _isSaving = false);
      return;
    }

    // Convert lines back to ExpenseItem format for saving
    final expensesMap = <String, List<Map<String, dynamic>>>{};
    // tasksMap.<room>.<taskId>.inputs is what the repo persists into
    // quote_tasks.inputs — the recap reads it back on next open, so the
    // editable fields must round-trip through here or "Mettre à jour" loses them.
    final tasksMap = <String, Map<String, Map<String, dynamic>>>{};

    // When the user came in via the full edit-flow (room→tasks→recap),
    // the provider holds the rich per-task state (selectedFournitures,
    // selectedProducts, note, photoPaths) that the recap's _DevisLine
    // doesn't track. Merge it back so update doesn't drop fournitures.
    final providerTasks = ref.read(quoteCreationProvider).roomTasks;
    _linesByRoom.forEach((roomId, lines) {
      expensesMap[roomId] = lines
          .map((l) => {
                'id': l.taskId,
                'title': l.label,
                // Forfait: the whole flat price rides in laborCost at qty 1, with no
                // fournitures — matches how room_task_screen emits a forfait line.
                'laborCost': l.forfaitEnabled ? l.forfaitPrice : l.moUnitPrice,
                'materialCost': l.forfaitEnabled ? 0.0 : l.fournituresUnitPrice,
                'materialQuantity':
                    l.forfaitEnabled ? 0.0 : l.billedFournituresQty,
                'quantity': l.forfaitEnabled ? 1.0 : l.qty,
                'unite': l.unite,
                'code': l.code,
                'famille': l.famille,
                'tempsHU': l.forfaitEnabled ? 0.0 : l.tempsHU,
                'tauxHoraire': l.forfaitEnabled ? 0.0 : l.tauxHoraire,
                // Standalone fourniture vs ouvrage, and the special line types — the
                // PDF needs these to split MO/Fournitures and render à charge/en attente.
                'isFourniture': l.isFourniture,
                'hideFournitures': l.hideFournitures,
                'lineType': l.lineType,
              })
          .toList();
      final perRoomProvider = (providerTasks[roomId] is Map)
          ? Map<String, dynamic>.from(providerTasks[roomId] as Map)
          : <String, dynamic>{};

      tasksMap[roomId] = {
        for (final l in lines)
          l.taskId: () {
            final prior = (perRoomProvider[l.taskId] is Map)
                ? Map<String, dynamic>.from(perRoomProvider[l.taskId] as Map)
                : <String, dynamic>{};
            final priorInputs = (prior['inputs'] is Map)
                ? Map<String, dynamic>.from(prior['inputs'] as Map)
                : <String, dynamic>{};
            final selectedFournitures = (prior['selectedFournitures'] is Map)
                ? Map<String, dynamic>.from(prior['selectedFournitures'] as Map)
                : <String, dynamic>{};
            if (!l.forfaitEnabled &&
                selectedFournitures.length == 1 &&
                l.billedFournituresQty > 0) {
              final key = selectedFournitures.keys.first;
              final item = selectedFournitures[key];
              if (item is Map) {
                selectedFournitures[key] = {
                  ...Map<String, dynamic>.from(item),
                  'quantity': l.billedFournituresQty,
                };
              }
            }
            // Recap-level edits win; preserve everything else from the
            // earlier edit-flow state so fournitures/products/notes survive.
            return <String, dynamic>{
              ...prior,
              'taskId': l.taskId,
              'label': l.label,
              'selectedFournitures': selectedFournitures,
              'inputs': {
                ...priorInputs,
                'quantity': l.qty,
                'tempsHU': l.tempsHU,
                'tauxHoraire': l.tauxHoraire,
                'unite': l.unite,
                'code': l.code,
                'famille': l.famille,
                'parentTaskId': l.parentTaskId,
                'forfaitEnabled': l.forfaitEnabled,
                'forfaitPrice': l.forfaitPrice,
                'fournituresQty': l.billedFournituresQty,
                'fournituresUnitPrice': l.fournituresUnitPrice,
                'fournituresTotal': l.totalFournitures,
                'hideFournitures': l.hideFournitures,
                'lineType': l.lineType,
              },
              'hours': l.tempsHU,
              'quantity': l.qty,
              'tauxHoraire': l.tauxHoraire,
              'unite': l.unite,
              'code': l.code,
              'famille': l.famille,
              'forfaitEnabled': l.forfaitEnabled,
              'forfaitPrice': l.forfaitPrice,
              'fournituresQty': l.billedFournituresQty,
              'fournituresUnitPrice': l.fournituresUnitPrice,
              'fournituresTotal': l.totalFournitures,
              'hideFournitures': l.hideFournitures,
            };
          }(),
      };
    });

    // The chantier this devis belongs to. When the flow started from a chantier
    // (chantier_devis_screen → _createDevis → setChantierId), the id lives in the
    // creation provider. Editing an existing devis carries it in widget.data.
    // Without this, saveQuote auto-creates an *orphan* chantier and the devis
    // tasks never surface under the real chantier (planner/dashboard show none).
    final effectiveChantierId = (widget.data['chantier_id'] as String?) ??
        ref.read(quoteCreationProvider).chantierId;

    final quoteData = {
      'quoteNumber': _quoteNumber,
      'createdAt': DateTime.now().toIso8601String(),
      'validity': _quoteValidity,
      'date': _quoteDate,
      'client': {
        'name': _clientName,
        'address': _clientAddress,
        'email': _clientEmail
      },
      'company': {
        'name': _companyName,
        'address': _companyAddress,
        'phone': _companyPhone,
        'email': _companyEmail,
        'siret': _companySiret,
        'rcs': _companyRcs,
        'tva': _companyTva,
        'formeJuridique': _companyLegalForm,
        // Public logo URL so the client signature website can show the
        // entreprise's real logo instead of the default Koji mark.
        'logo': _logoPath,
      },
      'siteAddress': _siteAddress,
      'travauxStart': _startCtrl.text.trim(),
      'travauxDuration': _durationCtrl.text.trim(),
      'mentions': _mentionsCtrl.text.trim(),
      'expenses': expensesMap,
      'tasks': tasksMap,
      // Per-lot HT (roomId → € HT) so the PDF récapitulatif can list each lot.
      'lotTotals': {
        for (final roomId in _roomOrder) roomId: _lotTotalHT(roomId),
      },
      'totals': {
        'moHT': _grandTotalMO,
        'fournituresHT': _grandTotalFournitures,
        'subtotalLots': _subtotalLots,
        'coordPct': _coordPct,
        'coordAmount': _coordAmount,
        'aleasPct': _aleasPct,
        'aleasAmount': _aleasAmount,
        'decennalePct': _decennalePct,
        'decennaleAmount': _decennaleAmount,
        // 'ht' is the TOTAL GÉNÉRAL HT (lots + provisions) — the figure shown on
        // the devis and stored in quotes.total_ht.
        'ht': _grandTotalGeneralHT,
        'tvaRate': _tvaRate,
        'tva': _tvaAmount,
        'ttc': _grandTotalTTC,
      },
      // Récapitulatif config + per-lot labels, persisted in quote metadata.
      'recap': {
        'coordPct': _coordPct,
        'aleasPct': _aleasPct,
        'decennalePct': _decennalePct,
        'tvaRate': _tvaRate,
      },
      'lots': {
        for (final entry in _lotMeta.entries) entry.key: entry.value,
      },
      if (effectiveChantierId != null) 'chantier_id': effectiveChantierId,
    };

    try {
      final existingId = widget.data['id'] as String?;
      final quoteId = await ref
          .read(quoteRepositoryProvider)
          .saveQuote(user.id, quoteData, quoteId: existingId);

      if (mounted) {
        // Clear editing state so the next "new devis" starts clean.
        ref.read(quoteCreationProvider.notifier).reset();
        if (existingId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Devis mis à jour'),
              backgroundColor: Color(0xFF15803D),
            ),
          );
        }
        // Both create and update land on the success screen so the user can
        // view / share the regenerated PDF and the Fournitures PDF.
        context.go('/quote/success', extra: {
          'quoteId': quoteId,
          'quoteData': {...quoteData, 'id': quoteId},
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9), shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(Icons.arrow_back,
                color: Color(0xFF0F172A), size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Récapitulatif de votre devis',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Color(0xFF0F172A)),
        ),
        actions: [
          // Discussion with the client — only meaningful once the devis exists
          // (has an id), since messages are keyed by quote id.
          if ((widget.data['id'] as String?)?.isNotEmpty == true)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9), shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.forum_outlined,
                    color: Color(0xFF0F172A), size: 20),
                tooltip: 'Discussion',
                onPressed: () => context.push('/quote/messages', extra: {
                  'quoteId': widget.data['id'],
                  'clientName': _clientName,
                }),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: _isLoadingDetails
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Info banner ───────────────────────────────────────
                  _buildInfoBanner(),
                  const SizedBox(height: 20),

                  // ── Header card ───────────────────────────────────────
                  _buildHeaderCard(),
                  const SizedBox(height: 16),

                  // ── Travaux (mandatory legal info) ────────────────────
                  _buildTravauxCard(),
                  const SizedBox(height: 24),

                  // ── KOJI devis table ──────────────────────────────────
                  if (_linesByRoom.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Aucune tâche ajoutée.',
                            style: TextStyle(color: Color(0xFF9CA3AF))),
                      ),
                    )
                  else
                    ..._roomOrder.where((r) => _linesByRoom.containsKey(r)).map(
                          (roomId) => _buildRoomSection(roomId),
                        ),

                  const SizedBox(height: 24),

                  // ── Grand totals ──────────────────────────────────────
                  _buildTotalsCard(),
                  const SizedBox(height: 24),

                  // ── Notes & mentions (editable) ───────────────────────
                  _buildMentionsCard(),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── Notes & mentions (editable per devis) ───────────────────────────────────
  Widget _buildMentionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes_outlined, size: 18, color: Color(0xFF0F172A)),
              SizedBox(width: 8),
              Text('Notes & mentions',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Conditions de paiement, délais, validité, réserves… Ce texte apparaît sur le devis.',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _mentionsCtrl,
            maxLines: null,
            minLines: 4,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
            decoration: InputDecoration(
              hintText: 'Saisissez vos mentions personnalisées…',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF0F172A)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Info banner ───────────────────────────────────────────────────────────────
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_note, size: 16, color: Color(0xFF16A34A)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Qté, Temps h/u et Prix HT sont modifiables. Saisir un Prix HT fixe le prix de la ligne (forfait) ; les totaux se recalculent en temps réel.',
              style: TextStyle(fontSize: 12, color: Color(0xFF15803D)),
            ),
          ),
          if (_hourlyRate > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_hourlyRate.toStringAsFixed(2)} €/h',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF166534)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Header card ───────────────────────────────────────────────────────────────
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _logoPath != null
                      ? Colors.white
                      : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  image: _logoPath != null
                      ? DecorationImage(
                          image: NetworkImage(_logoPath!), fit: BoxFit.cover)
                      : null,
                ),
                child: _logoPath == null
                    ? Icon(
                        Icons.business,
                        color: Theme.of(context).colorScheme.surface,
                        size: 22,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_companyName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text(_companyAddress,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF6B7280))),
                    Text(_companyPhone,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              // Quote number box
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5D8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text('DEVIS N°',
                        style:
                            TextStyle(fontSize: 8, color: Color(0xFFA18B73))),
                    Text(_quoteNumber,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Color(0xFF0F172A))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CLIENT',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFA18B73))),
                  const SizedBox(height: 4),
                  Text(_clientName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF0F172A))),
                  if (_clientAddress.isNotEmpty)
                    Text(_clientAddress,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF6B7280))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('DATE',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFA18B73))),
                  Text(_quoteDate,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  const Text('VALIDITÉ',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFA18B73))),
                  Text(_quoteValidity,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF0F172A))),
                ],
              ),
            ],
          ),
          if (_siteAddress.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF3E5D8)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: Color(0xFFA18B73)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_siteAddress,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A))),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Travaux card: lieu (read-only) + dates (editable, mandatory mentions) ─────
  Widget _buildTravauxCard() {
    final lieu = _siteAddress.isNotEmpty ? _siteAddress : _clientAddress;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TRAVAUX',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFA18B73))),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.place_outlined,
                  size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  lieu.isNotEmpty
                      ? 'Lieu d\'exécution : $lieu'
                      : 'Lieu d\'exécution : —',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _startCtrl,
                  keyboardType: TextInputType.datetime,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Date de début',
                    hintText: 'jj/mm/aaaa',
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _durationCtrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Durée des travaux',
                    hintText: 'ex : 3 semaines',
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Room section ──────────────────────────────────────────────────────────────
  Widget _buildRoomSection(String roomId) {
    final lines = _linesByRoom[roomId] ?? [];
    final roomTotal = lines.fold(0.0, (s, l) => s + l.totalLigne);

    // Split sous-ouvrages from top-level lines: a line whose parentTaskId
    // matches another line of this room is rendered indented under that parent
    // with a summed "Total ouvrage" (client request — la somme des
    // sous-ouvrages fait le prix de l'ouvrage).
    final ids = lines.map((l) => l.taskId).toSet();
    final childrenByParent = <String, List<_DevisLine>>{};
    final topLines = <_DevisLine>[];
    for (final l in lines) {
      if (l.parentTaskId.isNotEmpty &&
          l.parentTaskId != l.taskId &&
          ids.contains(l.parentTaskId)) {
        childrenByParent.putIfAbsent(l.parentTaskId, () => []).add(l);
      } else {
        topLines.add(l);
      }
    }

    // Group top-level lines by famille (sous-ouvrages follow their parent).
    final byFamille = <String, List<_DevisLine>>{};
    for (final l in topLines) {
      final fam = l.famille.isEmpty ? 'Général' : l.famille;
      byFamille.putIfAbsent(fam, () => []).add(l);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Room header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    _lotLabel(roomId, _roomOrder.indexOf(roomId) + 1),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.edit_outlined,
                      size: 16, color: Color(0xFFEAD8B1)),
                  onPressed: () =>
                      _editLot(roomId, _roomOrder.indexOf(roomId) + 1),
                ),
                const Spacer(),
                Text(
                  '${roomTotal.toStringAsFixed(2)} €',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFFEAD8B1)),
                ),
              ],
            ),
          ),

          // Lines by famille
          ...byFamille.entries.map((entry) {
            final famColor = _familleColor(entry.key);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LOT label
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: famColor.withValues(alpha: 0.08),
                  child: Row(
                    children: [
                      Container(
                          width: 3,
                          height: 14,
                          color: famColor,
                          margin: const EdgeInsets.only(right: 8)),
                      Text(
                        entry.key.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: famColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                ...entry.value.map((line) {
                  final children =
                      childrenByParent[line.taskId] ?? const <_DevisLine>[];
                  final childrenTotal = children.fold(
                      0.0, (double s, c) => s + c.totalLigne);
                  final ouvrageTotal = line.totalLigne + childrenTotal;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // The parent card displays the SOMME (its own price +
                      // all its sous-ouvrages) — the ouvrage price the client
                      // expects, not the parent's own 0 €.
                      _buildLineCard(
                          roomId, lines.indexOf(line), line, famColor,
                          childrenTotal: childrenTotal),
                      // Sous-ouvrages: indented under their parent ouvrage.
                      ...children.map((c) => Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: _buildLineCard(
                                roomId, lines.indexOf(c), c, famColor),
                          )),
                      // Somme : prix de l'ouvrage = ligne + sous-ouvrages.
                      if (children.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'TOTAL OUVRAGE — ${line.label}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                      color: Color(0xFF1E3A8A)),
                                ),
                              ),
                              Text(
                                '${ouvrageTotal.toStringAsFixed(2)} €',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E3A8A)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                }),
              ],
            );
          }),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Task line card (mobile-friendly) ─────────────────────────────────────────
  // [childrenTotal] > 0 marks a parent ouvrage: every displayed total includes
  // the somme of its sous-ouvrages so the ouvrage price = sum of sub prices.
  Widget _buildLineCard(
      String roomId, int lineIndex, _DevisLine line, Color famColor,
      {double childrenTotal = 0.0}) {
    final displayTotal = line.totalLigne + childrenTotal;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Title row ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                if (line.code.isNotEmpty) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: famColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(line.code,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                            color: famColor)),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    line.label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A)),
                  ),
                ),
                // Price chip — for charge/attente lines there is no billed total.
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: line.isBillable
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    line.isBillable
                        ? '${displayTotal.toStringAsFixed(2)} €'
                        : (line.isCharge ? 'À charge' : 'En attente'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: line.isBillable
                          ? Theme.of(context).colorScheme.surface
                          : const Color(0xFF475569),
                    ),
                  ),
                ),
                // Line-type selector (Normale / À votre charge / En attente).
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert,
                      size: 18, color: Color(0xFF94A3B8)),
                  onSelected: (v) => setState(
                      () => _linesByRoom[roomId]![lineIndex].lineType = v),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'normal', child: Text('Normale')),
                    PopupMenuItem(
                        value: 'charge',
                        child: Text('Fourniture à votre charge')),
                    PopupMenuItem(
                        value: 'attente',
                        child: Text('En attente de votre décision')),
                  ],
                ),
              ],
            ),
          ),

          // A non-billable line shows a tag and hides the qty/temps editor.
          if (!line.isBillable)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Text(
                  line.isCharge
                      ? 'Fourniture à votre charge — non facturée'
                      : 'En attente de votre décision — non chiffrée',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB45309)),
                ),
              ),
            ),

          if (line.isBillable)
            Container(height: 1, color: const Color(0xFFF1F5F9)),

          // ── Editable inputs row ──────────────────────────────────────
          if (line.isBillable)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Qté
                      _inputField(
                        label: 'Qté',
                        sublabel: line.unite,
                        value: line.qty,
                        onChanged: (v) => setState(
                            () => _linesByRoom[roomId]![lineIndex].qty = v),
                      ),
                      // A standalone fourniture is material-only: no Temps/MO field.
                      // Its total is simply Qté × prix unitaire de la fourniture.
                      if (!line.isFourniture) ...[
                        const SizedBox(width: 8),
                        // Temps h/u
                        _inputField(
                          label: 'Temps h/${line.unite}',
                          sublabel: 'h',
                          value: line.tempsHU,
                          onChanged: (v) => setState(() =>
                              _linesByRoom[roomId]![lineIndex].tempsHU = v),
                        ),
                      ],
                      const SizedBox(width: 8),
                      // Prix HT direct (client request) — saisir un prix ici
                      // passe la ligne en forfait : ce montant remplace le
                      // calcul Qté × Temps. Effacer (0) rétablit le calcul.
                      _inputField(
                        label: 'Prix HT',
                        sublabel: '€',
                        value: line.forfaitEnabled ? line.forfaitPrice : 0.0,
                        onChanged: (v) => setState(() {
                          final l = _linesByRoom[roomId]![lineIndex];
                          l.forfaitPrice = v;
                          l.forfaitEnabled = v > 0;
                        }),
                      ),
                    ],
                  ),
                  if (!line.isFourniture &&
                      !line.forfaitEnabled &&
                      line.fournituresUnitPrice > 0) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _inputField(
                          label: 'Fnt Qte',
                          sublabel: 'u',
                          value: line.fournituresQty,
                          onChanged: (v) => setState(() =>
                              _linesByRoom[roomId]![lineIndex].fournituresQty =
                                  v),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

          // ── Computed results row ────────────────────────────────────
          if (line.isBillable)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${displayTotal.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildLineBreakdown(line, childrenTotal: childrenTotal),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Line breakdown: shows HOW the total is computed ──────────────────────────
  // Labor part:  Qté × Temps × tarif effectif (taux × coefficient) = MO
  // Fournitures: shown only when there is a material cost on the line.
  Widget _buildLineBreakdown(_DevisLine line, {double childrenTotal = 0.0}) {
    final effectiveRate = line.tauxHoraire * line.conditionCoeff;

    String fmt(double v) {
      final s = v.toStringAsFixed(2);
      return s.replaceAll('.', ',');
    }

    final parts = <String>[];
    // Parent ouvrage: its displayed total includes the somme of its
    // sous-ouvrages — make that explicit in the breakdown.
    if (childrenTotal > 0) {
      parts.add('Sous-ouvrages : ${fmt(childrenTotal)} €');
    }
    if (line.forfaitEnabled) {
      // Flat-price line: no MO/fournitures math, just the forfait amount.
      parts.add('Forfait : ${fmt(line.forfaitPrice)} €');
    } else {
      // A standalone fourniture has no main d'œuvre, so never show the MO line.
      if (!line.isFourniture && line.tempsHU > 0 && effectiveRate > 0) {
        parts.add(
          'MO : ${fmt(line.qty)} × ${fmt(line.tempsHU)} h × ${fmt(effectiveRate)} € = ${fmt(line.totalMO)} €',
        );
      }
      // Fnt line appears only when the user added fourniture products to the
      // line (totalFournitures > 0). It reflects exactly the products chosen,
      // each with its own +/− quantity. No product ⇒ no Fnt line.
      final showLegacyFntBreakdown = line.taskId == '__legacy_fnt_breakdown__';
      if (line.totalFournitures > 0 && !line.hideFournitures) {
        parts.add(
          'Fnt : ${fmt(line.billedFournituresQty)} x ${fmt(line.fournituresUnitPrice)} € = ${fmt(line.totalFournitures)} €',
        );
      } else if (showLegacyFntBreakdown &&
          line.totalFournitures > 0 &&
          line.hideFournitures) {
        parts.add('Fournitures incluses');
      }
      if (showLegacyFntBreakdown &&
          line.totalFournitures > 0 &&
          !line.hideFournitures) {
        parts.add(
          'Fnt : ${fmt(line.qty)} × ${fmt(line.fournituresUnitPrice)} € = ${fmt(line.totalFournitures)} €',
        );
      } else if (line.totalFournitures > 0 && line.hideFournitures) {
        parts.add('Fournitures incluses');
      }
    }
    if (parts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts
          .map((p) => Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  p,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.3,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ))
          .toList(),
    );
  }

  // ── Small labeled input ───────────────────────────────────────────────────────
  Widget _inputField({
    required String label,
    required String sublabel,
    required double value,
    required void Function(double) onChanged,
  }) {
    final display = value > 0
        ? value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')
        : '';
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: Color(0xFF94A3B8))),
          const SizedBox(height: 6),
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF6FCF8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCFEAD9)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController.fromValue(
                      TextEditingValue(
                        text: display,
                        selection:
                            TextSelection.collapsed(offset: display.length),
                      ),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF15803D)),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    ),
                    onChanged: (v) => onChanged(double.tryParse(v) ?? 0.0),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(sublabel,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Label of a lot ("LOT n – Titre") from _lotMeta, falling back to order/room.
  String _lotLabel(String roomId, int index) {
    final meta = _lotMeta[roomId];
    final number = (meta?['number'] as num?)?.toInt() ?? index;
    final title = (meta?['title']?.toString().trim().isNotEmpty == true)
        ? meta!['title'].toString()
        : _getRoomLabel(roomId);
    return 'LOT $number – $title';
  }

  // Dialog to edit a lot's number and title.
  Future<void> _editLot(String roomId, int defaultNumber) async {
    final meta = _lotMeta[roomId];
    final numCtrl = TextEditingController(
        text: ((meta?['number'] as num?)?.toInt() ?? defaultNumber).toString());
    final titleCtrl = TextEditingController(
        text: (meta?['title']?.toString().trim().isNotEmpty == true)
            ? meta!['title'].toString()
            : _getRoomLabel(roomId));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier le LOT'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Numéro de lot'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Titre du lot'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enregistrer')),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        _lotMeta[roomId] = {
          'number': int.tryParse(numCtrl.text.trim()) ?? defaultNumber,
          'title': titleCtrl.text.trim(),
        };
      });
    }
  }

  // ── Totals card (récapitulatif) ───────────────────────────────────────────────
  Widget _buildTotalsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('RÉCAPITULATIF',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94A3B8))),
            ),
          ),
          // One row per LOT with its HT.
          ..._roomOrder.asMap().entries.map((e) => _totalRow(
              _lotLabel(e.value, e.key + 1),
              _lotTotalHT(e.value),
              const Color(0xFF334155))),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // Global provisions — editable percentages.
          _percentRow('Coordination de chantier', _coordPct, _coordAmount,
              (v) => setState(() => _coordPct = v)),
          _percentRow('Provision aléas de chantier', _aleasPct, _aleasAmount,
              (v) => setState(() => _aleasPct = v)),
          _percentRow('Assurance décennale', _decennalePct, _decennaleAmount,
              (v) => setState(() => _decennalePct = v)),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _totalRow('TOTAL GÉNÉRAL H.T.', _grandTotalGeneralHT,
              const Color(0xFF0F172A),
              bold: true, bigger: true),
          // TVA with selectable rate (10 % rénovation / 20 %).
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Text('TVA',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int>(
                      value: _tvaRate,
                      isDense: true,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 10, child: Text('10 %')),
                        DropdownMenuItem(value: 20, child: Text('20 %')),
                      ],
                      onChanged: (v) =>
                          setState(() => _tvaRate = v ?? _tvaRate),
                    ),
                  ),
                ]),
                Text('${_tvaAmount.toStringAsFixed(2)} €',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOTAL GÉNÉRAL T.T.C.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.surface,
                    )),
                Text(
                  '${_grandTotalTTC.toStringAsFixed(2)} €',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: Color(0xFFEAD8B1)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // An editable global-percentage row ("Coordination de chantier (10%)  …€").
  Widget _percentRow(
      String label, double pct, double amount, ValueChanged<double> onPct) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(children: [
              Flexible(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155))),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 46,
                child: TextFormField(
                  initialValue: _fmtPct(pct),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    isDense: true,
                    suffixText: '%',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  ),
                  style: const TextStyle(fontSize: 12),
                  onChanged: (v) =>
                      onPct(double.tryParse(v.replaceAll(',', '.')) ?? 0),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          Text('${amount.toStringAsFixed(2)} €',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155))),
        ],
      ),
    );
  }

  static String _fmtPct(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Widget _totalRow(String label, double value, Color color,
      {bool bold = false, bool bigger = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: bigger ? 14 : 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                  color: color)),
          Text(
            '${value.toStringAsFixed(2)} €',
            style: TextStyle(
                fontSize: bigger ? 16 : 13,
                fontWeight: FontWeight.bold,
                color: color),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _generateQuote,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.surface,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    widget.data.containsKey('id')
                        ? 'Mettre à jour'
                        : 'Générer le Devis',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  String _getRoomLabel(String id) {
    switch (id) {
      case 'salon':
        return 'Salon';
      case 'cuisine':
        return 'Cuisine';
      case 'chambre':
        return 'Chambre';
      case 'salle_de_bain':
        return 'Salle de bain';
      case 'bureau':
        return 'Bureau';
      case 'exterieur':
        return 'Extérieur';
      default:
        if (id.isEmpty) return 'Pièce';
        return id[0].toUpperCase() + id.substring(1);
    }
  }

  Color _familleColor(String famille) {
    switch (famille.toLowerCase()) {
      case 'carrelage':
        return const Color(0xFFB45309);
      case 'peinture':
        return const Color(0xFF7C3AED);
      case 'plomberie':
        return const Color(0xFF0369A1);
      case 'electricité':
      case 'electricite':
        return const Color(0xFFD97706);
      case 'menuiserie':
        return const Color(0xFF166534);
      case 'démolition':
      case 'demolition':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFF475569);
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
