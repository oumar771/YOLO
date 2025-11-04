import 'dart:async';
import 'dart:convert';
import '../core/http_client.dart';
import '../core/env.dart';
import '../models/attendance.dart';
import '../repositories/attendance_repository.dart';
import '../services/storage_service.dart';

/// Service de synchronisation entre la base locale et l'API distante
class SyncService {
  final HttpClient _httpClient = HttpClient();
  final AttendanceRepository _attendanceRepo = AttendanceRepository();
  final StorageService _storageService = StorageService();

  bool _isSyncing = false;
  Timer? _syncTimer;

  /// Démarrer la synchronisation automatique périodique
  void startAutoSync({Duration interval = const Duration(minutes: 5)}) {
    stopAutoSync(); // Arrêter l'ancien timer s'il existe

    _syncTimer = Timer.periodic(interval, (timer) async {
      await syncAll();
    });

    print('= Synchronisation automatique démarrée (intervalle: ${interval.inMinutes}min)');
  }

  /// Arrêter la synchronisation automatique
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    print('ø Synchronisation automatique arrêtée');
  }

  /// Synchroniser toutes les données non synchronisées
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      print('  Synchronisation déjà en cours, opération ignorée');
      return SyncResult(
        success: false,
        message: 'Synchronisation déjà en cours',
        syncedCount: 0,
        failedCount: 0,
      );
    }

    _isSyncing = true;

    try {
      // Vérifier si l'utilisateur est connecté
      final token = await _storageService.getToken();
      if (token == null) {
        print('  Aucun token trouvé, synchronisation annulée');
        return SyncResult(
          success: false,
          message: 'Utilisateur non authentifié',
          syncedCount: 0,
          failedCount: 0,
        );
      }

      _httpClient.setToken(token);

      // Récupérer les présences non synchronisées
      final unsyncedAttendances = await _attendanceRepo.getUnsyncedAttendances();

      if (unsyncedAttendances.isEmpty) {
        print(' Aucune donnée à synchroniser');
        return SyncResult(
          success: true,
          message: 'Aucune donnée à synchroniser',
          syncedCount: 0,
          failedCount: 0,
        );
      }

      print('=ä Synchronisation de ${unsyncedAttendances.length} présences...');

      int syncedCount = 0;
      int failedCount = 0;
      List<String> errors = [];

      // Synchroniser chaque présence
      for (var attendance in unsyncedAttendances) {
        try {
          // Essayer de créer la présence sur le serveur
          final response = await _httpClient.post(
            Environment.ATTENDANCES_ENDPOINT,
            {
              'employee_id': attendance.employeeId,
              'employee_name': attendance.employeeName,
              'timestamp': attendance.timestamp.toIso8601String(),
              'confidence': attendance.confidence,
              'photo_url': attendance.photoUrl,
            },
            needsAuth: true,
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            // Succès : marquer comme synchronisé
            final responseData = json.decode(response.body);
            final serverId = responseData['id'] ?? attendance.id;

            // Mettre à jour avec l'ID du serveur
            final updatedAttendance = Attendance(
              id: serverId,
              employeeId: attendance.employeeId,
              employeeName: attendance.employeeName,
              timestamp: attendance.timestamp,
              confidence: attendance.confidence,
              photoUrl: attendance.photoUrl,
              isSynced: true,
            );

            await _attendanceRepo.insertOrUpdate(updatedAttendance);
            syncedCount++;
            print(' Présence synchronisée: ${attendance.employeeId} à ${attendance.timestamp}');
          } else {
            // Échec
            failedCount++;
            final error = 'Erreur ${response.statusCode} pour ${attendance.employeeId}';
            errors.add(error);
            print('L $error');
          }
        } catch (e) {
          failedCount++;
          final error = 'Erreur réseau pour ${attendance.employeeId}: $e';
          errors.add(error);
          print('L $error');
        }

        // Petite pause pour éviter de surcharger l'API
        await Future.delayed(const Duration(milliseconds: 100));
      }

      final result = SyncResult(
        success: failedCount == 0,
        message: failedCount == 0
            ? 'Toutes les données ont été synchronisées'
            : '$syncedCount synchronisées, $failedCount échouées',
        syncedCount: syncedCount,
        failedCount: failedCount,
        errors: errors,
      );

      print('<¯ Synchronisation terminée: ${result.message}');
      return result;
    } catch (e) {
      print('L Erreur lors de la synchronisation: $e');
      return SyncResult(
        success: false,
        message: 'Erreur: $e',
        syncedCount: 0,
        failedCount: 0,
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Synchroniser les données depuis le serveur vers la base locale
  Future<bool> syncFromServer() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        print('  Aucun token trouvé');
        return false;
      }

      _httpClient.setToken(token);

      // Récupérer les présences depuis l'API
      final response = await _httpClient.get(
        Environment.ATTENDANCES_ENDPOINT,
        needsAuth: true,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final attendances = data.map((json) => Attendance.fromJson(json)).toList();

        // Insérer/Mettre à jour dans la base locale
        for (var attendance in attendances) {
          await _attendanceRepo.insertOrUpdate(attendance);
        }

        print('=å ${attendances.length} présences récupérées depuis le serveur');
        return true;
      } else {
        print('L Erreur lors de la récupération: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('L Erreur réseau: $e');
      return false;
    }
  }

  /// Synchronisation bidirectionnelle complète
  Future<SyncResult> fullSync() async {
    print('= Synchronisation complète...');

    // 1. Envoyer les données locales vers le serveur
    final uploadResult = await syncAll();

    // 2. Récupérer les nouvelles données depuis le serveur
    final downloadSuccess = await syncFromServer();

    return SyncResult(
      success: uploadResult.success && downloadSuccess,
      message: uploadResult.success && downloadSuccess
          ? 'Synchronisation complète réussie'
          : 'Synchronisation partielle: ${uploadResult.message}',
      syncedCount: uploadResult.syncedCount,
      failedCount: uploadResult.failedCount,
      errors: uploadResult.errors,
    );
  }

  /// Vérifier le statut de synchronisation
  Future<SyncStatus> getSyncStatus() async {
    final unsyncedCount = (await _attendanceRepo.getUnsyncedAttendances()).length;
    final totalCount = await _attendanceRepo.count();

    return SyncStatus(
      isSyncing: _isSyncing,
      unsyncedCount: unsyncedCount,
      totalCount: totalCount,
      lastSyncTime: DateTime.now(), // À améliorer avec une vraie persistance
    );
  }

  /// Nettoyer et relâcher les ressources
  void dispose() {
    stopAutoSync();
    _httpClient.dispose();
  }
}

/// Résultat d'une opération de synchronisation
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final int failedCount;
  final List<String>? errors;

  SyncResult({
    required this.success,
    required this.message,
    required this.syncedCount,
    required this.failedCount,
    this.errors,
  });

  @override
  String toString() {
    return 'SyncResult(success: $success, message: $message, '
        'synced: $syncedCount, failed: $failedCount)';
  }
}

/// Statut de la synchronisation
class SyncStatus {
  final bool isSyncing;
  final int unsyncedCount;
  final int totalCount;
  final DateTime lastSyncTime;

  SyncStatus({
    required this.isSyncing,
    required this.unsyncedCount,
    required this.totalCount,
    required this.lastSyncTime,
  });

  bool get isFullySynced => unsyncedCount == 0;
  double get syncPercentage =>
      totalCount > 0 ? ((totalCount - unsyncedCount) / totalCount) * 100 : 100.0;

  @override
  String toString() {
    return 'SyncStatus(isSyncing: $isSyncing, unsynced: $unsyncedCount/$totalCount, '
        'percentage: ${syncPercentage.toStringAsFixed(1)}%)';
  }
}
