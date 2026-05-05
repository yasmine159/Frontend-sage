import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'api_service_web.dart' if (dart.library.io) 'api_service_stub.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5160';

  static int get userId => AuthService.instance.currentUser?.id ?? 0;

  Dio get _dio {
    final token = AuthService.instance.currentUser?.token;
    return Dio(BaseOptions(
      baseUrl:        baseUrl,
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 60),
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    ));
  }

  // ── POST /api/users/login ────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/api/users/login', data: {
        'email': email, 'password': password,
      });
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401)
        throw Exception(e.response?.data?['message'] ?? 'Invalid email or password.');
      throw Exception('Login failed: ${e.message}');
    }
  }

  // ── POST /api/users/register ─────────────────────────────────────────────
  Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    try {
      final response = await _dio.post('/api/users/register', data: {
        'username': username, 'email': email,
        'password': password, 'role': 'User',
      });
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message);
    }
  }

  // ── GET /api/users ───────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await _dio.get('/api/users');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to load users: ${e.message}');
    }
  }

  // ── GET /api/users/admin/stats ───────────────────────────────────────────
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final response = await _dio.get('/api/users/admin/stats');
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to load stats: ${e.message}');
    }
  }

  // ── PUT /api/users/{id} ──────────────────────────────────────────────────
    Future<Map<String, dynamic>> updateUser(
      int id, String username, String email, String role,
      {String phone = '', String company = ''}) async {
    try {
      final response = await _dio.put('/api/users/$id', data: {
        'id': id, 'username': username, 'email': email,
        'role': role, 'phone': phone, 'company': company,
      });
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message);
    }
  }

  // ── DELETE /api/users/{id} ───────────────────────────────────────────────
  Future<void> deleteUser(int id) async {
    try {
      await _dio.delete('/api/users/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message);
    }
  }

  // ── PATCH /api/users/{id}/suspend ────────────────────────────────────────
  Future<void> suspendUser(int id) async {
    try {
      await _dio.patch('/api/users/$id/suspend');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message);
    }
  }

  // ── PATCH /api/users/{id}/activate ───────────────────────────────────────
  Future<void> activateUser(int id) async {
    try {
      await _dio.patch('/api/users/$id/activate');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message);
    }
  }

  // ── POST /api/users/{id}/change-password ─────────────────────────────────
  Future<void> changePassword(int uid, String oldPassword, String newPassword) async {
    try {
      await _dio.post('/api/users/$uid/change-password', data: {
        'oldPassword': oldPassword, 'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message);
    }
  }

  // ── GET /api/models ──────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getModels() async {
    try {
      final response = await _dio.get('/api/models');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to load models: ${e.message}');
    }
  }
  // ── GET /api/models/{code} ───────────────────────────────────────────────
Future<Map<String, dynamic>> getModelDetails(String code) async {
  try {
    final response = await _dio.get('/api/models/$code');
    return Map<String, dynamic>.from(response.data);
  } on DioException catch (e) {
    throw Exception('Failed to load model details: ${e.message}');
  }
}

  // ── GET /api/templates/{code}/excel ──────────────────────────────────────
  Future<void> downloadTemplate(String modelCode) async {
    try {
      final response = await _dio.get(
        '/api/templates/$modelCode/excel',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes    = Uint8List.fromList(response.data);
      final fileName = '${modelCode}_import_template.xlsx';
      kIsWeb
          ? triggerWebDownload(bytes, fileName)
          : await saveMobileFile(bytes, fileName);
    } on DioException catch (e) {
      throw Exception('Failed to download template: ${e.message}');
    }
  }

  // ── POST /api/imports/upload ─────────────────────────────────────────────
  Future<Map<String, dynamic>> uploadFile(
    dynamic file,
    String fileName, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final multipartFile = kIsWeb
          ? MultipartFile.fromBytes(file as Uint8List, filename: fileName)
          : await MultipartFile.fromFile(file.path as String, filename: fileName);

      final formData = FormData.fromMap({
        'file': multipartFile, 'userId': userId.toString(),
      });

      final response = await _dio.post(
        '/api/imports/upload',
        data: formData,
        onSendProgress: (sent, total) {
          if (total != -1 && onProgress != null) onProgress(sent / total);
        },
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422)
        return Map<String, dynamic>.from(e.response!.data);
      throw Exception('Upload failed: ${e.message}');
    }
  }

  // ── GET /api/imports/history (current user) ───────────────────────────────
  Future<List<Map<String, dynamic>>> getHistory({int? userId}) async {
    try {
      final id       = userId ?? ApiService.userId;
      final response = await _dio.get('/api/imports/history?userId=$id');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to load history: ${e.message}');
    }
  }

  // ── GET /api/imports/history (all users — admin) ──────────────────────────
  Future<List<Map<String, dynamic>>> getAllHistory() async {
    try {
      final response = await _dio.get('/api/imports/history');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to load activity: ${e.message}');
    }
  }

  // ── GET /api/imports/history/{id}/csv ────────────────────────────────────
  Future<void> downloadCsv(int importId) async {
    try {
      final response = await _dio.get(
        '/api/imports/history/$importId/csv',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes    = Uint8List.fromList(response.data);
      final fileName = 'import_$importId.csv';
      kIsWeb
          ? triggerWebDownload(bytes, fileName)
          : await saveMobileFile(bytes, fileName);
    } on DioException catch (e) {
      throw Exception('Download failed: ${e.message}');
    }
  }
  // ── GET /api/imports/stats ─────────────────────────────────────────────
Future<Map<String, dynamic>> getUserStats({int? userId}) async {
  try {
    final id = userId ?? ApiService.userId;
    final response = await _dio.get('/api/imports/stats?userId=$id');
    return Map<String, dynamic>.from(response.data);
  } on DioException catch (e) {
    throw Exception('Failed to load stats: ${e.message}');
  }
}
Future<Map<String, dynamic>> getAnalytics({int? userId, String period = '30d'}) async {
  try {
    final params = <String, dynamic>{'period': period};
    if (userId != null) params['userId'] = userId;
    final response = await _dio.get('/api/analytics', queryParameters: params);
    return Map<String, dynamic>.from(response.data);
  } on DioException catch (e) {
    throw Exception('Failed to load analytics: ${e.message}');
  }
}
// ═══════════════════════════════════════════════════════════════════════
  //  MAPPING ENDPOINTS — Add these methods to your ApiService class
  // ═══════════════════════════════════════════════════════════════════════

  // ── POST /api/mappings/read-headers ───────────────────────────────────
  Future<List<String>> readExcelHeaders(dynamic file, String fileName) async {
    try {
      final multipartFile = kIsWeb
          ? MultipartFile.fromBytes(file as Uint8List, filename: fileName)
          : await MultipartFile.fromFile(file.path as String, filename: fileName);
      final formData = FormData.fromMap({'file': multipartFile});
      final response = await _dio.post('/api/mappings/read-headers', data: formData);
      return List<String>.from(response.data['headers']);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to read headers');
    }
  }

  // ── GET /api/mappings/fields/{modelCode} ──────────────────────────────
  Future<List<Map<String, dynamic>>> getModelFields(String modelCode) async {
    try {
      final response = await _dio.get('/api/mappings/fields/$modelCode');
      return (response.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load fields: ${e.message}');
    }
  }

  // ── POST /api/mappings/save ───────────────────────────────────────────
  Future<Map<String, dynamic>> saveMapping(int userId, String name, String modelCode, String columnMappings) async {
    try {
      final response = await _dio.post('/api/mappings/save', data: {
        'userId': userId, 'mappingName': name,
        'modelCode': modelCode, 'columnMappings': columnMappings,
      });
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to save mapping');
    }
  }

  // ── GET /api/mappings?userId=X ────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getSavedMappings({int? userId}) async {
    try {
      final id = userId ?? ApiService.userId;
      final response = await _dio.get('/api/mappings?userId=$id');
      return (response.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load mappings: ${e.message}');
    }
  }

  // ── DELETE /api/mappings/{id} ─────────────────────────────────────────
  Future<void> deleteMapping(int mappingId) async {
    try {
      await _dio.delete('/api/mappings/$mappingId');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to delete mapping');
    }
  }

  // ── POST /api/mappings/upload ─────────────────────────────────────────
  Future<Map<String, dynamic>> uploadWithMapping({

    required dynamic file,
    required String fileName,
    required String modelCode,
    required String columnMappings,
    int? mappingId,
    void Function(double)? onProgress,
  }) async {
    try {
      final multipartFile = kIsWeb
          ? MultipartFile.fromBytes(file as Uint8List, filename: fileName)
          : await MultipartFile.fromFile(file.path as String, filename: fileName);

      final formData = FormData.fromMap({
        'file': multipartFile,
        'userId': userId.toString(),
        'modelCode': modelCode,
        'columnMappings': columnMappings,
        if (mappingId != null) 'mappingId': mappingId.toString(),
      });

      final response = await _dio.post('/api/mappings/upload', data: formData,
          onSendProgress: (sent, total) {
            if (total != -1 && onProgress != null) onProgress(sent / total);
          });
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422)
        return Map<String, dynamic>.from(e.response!.data);
      throw Exception('Upload failed: ${e.message}');
    }
  }

    // ── POST /api/chat ──────────────────────────────────────────────────
  Future<String> sendChatMessage(String message, {String? currentModelCode}) async {
  
    try {
      final response = await _dio.post('/api/chat', data: {
        'message': message,
        if (currentModelCode != null) 'currentModelCode': currentModelCode,
      });
      return response.data['reply'] as String;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Chat failed');
    }
  }
  // ── POST /api/feedback ────────────────────────────────────────────────
  Future<void> sendFeedback(String message, int userId, String username) async {
    try {
      await _dio.post('/api/feedback', data: {
        'message': message,
        'userId': userId,
        'username': username,
      });
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Échec de l\'envoi');
    }
  }
    // ── GET /api/feedback ─────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getFeedbacks() async {
    try {
      final response = await _dio.get('/api/feedback');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to load feedbacks: ${e.message}');
    }
  }

  // ── PATCH /api/feedback/{id}/read ─────────────────────────────────────
  Future<void> markFeedbackRead(int id) async {
    try {
      await _dio.patch('/api/feedback/$id/read');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message);
    }
  }

  // ── DELETE /api/feedback/{id} ─────────────────────────────────────────
  Future<void> deleteFeedback(int id) async {
    try {
      await _dio.delete('/api/feedback/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? e.message);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
//  AJOUTS À METTRE DANS api_service.dart  —  Section OCR
//  Ajouter ces 2 méthodes à la classe ApiService existante
// ═══════════════════════════════════════════════════════════════════════════

  // ── POST /api/ocr/scan-table ──────────────────────────────────────────────
  // Envoie une image au backend, reçoit headers + rows extraits par OCR
  Future<Map<String, dynamic>> scanImageToTable(Uint8List imageBytes,
      {String fileName = 'scan.jpg'}) async {
    try {
      final multipartFile =
          MultipartFile.fromBytes(imageBytes, filename: fileName);
      final formData = FormData.fromMap({'image': multipartFile});

      final response = await _dio.post('/api/ocr/scan-table', data: formData);
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?['message'] ?? 'Erreur OCR : ${e.message}');
    }
  }

  // ── POST /api/ocr/table-to-excel ─────────────────────────────────────────
  // Envoie headers + rows, reçoit un fichier .xlsx en bytes
  Future<Map<String, dynamic>> tableToExcel({
    required List<String> headers,
    required List<List<String>> rows,
    String? fileName,
  }) async {
    try {
      final response = await _dio.post(
        '/api/ocr/table-to-excel',
        data: {
          'headers': headers,
          'rows': rows,
          if (fileName != null) 'fileName': fileName,
        },
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = Uint8List.fromList(response.data as List<int>);
      final fn = fileName ?? 'scan_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      return {'excelBytes': bytes, 'fileName': fn};
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?['message'] ?? 'Erreur Excel : ${e.message}');
    }
  }

  
  

}

