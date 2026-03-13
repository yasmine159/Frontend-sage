// Web implementation — triggers a real browser file download
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;


void triggerWebDownload(Uint8List bytes, String fileName) {
  final blob = html.Blob([bytes]);
  final url  = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

// Mobile stub — not called on web but needed for compilation
Future<void> saveMobileFile(Uint8List bytes, String fileName) async {}