// Mobile (non-web) implementation — saves file to app documents directory
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// Web stub — not called on mobile
void triggerWebDownload(Uint8List bytes, String fileName) {}

Future<void> saveMobileFile(Uint8List bytes, String fileName) async {
  final dir  = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes);
}