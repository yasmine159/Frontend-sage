import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/api_service_web.dart'
if (dart.library.io) '../../services/api_service_stub.dart';

class MappingPage extends StatefulWidget {
  @override
  _MappingPageState createState() => _MappingPageState();
}

class _MappingPageState extends State<MappingPage> {
  final ApiService _api = ApiService();

  static const _blue   = Color(0xFF2563eb);
  static const _violet = Color(0xFF7c3aed);
  static const _green  = Color(0xFF059669);
  static const _red    = Color(0xFFdc2626);
  static const _amber  = Color(0xFFd97706);
  static const _cyan   = Color(0xFF0891b2);

  int _step = 0;

  // Step 0
  List<Map<String, dynamic>> _models = [];
  List<Map<String, dynamic>> _modelsDetails = [];
  bool _loadingModels = true;
  String? _selectedModelCode;
  String? _selectedModelName;
  String _modelSearch = '';

  // Step 1
  PlatformFile? _file;
  List<String> _excelHeaders = [];
  bool _readingHeaders = false;

  // Step 2
  List<Map<String, dynamic>> _sageFields = [];
  bool _loadingFields = false;
  Map<String, String> _mapping = {};
  String _fieldSearch = '';
  int? _activeMappingId;

  // Step 3
  bool _uploading = false;
  double _progress = 0;
  bool? _success;
  String? _modelCode;
  int? _rowCount;
  String? _csv;
  List<dynamic> _errors = [];

  // Saved mappings
  List<Map<String, dynamic>> _savedMappings = [];

  @override
  void initState() {
    super.initState();
    _loadModels();
    _loadSavedMappings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args != null && args['excelBytes'] != null) {
        _loadFromOcrBytes(
          args['excelBytes'] as Uint8List,
          args['excelFileName'] as String,
        );
      }
    });
  }

  Future<void> _loadFromOcrBytes(Uint8List bytes, String fileName) async {
    setState(() {
      _file = PlatformFile(name: fileName, size: bytes.length, bytes: bytes);
      _readingHeaders = true;
      _mapping = {};
    });
    try {
      final headers = await _api.readExcelHeaders(bytes, fileName);
      if (!mounted) return;
      setState(() {
        _excelHeaders = headers;
        _readingHeaders = false;
        _step = 0;
      });
      _snack('Fichier OCR prêt (${headers.length} colonnes). Choisissez un modèle Sage.', _cyan);
    } catch (e) {
      if (!mounted) return;
      setState(() => _readingHeaders = false);
      _snack('Impossible de lire les en-têtes : $e', _red);
    }
  }

  Future<void> _loadModels() async {
    setState(() => _loadingModels = true);
    try {
      final d = await _api.getModels();
      if (!mounted) return;
      setState(() { _models = d; _loadingModels = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingModels = false);
    }
  }

  Future<void> _loadSavedMappings() async {
    try {
      final d = await _api.getSavedMappings();
      if (!mounted) return;
      setState(() => _savedMappings = d);
    } catch (_) {}
  }

  Future<void> _selectModel(String code, String name) async {
    final hasFile = _file != null && _excelHeaders.isNotEmpty;
    setState(() {
      _selectedModelCode = code;
      _selectedModelName = name;
      _loadingFields = true;
      _step = hasFile ? 2 : 1;
    });
    try {
      final fields = await _api.getModelFields(code);
      if (!mounted) return;
      setState(() { _sageFields = fields; _loadingFields = false; });
      if (hasFile && _mapping.isEmpty) _autoMapColumns(silent: true);
    } catch (_) {
      if (mounted) setState(() => _loadingFields = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['xlsx'], withData: kIsWeb);
    if (result == null) return;
    setState(() { _file = result.files.single; _readingHeaders = true; _excelHeaders = []; _mapping = {}; });
    try {
      List<String> headers;
      if (kIsWeb) {
        headers = await _api.readExcelHeaders(_file!.bytes!, _file!.name);
      } else {
        headers = await _api.readExcelHeaders(_MF(_file!.path!), _file!.name);
      }
      if (!mounted) return;
      setState(() { _excelHeaders = headers; _readingHeaders = false; _step = 2; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _readingHeaders = false);
      _snack('Échec de lecture des colonnes : $e', _red);
    }
  }

  void _mapColumn(String excelCol, String sageField) {
    setState(() {
      _mapping.removeWhere((_, v) => v == sageField);
      _mapping[excelCol] = sageField;
    });
  }

  void _unmapColumn(String excelCol) => setState(() => _mapping.remove(excelCol));
  void _clearMapping() => setState(() => _mapping.clear());

  String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9àâäéèêëïîôùûüç]'), '');

  void _autoMapColumns({bool silent = false}) {
    if (_excelHeaders.isEmpty || _sageFields.isEmpty) return;
    final usedSage = _mapping.values.toSet();
    var added = 0;
    for (final header in _excelHeaders) {
      if (_mapping.containsKey(header)) continue;
      final hNorm = _normalize(header);
      if (hNorm.isEmpty) continue;
      Map<String, dynamic>? best;
      int bestScore = 0;
      for (final f in _sageFields) {
        final code = _fieldCode(f);
        if (usedSage.contains(code)) continue;
        final desc = _normalize(_fieldName(f));
        final codeNorm = _normalize(code);
        if (codeNorm == hNorm || desc == hNorm) {
          best = f; bestScore = 100; break;
        }
        if (hNorm.contains(codeNorm) || codeNorm.contains(hNorm)) {
          if (bestScore < 80) { best = f; bestScore = 80; }
        } else if (desc.isNotEmpty && (hNorm.contains(desc) || desc.contains(hNorm))) {
          if (bestScore < 60) { best = f; bestScore = 60; }
        }
      }
      if (best != null && bestScore >= 60) {
        final code = _fieldCode(best);
        _mapping[header] = code;
        usedSage.add(code);
        added++;
      }
    }
    setState(() {});
    if (!silent) {
      _snack(added > 0 ? '$added colonne(s) associée(s) automatiquement' : 'Aucune correspondance trouvée',
          added > 0 ? _green : _amber);
    }
  }

  List<Map<String, dynamic>> _unmappedRequiredFields() {
    final mapped = _mapping.values.toSet();
    return _sageFields.where((f) => _fieldRequired(f) && !mapped.contains(_fieldCode(f))).toList();
  }

  Future<void> _convert() async {
    if (_mapping.isEmpty) { _snack('Associez au moins une colonne', _amber); return; }
    final missing = _unmappedRequiredFields();
    if (missing.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Champs requis non mappés', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('${missing.length} champ(s) obligatoire(s) ne sont pas encore associés :',
                  style: TextStyle(fontSize: 13)),
              SizedBox(height: 10),
              ...missing.take(8).map((f) => Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('• ${_fieldName(f)} (${_fieldCode(f)})', style: TextStyle(fontSize: 12)),
              )),
              if (missing.length > 8) Text('… et ${missing.length - 8} autre(s)', style: TextStyle(fontSize: 11, color: Colors.grey)),
              SizedBox(height: 12),
              Text('La conversion peut échouer à la validation. Continuer quand même ?',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: Text('Annuler')),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: ElevatedButton.styleFrom(backgroundColor: _amber, foregroundColor: Colors.white),
              child: Text('Continuer'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (proceed != true) return;
    }
    if (!mounted) return;
    setState(() { _uploading = true; _progress = 0; _success = null; _errors = []; });
    final mappingJson = jsonEncode(_mapping.entries.map((e) => {'excelColumn': e.key, 'sageField': e.value}).toList());
    try {
      Map<String, dynamic> result;
      if (kIsWeb) {
        result = await _api.uploadWithMapping(
            file: _file!.bytes!, fileName: _file!.name,
            modelCode: _selectedModelCode!, columnMappings: mappingJson,
            mappingId: _activeMappingId,
            onProgress: (p) { if (mounted) setState(() => _progress = p); });
      } else {
        result = await _api.uploadWithMapping(
            file: _MF(_file!.path!), fileName: _file!.name,
            modelCode: _selectedModelCode!, columnMappings: mappingJson,
            mappingId: _activeMappingId,
            onProgress: (p) { if (mounted) setState(() => _progress = p); });
      }
      if (!mounted) return;
      setState(() {
        _uploading = false; _success = result['success'] ?? false;
        _modelCode = result['modelCode']; _rowCount = result['rowCount'];
        _csv = result['csvContent']; _errors = result['errors'] ?? []; _step = 3;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false; _success = false;
        _errors = [{'row': 0, 'field': '', 'message': e.toString()}]; _step = 3;
      });
    }
  }

  // ── FIX: dispose contrôleur après le frame suivant pour éviter "used after dispose"
  Future<void> _saveMapping() async {
    final nameCtrl = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Enregistrer le mapping', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: nameCtrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nom du mapping',
              hintText: 'ex. Mes commandes achat',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Color(0xFFF7F8FA),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: Text('Annuler')),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _violet, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Enregistrer'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (confirmed != true || nameCtrl.text.trim().isEmpty) return;
      final mappingJson = jsonEncode(
        _mapping.entries.map((e) => {'excelColumn': e.key, 'sageField': e.value}).toList(),
      );
      await _api.saveMapping(ApiService.userId, nameCtrl.text.trim(), _selectedModelCode!, mappingJson);
      if (!mounted) return;
      _loadSavedMappings();
      _activeMappingId = null;
      _snack('Mapping enregistré !', _green);
    } catch (e) {
      if (mounted) _snack('$e', _red);
    } finally {
      // ── FIX: dispose après le prochain frame pour éviter le crash animation
      WidgetsBinding.instance.addPostFrameCallback((_) => nameCtrl.dispose());
    }
  }

  Future<void> _loadMapping(Map<String, dynamic> saved) async {
    final code = saved['modelCode'] as String;
    final texte = _models.firstWhere((m) => m['codeModele'] == code, orElse: () => {})['texte'] ?? code;
    _activeMappingId = saved['id'] as int?;
    await _selectModel(code, texte.isNotEmpty ? texte : code);
    try {
      final entries = jsonDecode(saved['columnMappings'] as String) as List;
      final loaded = <String, String>{};
      for (final e in entries) {
        final excelCol = e['excelColumn'] as String;
        final sageField = e['sageField'] as String;
        if (_excelHeaders.isEmpty || _excelHeaders.contains(excelCol)) {
          loaded[excelCol] = sageField;
        }
      }
      if (!mounted) return;
      setState(() => _mapping = loaded);
      final msg = _excelHeaders.isEmpty
          ? 'Mapping « ${saved['mappingName']} » chargé. Importez votre fichier Excel.'
          : 'Mapping « ${saved['mappingName']} » appliqué (${loaded.length} colonne(s)).';
      _snack(msg, _blue);
    } catch (_) { _snack('Échec du chargement du mapping', _red); }
  }

  void _downloadCsv() {
    if (_csv == null) return;
    final name = '${_modelCode ?? 'export'}_mapped_${DateTime.now().millisecondsSinceEpoch}.csv';
    final bytes = Uint8List.fromList(utf8.encode(_csv!));
    kIsWeb ? triggerWebDownload(bytes, name) : saveMobileFile(bytes, name);
  }

  void _reset() => setState(() {
    _step = 0; _file = null; _excelHeaders = []; _mapping = {};
    _success = null; _errors = []; _csv = null;
    _selectedModelCode = null; _selectedModelName = null;
    _fieldSearch = ''; _activeMappingId = null;
  });

  void _snack(String msg, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle(fontSize: 13)),
      backgroundColor: c,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Sage field helpers ────────────────────────────────────────────────
  String _fieldName(Map<String, dynamic> f) => (f['designation'] ?? f['champ'] ?? '—').toString();
  String _fieldCode(Map<String, dynamic> f) => (f['champ'] ?? '—').toString();
  String _fieldGroup(Map<String, dynamic> f) => (f['indicateurGroup'] ?? '').toString();
  bool _fieldRequired(Map<String, dynamic> f) {
    if (f.containsKey('obligatoire')) return f['obligatoire'] == true;
    final code = _fieldCode(f).toUpperCase();
    return !(code == 'DISCRGVAL1' || code == 'DISCRGVAL2' || code == 'DISCRGVAL3' ||
        code == 'ORDREF' || code == 'VACBPR' || code == 'MDL' || code == 'EECICT' ||
        code == 'CHGCOE' || code == 'VAT' || code == 'ITMDES' || code == 'COM_0' ||
        code.endsWith('COMMENT') || code.endsWith('NOTE') || code.endsWith('REM'));
  }

  Future<void> _deleteSavedMapping(int id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer le mapping ?'),
        content: Text('« $name » sera définitivement supprimé.', style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (ok != true) return;
    try {
      await _api.deleteMapping(id);
      if (!mounted) return;
      if (_activeMappingId == id) _activeMappingId = null;
      _loadSavedMappings();
      _snack('Mapping supprimé', _green);
    } catch (e) {
      if (mounted) _snack('$e', _red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dk   = Theme.of(context).brightness == Brightness.dark;
    final bg   = dk ? Color(0xFF0b0e13) : Color(0xFFF7F8FA);
    final card = dk ? Color(0xFF151921) : Colors.white;
    final bord = dk ? Color(0xFF1e2028) : Color(0xFFf0f0f5);
    final txt  = dk ? Colors.white : Color(0xFF111827);
    final sub  = dk ? Color(0xFF6b7280) : Color(0xFF9ca3af);
    final desk = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(backgroundColor: bg, body: Column(children: [
      _header(context, desk, dk, card, bord, txt, sub),
      _stepper(dk, card, bord, txt, sub),
      Expanded(child: SingleChildScrollView(
          padding: EdgeInsets.all(desk ? 32 : 20),
          child: _buildStep(desk, dk, card, bord, txt, sub))),
    ]));
  }

  Widget _header(BuildContext ctx, bool desk, bool dk, Color card, Color bord, Color txt, Color sub) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: desk ? 32 : 20, vertical: 16),
      decoration: BoxDecoration(color: card, border: Border(bottom: BorderSide(color: bord))),
      child: Row(children: [
        _backBtn(ctx, dk, sub), SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Import personnalisé', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: txt, letterSpacing: -0.3)),
          Text('Associez vos colonnes Excel aux champs Sage X3', style: TextStyle(fontSize: 12, color: sub)),
        ])),
      ]),
    );
  }

  Widget _backBtn(BuildContext ctx, bool dk, Color sub) => Container(
      width: 38, height: 38,
      decoration: BoxDecoration(color: dk ? Color(0xFF1a1d24) : Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
      child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(10),
          child: InkWell(onTap: () => Navigator.pop(ctx), borderRadius: BorderRadius.circular(10),
              child: Icon(Icons.arrow_back, size: 18, color: sub))));

  Widget _stepper(bool dk, Color card, Color bord, Color txt, Color sub) {
    final steps = ['Modèle', 'Fichier', 'Mapping', 'Résultat'];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      decoration: BoxDecoration(color: card, border: Border(bottom: BorderSide(color: bord))),
      child: Row(children: steps.asMap().entries.map((e) {
        final i = e.key; final isDone = i < _step; final isCurrent = i == _step;
        final c = isDone ? _green : isCurrent ? _blue : sub.withOpacity(0.4);
        return Expanded(child: Row(children: [
          Container(width: 28, height: 28,
              decoration: BoxDecoration(color: c.withOpacity(isDone ? 0.12 : isCurrent ? 0.12 : 0.06), borderRadius: BorderRadius.circular(8)),
              child: Center(child: isDone
                  ? Icon(Icons.check, size: 14, color: c)
                  : Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)))),
          SizedBox(width: 8),
          Flexible(child: Text(e.value, style: TextStyle(fontSize: 11,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
              color: isCurrent ? txt : sub), overflow: TextOverflow.ellipsis)),
          if (i < steps.length - 1)
            Padding(padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.chevron_right, size: 14, color: sub.withOpacity(0.3))),
        ]));
      }).toList()),
    );
  }

  Widget _buildStep(bool desk, bool dk, Color card, Color bord, Color txt, Color sub) {
    switch (_step) {
      case 0: return _stepSelectModel(desk, dk, card, bord, txt, sub);
      case 1: return _stepUploadFile(desk, dk, card, bord, txt, sub);
      case 2: return _stepMapColumns(desk, dk, card, bord, txt, sub);
      case 3: return _stepResult(desk, dk, card, bord, txt, sub);
      default: return SizedBox();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STEP 0 — SELECT MODEL
  // ═══════════════════════════════════════════════════════════════════════
  Widget _stepSelectModel(bool desk, bool dk, Color card, Color bord, Color txt, Color sub) {
    final filtered = _models.where((m) {
      final q = _modelSearch.toLowerCase();
      return q.isEmpty
          || (m['codeModele'] ?? '').toString().toLowerCase().contains(q)
          || (m['texte'] ?? '').toString().toLowerCase().contains(q)
          || (m['objet'] ?? '').toString().toLowerCase().contains(q);
    }).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_file != null && _excelHeaders.isNotEmpty) ...[
        Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: dk ? _cyan.withOpacity(0.08) : Color(0xFFECFEFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _cyan.withOpacity(0.25)),
          ),
          child: Row(children: [
            Icon(Icons.check_circle_outline, color: _cyan, size: 20),
            SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Fichier prêt : ${_file!.name}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: txt)),
              Text('${_excelHeaders.length} colonnes détectées — choisissez le modèle Sage correspondant',
                  style: TextStyle(fontSize: 11, color: sub)),
            ])),
          ]),
        ),
        SizedBox(height: 16),
      ],

      Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: dk ? _blue.withOpacity(0.06) : Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: dk ? _blue.withOpacity(0.15) : Color(0xFFDBEAFE)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: EdgeInsets.all(8),
              decoration: BoxDecoration(color: _blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.help_outline, color: _blue, size: 18)),
          SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Comment choisir le bon modèle ?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: txt)),
            SizedBox(height: 4),
            Text('Sélectionnez le modèle Sage X3 qui correspond à vos données. '
                'Par exemple, pour des commandes d\'achat, choisissez un modèle commande (ex. YPOHEC).\n\n'
                'Vous n\'êtes pas obligé de mapper tous les champs — seulement ceux présents dans votre Excel. '
                'Les champs optionnels peuvent rester vides.',
                style: TextStyle(fontSize: 12, color: sub, height: 1.5)),
          ])),
        ]),
      ),
      SizedBox(height: 20),

      if (_savedMappings.isNotEmpty) ...[
        Text('Mappings enregistrés', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: txt)),
        SizedBox(height: 4),
        Text('Réutilisez une configuration précédente', style: TextStyle(fontSize: 12, color: sub)),
        SizedBox(height: 14),
        ..._savedMappings.map((s) {
          final id = s['id'] as int?;
          final name = s['mappingName'] ?? '—';
          return Container(
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12), border: Border.all(color: bord)),
            child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(12),
                child: InkWell(onTap: () => _loadMapping(s), borderRadius: BorderRadius.circular(12),
                    child: Padding(padding: EdgeInsets.all(14),
                        child: Row(children: [
                          Container(padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(color: _violet.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.bookmark_outlined, color: _violet, size: 18)),
                          SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: txt)),
                            Row(children: [
                              Text(s['modelCode'] ?? '—', style: TextStyle(fontSize: 11, color: _blue, fontWeight: FontWeight.w500)),
                              SizedBox(width: 8),
                              Text('Appuyer pour charger', style: TextStyle(fontSize: 10, color: sub)),
                            ]),
                          ])),
                          if (id != null)
                            IconButton(
                              icon: Icon(Icons.delete_outline, size: 18, color: _red.withOpacity(0.7)),
                              onPressed: () => _deleteSavedMapping(id, name.toString()),
                              tooltip: 'Supprimer',
                            ),
                          Icon(Icons.arrow_forward_ios, size: 14, color: sub.withOpacity(0.4)),
                        ])))),
          );
        }),
        SizedBox(height: 24),
      ],

      Text('Choisir un modèle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: txt)),
      SizedBox(height: 4),
      Text('Sélectionnez le modèle d\'import Sage X3 adapté à vos données', style: TextStyle(fontSize: 12, color: sub)),
      SizedBox(height: 14),

      Container(height: 44,
          decoration: BoxDecoration(color: dk ? Color(0xFF1a1d24) : card, borderRadius: BorderRadius.circular(12), border: Border.all(color: bord)),
          child: TextField(
              onChanged: (v) => setState(() => _modelSearch = v),
              style: TextStyle(fontSize: 14, color: txt),
              decoration: InputDecoration(
                  hintText: 'Rechercher par code, nom ou objet…',
                  hintStyle: TextStyle(fontSize: 13, color: sub),
                  prefixIcon: Icon(Icons.search, size: 18, color: sub),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)))),
      SizedBox(height: 14),

      if (_loadingModels)
        Center(child: Padding(padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(strokeWidth: 2, color: _blue)))
      else
        ...filtered.map((m) {
          final code  = (m['codeModele'] ?? '').toString();
          final texte = (m['texte'] ?? '').toString();
          final objet = (m['objet'] ?? '').toString().trim();
          final title = texte.isNotEmpty ? texte : code;
          return Container(
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12), border: Border.all(color: bord)),
            child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(12),
                child: InkWell(onTap: () => _selectModel(code, title), borderRadius: BorderRadius.circular(12),
                    child: Padding(padding: EdgeInsets.all(14),
                        child: Row(children: [
                          Container(width: 44, height: 44,
                              decoration: BoxDecoration(color: _blue.withOpacity(dk ? 0.15 : 0.08), borderRadius: BorderRadius.circular(10)),
                              child: Center(child: Text(title[0].toUpperCase(),
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _blue)))),
                          SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: txt),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            SizedBox(height: 4),
                            Row(children: [
                              Container(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: _blue.withOpacity(0.06), borderRadius: BorderRadius.circular(4)),
                                  child: Text(code, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _blue))),
                              if (objet.isNotEmpty) ...[
                                SizedBox(width: 8),
                                Container(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: _cyan.withOpacity(0.06), borderRadius: BorderRadius.circular(4)),
                                    child: Text(objet, style: TextStyle(fontSize: 10, color: _cyan))),
                              ],
                            ]),
                          ])),
                          Icon(Icons.arrow_forward_ios, size: 14, color: sub.withOpacity(0.4)),
                        ])))),
          );
        }),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STEP 1 — UPLOAD FILE
  // ═══════════════════════════════════════════════════════════════════════
  Widget _stepUploadFile(bool desk, bool dk, Color card, Color bord, Color txt, Color sub) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: EdgeInsets.all(14),
          decoration: BoxDecoration(color: _blue.withOpacity(dk ? 0.06 : 0.04), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _blue.withOpacity(0.15))),
          child: Row(children: [
            Icon(Icons.description_outlined, size: 16, color: _blue), SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_selectedModelName ?? _selectedModelCode ?? '—',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: txt)),
              Text('Code : $_selectedModelCode  •  ${_sageFields.length} champs disponibles',
                  style: TextStyle(fontSize: 11, color: sub)),
            ])),
            TextButton(onPressed: () => setState(() => _step = 0),
                child: Text('Modifier', style: TextStyle(fontSize: 12, color: _blue))),
          ])),
      SizedBox(height: 20),

      Text('Importer votre fichier Excel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: txt)),
      SizedBox(height: 4),
      Text('La première ligne doit contenir les noms de colonnes', style: TextStyle(fontSize: 12, color: sub)),
      SizedBox(height: 20),

      GestureDetector(
        onTap: _readingHeaders ? null : _pickFile,
        child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 48, horizontal: 32),
            decoration: BoxDecoration(
                color: dk ? Color(0xFF1a1d24) : Color(0xFFFAFBFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _file != null ? _cyan.withOpacity(0.4) : bord,
                    width: _file != null ? 2 : 1.5)),
            child: Column(children: [
              Container(padding: EdgeInsets.all(18),
                  decoration: BoxDecoration(color: _cyan.withOpacity(dk ? 0.12 : 0.06), shape: BoxShape.circle),
                  child: Icon(Icons.cloud_upload_outlined, size: 40, color: _cyan)),
              SizedBox(height: 20),
              Text(_file != null ? _file!.name : 'Sélectionnez votre fichier Excel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: txt)),
              SizedBox(height: 6),
              Text('Fichiers .xlsx uniquement — en-têtes en ligne 1',
                  style: TextStyle(fontSize: 13, color: sub)),
              if (_readingHeaders) ...[
                SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _cyan)),
                  SizedBox(width: 10), Text('Lecture des colonnes…', style: TextStyle(fontSize: 13, color: _cyan)),
                ]),
              ] else if (_file == null) ...[
                SizedBox(height: 20),
                Container(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                    decoration: BoxDecoration(color: _cyan, borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: _cyan.withOpacity(0.25), blurRadius: 12, offset: Offset(0, 4))]),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.folder_open_rounded, color: Colors.white, size: 16), SizedBox(width: 8),
                      Text('Parcourir', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                    ])),
              ],
            ])),
      ),
      SizedBox(height: 16),
      if (_file != null && _excelHeaders.isNotEmpty)
        Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _step = 2),
              icon: Icon(Icons.arrow_forward, size: 16),
              label: Text('Continuer vers le mapping'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue, foregroundColor: Colors.white, elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
      TextButton.icon(onPressed: () => setState(() => _step = 0),
          icon: Icon(Icons.arrow_back, size: 14), label: Text('Retour au choix du modèle'),
          style: TextButton.styleFrom(foregroundColor: sub)),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STEP 2 — MAP COLUMNS
  // ═══════════════════════════════════════════════════════════════════════
  Widget _stepMapColumns(bool desk, bool dk, Color card, Color bord, Color txt, Color sub) {
    final unmapped = _excelHeaders.where((h) => !_mapping.containsKey(h)).toList();
    final mappedSageFields = _mapping.values.toSet();
    final requiredFields   = _sageFields.where((f) => _fieldRequired(f)).length;
    final mappedRequired   = _sageFields.where((f) => _fieldRequired(f) && mappedSageFields.contains(_fieldCode(f))).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        _infoBadge(Icons.description_outlined, '$_selectedModelCode', _blue, dk),
        _infoBadge(Icons.insert_drive_file_outlined, '${_file?.name ?? "—"}', _cyan, dk),
        _infoBadge(Icons.link, '${_mapping.length} / ${_sageFields.length} mappé(s)', _green, dk),
        _infoBadge(Icons.star_outline, '$mappedRequired / $requiredFields requis', _amber, dk),
      ]),
      SizedBox(height: 16),

      if (_mapping.isNotEmpty) ...[
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: _clearMapping,
            icon: Icon(Icons.clear_all, size: 16),
            label: Text('Effacer'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _red,
              side: BorderSide(color: _red.withOpacity(0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        SizedBox(height: 20),
      ],

      Text('Associer les colonnes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: txt)),
      SizedBox(height: 4),
      Text(
        desk
            ? 'Glissez vos colonnes Excel (gauche) vers les champs Sage X3 (droite). Les champs obligatoires sont marqués ★.'
            : 'Appuyez sur « Choisir… » en face de chaque colonne Excel pour lui associer un champ Sage X3. Les champs requis sont marqués ★.',
        style: TextStyle(fontSize: 12, color: sub, height: 1.4),
      ),
      SizedBox(height: 20),

      desk
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _excelPanel(unmapped, dk, card, bord, txt, sub)),
        SizedBox(width: 20),
        Expanded(child: _sagePanel(mappedSageFields, dk, card, bord, txt, sub)),
      ])
          : _mobileMapPanel(dk, card, bord, txt, sub),

      SizedBox(height: 24),

      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          TextButton.icon(onPressed: () => setState(() => _step = 1),
              icon: Icon(Icons.arrow_back, size: 14), label: Text('Retour'),
              style: TextButton.styleFrom(foregroundColor: sub)),
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (_mapping.isNotEmpty) ...[
              OutlinedButton.icon(onPressed: _saveMapping,
                  icon: Icon(Icons.bookmark_add_outlined, size: 14), label: Text('Enregistrer'),
                  style: OutlinedButton.styleFrom(foregroundColor: _violet,
                      side: BorderSide(color: _violet.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
              SizedBox(width: 10),
            ],
            Container(
              decoration: BoxDecoration(
                  gradient: _mapping.isNotEmpty ? LinearGradient(colors: [_green, Color(0xFF10b981)]) : null,
                  color: _mapping.isEmpty ? sub.withOpacity(0.2) : null,
                  borderRadius: BorderRadius.circular(12)),
              child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                      onTap: _mapping.isNotEmpty && !_uploading ? _convert : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.play_arrow_rounded,
                                color: _mapping.isNotEmpty ? Colors.white : sub, size: 18),
                            SizedBox(width: 6),
                            Text('Convertir en CSV', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                color: _mapping.isNotEmpty ? Colors.white : sub)),
                          ])))),
            ),
          ]),
        ],
      ),
      if (_uploading) ...[
        SizedBox(height: 20),
        ClipRRect(borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: _progress, minHeight: 6,
                backgroundColor: _blue.withOpacity(0.1), color: _blue)),
      ],
    ]);
  }

  Widget _infoBadge(IconData icon, String text, Color color, bool dk) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(dk ? 0.12 : 0.06), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color), SizedBox(width: 5),
        Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  MOBILE MAP PANEL
  //  FIX: boutons toolbar en icônes seules → évite le débordement Row (+57px)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _mobileMapPanel(bool dk, Color card, Color bord, Color txt, Color sub) {
    final filteredSageFields = _sageFields.where((f) {
      final q = _fieldSearch.toLowerCase();
      return q.isEmpty ||
          _fieldCode(f).toLowerCase().contains(q) ||
          _fieldName(f).toLowerCase().contains(q);
    }).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── FIX: boutons icônes uniquement pour éviter le débordement ────────
      Row(children: [
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: dk ? Color(0xFF1a1d24) : card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: bord),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _fieldSearch = v),
              style: TextStyle(fontSize: 13, color: txt),
              decoration: InputDecoration(
                hintText: 'Filtrer les champs Sage…',
                hintStyle: TextStyle(fontSize: 12, color: sub),
                prefixIcon: Icon(Icons.search, size: 16, color: sub),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
        // Bouton Auto — icône seule
        GestureDetector(
          onTap: _autoMapColumns,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _cyan.withOpacity(dk ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _cyan.withOpacity(0.3)),
            ),
            child: Icon(Icons.auto_fix_high, size: 18, color: _cyan),
          ),
        ),
        SizedBox(width: 8),
        // Bouton Effacer — icône seule
        if (_mapping.isNotEmpty)
          GestureDetector(
            onTap: _clearMapping,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _red.withOpacity(dk ? 0.12 : 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _red.withOpacity(0.25)),
              ),
              child: Icon(Icons.link_off, size: 18, color: _red),
            ),
          ),
      ]),
      SizedBox(height: 12),

      // ── En-têtes des colonnes ────────────────────────────────────────
      Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: dk ? Color(0xFF1a1d24) : Color(0xFFF3F4F6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          border: Border.all(color: bord),
        ),
        child: Row(children: [
          Expanded(child: Row(children: [
            Icon(Icons.table_chart_outlined, size: 13, color: _cyan),
            SizedBox(width: 6),
            Text('Colonne Excel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: sub, letterSpacing: 0.5)),
          ])),
          SizedBox(width: 10),
          Expanded(child: Row(children: [
            Icon(Icons.schema_outlined, size: 13, color: _blue),
            SizedBox(width: 6),
            Text('Champ Sage X3', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: sub, letterSpacing: 0.5)),
          ])),
        ]),
      ),

      // ── Lignes de mapping ────────────────────────────────────────────
      Container(
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
          border: Border(
            left: BorderSide(color: bord),
            right: BorderSide(color: bord),
            bottom: BorderSide(color: bord),
          ),
        ),
        child: Column(
          children: _excelHeaders.asMap().entries.map((entry) {
            final i = entry.key;
            final col = entry.value;
            final currentSageCode = _mapping[col];
            final isMapped = currentSageCode != null;
            final isLast = i == _excelHeaders.length - 1;

            final currentSageField = isMapped
                ? _sageFields.firstWhere(
                  (f) => _fieldCode(f) == currentSageCode,
              orElse: () => {},
            )
                : null;
            final isRequired = currentSageField != null && _fieldRequired(currentSageField);

            return Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMapped
                    ? (isRequired ? _green.withOpacity(dk ? 0.05 : 0.03) : Colors.transparent)
                    : Colors.transparent,
                border: isLast ? null : Border(bottom: BorderSide(color: bord, width: 0.8)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                // Colonne Excel
                Expanded(
                  child: Row(children: [
                    Container(
                      width: 7, height: 7,
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isMapped ? _green : sub.withOpacity(0.35),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(col,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isMapped ? FontWeight.w600 : FontWeight.w400,
                          color: isMapped ? txt : sub,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ),

                // Flèche
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 14,
                      color: isMapped ? _green.withOpacity(0.7) : sub.withOpacity(0.3)),
                ),

                // Dropdown Sage X3
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showSageFieldPicker(col, filteredSageFields, dk, card, bord, txt, sub),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isMapped
                            ? _green.withOpacity(dk ? 0.12 : 0.07)
                            : (dk ? Color(0xFF1a1d24) : Color(0xFFF9FAFB)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isMapped ? _green.withOpacity(0.4) : bord,
                          width: isMapped ? 1.5 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: isMapped
                              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_fieldName(currentSageField!),
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _green),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(currentSageCode,
                                style: TextStyle(fontSize: 9, color: _green.withOpacity(0.7),
                                    fontFamily: 'monospace'),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ])
                              : Text('Choisir…', style: TextStyle(fontSize: 12, color: sub)),
                        ),
                        if (isMapped)
                          GestureDetector(
                            onTap: () => _unmapColumn(col),
                            child: Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.close, size: 14, color: _red.withOpacity(0.7)),
                            ),
                          )
                        else
                          Icon(Icons.expand_more, size: 16, color: sub),
                      ]),
                    ),
                  ),
                ),
              ]),
            );
          }).toList(),
        ),
      ),
    ]);
  }

  // ── Sélecteur de champ Sage (bottom sheet)
  //  FIX 1: hauteur précalculée avant ouverture → évite Column overflow 99610px
  //  FIX 2: dispose après le prochain frame → évite "controller used after dispose"
  Future<void> _showSageFieldPicker(
      String excelCol,
      List<Map<String, dynamic>> fields,
      bool dk, Color card, Color bord, Color txt, Color sub,
      ) async {
    // FIX: précalculer la hauteur ici avec le bon context
    final sheetHeight = MediaQuery.of(context).size.height * 0.75;

    final searchCtrl = TextEditingController();
    List<Map<String, dynamic>> filtered = List.from(fields);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            height: sheetHeight, // FIX: valeur précalculée
            decoration: BoxDecoration(
              color: dk ? Color(0xFF151921) : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(children: [
              Container(
                margin: EdgeInsets.only(top: 12, bottom: 8),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: sub.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(children: [
                  Icon(Icons.schema_outlined, size: 16, color: _blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Champ pour « $excelCol »',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: txt),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  if (_mapping.containsKey(excelCol))
                    TextButton(
                      onPressed: () { _unmapColumn(excelCol); Navigator.pop(ctx); },
                      child: Text('Effacer', style: TextStyle(color: _red, fontSize: 12)),
                    ),
                ]),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: searchCtrl,
                  autofocus: true,
                  style: TextStyle(fontSize: 14, color: txt),
                  onChanged: (v) {
                    final q = v.toLowerCase();
                    setModalState(() {
                      filtered = fields.where((f) =>
                      q.isEmpty ||
                          _fieldCode(f).toLowerCase().contains(q) ||
                          _fieldName(f).toLowerCase().contains(q) ||
                          _fieldGroup(f).toLowerCase().contains(q)).toList();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Rechercher un champ…',
                    hintStyle: TextStyle(fontSize: 13, color: sub),
                    prefixIcon: Icon(Icons.search, size: 16, color: sub),
                    filled: true,
                    fillColor: dk ? Color(0xFF1a1d24) : Color(0xFFF3F4F6),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              Divider(height: 1, color: bord),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: bord, indent: 16, endIndent: 16),
                  itemBuilder: (_, i) {
                    final f = filtered[i];
                    final code = _fieldCode(f);
                    final name = _fieldName(f);
                    final group = _fieldGroup(f);
                    final required = _fieldRequired(f);
                    final isCurrentlyMapped = _mapping[excelCol] == code;
                    final usedByOther = _mapping.entries
                        .where((e) => e.key != excelCol && e.value == code)
                        .isNotEmpty;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: usedByOther ? null : () {
                          _mapColumn(excelCol, code);
                          Navigator.pop(ctx);
                        },
                        child: Opacity(
                          opacity: usedByOther ? 0.4 : 1.0,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(children: [
                              if (required)
                                Icon(Icons.star, size: 10,
                                    color: isCurrentlyMapped ? _green : _amber)
                              else
                                Container(width: 6, height: 6,
                                    decoration: BoxDecoration(
                                        color: isCurrentlyMapped ? _green : sub.withOpacity(0.25),
                                        shape: BoxShape.circle)),
                              SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                    color: isCurrentlyMapped ? _green : txt)),
                                SizedBox(height: 3),
                                Row(children: [
                                  Text(code, style: TextStyle(fontSize: 10, color: sub,
                                      fontFamily: 'monospace', fontWeight: FontWeight.w500)),
                                  if (group.isNotEmpty) ...[
                                    SizedBox(width: 6),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(color: _cyan.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(3)),
                                      child: Text(group, style: TextStyle(fontSize: 8,
                                          color: _cyan, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                  if (!required) ...[
                                    SizedBox(width: 6),
                                    Text('optionnel', style: TextStyle(fontSize: 8,
                                        color: sub.withOpacity(0.5), fontStyle: FontStyle.italic)),
                                  ],
                                  if (usedByOther) ...[
                                    SizedBox(width: 6),
                                    Text('déjà utilisé', style: TextStyle(fontSize: 8,
                                        color: _amber, fontStyle: FontStyle.italic)),
                                  ],
                                ]),
                              ])),
                              if (isCurrentlyMapped)
                                Icon(Icons.check_circle, size: 18, color: _green),
                            ]),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ]),
          );
        },
      ),
    );
    // FIX: dispose après le prochain frame pour éviter "controller used after dispose"
    WidgetsBinding.instance.addPostFrameCallback((_) => searchCtrl.dispose());
  }

  // ── Excel columns panel ───────────────────────────────────────────────
  Widget _excelPanel(List<String> unmapped, bool dk, Color card, Color bord, Color txt, Color sub) {
    return Container(
      constraints: BoxConstraints(maxHeight: 520),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(children: [
              Icon(Icons.table_chart_outlined, size: 16, color: _cyan), SizedBox(width: 8),
              Text('Colonnes Excel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: txt)),
              Spacer(),
              Text('${unmapped.length} restante(s)', style: TextStyle(fontSize: 11, color: sub)),
            ])),
        Divider(height: 1, color: bord),
        Expanded(child: ListView(children: [
          ..._mapping.entries.map((e) {
            final sageField = _sageFields.firstWhere((f) => _fieldCode(f) == e.value, orElse: () => {});
            final sageName = sageField.isNotEmpty ? _fieldName(sageField) : e.value;
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: bord))),
              child: Row(children: [
                Icon(Icons.link, size: 14, color: _green), SizedBox(width: 10),
                Expanded(child: Text(e.key,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _green))),
                Icon(Icons.arrow_forward, size: 12, color: _green.withOpacity(0.5)), SizedBox(width: 6),
                Flexible(child: Text(sageName,
                    style: TextStyle(fontSize: 11, color: _green, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis)),
                SizedBox(width: 8),
                GestureDetector(onTap: () => _unmapColumn(e.key),
                    child: Icon(Icons.close, size: 14, color: _red.withOpacity(0.6))),
              ]),
            );
          }),
          if (unmapped.isNotEmpty)
            ...unmapped.map((col) => Draggable<String>(
              data: col,
              feedback: Material(color: Colors.transparent,
                  child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: _cyan, borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: _cyan.withOpacity(0.3), blurRadius: 12)]),
                      child: Text(col, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)))),
              childWhenDragging: Container(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(color: _cyan.withOpacity(0.04),
                    border: Border(bottom: BorderSide(color: bord))),
                child: Row(children: [
                  Icon(Icons.drag_indicator, size: 14, color: sub.withOpacity(0.3)), SizedBox(width: 10),
                  Text(col, style: TextStyle(fontSize: 13, color: sub.withOpacity(0.4))),
                ]),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: bord))),
                child: Row(children: [
                  Icon(Icons.drag_indicator, size: 14, color: sub), SizedBox(width: 10),
                  Expanded(child: Text(col,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: txt))),
                  Icon(Icons.open_with, size: 14, color: _cyan.withOpacity(0.5)),
                ]),
              ),
            )),
          if (unmapped.isEmpty && _mapping.isEmpty)
            Padding(padding: EdgeInsets.all(24),
                child: Center(child: Text('Aucune colonne trouvée',
                    style: TextStyle(fontSize: 12, color: sub)))),
        ])),
      ]),
    );
  }

  // ── Sage fields panel (drop targets) ──────────────────────────────────
  Widget _sagePanel(Set<String> mapped, bool dk, Color card, Color bord, Color txt, Color sub) {
    final q = _fieldSearch.toLowerCase();
    final filteredFields = _sageFields.where((f) {
      if (q.isEmpty) return true;
      return _fieldCode(f).toLowerCase().contains(q) ||
          _fieldName(f).toLowerCase().contains(q) ||
          _fieldGroup(f).toLowerCase().contains(q);
    }).toList();

    return Container(
      constraints: BoxConstraints(maxHeight: 520),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Row(children: [
              Icon(Icons.schema_outlined, size: 16, color: _blue), SizedBox(width: 8),
              Text('Champs Sage X3', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: txt)),
              Spacer(),
              Text('${filteredFields.length} / ${_sageFields.length}', style: TextStyle(fontSize: 11, color: sub)),
            ])),
        Padding(
          padding: EdgeInsets.fromLTRB(18, 0, 18, 10),
          child: TextField(
            onChanged: (v) => setState(() => _fieldSearch = v),
            style: TextStyle(fontSize: 13, color: txt),
            decoration: InputDecoration(
              hintText: 'Rechercher un champ…',
              hintStyle: TextStyle(fontSize: 12, color: sub),
              prefixIcon: Icon(Icons.search, size: 16, color: sub),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        Divider(height: 1, color: bord),

        if (_loadingFields)
          Expanded(child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _blue)))
        else if (filteredFields.isEmpty)
          Expanded(child: Center(child: Text('Aucun champ correspondant',
              style: TextStyle(fontSize: 12, color: sub))))
        else
          Expanded(child: ListView(children: [
            ...filteredFields.map((f) {
              final code     = _fieldCode(f);
              final desc     = _fieldName(f);
              final group    = _fieldGroup(f);
              final required = _fieldRequired(f);
              final isMapped = mapped.contains(code);
              final mappedFrom = _mapping.entries.where((e) => e.value == code).map((e) => e.key).firstOrNull;

              return DragTarget<String>(
                onWillAcceptWithDetails: (_) => true,
                onAcceptWithDetails: (details) => _mapColumn(details.data, code),
                builder: (context, candidateData, rejectedData) {
                  final hovering = candidateData.isNotEmpty;
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: hovering ? _blue.withOpacity(0.08)
                          : isMapped ? _green.withOpacity(dk ? 0.06 : 0.03)
                          : Colors.transparent,
                      border: Border(bottom: BorderSide(
                          color: hovering ? _blue.withOpacity(0.3) : bord)),
                    ),
                    child: Row(children: [
                      if (required)
                        Padding(padding: EdgeInsets.only(right: 6),
                            child: Icon(Icons.star, size: 10, color: isMapped ? _green : _amber))
                      else
                        Padding(padding: EdgeInsets.only(right: 6),
                            child: Container(width: 6, height: 6,
                                decoration: BoxDecoration(
                                    color: isMapped ? _green : sub.withOpacity(0.2),
                                    shape: BoxShape.circle))),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(desc, style: TextStyle(fontSize: 13,
                            fontWeight: isMapped ? FontWeight.w600 : FontWeight.w500,
                            color: isMapped ? _green : txt),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        SizedBox(height: 2),
                        Row(children: [
                          Text(code, style: TextStyle(fontSize: 10, color: sub,
                              fontFamily: 'monospace', fontWeight: FontWeight.w500)),
                          SizedBox(width: 6),
                          Container(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(color: _cyan.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(3)),
                              child: Text(group, style: TextStyle(fontSize: 8,
                                  fontWeight: FontWeight.w600, color: _cyan))),
                          if (!required) ...[
                            SizedBox(width: 6),
                            Text('optionnel', style: TextStyle(fontSize: 8,
                                color: sub.withOpacity(0.5), fontStyle: FontStyle.italic)),
                          ],
                        ]),
                      ])),
                      if (isMapped && mappedFrom != null) ...[
                        Icon(Icons.arrow_back, size: 12, color: _green.withOpacity(0.5)), SizedBox(width: 4),
                        Flexible(child: Text(mappedFrom,
                            style: TextStyle(fontSize: 10, color: _green, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis)),
                      ] else
                        Text(hovering ? 'Relâcher ici' : 'Déposer ici',
                            style: TextStyle(fontSize: 10,
                                color: hovering ? _blue : sub.withOpacity(0.4))),
                    ]),
                  );
                },
              );
            }),
          ])),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STEP 3 — RESULT
  // ═══════════════════════════════════════════════════════════════════════
  Widget _stepResult(bool desk, bool dk, Color card, Color bord, Color txt, Color sub) {
    if (_success == true) {
      final hasCsv = _csv != null && _csv!.isNotEmpty;
      return Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: dk ? _green.withOpacity(0.06) : Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: dk ? _green.withOpacity(0.2) : Color(0xFFbbf7d0))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: EdgeInsets.all(10),
                decoration: BoxDecoration(color: _green.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.check_circle_rounded, color: _green, size: 24)),
            SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Conversion réussie !', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _green)),
              Text('$_modelCode  •  $_rowCount ligne(s) convertie(s)', style: TextStyle(fontSize: 13, color: sub)),
            ])),
          ]),
          if (hasCsv) ...[
            SizedBox(height: 18),
            Container(
                width: double.infinity, padding: EdgeInsets.all(14),
                decoration: BoxDecoration(color: dk ? Color(0xFF151921) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _green.withOpacity(0.2))),
                constraints: BoxConstraints(maxHeight: 120),
                child: SingleChildScrollView(child: Text(
                    _csv!.length > 500 ? '${_csv!.substring(0, 500)}\n...' : _csv!,
                    style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: txt.withOpacity(0.7))))),
            SizedBox(height: 18),
            Container(
                width: double.infinity, height: 50,
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_green, Color(0xFF10b981)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: _green.withOpacity(0.25), blurRadius: 12, offset: Offset(0, 4))]),
                child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(12),
                    child: InkWell(onTap: _downloadCsv, borderRadius: BorderRadius.circular(12),
                        child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.download_rounded, color: Colors.white, size: 18), SizedBox(width: 8),
                          Text('Télécharger le CSV',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                        ]))))),
          ],
          SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 44,
              child: OutlinedButton.icon(onPressed: _reset,
                  icon: Icon(Icons.refresh, size: 16), label: Text('Nouvel import'),
                  style: OutlinedButton.styleFrom(foregroundColor: _green,
                      side: BorderSide(color: _green.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
        ]),
      );
    }
    return _buildErrorReport(desk, dk, card, bord, txt, sub);
  }

  String _classifyError(Map e) {
    switch ((e['errorType'] ?? '').toString()) {
      case 'EmptyRequired':    return 'Champ vide';
      case 'InvalidDate':      return 'Date incorrecte';
      case 'InvalidNumber':    return 'Nombre invalide';
      case 'TooLong':          return 'Texte trop long';
      case 'UnmappedRequired': return 'Champ non mappé';
      case 'System':           return 'Erreur système';
    }
    final msg = (e['message'] ?? '').toString().toLowerCase();
    final row = e['row'] ?? 0;
    if (row == 0 && (e['field'] ?? '').toString().isEmpty) return 'Erreur système';
    if (msg.contains('vide') || msg.contains('obligatoire')) return 'Champ vide';
    if (msg.contains('date'))   return 'Date incorrecte';
    if (msg.contains('nombre') || msg.contains('numérique')) return 'Nombre invalide';
    if (msg.contains('dépasse') || msg.contains('caractères')) return 'Texte trop long';
    return 'Autre';
  }

  String _errorTip(String type, Map e) {
    final msg = (e['message'] ?? '').toString();
    switch (type) {
      case 'Champ vide':      return 'Ce champ est obligatoire. Remplissez-le dans votre fichier Excel.';
      case 'Date incorrecte':
        final fmtMatch = RegExp(r'Format attendu\s*:\s*(\S+)').firstMatch(msg);
        final fmt = fmtMatch?.group(1) ?? 'JJ/MM/AAAA';
        return 'Entrez la date au format $fmt. Exemple : ${_dateExample(fmt)}';
      case 'Nombre invalide':  return 'Ce champ n\'accepte que des chiffres. Exemples : 100, 3.5, 0';
      case 'Texte trop long':
        final lenMatch = RegExp(r'dépasse (\d+) caractères').firstMatch(msg);
        final max = lenMatch?.group(1) ?? '?';
        return 'Maximum $max caractères autorisés. Raccourcissez la valeur.';
      case 'Champ non mappé': return 'Associez ce champ obligatoire à une colonne de votre Excel.';
      default:                return 'Vérifiez la valeur et réessayez.';
    }
  }

  String _dateExample(String fmt) {
    final now = DateTime.now();
    final d = now.day.toString().padLeft(2, '0');
    final m = now.month.toString().padLeft(2, '0');
    final y = now.year.toString();
    if (fmt.contains('YYYY') || fmt.contains('yyyy')) {
      if (fmt.startsWith('Y')) return '$y$m$d';
      return '$d/$m/$y';
    }
    return '$d/$m/$y';
  }

  Color _errorTypeColor(String type) {
    switch (type) {
      case 'Champ vide':      return _red;
      case 'Date incorrecte': return _amber;
      case 'Nombre invalide': return _violet;
      case 'Texte trop long': return _cyan;
      case 'Champ non mappé': return Color(0xFFf97316);
      default:                return Color(0xFF6b7280);
    }
  }

  IconData _errorTypeIcon(String type) {
    switch (type) {
      case 'Champ vide':      return Icons.remove_circle_outline_rounded;
      case 'Date incorrecte': return Icons.calendar_today_rounded;
      case 'Nombre invalide': return Icons.numbers_rounded;
      case 'Texte trop long': return Icons.text_fields_rounded;
      case 'Champ non mappé': return Icons.link_off_rounded;
      default:                return Icons.warning_amber_rounded;
    }
  }

  void _exportErrorReport() {
    final lines = <String>[];
    lines.add('Rapport d\'erreurs — ${_file?.name ?? ''} — ${DateTime.now().toLocal()}');
    lines.add('Modèle : ${_modelCode ?? _selectedModelCode ?? ''}');
    lines.add('Total erreurs : ${_errors.length}');
    lines.add('');
    lines.add('Ligne\tChamp\tType\tMessage\tConseil');
    for (final e in _errors) {
      final type = _classifyError(e as Map);
      final tip  = _errorTip(type, e);
      lines.add('${e['row'] ?? ''}\t${e['field'] ?? ''}\t$type\t${e['message'] ?? ''}\t$tip');
    }
    final bytes = Uint8List.fromList(utf8.encode(lines.join('\n')));
    final name = 'rapport_erreurs_${DateTime.now().millisecondsSinceEpoch}.txt';
    kIsWeb ? triggerWebDownload(bytes, name) : saveMobileFile(bytes, name);
  }

  Widget _buildErrorReport(bool desk, bool dk, Color card, Color bord, Color txt, Color sub) {
    final Map<int, List<dynamic>> byRow = {};
    for (final e in _errors) {
      final row = (e as Map)['row'] as int? ?? 0;
      byRow.putIfAbsent(row, () => []).add(e);
    }
    final sortedRows = byRow.keys.toList()..sort();
    final Map<String, int> typeCounts = {};
    for (final e in _errors) {
      final t = _classifyError(e as Map);
      typeCounts[t] = (typeCounts[t] ?? 0) + 1;
    }
    final affectedRows = sortedRows.where((r) => r > 0).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: dk ? _red.withOpacity(0.07) : Color(0xFFFEF2F2),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          border: Border.all(color: dk ? _red.withOpacity(0.3) : Color(0xFFFECACA)),
        ),
        child: Row(children: [
          Container(padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: _red.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(Icons.error_outline_rounded, color: _red, size: 26)),
          SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Le fichier contient des erreurs',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _red)),
            SizedBox(height: 4),
            Text(
                affectedRows > 0
                    ? '$affectedRows ligne${affectedRows > 1 ? 's' : ''} à corriger · '
                    '${_errors.length} erreur${_errors.length > 1 ? 's' : ''} au total'
                    : '${_errors.length} erreur${_errors.length > 1 ? 's' : ''} de structure détectée${_errors.length > 1 ? 's' : ''}',
                style: TextStyle(fontSize: 12, color: sub)),
          ])),
          TextButton.icon(
            onPressed: _exportErrorReport,
            icon: Icon(Icons.download_outlined, size: 15),
            label: Text('Exporter', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: _red,
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
          ),
        ]),
      ),

      if (typeCounts.isNotEmpty)
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: dk ? Color(0xFF1a1d24) : Color(0xFFFFF7F7),
            border: Border(
              left: BorderSide(color: dk ? _red.withOpacity(0.2) : Color(0xFFFECACA)),
              right: BorderSide(color: dk ? _red.withOpacity(0.2) : Color(0xFFFECACA)),
            ),
          ),
          child: Wrap(spacing: 8, runSpacing: 6, children: [
            ...typeCounts.entries.map((entry) {
              final c = _errorTypeColor(entry.key);
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: c.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20), border: Border.all(color: c.withOpacity(0.3))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_errorTypeIcon(entry.key), size: 12, color: c), SizedBox(width: 5),
                  Text(entry.key, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c)),
                  SizedBox(width: 5),
                  Container(padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text('${entry.value}',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c))),
                ]),
              );
            }),
          ]),
        ),

      Container(
        constraints: BoxConstraints(maxHeight: 420),
        decoration: BoxDecoration(
          color: dk ? Color(0xFF0f1117) : Colors.white,
          border: Border(
            left: BorderSide(color: dk ? _red.withOpacity(0.2) : Color(0xFFFECACA)),
            right: BorderSide(color: dk ? _red.withOpacity(0.2) : Color(0xFFFECACA)),
          ),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.symmetric(vertical: 8),
          itemCount: sortedRows.length,
          separatorBuilder: (_, __) => Divider(height: 1,
              color: dk ? Color(0xFF1e2028) : Color(0xFFF3F4F6), indent: 16, endIndent: 16),
          itemBuilder: (_, i) {
            final rowNum = sortedRows[i];
            final rowErrors = byRow[rowNum]!;
            final isStructural = rowNum == 0;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isStructural ? Color(0xFF6b7280).withOpacity(0.15) : _red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(isStructural ? 'Fichier' : 'Ligne ${rowNum}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: isStructural ? Color(0xFF6b7280) : _red)),
                  ),
                  SizedBox(width: 8),
                  Text('${rowErrors.length} erreur${rowErrors.length > 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 11, color: sub)),
                ]),
                SizedBox(height: 10),
                ...rowErrors.map((e) {
                  final em = e as Map;
                  final type = _classifyError(em);
                  final typeColor = _errorTypeColor(type);
                  final tip = _errorTip(type, em);
                  final msgStr = (em['message'] ?? '').toString();
                  final fieldMatch = RegExp(r'"([^"]+)"').firstMatch(msgStr);
                  final fieldName = fieldMatch?.group(1) ?? (em['field'] ?? '').toString();
                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(dk ? 0.06 : 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: typeColor.withOpacity(0.2)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(_errorTypeIcon(type), size: 14, color: typeColor),
                        SizedBox(width: 6),
                        Container(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: typeColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4)),
                            child: Text(type, style: TextStyle(fontSize: 10,
                                fontWeight: FontWeight.w700, color: typeColor))),
                        if (fieldName.isNotEmpty) ...[
                          SizedBox(width: 8),
                          Flexible(child: Text('· $fieldName',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: txt),
                              overflow: TextOverflow.ellipsis)),
                        ],
                      ]),
                      SizedBox(height: 8),
                      Text(msgStr, style: TextStyle(fontSize: 12, color: txt.withOpacity(0.85))),
                      SizedBox(height: 6),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.lightbulb_outline_rounded, size: 13, color: _amber),
                        SizedBox(width: 5),
                        Expanded(child: Text(tip, style: TextStyle(fontSize: 11,
                            color: _amber, fontStyle: FontStyle.italic))),
                      ]),
                    ]),
                  );
                }),
              ]),
            );
          },
        ),
      ),

      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dk ? Color(0xFF151921) : Color(0xFFFFF1F1),
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
          border: Border.all(color: dk ? _red.withOpacity(0.2) : Color(0xFFFECACA)),
        ),
        child: Column(children: [
          Container(
            width: double.infinity, padding: EdgeInsets.all(12),
            margin: EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: dk ? Color(0xFF1a1d24) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: dk ? Color(0xFF1e2028) : Color(0xFFE5E7EB)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline_rounded, size: 15, color: _blue), SizedBox(width: 8),
              Expanded(child: Text(
                'Corrigez les erreurs dans votre fichier Excel en suivant les conseils ci-dessus, '
                    'puis relancez la conversion.',
                style: TextStyle(fontSize: 12, color: sub, height: 1.4),
              )),
            ]),
          ),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () => setState(() {
                _step = 0;
                _file = null;
                _excelHeaders = [];
                _mapping = {};
                _success = null;
                _errors = [];
                _csv = null;
                _selectedModelCode = null;
                _selectedModelName = null;
                _fieldSearch = '';
                _activeMappingId = null;
              }),
              icon: Icon(Icons.arrow_back, size: 15),
              label: Text('Changer de modèle', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(foregroundColor: _amber,
                  side: BorderSide(color: _amber.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: Size(0, 44)),
            )),
            SizedBox(width: 10),
            Expanded(child: ElevatedButton.icon(
              onPressed: _reset,
              icon: Icon(Icons.refresh, size: 15),
              label: Text('Recommencer', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: Size(0, 44)),
            )),
          ]),
        ]),
      ),
    ]);
  }
}

class _MF { final String path; _MF(this.path); }