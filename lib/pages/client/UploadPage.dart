import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';
import '../../services/api_service_web.dart'
    if (dart.library.io) '../../services/api_service_stub.dart';

class UploadPage extends StatefulWidget {
  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final ApiService _api = ApiService();

  PlatformFile? _file;
  bool   _uploading = false;
  double _progress  = 0;

  bool?         _success;
  String?       _modelCode;
  int?          _rowCount;
  String?       _csv;
  List<dynamic> _errors = [];

  List<Map<String, dynamic>> _history = [];
  bool _historyLoading = false;

  // Tokens de design
  static const _blue   = Color(0xFF2563eb);
  static const _violet = Color(0xFF7c3aed);
  static const _green  = Color(0xFF059669);
  static const _red    = Color(0xFFdc2626);
  static const _amber  = Color(0xFFd97706);

  @override
  void initState() { super.initState(); _loadHistory(); }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    try {
      final data = await _api.getHistory(userId: ApiService.userId);
      setState(() { _history = data; _historyLoading = false; });
    } catch (_) { setState(() => _historyLoading = false); }
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['xlsx'], withData: kIsWeb);
    if (result != null) setState(() {
      _file = result.files.single; _success = null; _errors = []; _progress = 0; _csv = null;
    });
  }

  Future<void> _upload() async {
    if (_file == null) return;
    setState(() { _uploading = true; _progress = 0; _success = null; _errors = []; });
    try {
      final r = kIsWeb
          ? await _api.uploadFile(_file!.bytes!, _file!.name, onProgress: (p) => setState(() => _progress = p))
          : await _api.uploadFile(_MF(_file!.path!), _file!.name, onProgress: (p) => setState(() => _progress = p));
      setState(() {
        _uploading = false; _success = r['success'] ?? false; _modelCode = r['modelCode'];
        _rowCount = r['rowCount']; _csv = r['csvContent']; _errors = r['errors'] ?? [];
      });
      _loadHistory();
    } catch (e) {
      setState(() { _uploading = false; _success = false;
        _errors = [{'row': 0, 'field': '', 'message': e.toString()}]; });
    }
  }

  void _downloadCsv() {
    if (_csv == null || _csv!.isEmpty) return;
    final name  = '${_modelCode ?? 'export'}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final bytes = Uint8List.fromList(utf8.encode(_csv!));
    kIsWeb ? triggerWebDownload(bytes, name) : saveMobileFile(bytes, name);
  }

  void _reset() => setState(() {
    _file = null; _success = null; _errors = []; _progress = 0; _modelCode = null; _rowCount = null; _csv = null;
  });

  String get _fileName  => _file?.name ?? '';
  double get _fileMb    => (_file?.size ?? 0) / (1024 * 1024);

  @override
  Widget build(BuildContext context) {
    final dk   = Theme.of(context).brightness == Brightness.dark;
    final bg   = dk ? Color(0xFF0b0e13) : Color(0xFFF7F8FA);
    final card = dk ? Color(0xFF151921) : Colors.white;
    final bord = dk ? Color(0xFF1e2028) : Color(0xFFf0f0f5);
    final txt  = dk ? Colors.white : Color(0xFF111827);
    final sub  = dk ? Color(0xFF6b7280) : Color(0xFF9ca3af);
    final desk = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: bg,
      body: Column(children: [
        _header(context, desk, dk, card, bord, txt, sub),
        Expanded(child: SingleChildScrollView(
          padding: EdgeInsets.all(desk ? 32 : 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Zone de dépôt ────────────────────────────────────────────
            _dropZone(dk, card, bord, txt, sub),

            // ── Fichier sélectionné ──────────────────────────────────────
            if (_file != null && _success == null) ...[
              SizedBox(height: 20),
              _filePreview(dk, card, bord, txt, sub),
            ],

            // ── Envoi en cours ───────────────────────────────────────────
            if (_uploading) ...[
              SizedBox(height: 20),
              _progressCard(dk, card, bord, txt, sub),
            ],

            // ── Succès ───────────────────────────────────────────────────
            if (_success == true) ...[
              SizedBox(height: 20),
              _successCard(dk, card, bord, txt, sub),
            ],

            // ── Erreurs ──────────────────────────────────────────────────
            if (_success == false && _errors.isNotEmpty) ...[
              SizedBox(height: 20),
              _errorCard(dk, card, bord, txt, sub),
            ],

            // ── Historique ───────────────────────────────────────────────
            SizedBox(height: 36),
            _historySection(dk, card, bord, txt, sub),
          ]),
        )),
      ]),
    );
  }

  // ── En-tête ───────────────────────────────────────────────────────────
  Widget _header(BuildContext ctx, bool desk, bool dk, Color card, Color bord, Color txt, Color sub) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: desk ? 32 : 20, vertical: 16),
      decoration: BoxDecoration(color: card, border: Border(bottom: BorderSide(color: bord))),
      child: Row(children: [
        _backBtn(ctx, dk, sub), SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Importer un fichier', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: txt, letterSpacing: -0.3)),
          Text('Importez vos données Excel pour validation et conversion CSV',
              style: TextStyle(fontSize: 12, color: sub)),
        ])),
      ]),
    );
  }

  // ── Zone de dépôt ─────────────────────────────────────────────────────
  Widget _dropZone(bool dk, Color card, Color bord, Color txt, Color sub) {
    final hasSel = _file != null;
    return GestureDetector(
      onTap: _uploading ? null : _pick,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 48, horizontal: 32),
        decoration: BoxDecoration(
          color: dk ? Color(0xFF1a1d24) : Color(0xFFFAFBFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasSel ? _blue.withOpacity(0.4) : (dk ? Color(0xFF2a2e38) : Color(0xFFe5e7eb)),
            width: hasSel ? 2 : 1.5,
          ),
        ),
        child: Column(children: [
          Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _blue.withOpacity(dk ? 0.12 : 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cloud_upload_outlined, size: 40, color: _blue),
          ),
          SizedBox(height: 20),
          Text(hasSel ? 'Appuyer pour changer le fichier' : 'Sélectionner un fichier Excel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: txt)),
          SizedBox(height: 6),
          Text('Seuls les fichiers .xlsx sont acceptés',
              style: TextStyle(fontSize: 13, color: sub)),
          if (!hasSel) ...[
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              decoration: BoxDecoration(
                color: _blue, borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: _blue.withOpacity(0.25), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.folder_open_rounded, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Parcourir les fichiers', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  // ── Aperçu du fichier ─────────────────────────────────────────────────
  Widget _filePreview(bool dk, Color card, Color bord, Color txt, Color sub) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bord)),
      child: Column(children: [
        Row(children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(color: _green.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.insert_drive_file_rounded, color: _green, size: 24),
          ),
          SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_fileName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: txt),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 3),
            Text('${_fileMb.toStringAsFixed(2)} Mo', style: TextStyle(fontSize: 12, color: sub)),
          ])),
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: dk ? Color(0xFF1a1d24) : Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
            child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(8),
                child: InkWell(onTap: _reset, borderRadius: BorderRadius.circular(8),
                    child: Icon(Icons.close, size: 16, color: sub))),
          ),
        ]),
        SizedBox(height: 18),
        Row(children: [
          Expanded(child: Container(
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_blue, Color(0xFF3b82f6)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: _blue.withOpacity(0.25), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _uploading ? null : _upload,
                borderRadius: BorderRadius.circular(12),
                child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.upload_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Importer & Valider', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                ])),
              ),
            ),
          )),
          SizedBox(width: 12),
          Container(
            height: 46, width: 46,
            decoration: BoxDecoration(
              color: dk ? Color(0xFF1a1d24) : Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: bord),
            ),
            child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(12),
                child: InkWell(onTap: _pick, borderRadius: BorderRadius.circular(12),
                    child: Icon(Icons.swap_horiz, size: 18, color: sub))),
          ),
        ]),
      ]),
    );
  }

  // ── Progression ───────────────────────────────────────────────────────
  Widget _progressCard(bool dk, Color card, Color bord, Color txt, Color sub) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bord)),
      child: Column(children: [
        Row(children: [
          SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: _blue)),
          SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Envoi et validation en cours...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: txt)),
            SizedBox(height: 2),
            Text('${(_progress * 100).toInt()}% terminé', style: TextStyle(fontSize: 12, color: sub)),
          ])),
        ]),
        SizedBox(height: 14),
        ClipRRect(borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: _progress, minHeight: 6,
                backgroundColor: _blue.withOpacity(0.1), color: _blue)),
      ]),
    );
  }

  // ── Succès ────────────────────────────────────────────────────────────
  Widget _successCard(bool dk, Color card, Color bord, Color txt, Color sub) {
    final hasCsv = _csv != null && _csv!.isNotEmpty;
    return Container(
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: dk ? _green.withOpacity(0.06) : Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dk ? _green.withOpacity(0.2) : Color(0xFFbbf7d0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: EdgeInsets.all(10),
              decoration: BoxDecoration(color: _green.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.check_circle_rounded, color: _green, size: 24)),
          SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Importation réussie', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _green)),
            SizedBox(height: 2),
            Text('$_modelCode  •  $_rowCount lignes converties', style: TextStyle(fontSize: 13, color: sub)),
          ])),
        ]),

        if (hasCsv) ...[
          SizedBox(height: 18),
          // Aperçu CSV
          Container(
            width: double.infinity, padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: dk ? Color(0xFF151921) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _green.withOpacity(0.2)),
            ),
            constraints: BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(child: Text(
              _csv!.length > 500 ? '${_csv!.substring(0, 500)}\n...' : _csv!,
              style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: txt.withOpacity(0.7)),
            )),
          ),
          SizedBox(height: 18),
          // Bouton de téléchargement
          Container(
            width: double.infinity, height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_green, Color(0xFF10b981)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: _green.withOpacity(0.25), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(12),
              child: InkWell(onTap: _downloadCsv, borderRadius: BorderRadius.circular(12),
                child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.download_rounded, color: Colors.white, size: 18), SizedBox(width: 8),
                  Text('Télécharger le CSV', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                ])))),
          ),
        ],
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 44,
          child: OutlinedButton.icon(
            onPressed: _reset,
            icon: Icon(Icons.upload_rounded, size: 16),
            label: Text('Importer un autre fichier'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _green,
              side: BorderSide(color: _green.withOpacity(0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Erreurs ───────────────────────────────────────────────────────────
  Widget _errorCard(bool dk, Color card, Color bord, Color txt, Color sub) {
    final global = _errors.where((e) => (e['row'] ?? 0) == 0).toList();
    final byRow  = <int, List<Map<String, dynamic>>>{};
    for (final e in _errors.where((e) => (e['row'] ?? 0) != 0)) {
      byRow.putIfAbsent(e['row'] as int, () => []).add(e);
    }

    return Container(
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: dk ? _red.withOpacity(0.04) : Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dk ? _red.withOpacity(0.2) : Color(0xFFFECACA)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: EdgeInsets.all(10),
              decoration: BoxDecoration(color: _red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.error_outline_rounded, color: _red, size: 24)),
          SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${_errors.length} erreur${_errors.length > 1 ? 's' : ''} détectée${_errors.length > 1 ? 's' : ''}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _red)),
            SizedBox(height: 2),
            Text('Corrigez les erreurs dans votre fichier Excel et réessayez', style: TextStyle(fontSize: 12, color: sub)),
          ])),
        ]),

        // Erreurs globales
        if (global.isNotEmpty) ...[
          SizedBox(height: 16),
          ...global.map((e) => Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.warning_amber_rounded, color: _red, size: 15),
              SizedBox(width: 8),
              Expanded(child: Text(e['message'] ?? '', style: TextStyle(fontSize: 13, color: _red, fontWeight: FontWeight.w500))),
            ]),
          )),
        ],

        // Erreurs par ligne
        if (byRow.isNotEmpty) ...[
          SizedBox(height: 16),
          Text('Par ligne :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: txt)),
          SizedBox(height: 10),
          ...byRow.entries.take(8).map((entry) => Container(
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: dk ? Color(0xFF151921) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _red.withOpacity(0.15)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _red.withOpacity(dk ? 0.08 : 0.04),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: Row(children: [
                  Icon(Icons.table_rows_outlined, size: 13, color: _red),
                  SizedBox(width: 6),
                  Text('Ligne ${entry.key}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _red)),
                  SizedBox(width: 6),
                  Text('${entry.value.length} erreur${entry.value.length > 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 10, color: _red.withOpacity(0.6))),
                ]),
              ),
              ...entry.value.map((err) => Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(margin: EdgeInsets.only(top: 3), padding: EdgeInsets.all(3),
                      decoration: BoxDecoration(color: _red.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                      child: Icon(Icons.edit_note, size: 11, color: _red)),
                  SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if ((err['field'] ?? '').toString().isNotEmpty)
                      Text(err['field'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: sub, fontFamily: 'monospace')),
                    Text(err['message'] ?? '', style: TextStyle(fontSize: 12, color: txt)),
                  ])),
                ]),
              )),
            ]),
          )),
          if (byRow.length > 8) Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(color: _amber.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(Icons.info_outline, color: _amber, size: 14), SizedBox(width: 8),
              Expanded(child: Text('... et ${byRow.length - 8} autres lignes avec des erreurs',
                  style: TextStyle(fontSize: 12, color: _amber))),
            ]),
          ),
        ],

        SizedBox(height: 18),
        Container(
          width: double.infinity, height: 46,
          decoration: BoxDecoration(color: _red, borderRadius: BorderRadius.circular(12)),
          child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(12),
            child: InkWell(onTap: _reset, borderRadius: BorderRadius.circular(12),
              child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.refresh_rounded, color: Colors.white, size: 16), SizedBox(width: 8),
                Text('Corriger & Réessayer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              ])))),
        ),
      ]),
    );
  }

  // ── Section historique ────────────────────────────────────────────────
  Widget _historySection(bool dk, Color card, Color bord, Color txt, Color sub) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Importations récentes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: txt)),
        Spacer(),
        TextButton.icon(onPressed: _loadHistory,
            icon: Icon(Icons.refresh, size: 14), label: Text('Actualiser', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: _blue)),
      ]),
      SizedBox(height: 14),
      if (_historyLoading)
        Center(child: Padding(padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(strokeWidth: 2, color: _blue)))
      else if (_history.isEmpty)
        Container(
          width: double.infinity, padding: EdgeInsets.all(32),
          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bord)),
          child: Column(children: [
            Icon(Icons.inbox_outlined, size: 36, color: sub.withOpacity(0.3)),
            SizedBox(height: 10),
            Text('Aucune importation pour le moment', style: TextStyle(fontSize: 13, color: sub)),
          ]),
        )
      else
        ...(_history.take(5).map((h) => _historyItem(h, dk, card, bord, txt, sub))),
    ]);
  }

  Widget _historyItem(Map<String, dynamic> h, bool dk, Color card, Color bord, Color txt, Color sub) {
    final ok    = (h['status'] ?? '').toString().toLowerCase() == 'converted';
    final color = ok ? _green : _red;
    final hasCsv = ok && h['csvContent'] != null;

    String time = '';
    try {
      final dt = DateTime.parse(h['uploadDate'] ?? '').toLocal();
      final df = DateTime.now().difference(dt);
      if (df.inHours < 1) time = 'Il y a ${df.inMinutes}min';
      else if (df.inHours < 24) time = 'Il y a ${df.inHours}h';
      else time = 'Il y a ${df.inDays}j';
    } catch (_) {}

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12), border: Border.all(color: bord)),
      child: Row(children: [
        Container(width: 34, height: 34,
            decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: Icon(ok ? Icons.check_rounded : Icons.close_rounded, color: color, size: 16)),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(h['fileName'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: txt),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 3),
          Row(children: [
            Text(h['modelCode'] ?? '', style: TextStyle(fontSize: 11, color: _blue, fontWeight: FontWeight.w500)),
            if (time.isNotEmpty) ...[
              Text('  •  ', style: TextStyle(color: sub.withOpacity(0.3))),
              Text(time, style: TextStyle(fontSize: 11, color: sub)),
            ],
            if (ok && h['rowCount'] != null) ...[
              Text('  •  ', style: TextStyle(color: sub.withOpacity(0.3))),
              Text('${h['rowCount']} lignes', style: TextStyle(fontSize: 11, color: sub)),
            ],
          ]),
        ])),
        if (hasCsv)
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: _blue.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  final csv = h['csvContent'] as String;
                  final name = '${h['modelCode'] ?? 'export'}_${h['id'] ?? ''}.csv';
                  final bytes = Uint8List.fromList(utf8.encode(csv));
                  kIsWeb ? triggerWebDownload(bytes, name) : saveMobileFile(bytes, name);
                },
                child: Icon(Icons.download_rounded, size: 15, color: _blue),
              ),
            ),
          ),
        SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
          child: Text(ok ? 'Converti' : 'Erreur', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ),
      ]),
    );
  }

  // ── Partagé ───────────────────────────────────────────────────────────
  Widget _backBtn(BuildContext ctx, bool dk, Color sub) {
    return Container(width: 38, height: 38,
        decoration: BoxDecoration(color: dk ? Color(0xFF1a1d24) : Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
        child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(10),
            child: InkWell(onTap: () => Navigator.pop(ctx), borderRadius: BorderRadius.circular(10),
                child: Icon(Icons.arrow_back, size: 18, color: sub))));
  }
}

class _MF { final String path; _MF(this.path); }