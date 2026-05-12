// Mobile (non-web) implementation
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void triggerWebDownload(Uint8List bytes, String fileName) {}

Future<void> saveMobileFile(Uint8List bytes, String fileName) async {
  if (Platform.isAndroid) {
    try {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) {
        final file = File('${downloadsDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        return;
      }
    } catch (_) {}
    // Fallback
    final extDirs = await getExternalStorageDirectories();
    if (extDirs != null && extDirs.isNotEmpty) {
      await File('${extDirs.first.path}/$fileName').writeAsBytes(bytes);
      return;
    }
  }
  // iOS ou fallback final
  final dir = await getApplicationDocumentsDirectory();
  await File('${dir.path}/$fileName').writeAsBytes(bytes);
}