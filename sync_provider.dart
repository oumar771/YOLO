import 'package:flutter/foundation.dart';
import '../services/sync_service.dart';

/// Provider pour gérer l'état de la synchronisation dans l'application
class SyncProvider with ChangeNotifier {
  final SyncService _syncService = SyncService();

  bool _isSyncing = false;
  bool _autoSyncEnabled = false;
  SyncStatus? _lastSyncStatus;
  SyncResult? _lastSyncResult;
  String? _errorMessage;

  // Getters
  bool get isSyncing => _isSyncing;
  bool get autoSyncEnabled => _autoSyncEnabled;
  SyncStatus? get lastSyncStatus => _lastSyncStatus;
  SyncResult? get lastSyncResult => _lastSyncResult;
  String? get errorMessage => _errorMessage;

  bool get hasUnsyncedData =>
      _lastSyncStatus != null && _lastSyncStatus!.unsyncedCount > 0;

  int get unsyncedCount => _lastSyncStatus?.unsyncedCount ?? 0;

  double get syncPercentage => _lastSyncStatus?.syncPercentage ?? 100.0;

  /// Initialiser le provider (à appeler au démarrage de l'app)
  Future<void> initialize({bool enableAutoSync = true}) async {
    try {
      await refreshSyncStatus();

      if (enableAutoSync) {
        startAutoSync();
      }
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'initialisation: $e';
      notifyListeners();
    }
  }

  /// Démarrer la synchronisation automatique
  void startAutoSync({Duration interval = const Duration(minutes: 5)}) {
    _syncService.startAutoSync(interval: interval);
    _autoSyncEnabled = true;
    notifyListeners();
  }

  /// Arrêter la synchronisation automatique
  void stopAutoSync() {
    _syncService.stopAutoSync();
    _autoSyncEnabled = false;
    notifyListeners();
  }

  /// Synchroniser toutes les données
  Future<void> syncAll() async {
    if (_isSyncing) {
      print('⚠️ Synchronisation déjà en cours');
      return;
    }

    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _syncService.syncAll();
      _lastSyncResult = result;

      if (!result.success) {
        _errorMessage = result.message;
      }

      // Rafraîchir le statut après la synchronisation
      await refreshSyncStatus();
    } catch (e) {
      _errorMessage = 'Erreur de synchronisation: $e';
      print('❌ Erreur: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Synchronisation complète (bidirectionnelle)
  Future<void> fullSync() async {
    if (_isSyncing) {
      print('⚠️ Synchronisation déjà en cours');
      return;
    }

    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _syncService.fullSync();
      _lastSyncResult = result;

      if (!result.success) {
        _errorMessage = result.message;
      }

      await refreshSyncStatus();
    } catch (e) {
      _errorMessage = 'Erreur de synchronisation complète: $e';
      print('❌ Erreur: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Synchroniser depuis le serveur uniquement
  Future<void> syncFromServer() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _syncService.syncFromServer();

      if (!success) {
        _errorMessage = 'Échec de la synchronisation depuis le serveur';
      }

      await refreshSyncStatus();
    } catch (e) {
      _errorMessage = 'Erreur: $e';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Rafraîchir le statut de synchronisation
  Future<void> refreshSyncStatus() async {
    try {
      _lastSyncStatus = await _syncService.getSyncStatus();
      notifyListeners();
    } catch (e) {
      print('❌ Erreur lors de la récupération du statut: $e');
    }
  }

  /// Effacer les erreurs
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }
}
