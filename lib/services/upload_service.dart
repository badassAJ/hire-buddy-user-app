import 'dart:io';
import 'package:dio/dio.dart';
import 'api_service.dart';

class UploadService {
  final ApiService _api = ApiService();

  // Upload single image
  Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await _api.post('/api/v1/upload/image', data: formData);

      return {
        'success': true,
        'url': response.data['data']['url'],
        'key': response.data['data']['key'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Failed to upload image',
      };
    }
  }

  // Upload multiple images
  Future<Map<String, dynamic>> uploadMultipleImages(
    List<File> imageFiles,
  ) async {
    try {
      final formData = FormData();

      for (var file in imageFiles) {
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(
              file.path,
              filename: file.path.split('/').last,
            ),
          ),
        );
      }

      final response = await _api.post('/api/v1/upload/images', data: formData);

      final List<dynamic> data = response.data['data'];
      final urls = data.map((item) => item['url'] as String).toList();
      final keys = data.map((item) => item['key'] as String).toList();

      return {'success': true, 'urls': urls, 'keys': keys};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Failed to upload images',
      };
    }
  }

  // Upload profile image
  Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'profile': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await _api.post(
        '/api/v1/upload/profile',
        data: formData,
      );

      return {
        'success': true,
        'url': response.data['data']['url'],
        'key': response.data['data']['key'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Failed to upload profile image',
      };
    }
  }

  // Upload document
  Future<Map<String, dynamic>> uploadDocument(File documentFile) async {
    try {
      final formData = FormData.fromMap({
        'document': await MultipartFile.fromFile(
          documentFile.path,
          filename: documentFile.path.split('/').last,
        ),
      });

      final response = await _api.post(
        '/api/v1/upload/document',
        data: formData,
      );

      return {
        'success': true,
        'url': response.data['data']['url'],
        'key': response.data['data']['key'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Failed to upload document',
      };
    }
  }

  // Delete file
  Future<Map<String, dynamic>> deleteFile(String key) async {
    try {
      final response = await _api.delete(
        '/api/v1/upload/file',
        data: {'key': key},
      );

      return {'success': true, 'message': response.data['message']};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Failed to delete file',
      };
    }
  }
}
