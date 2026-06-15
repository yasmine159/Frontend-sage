import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../services/api_service.dart';
import '../../services/api_service_web.dart'
if (dart.library.io) '../../services/api_service_stub.dart';

class OcrScanPage extends StatefulWidget {
  const OcrScanPage({Key? key}) : super(key: key);
  @override
  State<OcrScanPage> createState() => _OcrScanPageState();
}

class _OcrScanPageState extends State<OcrScanPage>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  XFile? _imageFile;
  Uint8List? _imageBytes;

  bool _scanning = false;
  String _scanStatus = '';

  List<String> _headers = [];
  List<List<String>> _rows = [];
  bool _showTable = false;

  bool _generatingExcel = false;
  bool _showPhotoGuide = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  static const _blue   = Color(0xFF2563eb);
  static const _violet = Color(0xFF7c3aed);
  static const _green  = Color(0xFF059669);
  static const _red    = Color(0xFFdc2626);
  static const _amber  = Color(0xFFd97706);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulse = Tween(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final xfile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        preferredCameraDevice: CameraDevice.rear);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageFile = xfile; _imageBytes = bytes;
      _headers = []; _rows = []; _showTable = false;
      _showPhotoGuide = true;
    });
  }

  Future<void> _pickFromGallery() async {
    final xfile = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 100);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageFile = xfile; _imageBytes = bytes;
      _headers = []; _rows = []; _showTable = false;
      _showPhotoGuide = true;
    });
  }

  Future<void> _scanWeb() async {
    if (_imageBytes == null) return;
    setState(() {
      _scanning = true;
      _scanStatus = "Envoi de l'image au serveur...";
      _showTable = false;
      _showPhotoGuide = false;
    });
    try {
      setState(() => _scanStatus = 'Analyse du tableau en cours...');
      final result = await _api.scanImageToTable(
        _imageBytes!,
        fileName: _imageFile?.name ?? 'scan.jpg',
      );
      if (!mounted) return;
      final rawHeaders = (result['headers'] as List<dynamic>? ?? [])
          .map((e) => e.toString()).toList();
      final rawRows = (result['rows'] as List<dynamic>? ?? [])
          .map((r) => (r as List<dynamic>).map((c) => c.toString()).toList())
          .toList();
      setState(() {
        _headers = rawHeaders;
        _rows = rawRows;
        _showTable = true;
        _scanning = false;
        _scanStatus = '';
      });
      if (_headers.isEmpty) {
        _snack('Aucun tableau détecté. Essayez avec une image plus nette.', _amber);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _scanning = false; _scanStatus = ''; });
      _snack('Erreur : $e', _red);
    }
  }

  Future<void> _scan() async {
    if (_imageFile == null || kIsWeb) return;
    setState(() {
      _scanning = true;
      _scanStatus = 'Reconnaissance du texte en cours...';
      _showTable = false;
      _showPhotoGuide = false;
    });
    try {
      final inputImage = InputImage.fromFilePath(_imageFile!.path!);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      if (!mounted) return;
      setState(() => _scanStatus = 'Analyse des colonnes du tableau...');
      final recognized = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();
      final blocks = recognized.blocks;
      if (blocks.isEmpty) {
        if (!mounted) return;
        setState(() { _scanning = false; _scanStatus = ''; _showTable = true; });
        return;
      }
      final (headers, rows) = _buildTableFromBlocks(blocks);
      if (!mounted) return;
      setState(() {
        _headers = headers; _rows = rows;
        _showTable = true; _scanning = false; _scanStatus = '';
      });
      if (_headers.isEmpty) {
        _snack('Aucun tableau détecté. Essayez de photographier de face.', _amber);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _scanning = false; _scanStatus = ''; });
      _snack('Erreur ML Kit : $e', _red);
    }
  }

  // ── Parser ML Kit — VERSION FINALE (inversion + fragments + transposition) ───
  (List<String>, List<List<String>>) _buildTableFromBlocks(List<TextBlock> blocks) {
    // 1. Collecter tous les éléments
    final elements = <_TextElement>[];
    for (final block in blocks) {
      for (final line in block.lines) {
        final bbox = line.boundingBox;
        final text = line.text.trim();
        if (text.isNotEmpty && bbox != null) {
          elements.add(_TextElement(
            text: text,
            x: bbox.left.toDouble(), y: bbox.top.toDouble(),
            width: bbox.width.toDouble(), height: bbox.height.toDouble(),
          ));
        }
      }
    }
    if (elements.isEmpty) return ([], []);

    // 2. Paramètres adaptatifs
    final avgH = elements.map((e) => e.height).reduce((a, b) => a + b) / elements.length;
    final rowTol = (avgH * 0.8).clamp(8.0, 60.0);
    final minX = elements.map((e) => e.x).reduce((a, b) => a < b ? a : b);
    final maxX = elements.map((e) => e.x + e.width).reduce((a, b) => a > b ? a : b);
    final tableW = maxX - minX;
    final colThreshold = (tableW * 0.08).clamp(20.0, 100.0);

    // 3. Grouper par lignes avec centre moyen (évite le drift)
    final sortedByY = [...elements]..sort((a, b) => a.y.compareTo(b.y));
    final lineGroups = <List<_TextElement>>[];
    var current = [sortedByY[0]];
    for (int i = 1; i < sortedByY.length; i++) {
      final groupCY = current.map((e) => e.y + e.height / 2).reduce((a, b) => a + b) / current.length;
      final elCY = sortedByY[i].y + sortedByY[i].height / 2;
      if ((elCY - groupCY).abs() <= rowTol) {
        current.add(sortedByY[i]);
      } else {
        lineGroups.add([...current]..sort((a, b) => a.x.compareTo(b.x)));
        current = [sortedByY[i]];
      }
    }
    lineGroups.add([...current]..sort((a, b) => a.x.compareTo(b.x)));

    // 4. Clustering colonnes
    final allCX = elements.map((e) => e.x + e.width / 2).toList()..sort();
    final colCenters = _clusterValues(allCX, threshold: colThreshold);
    final nc = colCenters.length;
    if (nc == 0) return ([], []);

    int nearestCol(double cx) {
      int best = 0; double minD = double.infinity;
      for (int i = 0; i < colCenters.length; i++) {
        final d = (cx - colCenters[i]).abs();
        if (d < minD) { minD = d; best = i; }
      }
      return best;
    }

    // 5. Construire grille brute
    var grid = <List<String>>[];
    for (final line in lineGroups) {
      final row = List.filled(nc, '');
      for (final el in line) {
        final ci = nearestCol(el.x + el.width / 2);
        row[ci] = row[ci].isEmpty ? el.text : '${row[ci]} ${el.text}';
      }
      if (row.any((c) => c.isNotEmpty)) grid.add(row);
    }
    if (grid.isEmpty) return ([], []);

    // 6. Fusionner les lignes fragmentées
    // ML Kit peut retourner les cellules d'une même ligne en plusieurs blocs séparés
    final mergedGrid = <List<String>>[];
    for (int i = 0; i < grid.length; i++) {
      final row = grid[i];
      final filled = row.where((c) => c.isNotEmpty).length;
      if (mergedGrid.isNotEmpty && filled <= nc ~/ 2) {
        final prev = mergedGrid.last;
        final prevFilled = prev.where((c) => c.isNotEmpty).length;
        if (prevFilled <= nc - 1) {
          // Compléter la ligne précédente avec les cellules manquantes
          for (int c = 0; c < nc; c++) {
            if (c < row.length && row[c].isNotEmpty &&
                (c >= prev.length || prev[c].isEmpty)) {
              prev[c] = row[c];
            }
          }
          continue;
        }
      }
      mergedGrid.add([...row]);
    }
    grid = mergedGrid;

    // 7. Supprimer colonnes vides
    final nonEmptyCols = List.generate(nc, (i) => i)
        .where((i) => grid.any((row) => i < row.length && row[i].trim().isNotEmpty))
        .toList();
    if (nonEmptyCols.isEmpty) return ([], []);
    grid = grid.map((row) =>
        nonEmptyCols.map((i) => i < row.length ? row[i].trim() : '').toList()
    ).toList();

    final nCols = grid.isEmpty ? 0 : grid[0].length;

    // 8. Détecter si transposé (colonnes lues comme lignes)
    if (nCols > 0 && grid.length > nCols) {
      final singleElem = grid.where((r) => r.where((c) => c.isNotEmpty).length == 1).length;
      if (singleElem > grid.length * 0.6) {
        final transposed = List.generate(
          nCols,
              (c) => List.generate(grid.length,
                  (r) => r < grid.length && c < grid[r].length ? grid[r][c] : ''),
        );
        grid = transposed;
      }
    }

    // 9. Détecter la ligne header — chercher dans toutes les lignes
    bool isHeaderLike(String s) {
      final t = s.trim();
      return t.isNotEmpty &&
          t.length <= 20 &&
          RegExp(r'^[A-Za-zÀ-ÿ\s\-/éèêëàâùûîïôç]+$').hasMatch(t);
    }
    int headerScore(List<String> row) => row.where((c) => isHeaderLike(c)).length;

    // Trouver l'index de la meilleure ligne header
    int bestHeaderIdx = 0;
    int bestScore = headerScore(grid[0]);
    for (int i = 1; i < grid.length; i++) {
      final score = headerScore(grid[i]);
      if (score > bestScore) { bestScore = score; bestHeaderIdx = i; }
    }

    // Si le header est dans la 2ème moitié → inverser le tableau
    if (bestHeaderIdx > grid.length ~/ 2) {
      grid = grid.reversed.toList();
      bestHeaderIdx = grid.length - 1 - bestHeaderIdx;
    }

    // Re-vérifier parmi les 3 premières lignes après inversion
    bestHeaderIdx = 0;
    bestScore = headerScore(grid[0]);
    for (int i = 1; i < grid.length && i < 3; i++) {
      final score = headerScore(grid[i]);
      if (score > bestScore) { bestScore = score; bestHeaderIdx = i; }
    }

    // 10. Séparer headers et rows
    final headers = grid[bestHeaderIdx].map((h) => h.trim()).toList();
    final rows = grid
        .asMap().entries
        .where((e) => e.key != bestHeaderIdx)
        .map((e) => e.value.map((c) => c.trim()).toList())
        .where((r) => r.any((c) => c.isNotEmpty))
        .toList();

    return (headers, rows);
  }

  List<double> _clusterValues(List<double> sorted, {double threshold = 30}) {
    if (sorted.isEmpty) return [];
    final clusters = <List<double>>[[sorted[0]]];
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i] - clusters.last.last <= threshold) {
        clusters.last.add(sorted[i]);
      } else { clusters.add([sorted[i]]); }
    }
    return clusters.map((c) => c.reduce((a, b) => a + b) / c.length).toList();
  }

  void _editCell(int row, int col, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(row == -1 ? 'Modifier l\'en-tête' : 'Modifier la cellule',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl, autofocus: true,
          decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              if (!mounted) return;
              setState(() {
                if (row == -1) { _headers[col] = ctrl.text; }
                else { while (_rows[row].length <= col) _rows[row].add(''); _rows[row][col] = ctrl.text; }
              });
              WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose());
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _violet, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('OK'),
          ),
        ],
      ),
    ).then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try { ctrl.dispose(); } catch (_) {}
      });
    });
  }

  void _addRow() => setState(() => _rows.add(List.filled(_headers.length, '')));
  void _deleteRow(int i) => setState(() => _rows.removeAt(i));

  Future<void> _downloadExcel() async {
    if (_headers.isEmpty) return;
    setState(() => _generatingExcel = true);
    try {
      final result = await _api.tableToExcel(
          headers: _headers, rows: _rows,
          fileName: 'scan_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      final bytes    = result['excelBytes'] as Uint8List;
      final fileName = result['fileName'] as String;
      if (!mounted) return;
      setState(() => _generatingExcel = false);
      if (kIsWeb) {
        triggerWebDownload(bytes, fileName);
        _snack('✅ Excel téléchargé avec succès !', _green);
      } else {
        await saveMobileFile(bytes, fileName);
        if (!mounted) return;
        _showSaveSuccessDialog(fileName);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _generatingExcel = false);
      _snack('Erreur : $e', _red);
    }
  }

  void _showSaveSuccessDialog(String fileName) {
    if (!mounted) return;
    final dk  = Theme.of(context).brightness == Brightness.dark;
    final txt = dk ? Colors.white : const Color(0xFF111827);
    final sub = const Color(0xFF6b7280);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _green.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: _green, size: 40),
          ),
          const SizedBox(height: 16),
          Text('Excel sauvegardé !',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: txt)),
          const SizedBox(height: 8),
          Text('Votre fichier a été enregistré dans :',
              style: TextStyle(fontSize: 13, color: sub), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: dk ? const Color(0xFF1e2028) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(Icons.folder_rounded, color: _amber, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('📁 Téléchargements/$fileName',
                  style: TextStyle(fontSize: 12, color: txt, fontWeight: FontWeight.w500))),
            ]),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _green, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Parfait !',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  void _snack(String msg, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 13)),
      backgroundColor: c,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dk   = Theme.of(context).brightness == Brightness.dark;
    final bg   = dk ? const Color(0xFF0b0e13) : const Color(0xFFF7F8FA);
    final card = dk ? const Color(0xFF151921) : Colors.white;
    final bord = dk ? const Color(0xFF1e2028) : const Color(0xFFf0f0f5);
    final txt  = dk ? Colors.white : const Color(0xFF111827);
    final sub  = dk ? const Color(0xFF6b7280) : const Color(0xFF9ca3af);
    final desk = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: bg,
      body: Column(children: [
        _header(context, desk, dk, card, bord, txt, sub),
        Expanded(child: SingleChildScrollView(
          padding: EdgeInsets.all(desk ? 32 : 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 24),
            _photoSection(dk, card, bord, txt, sub),
            if (_imageBytes != null) ...[
              const SizedBox(height: 20),
              _imagePreview(dk, card, bord, txt, sub),
              const SizedBox(height: 16),
              _scanBtn(),
            ],
            if (_scanning) ...[
              const SizedBox(height: 24),
              _scanningCard(dk, card, bord, txt, sub),
            ],
            if (_showTable && _headers.isNotEmpty) ...[
              const SizedBox(height: 24),
              _tableSection(dk, card, bord, txt, sub),
              const SizedBox(height: 20),
              _downloadBtn(),
            ],
            if (_showTable && _headers.isEmpty)
              _emptyCard(dk, card, bord, txt, sub),
            const SizedBox(height: 40),
          ]),
        )),
      ]),
    );
  }

  Widget _header(BuildContext ctx, bool desk, bool dk, Color card, Color bord, Color txt, Color sub) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: desk ? 32 : 20, vertical: 16),
      decoration: BoxDecoration(color: card, border: Border(bottom: BorderSide(color: bord))),
      child: Row(children: [
        _backBtn(ctx, dk, sub), const SizedBox(width: 14),
        Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _violet.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.document_scanner_rounded, color: _violet, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Scanner un document',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: txt, letterSpacing: -0.3)),
          Text('Photo → ML Kit / Serveur → Excel',
              style: TextStyle(fontSize: 12, color: sub)),
        ])),
      ]),
    );
  }

  Widget _photoSection(bool dk, Color card, Color bord, Color txt, Color sub) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Source de l\'image',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: txt)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _srcBtn(
            icon: Icons.camera_alt_rounded, label: 'Prendre une photo',
            sublabel: 'Recommandé', color: _violet,
            onTap: kIsWeb ? null : _takePhoto, disabled: kIsWeb,
            dk: dk, card: card, bord: bord, txt: txt, sub: sub)),
        const SizedBox(width: 12),
        Expanded(child: _srcBtn(
            icon: Icons.photo_library_rounded, label: 'Depuis la galerie',
            sublabel: kIsWeb ? 'Fichier depuis PC' : 'Galerie / Fichier', color: _blue,
            onTap: _pickFromGallery, disabled: false,
            dk: dk, card: card, bord: bord, txt: txt, sub: sub)),
      ]),
    ]);
  }

  Widget _srcBtn({
    required IconData icon, required String label, required String sublabel,
    required Color color, required VoidCallback? onTap, required bool dk,
    required Color card, required Color bord, required Color txt, required Color sub,
    bool disabled = false,
  }) {
    return Opacity(
      opacity: disabled ? 0.35 : 1.0,
      child: Container(
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: bord)),
        child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(14),
          child: InkWell(onTap: disabled ? null : onTap, borderRadius: BorderRadius.circular(14),
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(children: [
                  Container(padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(icon, color: color, size: 24)),
                  const SizedBox(height: 10),
                  Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: txt),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 2),
                  Text(sublabel, style: TextStyle(fontSize: 10, color: sub),
                      textAlign: TextAlign.center),
                ]),
              )),
        ),
      ),
    );
  }

  Widget _imagePreview(bool dk, Color card, Color bord, Color txt, Color sub) {
    return Container(
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(14),
            child: Row(children: [
              Icon(Icons.image_outlined, size: 16, color: sub), const SizedBox(width: 8),
              Expanded(child: Text(_imageFile?.name ?? 'Image',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: txt),
                  overflow: TextOverflow.ellipsis)),
              GestureDetector(
                  onTap: () => setState(() {
                    _imageFile = null; _imageBytes = null; _showTable = false;
                  }),
                  child: Icon(Icons.close, size: 16, color: sub)),
            ])),
        ClipRRect(borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
            child: Image.memory(_imageBytes!, width: double.infinity, height: 220, fit: BoxFit.cover)),
      ]),
    );
  }

  Widget _scanBtn() {
    return SizedBox(
      width: double.infinity, height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_violet, _blue],
                begin: Alignment.centerLeft, end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: _violet.withOpacity(0.3), blurRadius: 12,
                offset: const Offset(0, 4))]),
        child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _scanning ? null : (kIsWeb ? _scanWeb : _scan),
              borderRadius: BorderRadius.circular(14),
              child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(_showTable ? 'Re-scanner' : 'Analyser le tableau',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              ])),
            )),
      ),
    );
  }

  Widget _scanningCard(bool dk, Color card, Color bord, Color txt, Color sub) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bord)),
      child: Column(children: [
        ScaleTransition(scale: _pulse,
            child: Container(padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: _violet.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.document_scanner_rounded, color: _violet, size: 32))),
        const SizedBox(height: 16),
        Text(_scanStatus, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: txt)),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          backgroundColor: _violet.withOpacity(0.1),
          valueColor: const AlwaysStoppedAnimation(_violet),
          borderRadius: BorderRadius.circular(4),
        ),
      ]),
    );
  }

  Widget _tableSection(bool dk, Color card, Color bord, Color txt, Color sub) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check_circle_outline, size: 13, color: _green), const SizedBox(width: 4),
              Text('${_rows.length} lignes • ${_headers.length} colonnes',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _green)),
            ])),
        const Spacer(),
        TextButton.icon(onPressed: _addRow,
            icon: Icon(Icons.add, size: 14, color: _blue),
            label: Text('Ligne', style: TextStyle(fontSize: 12, color: _blue, fontWeight: FontWeight.w500))),
      ]),
      const SizedBox(height: 8),
      Text('Tapez sur une cellule pour modifier', style: TextStyle(fontSize: 11, color: sub)),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: bord)),
        child: ClipRRect(borderRadius: BorderRadius.circular(13),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                  dk ? const Color(0xFF1e2028) : const Color(0xFFF3F4F6)),
              dataRowMinHeight: 40, dataRowMaxHeight: 56, columnSpacing: 20,
              columns: [
                DataColumn(label: Text('#',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sub))),
                ..._headers.asMap().entries.map((e) => DataColumn(
                  label: GestureDetector(
                    onTap: () => _editCell(-1, e.key, e.value),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(e.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: txt)),
                      const SizedBox(width: 4),
                      Icon(Icons.edit, size: 11, color: sub),
                    ]),
                  ),
                )),
                const DataColumn(label: SizedBox()),
              ],
              rows: _rows.asMap().entries.map((re) {
                final ri = re.key; final row = re.value;
                return DataRow(cells: [
                  DataCell(Text('${ri + 1}', style: TextStyle(fontSize: 11, color: sub))),
                  ..._headers.asMap().entries.map((ce) {
                    final ci = ce.key;
                    final val = ci < row.length ? row[ci] : '';
                    return DataCell(GestureDetector(
                      onTap: () => _editCell(ri, ci, val),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Flexible(child: Text(val,
                              style: TextStyle(fontSize: 12, color: txt),
                              overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 4),
                          Icon(Icons.edit, size: 10, color: sub),
                        ]),
                      ),
                    ));
                  }),
                  DataCell(IconButton(
                    icon: Icon(Icons.delete_outline, size: 16, color: _red.withOpacity(0.5)),
                    onPressed: () => _deleteRow(ri),
                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  )),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _downloadBtn() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: _generatingExcel ? null : const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10b981)],
          begin: Alignment.centerLeft, end: Alignment.centerRight,
        ),
        color: _generatingExcel ? const Color(0xFF059669).withOpacity(0.6) : null,
        boxShadow: _generatingExcel ? null : [
          BoxShadow(color: const Color(0xFF059669).withOpacity(0.35),
              blurRadius: 16, offset: const Offset(0, 6))
        ],
      ),
      child: Material(
        color: Colors.transparent, borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _generatingExcel ? null : _downloadExcel,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            child: _generatingExcel
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5,
                      color: Colors.white.withOpacity(0.9))),
              const SizedBox(width: 14),
              const Text('Génération en cours...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ])
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.download_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const Column(crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, children: [
                    Text('Télécharger en Excel',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                            color: Colors.white, letterSpacing: -0.2)),
                    Text('Fichier .xlsx prêt à l\'import',
                        style: TextStyle(fontSize: 11, color: Colors.white70,
                            fontWeight: FontWeight.w400)),
                  ]),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('XLSX',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                        color: Colors.white, letterSpacing: 0.5)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _emptyCard(bool dk, Color card, Color bord, Color txt, Color sub) {
    return Container(
      margin: const EdgeInsets.only(top: 24), padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _amber.withOpacity(0.2))),
      child: Column(children: [
        Icon(Icons.tips_and_updates_outlined, size: 40, color: _amber.withOpacity(0.6)),
        const SizedBox(height: 12),
        Text('Aucun tableau détecté',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: txt)),
        const SizedBox(height: 8),
        Text('Conseils pour une meilleure photo :\n'
            '• Photographiez de face (pas en biais)\n'
            '• Bonne lumière, évitez les ombres\n'
            '• Le tableau doit occuper la majorité de la photo\n'
            '• Évitez le flash direct',
            style: TextStyle(fontSize: 12, color: sub, height: 1.6),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _backBtn(BuildContext ctx, bool dk, Color sub) {
    return Container(width: 38, height: 38,
        decoration: BoxDecoration(
            color: dk ? const Color(0xFF1a1d24) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10)),
        child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(10),
            child: InkWell(onTap: () => Navigator.pop(ctx),
                borderRadius: BorderRadius.circular(10),
                child: Icon(Icons.arrow_back, size: 18, color: sub))));
  }
}

class _TextElement {
  final String text;
  final double x, y, width, height;
  const _TextElement({
    required this.text, required this.x, required this.y,
    required this.width, required this.height,
  });
}