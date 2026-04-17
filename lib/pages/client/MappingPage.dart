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
  List<Map<String, dynamic>> _modelsDetails = []; // with field counts
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
  void initState() { super.initState(); _loadModels(); _loadSavedMappings(); }

  Future<void> _loadModels() async {
    setState(() => _loadingModels = true);
    try {
      final d = await _api.getModels();
      setState(() { _models = d; _loadingModels = false; });
    } catch (_) { setState(() => _loadingModels = false); }
  }

  Future<void> _loadSavedMappings() async {
    try {
      final d = await _api.getSavedMappings();
      setState(() => _savedMappings = d);
    } catch (_) {}
  }

  Future<void> _selectModel(String code, String name) async {
    setState(() { _selectedModelCode = code; _selectedModelName = name; _loadingFields = true; _step = 1; });
    try {
      final fields = await _api.getModelFields(code);
      setState(() { _sageFields = fields; _loadingFields = false; });
    } catch (_) { setState(() => _loadingFields = false); }
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
      setState(() { _excelHeaders = headers; _readingHeaders = false; _step = 2; });
    } catch (e) {
      setState(() => _readingHeaders = false);
      _snack('Failed to read headers: $e', _red);
    }
  }

  void _mapColumn(String excelCol, String sageField) {
    setState(() {
      _mapping.removeWhere((_, v) => v == sageField);
      _mapping[excelCol] = sageField;
    });
  }

  void _unmapColumn(String excelCol) => setState(() => _mapping.remove(excelCol));

  Future<void> _convert() async {
    if (_mapping.isEmpty) { _snack('Map at least one column first', _amber); return; }
    setState(() { _uploading = true; _progress = 0; _success = null; _errors = []; });
    final mappingJson = jsonEncode(_mapping.entries.map((e) => {'excelColumn': e.key, 'sageField': e.value}).toList());
    try {
      Map<String, dynamic> result;
      if (kIsWeb) {
        result = await _api.uploadWithMapping(file: _file!.bytes!, fileName: _file!.name,
            modelCode: _selectedModelCode!, columnMappings: mappingJson,
            onProgress: (p) => setState(() => _progress = p));
      } else {
        result = await _api.uploadWithMapping(file: _MF(_file!.path!), fileName: _file!.name,
            modelCode: _selectedModelCode!, columnMappings: mappingJson,
            onProgress: (p) => setState(() => _progress = p));
      }
      setState(() { _uploading = false; _success = result['success'] ?? false;
        _modelCode = result['modelCode']; _rowCount = result['rowCount'];
        _csv = result['csvContent']; _errors = result['errors'] ?? []; _step = 3; });
    } catch (e) {
      setState(() { _uploading = false; _success = false;
        _errors = [{'row': 0, 'field': '', 'message': e.toString()}]; _step = 3; });
    }
  }

  Future<void> _saveMapping() async {
    final nameCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Save Mapping', style: TextStyle(fontWeight: FontWeight.bold)),
      content: TextField(controller: nameCtrl, autofocus: true,
          decoration: InputDecoration(labelText: 'Mapping name', hintText: 'e.g. My Purchase Orders',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Color(0xFFF7F8FA))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _violet, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Save')),
      ],
    ));
    if (confirmed != true || nameCtrl.text.trim().isEmpty) return;
    try {
      final mappingJson = jsonEncode(_mapping.entries.map((e) => {'excelColumn': e.key, 'sageField': e.value}).toList());
      await _api.saveMapping(ApiService.userId, nameCtrl.text.trim(), _selectedModelCode!, mappingJson);
      _loadSavedMappings();
      _snack('Mapping saved!', _green);
    } catch (e) { _snack('$e', _red); }
  }

  Future<void> _loadMapping(Map<String, dynamic> saved) async {
    final code = saved['modelCode'] as String;
    final texte = _models.firstWhere((m) => m['codeModele'] == code, orElse: () => {})['texte'] ?? code;
    await _selectModel(code, texte.isNotEmpty ? texte : code);
    try {
      final entries = jsonDecode(saved['columnMappings'] as String) as List;
      final loaded = <String, String>{};
      for (final e in entries) loaded[e['excelColumn'] as String] = e['sageField'] as String;
      setState(() => _mapping = loaded);
      _snack('Mapping "${saved['mappingName']}" loaded. Now upload your file.', _blue);
    } catch (_) { _snack('Failed to load mapping', _red); }
  }

  void _downloadCsv() {
    if (_csv == null) return;
    final name = '${_modelCode ?? 'export'}_mapped_${DateTime.now().millisecondsSinceEpoch}.csv';
    final bytes = Uint8List.fromList(utf8.encode(_csv!));
    kIsWeb ? triggerWebDownload(bytes, name) : saveMobileFile(bytes, name);
  }

  void _reset() => setState(() { _step = 0; _file = null; _excelHeaders = []; _mapping = {};
    _success = null; _errors = []; _csv = null; _selectedModelCode = null; _selectedModelName = null; });

  void _snack(String msg, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle(fontSize: 13)), backgroundColor: c,
      behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));

  // ── Sage field helpers ────────────────────────────────────────────────
  String _fieldName(Map<String, dynamic> f) => (f['designation'] ?? f['champ'] ?? '—').toString();
  String _fieldCode(Map<String, dynamic> f) => (f['champ'] ?? '—').toString();
  String _fieldGroup(Map<String, dynamic> f) => (f['indicateurGroup'] ?? '').toString();
  bool   _fieldRequired(Map<String, dynamic> f) {
    final code = _fieldCode(f).toUpperCase();
    // Same logic as IsOptionalField in backend
    return !(code == 'DISCRGVAL1' || code == 'DISCRGVAL2' || code == 'DISCRGVAL3' ||
        code == 'ORDREF' || code == 'VACBPR' || code == 'MDL' || code == 'EECICT' ||
        code == 'CHGCOE' || code == 'VAT' || code == 'ITMDES' || code == 'COM_0' ||
        code.endsWith('COMMENT') || code.endsWith('NOTE') || code.endsWith('REM'));
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
      Expanded(child: SingleChildScrollView(padding: EdgeInsets.all(desk ? 32 : 20),
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
          Text('Custom Import', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: txt, letterSpacing: -0.3)),
          Text('Map your own Excel columns to Sage X3 fields', style: TextStyle(fontSize: 12, color: sub)),
        ])),
      ]),
    );
  }

  Widget _backBtn(BuildContext ctx, bool dk, Color sub) => Container(width: 38, height: 38,
      decoration: BoxDecoration(color: dk ? Color(0xFF1a1d24) : Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
      child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(10),
          child: InkWell(onTap: () => Navigator.pop(ctx), borderRadius: BorderRadius.circular(10),
              child: Icon(Icons.arrow_back, size: 18, color: sub))));

  Widget _stepper(bool dk, Color card, Color bord, Color txt, Color sub) {
    final steps = ['Select Model', 'Upload File', 'Map Columns', 'Result'];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      decoration: BoxDecoration(color: card, border: Border(bottom: BorderSide(color: bord))),
      child: Row(children: steps.asMap().entries.map((e) {
        final i = e.key; final isDone = i < _step; final isCurrent = i == _step;
        final c = isDone ? _green : isCurrent ? _blue : sub.withOpacity(0.4);
        return Expanded(child: Row(children: [
          Container(width: 28, height: 28,
              decoration: BoxDecoration(color: c.withOpacity(isDone ? 0.12 : isCurrent ? 0.12 : 0.06), borderRadius: BorderRadius.circular(8)),
              child: Center(child: isDone ? Icon(Icons.check, size: 14, color: c)
                  : Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)))),
          SizedBox(width: 8),
          Flexible(child: Text(e.value, style: TextStyle(fontSize: 11,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
              color: isCurrent ? txt : sub), overflow: TextOverflow.ellipsis)),
          if (i < steps.length - 1) Padding(padding: EdgeInsets.symmetric(horizontal: 8),
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
  //  STEP 0 — SELECT MODEL (with guidance)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _stepSelectModel(bool desk, bool dk, Color card, Color bord, Color txt, Color sub) {
    final filtered = _models.where((m) {
      final q = _modelSearch.toLowerCase();
      return q.isEmpty || (m['codeModele'] ?? '').toString().toLowerCase().contains(q)
          || (m['texte'] ?? '').toString().toLowerCase().contains(q)
          || (m['objet'] ?? '').toString().toLowerCase().contains(q);
    }).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Help banner ───────────────────────────────────────────────────
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
            Text('How to choose the right model?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: txt)),
            SizedBox(height: 4),
            Text('Choose the model that matches the type of data you want to import. '
                'For example, if your Excel contains purchase orders, select the purchase order model (e.g. YPOHEC). '
                'If it contains products, select a product model.\n\n'
                'You don\'t need to map ALL fields — only the ones that match your Excel columns. '
                'Optional fields can be left unmapped.',
                style: TextStyle(fontSize: 12, color: sub, height: 1.5)),
          ])),
        ]),
      ),
      SizedBox(height: 20),

      // ── Saved mappings ────────────────────────────────────────────────
      if (_savedMappings.isNotEmpty) ...[
        Text('Saved Mappings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: txt)),
        SizedBox(height: 4),
        Text('Reuse a previous mapping configuration', style: TextStyle(fontSize: 12, color: sub)),
        SizedBox(height: 14),
        ..._savedMappings.map((s) => Container(
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
                    Text(s['mappingName'] ?? '—', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: txt)),
                    Row(children: [
                      Text(s['modelCode'] ?? '—', style: TextStyle(fontSize: 11, color: _blue, fontWeight: FontWeight.w500)),
                      SizedBox(width: 8),
                      Text('Tap to load', style: TextStyle(fontSize: 10, color: sub)),
                    ]),
                  ])),
                  Icon(Icons.arrow_forward_ios, size: 14, color: sub.withOpacity(0.4)),
                ])))),
        )),
        SizedBox(height: 24),
      ],

      // ── Model list ────────────────────────────────────────────────────
      Text('Choose a Model', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: txt)),
      SizedBox(height: 4),
      Text('Select the Sage X3 import model that matches your data type', style: TextStyle(fontSize: 12, color: sub)),
      SizedBox(height: 14),

      Container(height: 44,
          decoration: BoxDecoration(color: dk ? Color(0xFF1a1d24) : card, borderRadius: BorderRadius.circular(12), border: Border.all(color: bord)),
          child: TextField(onChanged: (v) => setState(() => _modelSearch = v),
              style: TextStyle(fontSize: 14, color: txt),
              decoration: InputDecoration(hintText: 'Search by code, name or object...', hintStyle: TextStyle(fontSize: 13, color: sub),
                  prefixIcon: Icon(Icons.search, size: 18, color: sub), border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)))),
      SizedBox(height: 14),

      if (_loadingModels)
        Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(strokeWidth: 2, color: _blue)))
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
                        child: Center(child: Text(title[0].toUpperCase(), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _blue)))),
                    SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // ── Description en grand ──────────────────────────
                      Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: txt), maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 4),
                      Row(children: [
                        // ── Code en petit badge ─────────────────────────
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
      // Model info
      Container(padding: EdgeInsets.all(14),
          decoration: BoxDecoration(color: _blue.withOpacity(dk ? 0.06 : 0.04), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _blue.withOpacity(0.15))),
          child: Row(children: [
            Icon(Icons.description_outlined, size: 16, color: _blue), SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_selectedModelName ?? _selectedModelCode ?? '—',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: txt)),
              Text('Code: $_selectedModelCode  •  ${_sageFields.length} fields available',
                  style: TextStyle(fontSize: 11, color: sub)),
            ])),
            TextButton(onPressed: () => setState(() => _step = 0),
                child: Text('Change', style: TextStyle(fontSize: 12, color: _blue))),
          ])),
      SizedBox(height: 20),

      Text('Upload Your Excel File', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: txt)),
      SizedBox(height: 4),
      Text('The first row must contain your column headers (names)', style: TextStyle(fontSize: 12, color: sub)),
      SizedBox(height: 20),

      GestureDetector(
        onTap: _readingHeaders ? null : _pickFile,
        child: Container(width: double.infinity, padding: EdgeInsets.symmetric(vertical: 48, horizontal: 32),
          decoration: BoxDecoration(
            color: dk ? Color(0xFF1a1d24) : Color(0xFFFAFBFC), borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _file != null ? _cyan.withOpacity(0.4) : bord, width: _file != null ? 2 : 1.5)),
          child: Column(children: [
            Container(padding: EdgeInsets.all(18),
                decoration: BoxDecoration(color: _cyan.withOpacity(dk ? 0.12 : 0.06), shape: BoxShape.circle),
                child: Icon(Icons.cloud_upload_outlined, size: 40, color: _cyan)),
            SizedBox(height: 20),
            Text(_file != null ? _file!.name : 'Select your Excel file',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: txt)),
            SizedBox(height: 6),
            Text('.xlsx files only — headers in row 1', style: TextStyle(fontSize: 13, color: sub)),
            if (_readingHeaders) ...[
              SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _cyan)),
                SizedBox(width: 10), Text('Reading columns...', style: TextStyle(fontSize: 13, color: _cyan)),
              ]),
            ] else if (_file == null) ...[
              SizedBox(height: 20),
              Container(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  decoration: BoxDecoration(color: _cyan, borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: _cyan.withOpacity(0.25), blurRadius: 12, offset: Offset(0, 4))]),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.folder_open_rounded, color: Colors.white, size: 16), SizedBox(width: 8),
                    Text('Browse Files', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  ])),
            ],
          ])),
      ),
      SizedBox(height: 16),
      TextButton.icon(onPressed: () => setState(() => _step = 0),
          icon: Icon(Icons.arrow_back, size: 14), label: Text('Back to model selection'),
          style: TextButton.styleFrom(foregroundColor: sub)),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STEP 2 — MAP COLUMNS (improved UX)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _stepMapColumns(bool desk, bool dk, Color card, Color bord, Color txt, Color sub) {
    final unmapped = _excelHeaders.where((h) => !_mapping.containsKey(h)).toList();
    final mappedSageFields = _mapping.values.toSet();
    final requiredFields   = _sageFields.where((f) => _fieldRequired(f)).length;
    final mappedRequired   = _sageFields.where((f) => _fieldRequired(f) && mappedSageFields.contains(_fieldCode(f))).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Info bar ──────────────────────────────────────────────────────
      Wrap(spacing: 8, runSpacing: 8, children: [
        _infoBadge(Icons.description_outlined, '$_selectedModelCode', _blue, dk),
        _infoBadge(Icons.insert_drive_file_outlined, '${_file?.name ?? "—"}', _cyan, dk),
        _infoBadge(Icons.link, '${_mapping.length} / ${_sageFields.length} mapped', _green, dk),
        _infoBadge(Icons.star_outline, '$mappedRequired / $requiredFields required', _amber, dk),
      ]),
      SizedBox(height: 20),

      // ── Instructions ──────────────────────────────────────────────────
      Text('Map Your Columns', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: txt)),
      SizedBox(height: 4),
      Text('Drag your Excel columns from the left onto the matching Sage X3 fields on the right. '
          'Required fields are marked with a star.',
          style: TextStyle(fontSize: 12, color: sub, height: 1.4)),
      SizedBox(height: 20),

      // ── Two columns ───────────────────────────────────────────────────
      desk
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _excelPanel(unmapped, dk, card, bord, txt, sub)),
              SizedBox(width: 20),
              Expanded(child: _sagePanel(mappedSageFields, dk, card, bord, txt, sub)),
            ])
          : Column(children: [
              _excelPanel(unmapped, dk, card, bord, txt, sub),
              SizedBox(height: 20),
              _sagePanel(mappedSageFields, dk, card, bord, txt, sub),
            ]),

      SizedBox(height: 24),

      // ── Actions ───────────────────────────────────────────────────────
      Row(children: [
        TextButton.icon(onPressed: () => setState(() => _step = 1),
            icon: Icon(Icons.arrow_back, size: 14), label: Text('Back'),
            style: TextButton.styleFrom(foregroundColor: sub)),
        Spacer(),
        if (_mapping.isNotEmpty)
          OutlinedButton.icon(onPressed: _saveMapping,
              icon: Icon(Icons.bookmark_add_outlined, size: 14), label: Text('Save'),
              style: OutlinedButton.styleFrom(foregroundColor: _violet,
                  side: BorderSide(color: _violet.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
        SizedBox(width: 10),
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
                  Icon(Icons.play_arrow_rounded, color: _mapping.isNotEmpty ? Colors.white : sub, size: 18),
                  SizedBox(width: 6),
                  Text('Convert to CSV', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: _mapping.isNotEmpty ? Colors.white : sub)),
                ])))),
        ),
      ]),
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

  // ── Excel columns panel ───────────────────────────────────────────────
  Widget _excelPanel(List<String> unmapped, bool dk, Color card, Color bord, Color txt, Color sub) {
    return Container(
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: Row(children: [
            Icon(Icons.table_chart_outlined, size: 16, color: _cyan), SizedBox(width: 8),
            Text('Your Excel Columns', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: txt)),
            Spacer(),
            Text('${unmapped.length} remaining', style: TextStyle(fontSize: 11, color: sub)),
          ])),
        Divider(height: 1, color: bord),

        // Mapped (connected)
        ..._mapping.entries.map((e) {
          final sageField = _sageFields.firstWhere((f) => _fieldCode(f) == e.value, orElse: () => {});
          final sageName = sageField.isNotEmpty ? _fieldName(sageField) : e.value;
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: bord))),
            child: Row(children: [
              Icon(Icons.link, size: 14, color: _green), SizedBox(width: 10),
              Expanded(child: Text(e.key, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _green))),
              Icon(Icons.arrow_forward, size: 12, color: _green.withOpacity(0.5)), SizedBox(width: 6),
              // ── Show description, not code ────────────────────────
              Flexible(child: Text(sageName, style: TextStyle(fontSize: 11, color: _green, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis)),
              SizedBox(width: 8),
              GestureDetector(onTap: () => _unmapColumn(e.key),
                  child: Icon(Icons.close, size: 14, color: _red.withOpacity(0.6))),
            ]),
          );
        }),

        // Unmapped (draggable)
        if (unmapped.isNotEmpty)
          ...unmapped.map((col) => Draggable<String>(
            data: col,
            feedback: Material(color: Colors.transparent,
              child: Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: _cyan, borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: _cyan.withOpacity(0.3), blurRadius: 12)]),
                  child: Text(col, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)))),
            childWhenDragging: Container(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(color: _cyan.withOpacity(0.04), border: Border(bottom: BorderSide(color: bord))),
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
                Expanded(child: Text(col, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: txt))),
                Icon(Icons.open_with, size: 14, color: _cyan.withOpacity(0.5)),
              ]),
            ),
          )),

        if (unmapped.isEmpty && _mapping.isEmpty)
          Padding(padding: EdgeInsets.all(24),
              child: Center(child: Text('No columns found', style: TextStyle(fontSize: 12, color: sub)))),
      ]),
    );
  }

  // ── Sage fields panel (drop targets) — DESCRIPTION PROMINENT ──────────
  Widget _sagePanel(Set<String> mapped, bool dk, Color card, Color bord, Color txt, Color sub) {
    return Container(
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: Row(children: [
            Icon(Icons.schema_outlined, size: 16, color: _blue), SizedBox(width: 8),
            Text('Sage X3 Fields', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: txt)),
            Spacer(),
            Text('${_sageFields.length} fields', style: TextStyle(fontSize: 11, color: sub)),
          ])),
        Divider(height: 1, color: bord),

        if (_loadingFields)
          Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _blue)))
        else
          ..._sageFields.map((f) {
            final code      = _fieldCode(f);
            final desc      = _fieldName(f);
            final group     = _fieldGroup(f);
            final required  = _fieldRequired(f);
            final isMapped  = mapped.contains(code);
            final mappedFrom = _mapping.entries.where((e) => e.value == code).map((e) => e.key).firstOrNull;

            return DragTarget<String>(
              onWillAcceptWithDetails: (_) => true,
              onAcceptWithDetails: (details) => _mapColumn(details.data, code),
              builder: (context, candidateData, rejectedData) {
                final hovering = candidateData.isNotEmpty;
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: hovering ? _blue.withOpacity(0.08) : isMapped ? _green.withOpacity(dk ? 0.06 : 0.03) : Colors.transparent,
                    border: Border(bottom: BorderSide(color: hovering ? _blue.withOpacity(0.3) : bord)),
                  ),
                  child: Row(children: [
                    // Required indicator
                    if (required)
                      Padding(padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.star, size: 10, color: isMapped ? _green : _amber))
                    else
                      Padding(padding: EdgeInsets.only(right: 6),
                          child: Container(width: 6, height: 6,
                              decoration: BoxDecoration(color: isMapped ? _green : sub.withOpacity(0.2), shape: BoxShape.circle))),

                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // ── DESCRIPTION in prominent text ─────────────────
                      Text(desc, style: TextStyle(fontSize: 13,
                          fontWeight: isMapped ? FontWeight.w600 : FontWeight.w500,
                          color: isMapped ? _green : txt),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 2),
                      // ── Code + group in small text ────────────────────
                      Row(children: [
                        Text(code, style: TextStyle(fontSize: 10, color: sub,
                            fontFamily: 'monospace', fontWeight: FontWeight.w500)),
                        SizedBox(width: 6),
                        Container(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(color: _cyan.withOpacity(0.06), borderRadius: BorderRadius.circular(3)),
                            child: Text(group, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: _cyan))),
                        if (!required) ...[
                          SizedBox(width: 6),
                          Text('optional', style: TextStyle(fontSize: 8, color: sub.withOpacity(0.5), fontStyle: FontStyle.italic)),
                        ],
                      ]),
                    ])),

                    if (isMapped && mappedFrom != null) ...[
                      Icon(Icons.arrow_back, size: 12, color: _green.withOpacity(0.5)), SizedBox(width: 4),
                      Flexible(child: Text(mappedFrom, style: TextStyle(fontSize: 10, color: _green, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis)),
                    ] else
                      Text(hovering ? 'Release here' : 'Drop here',
                          style: TextStyle(fontSize: 10, color: hovering ? _blue : sub.withOpacity(0.4))),
                  ]),
                );
              },
            );
          }),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STEP 3 — RESULT
  // ═══════════════════════════════════════════════════════════════════════
  Widget _stepResult(bool desk, bool dk, Color card, Color bord, Color txt, Color sub) {
    if (_success == true) {
      final hasCsv = _csv != null && _csv!.isNotEmpty;
      return Container(padding: EdgeInsets.all(24),
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
              Text('Conversion Successful!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _green)),
              Text('$_modelCode  •  $_rowCount rows converted via custom mapping', style: TextStyle(fontSize: 13, color: sub)),
            ])),
          ]),
          if (hasCsv) ...[
            SizedBox(height: 18),
            Container(width: double.infinity, padding: EdgeInsets.all(14),
                decoration: BoxDecoration(color: dk ? Color(0xFF151921) : Colors.white,
                    borderRadius: BorderRadius.circular(10), border: Border.all(color: _green.withOpacity(0.2))),
                constraints: BoxConstraints(maxHeight: 120),
                child: SingleChildScrollView(child: Text(
                    _csv!.length > 500 ? '${_csv!.substring(0, 500)}\n...' : _csv!,
                    style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: txt.withOpacity(0.7))))),
            SizedBox(height: 18),
            Container(width: double.infinity, height: 50,
                decoration: BoxDecoration(gradient: LinearGradient(colors: [_green, Color(0xFF10b981)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: _green.withOpacity(0.25), blurRadius: 12, offset: Offset(0, 4))]),
                child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(12),
                    child: InkWell(onTap: _downloadCsv, borderRadius: BorderRadius.circular(12),
                        child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.download_rounded, color: Colors.white, size: 18), SizedBox(width: 8),
                          Text('Download CSV', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                        ]))))),
          ],
          SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 44,
              child: OutlinedButton.icon(onPressed: _reset, icon: Icon(Icons.refresh, size: 16),
                  label: Text('New Import'), style: OutlinedButton.styleFrom(foregroundColor: _green,
                      side: BorderSide(color: _green.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
        ]),
      );
    }

    // Errors
    return Container(padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: dk ? _red.withOpacity(0.04) : Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dk ? _red.withOpacity(0.2) : Color(0xFFFECACA))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: EdgeInsets.all(10),
              decoration: BoxDecoration(color: _red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.error_outline_rounded, color: _red, size: 24)),
          SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${_errors.length} error${_errors.length > 1 ? 's' : ''} detected',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _red)),
            Text('Fix the errors and try again', style: TextStyle(fontSize: 12, color: sub)),
          ])),
        ]),
        SizedBox(height: 16),
        ..._errors.take(10).map((e) => Padding(padding: EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.warning_amber_rounded, color: _red, size: 14), SizedBox(width: 8),
              if ((e['field'] ?? '').toString().isNotEmpty) ...[
                Text(e['field'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sub, fontFamily: 'monospace')),
                SizedBox(width: 6),
              ],
              Expanded(child: Text(e['message'] ?? '', style: TextStyle(fontSize: 12, color: txt))),
            ]))),
        SizedBox(height: 18),
        Row(children: [
          Expanded(child: ElevatedButton.icon(onPressed: () => setState(() => _step = 2),
              icon: Icon(Icons.arrow_back, size: 16), label: Text('Back to Mapping'),
              style: ElevatedButton.styleFrom(backgroundColor: _amber, foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), minimumSize: Size(0, 46)))),
          SizedBox(width: 12),
          Expanded(child: ElevatedButton.icon(onPressed: _reset,
              icon: Icon(Icons.refresh, size: 16), label: Text('Start Over'),
              style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), minimumSize: Size(0, 46)))),
        ]),
      ]),
    );
  }
}

class _MF { final String path; _MF(this.path); }