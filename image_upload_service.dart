import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/env.dart';
import '../services/storage_service.dart';

/// Service pour l'upload d'images vers l'API
class ImageUploadService {
  final StorageService _storageService = StorageService();

  /// Upload une image vers le serveur
  ///
  /// [imagePath] : Chemin local de l'image
  /// [endpoint] : Endpoint de l'API (par défaut: /api/upload)
  /// [fieldName] : Nom du champ dans le formulaire (par défaut: 'image')
  ///
  /// Retourne l'URL de l'image uploadée ou null en cas d'erreur
  Future<String?> uploadImage({
    required String imagePath,
    String endpoint = '/api/upload',
    String fieldName = 'image',
    Map<String, String>? additionalFields,
  }) async {
    try {
      // Vérifier que le fichier existe
      final file = File(imagePath);
      if (!await file.exists()) {
        print('❌ Fichier introuvable: $imagePath');
        return null;
      }

      // Obtenir le token d'authentification
      final token = await _storageService.getToken();
      if (token == null) {
        print('❌ Token non trouvé, authentification requise');
        return null;
      }

      // Créer la requête multipart
      final uri = Uri.parse('${Environment.BASE_URL}$endpoint');
      final request = http.MultipartRequest('POST', uri);

      // Ajouter les headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Ajouter l'image
      final stream = http.ByteStream(file.openRead());
      final length = await file.length();
      final multipartFile = http.MultipartFile(
        fieldName,
        stream,
        length,
        filename: file.path.split('/').last,
      );
      request.files.add(multipartFile);

      // Ajouter des champs supplémentaires si nécessaires
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      print('📤 Upload en cours: ${file.path.split('/').last} (${_formatBytes(length)})');

      // Envoyer la requête
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final imageUrl = data['url'] ?? data['file_url'] ?? data['path'];

        if (imageUrl != null) {
          print('✅ Image uploadée avec succès: $imageUrl');
          return imageUrl;
        } else {
          print('⚠️ Réponse sans URL: ${response.body}');
          return null;
        }
      } else {
        print('❌ Erreur upload: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Erreur lors de l\'upload: $e');
      return null;
    }
  }

  /// Upload une image pour une présence
  Future<String?> uploadAttendancePhoto({
    required String imagePath,
    required String employeeId,
  }) async {
    return await uploadImage(
      imagePath: imagePath,
      endpoint: '/api/attendances/upload',
      fieldName: 'photo',
      additionalFields: {
        'employee_id': employeeId,
        'type': 'attendance',
      },
    );
  }

  /// Upload une image pour un visage inconnu
  Future<String?> uploadUnknownFacePhoto({
    required String imagePath,
  }) async {
    return await uploadImage(
      imagePath: imagePath,
      endpoint: '/api/unknown-faces/upload',
      fieldName: 'photo',
      additionalFields: {
        'type': 'unknown_face',
      },
    );
  }

  /// Upload une photo de profil utilisateur
  Future<String?> uploadProfilePhoto({
    required String imagePath,
    required String userId,
  }) async {
    return await uploadImage(
      imagePath: imagePath,
      endpoint: '/api/users/$userId/photo',
      fieldName: 'photo',
      additionalFields: {
        'type': 'profile',
      },
    );
  }

  /// Upload multiple images en batch
  Future<List<String>> uploadMultipleImages({
    required List<String> imagePaths,
    String endpoint = '/api/upload/batch',
    String fieldName = 'images',
  }) async {
    final uploadedUrls = <String>[];

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        print('❌ Token non trouvé');
        return uploadedUrls;
      }

      final uri = Uri.parse('${Environment.BASE_URL}$endpoint');
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Ajouter toutes les images
      for (var imagePath in imagePaths) {
        final file = File(imagePath);
        if (await file.exists()) {
          final stream = http.ByteStream(file.openRead());
          final length = await file.length();
          final multipartFile = http.MultipartFile(
            '$fieldName[]', // Notation array
            stream,
            length,
            filename: file.path.split('/').last,
          );
          request.files.add(multipartFile);
        }
      }

      print('📤 Upload de ${request.files.length} images...');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // L'API peut retourner les URLs de différentes manières
        if (data['urls'] != null) {
          uploadedUrls.addAll(List<String>.from(data['urls']));
        } else if (data['files'] != null) {
          for (var file in data['files']) {
            if (file['url'] != null) {
              uploadedUrls.add(file['url']);
            }
          }
        }

        print('✅ ${uploadedUrls.length} images uploadées avec succès');
      } else {
        print('❌ Erreur batch upload: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur lors du batch upload: $e');
    }

    return uploadedUrls;
  }

  /// Formater la taille en bytes en format lisible
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Télécharger une image depuis une URL
  Future<File?> downloadImage({
    required String imageUrl,
    required String savePath,
  }) async {
    try {
      final token = await _storageService.getToken();

      final headers = <String, String>{};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      print('📥 Téléchargement de l\'image...');

      final response = await http.get(
        Uri.parse(imageUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        print('✅ Image téléchargée: $savePath');
        return file;
      } else {
        print('❌ Erreur téléchargement: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Erreur lors du téléchargement: $e');
      return null;
    }
  }

  /// Vérifier si une image existe sur le serveur
  Future<bool> checkImageExists(String imageUrl) async {
    try {
      final response = await http.head(Uri.parse(imageUrl));
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Erreur vérification image: $e');
      return false;
    }
  }
}

/// Résultat d'un upload d'image
class ImageUploadResult {
  final bool success;
  final String? url;
  final String? errorMessage;
  final int? fileSize;

  ImageUploadResult({
    required this.success,
    this.url,
    this.errorMessage,
    this.fileSize,
  });

  @override
  String toString() {
    return 'ImageUploadResult(success: $success, url: $url, error: $errorMessage)';
  }
}
