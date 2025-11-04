import 'package:flutter_test/flutter_test.dart';
import 'package:dev_mobile/services/sync_service.dart';
import 'package:dev_mobile/services/attendance_service.dart';
import 'package:dev_mobile/services/image_upload_service.dart';

void main() {
  group('Services Tests', () {
    test('SyncService - Création d\'instance', () {
      final syncService = SyncService();
      expect(syncService, isNotNull);
    });

    test('AttendanceService - Création d\'instance', () {
      final attendanceService = AttendanceService();
      expect(attendanceService, isNotNull);
    });

    test('ImageUploadService - Création d\'instance', () {
      final imageUploadService = ImageUploadService();
      expect(imageUploadService, isNotNull);
    });

    test('SyncResult - Création avec succès', () {
      final result = SyncResult(
        success: true,
        message: 'Test réussi',
        syncedCount: 5,
        failedCount: 0,
      );

      expect(result.success, isTrue);
      expect(result.syncedCount, equals(5));
      expect(result.failedCount, equals(0));
    });

    test('SyncStatus - Calcul du pourcentage', () {
      final status = SyncStatus(
        isSyncing: false,
        unsyncedCount: 2,
        totalCount: 10,
        lastSyncTime: DateTime.now(),
      );

      expect(status.syncPercentage, equals(80.0));
      expect(status.isFullySynced, isFalse);
    });

    test('SyncStatus - Tous synchronisés', () {
      final status = SyncStatus(
        isSyncing: false,
        unsyncedCount: 0,
        totalCount: 10,
        lastSyncTime: DateTime.now(),
      );

      expect(status.isFullySynced, isTrue);
      expect(status.syncPercentage, equals(100.0));
    });
  });

  group('Integration Tests - NOTE', () {
    test('Les tests d\'intégration nécessitent une API en cours d\'exécution', () {
      // Pour exécuter les tests d'intégration :
      // 1. Démarrez votre API backend
      // 2. Assurez-vous que l'URL dans env.dart est correcte
      // 3. Créez un utilisateur de test
      // 4. Décommentez les tests ci-dessous

      expect(true, isTrue); // Placeholder
    });

    /* DÉCOMMENTEZ POUR LES TESTS D'INTÉGRATION

    test('AttendanceService - Créer une présence', () async {
      final attendanceService = AttendanceService();

      final attendance = await attendanceService.createAttendance(
        employeeId: 'TEST001',
        employeeName: 'Test User',
        timestamp: DateTime.now(),
        confidence: 0.95,
      );

      expect(attendance, isNotNull);
      expect(attendance?.employeeId, equals('TEST001'));
    });

    test('SyncService - Synchronisation complète', () async {
      final syncService = SyncService();

      final result = await syncService.syncAll();

      expect(result, isNotNull);
      expect(result.success, isTrue);
    });

    */
  });
}
