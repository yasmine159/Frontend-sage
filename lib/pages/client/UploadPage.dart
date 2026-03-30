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

  PlatformFile? _selectedPlatformFile;

  bool   _isUploading = false;
  double _progress    = 0.0;

  bool?         _success;
  String?       _modelCode;
  int?          _rowCount;
  String?       _csvContent;
  List<dynamic> _errors = [];

  List<Map<String, dynamic>> _history        = [];
  bool                       _historyLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    try {
      final history = await _api.getHistory(userId: ApiService.userId);
      setState(() { _history = history; _historyLoading = false; });
    } catch (_) {
      setState(() => _historyLoading = false);
    }
  }

  Future<void> _selectFile() async {
    final result = await FilePicker.platform.pickFiles(
      type:              FileType.custom,
      allowedExtensions: ['xlsx'],
      withData:          kIsWeb,
    );
    if (result != null) {
      setState(() {
        _selectedPlatformFile = result.files.single;
        _success    = null;
        _errors     = [];
        _progress   = 0.0;
        _csvContent = null;
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedPlatformFile == null) return;
    setState(() {
      _isUploading = true;
      _progress    = 0.0;
      _success     = null;
      _errors      = [];
    });

    try {
      final fileName = _selectedPlatformFile!.name;
      Map<String, dynamic> result;

      if (kIsWeb) {
        result = await _api.uploadFile(
          _selectedPlatformFile!.bytes!,
          fileName,
          onProgress: (p) => setState(() => _progress = p),
        );
      } else {
        result = await _api.uploadFile(
          _MobileFile(_selectedPlatformFile!.path!),
          fileName,
          onProgress: (p) => setState(() => _progress = p),
        );
      }

      setState(() {
        _isUploading = false;
        _success     = result['success'] ?? false;
        _modelCode   = result['modelCode'];
        _rowCount    = result['rowCount'];
        _csvContent  = result['csvContent'];
        _errors      = result['errors'] ?? [];
      });

      _loadHistory();
    } catch (e) {
      setState(() {
        _isUploading = false;
        _success     = false;
        _errors      = [{'row': 0, 'field': '', 'message': e.toString()}];
      });
    }
  }

  // ── Download CSV ──────────────────────────────────────────────────────────
  void _downloadCsv() {
    if (_csvContent == null || _csvContent!.isEmpty) return;
    final fileName = '${_modelCode ?? 'export'}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final bytes    = Uint8List.fromList(utf8.encode(_csvContent!));
    if (kIsWeb) {
      triggerWebDownload(bytes, fileName);
    } else {
      saveMobileFile(bytes, fileName);
    }
  }

  void _resetForm() {
    setState(() {
      _selectedPlatformFile = null;
      _success    = null;
      _errors     = [];
      _progress   = 0.0;
      _modelCode  = null;
      _rowCount   = null;
      _csvContent = null;
    });
  }

  String get _fileName    => _selectedPlatformFile?.name ?? '';
  double get _fileSizeMb  => (_selectedPlatformFile?.size ?? 0) / (1024 * 1024);

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.brightness == Brightness.light
                  ? Color(0xFFe2e8f0) : Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(child: Column(children: [
          _buildAppBar(context),
          Expanded(child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildUploadArea(colorScheme, theme),
              if (_selectedPlatformFile != null && _success == null) ...[
                SizedBox(height: 20),
                _buildFilePreview(colorScheme, theme),
              ],
              if (_isUploading) ...[
                SizedBox(height: 20),
                _buildProgressBar(colorScheme),
              ],
              if (_success == true) ...[
                SizedBox(height: 20),
                _buildSuccessResult(colorScheme),
              ],
              if (_success == false && _errors.isNotEmpty) ...[
                SizedBox(height: 20),
                _buildErrorResult(colorScheme),
              ],
              SizedBox(height: 32),
              _buildHistory(colorScheme, theme),
            ]),
          )),
        ])),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [BoxShadow(
          color:      theme.brightness == Brightness.light
              ? Colors.black12 : Colors.black54,
          blurRadius: 10, offset: Offset(0, 2),
        )],
      ),
      child: Row(children: [
        IconButton(
          icon:      Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Upload File',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface)),
          Text('Import your Excel data',
              style: TextStyle(fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.6))),
        ]),
      ]),
    );
  }

  Widget _buildUploadArea(ColorScheme colorScheme, ThemeData theme) {
    return GestureDetector(
      onTap: _isUploading ? null : _selectFile,
      child: Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color:        colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedPlatformFile != null
                ? colorScheme.primary : theme.dividerColor,
            width: 2,
          ),
          boxShadow: [BoxShadow(
            color: colorScheme.primary.withOpacity(0.08),
            blurRadius: 12, offset: Offset(0, 6),
          )],
        ),
        child: Column(children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.cloud_upload_rounded,
                size: 56, color: colorScheme.primary),
          ),
          SizedBox(height: 16),
          Text(
            _selectedPlatformFile == null
                ? 'Tap to select Excel file' : 'Tap to change file',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                color: colorScheme.onSurface),
          ),
          SizedBox(height: 6),
          Text('.xlsx files only',
              style: TextStyle(fontSize: 13,
                  color: colorScheme.onSurface.withOpacity(0.5))),
          if (_selectedPlatformFile == null) ...[
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _selectFile,
              icon: Icon(Icons.folder_open), label: Text('Browse Files'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildFilePreview(ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:        Color(0xFF10b981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.insert_drive_file,
                color: Color(0xFF10b981), size: 32),
          ),
          SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_fileName,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 4),
              Text('${_fileSizeMb.toStringAsFixed(2)} MB',
                  style: TextStyle(fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.5))),
            ],
          )),
          IconButton(
            icon:      Icon(Icons.close, color: colorScheme.error),
            onPressed: _resetForm,
          ),
        ]),
        SizedBox(height: 16),
        Row(children: [
          Expanded(child: ElevatedButton.icon(
            onPressed: _isUploading ? null : _uploadFile,
            icon: Icon(Icons.upload_rounded), label: Text('Upload & Validate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          )),
          SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _isUploading ? null : _selectFile,
            icon: Icon(Icons.refresh), label: Text('Change'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: colorScheme.primary),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildProgressBar(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Row(children: [
          SizedBox(width: 24, height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 3, color: colorScheme.primary)),
          SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Uploading & validating...',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface)),
            Text('${(_progress * 100).toInt()}% complete',
                style: TextStyle(fontSize: 13,
                    color: colorScheme.onSurface.withOpacity(0.5))),
          ])),
        ]),
        SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value:           _progress,
            minHeight:       8,
            backgroundColor: colorScheme.surface.withOpacity(0.3),
            color:           colorScheme.primary,
          ),
        ),
      ]),
    );
  }

  // ── Success result — with Download CSV button ─────────────────────────────
  Widget _buildSuccessResult(ColorScheme colorScheme) {
    final hasCsv = _csvContent != null && _csvContent!.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        Color(0xFF10b981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: Color(0xFF10b981).withOpacity(0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──────────────────────────────────────────────────────────
        Row(children: [
          Icon(Icons.check_circle, color: Color(0xFF10b981), size: 28),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Import Successful!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                    color: Color(0xFF10b981))),
            Text('Model: $_modelCode  •  $_rowCount rows converted',
                style: TextStyle(fontSize: 13,
                    color: colorScheme.onSurface.withOpacity(0.7))),
          ])),
        ]),

        SizedBox(height: 16),

        // ── CSV preview ──────────────────────────────────────────────────────
        if (hasCsv) ...[
          Row(children: [
            Icon(Icons.article_outlined, size: 15,
                color: colorScheme.onSurface.withOpacity(0.6)),
            SizedBox(width: 6),
            Text('Generated CSV preview',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.7))),
          ]),
          SizedBox(height: 8),
          Container(
            width:      double.infinity,
            padding:    EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:        colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xFF10b981).withOpacity(0.3)),
            ),
            child: Text(
              _csvContent!.length > 400
                  ? _csvContent!.substring(0, 400) + '\n...'
                  : _csvContent!,
              style: TextStyle(fontSize: 11, fontFamily: 'monospace',
                  color: colorScheme.onSurface.withOpacity(0.8)),
            ),
          ),
          SizedBox(height: 16),
        ],

        // ── Action buttons ───────────────────────────────────────────────────
        // Download CSV button (primary action when CSV is available)
        if (hasCsv)
          ElevatedButton.icon(
            onPressed: _downloadCsv,
            icon:  Icon(Icons.download_rounded, size: 20),
            label: Text('Download CSV File',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF10b981),
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
          ),

        SizedBox(height: hasCsv ? 10 : 0),

        // Upload another file (secondary)
        OutlinedButton.icon(
          onPressed: _resetForm,
          icon:  Icon(Icons.upload_rounded, size: 18),
          label: Text('Upload Another File'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Color(0xFF10b981),
            minimumSize: Size(double.infinity, 48),
            side:  BorderSide(color: Color(0xFF10b981).withOpacity(0.6)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]),
    );
  }

  Widget _buildErrorResult(ColorScheme colorScheme) {
  // Sépare les erreurs globales (row=0) des erreurs de ligne
  final globalErrors = _errors
      .where((e) => (e['row'] ?? 0) == 0)
      .toList();
  final lineErrors = _errors
      .where((e) => (e['row'] ?? 0) != 0)
      .toList();

  // Groupe les erreurs par numéro de ligne
  final Map<int, List<Map<String, dynamic>>> errorsByRow = {};
  for (final err in lineErrors) {
    final row = err['row'] as int;
    errorsByRow.putIfAbsent(row, () => []).add(err);
  }

  return Container(
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      color:        Color(0xFFef4444).withOpacity(0.06),
      borderRadius: BorderRadius.circular(16),
      border:       Border.all(color: Color(0xFFef4444).withOpacity(0.35)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // ── En-tête ─────────────────────────────────────────────────────────
      Row(children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Color(0xFFef4444).withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.error_outline, color: Color(0xFFef4444), size: 24),
        ),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            _errors.length == 1
                ? '1 erreur détectée'
                : '${_errors.length} erreurs détectées',
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold,
              color: Color(0xFFef4444),
            ),
          ),
          Text(
            'Corrigez les erreurs dans votre fichier Excel puis réessayez.',
            style: TextStyle(fontSize: 12, color: Colors.red.shade300),
          ),
        ])),
      ]),

      // ── Erreurs globales (fichier entier) ────────────────────────────────
      if (globalErrors.isNotEmpty) ...[
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:        Color(0xFFef4444).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(color: Color(0xFFef4444).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: globalErrors.map((err) => Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFef4444), size: 16),
                SizedBox(width: 8),
                Expanded(child: Text(
                  err['message'] ?? '',
                  style: TextStyle(
                    fontSize: 13, color: Colors.red.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                )),
              ]),
            )).toList(),
          ),
        ),
      ],

      // ── Erreurs par ligne ─────────────────────────────────────────────────
      if (errorsByRow.isNotEmpty) ...[
        SizedBox(height: 16),
        Text(
          'Détail par ligne :',
          style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: Color(0xFF0f172a),
          ),
        ),
        SizedBox(height: 8),

        // Affiche max 8 lignes en erreur
        ...errorsByRow.entries.take(8).map((entry) {
          final rowNum  = entry.key;
          final rowErrs = entry.value;

          return Container(
            margin: EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFef4444).withOpacity(0.2)),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6, offset: Offset(0, 2),
              )],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Badge ligne ────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFFef4444).withOpacity(0.08),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(children: [
                  Icon(Icons.table_rows_outlined,
                      size: 14, color: Color(0xFFef4444)),
                  SizedBox(width: 6),
                  Text(
                    'Ligne $rowNum',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold,
                      color: Color(0xFFef4444),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${rowErrs.length} erreur${rowErrs.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 11, color: Color(0xFFef4444).withOpacity(0.7),
                    ),
                  ),
                ]),
              ),

              // ── Liste des erreurs de cette ligne ───────────────────────
              ...rowErrs.map((err) {
                final field = err['field']?.toString() ?? '';
                final msg   = err['message']?.toString() ?? '';
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icône champ
                      Container(
                        margin: EdgeInsets.only(top: 2),
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color:        Color(0xFFef4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(Icons.edit_note,
                            size: 12, color: Color(0xFFef4444)),
                      ),
                      SizedBox(width: 10),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (field.isNotEmpty)
                            Text(
                              field,
                              style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold,
                                color: Color(0xFF64748b),
                                fontFamily: 'monospace',
                              ),
                            ),
                          SizedBox(height: 2),
                          Text(
                            msg,
                            style: TextStyle(
                              fontSize: 13, color: Color(0xFF0f172a),
                            ),
                          ),
                        ],
                      )),
                    ],
                  ),
                );
              }),

              // Séparateur entre erreurs si plusieurs
              if (rowErrs.length > 1)
                Divider(height: 1, color: Color(0xFFef4444).withOpacity(0.1)),
            ]),
          );
        }),

        // Message si trop d'erreurs
        if (errorsByRow.length > 8)
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:        Color(0xFFf59e0b).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xFFf59e0b).withOpacity(0.3)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, color: Color(0xFFf59e0b), size: 16),
              SizedBox(width: 8),
              Expanded(child: Text(
                '... et ${errorsByRow.length - 8} autres lignes en erreur. '
                'Corrigez les erreurs affichées en premier.',
                style: TextStyle(fontSize: 12, color: Color(0xFF92400e)),
              )),
            ]),
          ),
      ],

      SizedBox(height: 16),

      // ── Bouton réessayer ─────────────────────────────────────────────────
      ElevatedButton.icon(
        onPressed: _resetForm,
        icon:  Icon(Icons.refresh_rounded, size: 18),
        label: Text('Corriger et réessayer',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFef4444),
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    ]),
  );
}

  Widget _buildHistory(ColorScheme colorScheme, ThemeData theme) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Recent Uploads',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: colorScheme.onSurface)),
        TextButton.icon(
          onPressed: _loadHistory,
          icon: Icon(Icons.refresh, size: 16), label: Text('Refresh'),
        ),
      ]),
      SizedBox(height: 12),
      if (_historyLoading)
        Center(child: CircularProgressIndicator(color: colorScheme.primary))
      else if (_history.isEmpty)
        Center(child: Text('No uploads yet',
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))))
      else
        ..._history.take(5).map((item) => _buildHistoryItem(item, colorScheme)),
    ]);
  }

  Widget _buildHistoryItem(Map<String, dynamic> item, ColorScheme colorScheme) {
    final status    = item['status'] ?? 'Unknown';
    final isSuccess = status == 'Converted';
    final color     = isSuccess ? Color(0xFF10b981) : Color(0xFFef4444);
    final icon      = isSuccess ? Icons.check_circle : Icons.error;

    String dateStr = '';
    try {
      final dt   = DateTime.parse(item['uploadDate'] ?? '');
      final diff = DateTime.now().difference(dt);
      if (diff.inHours < 1)       dateStr = '${diff.inMinutes}m ago';
      else if (diff.inHours < 24) dateStr = '${diff.inHours}h ago';
      else                        dateStr = '${diff.inDays}d ago';
    } catch (_) {}

    return Container(
      margin:  EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:        color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['fileName'] ?? '',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 4),
          Row(children: [
            Text(item['modelCode'] ?? '',
                style: TextStyle(fontSize: 12, color: colorScheme.primary,
                    fontWeight: FontWeight.w500)),
            if (dateStr.isNotEmpty) ...[
              Text('  •  ',
                  style: TextStyle(color: colorScheme.onSurface.withOpacity(0.3))),
              Text(dateStr,
                  style: TextStyle(fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.5))),
            ],
            if (isSuccess && item['rowCount'] != null) ...[
              Text('  •  ',
                  style: TextStyle(color: colorScheme.onSurface.withOpacity(0.3))),
              Text('${item['rowCount']} rows',
                  style: TextStyle(fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.5))),
            ],
          ]),
        ])),
        // Download CSV from history if csvContent is available
        if (isSuccess && item['csvContent'] != null)
          IconButton(
            icon:    Icon(Icons.download_rounded, color: colorScheme.primary, size: 20),
            tooltip: 'Download CSV',
            onPressed: () {
              final csv      = item['csvContent'] as String;
              final model    = item['modelCode'] ?? 'export';
              final fileName = '${model}_${item['id'] ?? ''}.csv';
              final bytes    = Uint8List.fromList(utf8.encode(csv));
              if (kIsWeb) {
                triggerWebDownload(bytes, fileName);
              } else {
                saveMobileFile(bytes, fileName);
              }
            },
          ),
        SizedBox(width: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color:        color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(status,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                  color: color)),
        ),
      ]),
    );
  }
}

class _MobileFile {
  final String path;
  _MobileFile(this.path);
}