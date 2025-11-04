import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';

/// Widget affichant le statut de synchronisation
class SyncStatusWidget extends StatelessWidget {
  final bool showDetails;

  const SyncStatusWidget({
    Key? key,
    this.showDetails = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        if (syncProvider.isSyncing) {
          return _buildSyncingIndicator(context);
        }

        if (syncProvider.hasUnsyncedData) {
          return _buildUnsyncedWarning(context, syncProvider);
        }

        return _buildSyncedStatus(context);
      },
    );
  }

  Widget _buildSyncingIndicator(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            const Text(
              'Synchronisation en cours...',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnsyncedWarning(BuildContext context, SyncProvider provider) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.orange.shade700, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${provider.unsyncedCount} donnée(s) non synchronisée(s)',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  if (showDetails)
                    Text(
                      'Synchronisation: ${provider.syncPercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade600,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.sync),
              color: Colors.orange.shade700,
              onPressed: () => provider.syncAll(),
              tooltip: 'Synchroniser maintenant',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncedStatus(BuildContext context) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.cloud_done, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 12),
            Text(
              'Toutes les données sont synchronisées',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton flottant de synchronisation
class SyncFloatingActionButton extends StatelessWidget {
  const SyncFloatingActionButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        return FloatingActionButton(
          onPressed: syncProvider.isSyncing ? null : () => syncProvider.fullSync(),
          tooltip: 'Synchronisation complète',
          child: syncProvider.isSyncing
              ? const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                )
              : Stack(
                  children: [
                    const Icon(Icons.sync),
                    if (syncProvider.hasUnsyncedData)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${syncProvider.unsyncedCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

/// Indicateur de synchronisation dans l'AppBar
class SyncAppBarIndicator extends StatelessWidget {
  const SyncAppBarIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        if (syncProvider.isSyncing) {
          return IconButton(
            icon: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            onPressed: null,
          );
        }

        if (syncProvider.hasUnsyncedData) {
          return Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.cloud_upload),
                onPressed: () => syncProvider.syncAll(),
                tooltip: 'Synchroniser',
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${syncProvider.unsyncedCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return IconButton(
          icon: const Icon(Icons.cloud_done),
          onPressed: () => syncProvider.fullSync(),
          tooltip: 'Rafraîchir',
        );
      },
    );
  }
}

/// Dialog de synchronisation avec détails
class SyncDetailsDialog extends StatelessWidget {
  const SyncDetailsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        final status = syncProvider.lastSyncStatus;
        final result = syncProvider.lastSyncResult;

        return AlertDialog(
          title: const Text('Statut de synchronisation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (status != null) ...[
                _buildStatusRow('État', status.isSyncing ? 'En cours' : 'Inactif'),
                _buildStatusRow('Non synchronisées', '${status.unsyncedCount}'),
                _buildStatusRow('Total', '${status.totalCount}'),
                _buildStatusRow(
                  'Progression',
                  '${status.syncPercentage.toStringAsFixed(1)}%',
                ),
                const SizedBox(height: 16),
              ],
              if (result != null) ...[
                const Text(
                  'Dernier résultat:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildStatusRow('Succès', result.success ? 'Oui' : 'Non'),
                _buildStatusRow('Synchronisées', '${result.syncedCount}'),
                _buildStatusRow('Échouées', '${result.failedCount}'),
                Text(
                  result.message,
                  style: TextStyle(
                    color: result.success ? Colors.green : Colors.red,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Sync auto:'),
                  const SizedBox(width: 8),
                  Switch(
                    value: syncProvider.autoSyncEnabled,
                    onChanged: (value) {
                      if (value) {
                        syncProvider.startAutoSync();
                      } else {
                        syncProvider.stopAutoSync();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
            ElevatedButton.icon(
              onPressed: syncProvider.isSyncing
                  ? null
                  : () {
                      syncProvider.fullSync();
                      Navigator.of(context).pop();
                    },
              icon: const Icon(Icons.sync),
              label: const Text('Synchroniser'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
