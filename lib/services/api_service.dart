import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // kIsWeb

import 'api_service_web.dart' if (dart.library.io) 'api_service_stub.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5160';
  static const int    userId  = 1;

  final Dio _dio = Dio(BaseOptions(
    baseUrl:        baseUrl,
    connectTimeout: Duration(seconds: 30),
    receiveTimeout: Duration(seconds: 60),
  ));

  // ── GET /api/models ──────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getModels() async {
    try {
      final response = await _dio.get('/api/models');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to load models: ${e.message}');
    }
  }

  // ── GET /api/templates/{code}/excel ─────────────────────────────────────
  Future<void> downloadTemplate(String modelCode) async {
    try {
      final response = await _dio.get(
        '/api/templates/$modelCode/excel',
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes    = Uint8List.fromList(response.data);
      final fileName = '${modelCode}_import_template.xlsx';

      if (kIsWeb) {
        triggerWebDownload(bytes, fileName);
      } else {
        await saveMobileFile(bytes, fileName);
      }
    } on DioException catch (e) {
      throw Exception('Failed to download template: ${e.message}');
    }
  }

  // ── POST /api/imports/upload ─────────────────────────────────────────────
  // [file] is Uint8List on web, or a file-path-wrapper on mobile
  Future<Map<String, dynamic>> uploadFile(
    dynamic file,
    String fileName, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      MultipartFile multipartFile;

      if (kIsWeb) {
        // file is Uint8List
        multipartFile = MultipartFile.fromBytes(
          file as Uint8List,
          filename: fileName,
        );
      } else {
        // file has a .path property
        multipartFile = await MultipartFile.fromFile(
          file.path as String,
          filename: fileName,
        );
      }

      final formData = FormData.fromMap({
        'file':   multipartFile,
        'userId': userId.toString(),
      });

      final response = await _dio.post(
        '/api/imports/upload',
        data: formData,
        onSendProgress: (sent, total) {
          if (total != -1 && onProgress != null) {
            onProgress(sent / total);
          }
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        return Map<String, dynamic>.from(e.response!.data);
      }
      throw Exception('Upload failed: ${e.message}');
    }
  }

  // ── GET /api/imports/history ─────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getHistory({int? userId}) async {
    try {
      final query    = userId != null ? '?userId=$userId' : '';
      final response = await _dio.get('/api/imports/history$query');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to load history: ${e.message}');
    }
  }
}