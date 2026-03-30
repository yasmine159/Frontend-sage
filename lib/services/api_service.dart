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
      int id, String username, String email, String role) async {
    try {
      final response = await _dio.put('/api/users/$id', data: {
        'id': id, 'username': username, 'email': email, 'role': role,
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
}