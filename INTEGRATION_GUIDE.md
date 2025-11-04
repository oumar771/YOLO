# Guide d'Intégration - Connexion Base de Données Flutter

Ce guide explique comment utiliser les nouveaux services de synchronisation et d'upload d'images dans votre application Flutter.

## 📋 Fichiers Ajoutés

### Services
- `sync_service.dart` - Service de synchronisation bidirectionnelle
- `image_upload_service.dart` - Service d'upload d'images

### Providers
- `sync_provider.dart` - Provider pour gérer l'état de synchronisation

### Widgets UI
- `sync_status_widget.dart` - Widgets d'interface pour la synchronisation

### Services Modifiés
- `attendance_service.dart` - Ajout des méthodes POST/PUT/DELETE

---

## 🚀 Installation et Configuration

### 1. Mettre à jour main.dart

Ajoutez le `SyncProvider` dans votre arbre de providers :

```dart
import 'package:provider/provider.dart';
import 'providers/sync_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/attendance_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
        // ... autres providers
      ],
      child: MyApp(),
    ),
  );
}
```

### 2. Initialiser la Synchronisation

Dans votre écran principal (après l'authentification) :

```dart
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    // Initialiser la synchronisation automatique
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final syncProvider = Provider.of<SyncProvider>(context, listen: false);
      syncProvider.initialize(enableAutoSync: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accueil'),
        actions: [
          SyncAppBarIndicator(), // Indicateur dans l'AppBar
        ],
      ),
      body: Column(
        children: [
          SyncStatusWidget(), // Widget de statut
          // ... reste de votre UI
        ],
      ),
      floatingActionButton: SyncFloatingActionButton(), // Bouton de sync
    );
  }
}
```

---

## 💾 Utilisation des Services

### Synchronisation

#### Synchronisation Manuelle

```dart
final syncProvider = Provider.of<SyncProvider>(context, listen: false);

// Synchroniser toutes les données locales vers le serveur
await syncProvider.syncAll();

// Synchronisation complète (bidirectionnelle)
await syncProvider.fullSync();

// Récupérer uniquement depuis le serveur
await syncProvider.syncFromServer();
```

#### Synchronisation Automatique

```dart
final syncProvider = Provider.of<SyncProvider>(context, listen: false);

// Démarrer la synchronisation automatique (toutes les 5 minutes par défaut)
syncProvider.startAutoSync();

// Avec intervalle personnalisé
syncProvider.startAutoSync(interval: Duration(minutes: 10));

// Arrêter la synchronisation automatique
syncProvider.stopAutoSync();
```

#### Vérifier le Statut

```dart
final syncProvider = Provider.of<SyncProvider>(context);

// Vérifier s'il y a des données non synchronisées
if (syncProvider.hasUnsyncedData) {
  print('${syncProvider.unsyncedCount} données non synchronisées');
  print('Progression: ${syncProvider.syncPercentage}%');
}

// Vérifier si une synchronisation est en cours
if (syncProvider.isSyncing) {
  print('Synchronisation en cours...');
}
```

---

### Créer une Présence

#### En ligne (avec sync automatique)

```dart
import 'services/attendance_service.dart';

final attendanceService = AttendanceService();

final attendance = await attendanceService.createAttendance(
  employeeId: 'EMP001',
  employeeName: 'Jean Dupont',
  timestamp: DateTime.now(),
  confidence: 0.95,
  photoUrl: 'https://example.com/photo.jpg',
);

if (attendance != null) {
  print('✅ Présence créée: ${attendance.id}');
} else {
  print('❌ Erreur lors de la création');
}
```

#### Hors ligne (sera synchronisée automatiquement)

```dart
final attendance = await attendanceService.createOfflineAttendance(
  employeeId: 'EMP001',
  employeeName: 'Jean Dupont',
  timestamp: DateTime.now(),
  confidence: 0.95,
);

print('💾 Présence sauvegardée en mode hors ligne');
// La synchronisation automatique l'enverra au serveur plus tard
```

---

### Upload d'Images

#### Upload Simple

```dart
import 'services/image_upload_service.dart';

final imageUploadService = ImageUploadService();

// Upload une image générique
final imageUrl = await imageUploadService.uploadImage(
  imagePath: '/path/to/image.jpg',
  endpoint: '/api/upload',
);

if (imageUrl != null) {
  print('✅ Image uploadée: $imageUrl');
}
```

#### Upload de Photo de Présence

```dart
// Upload une photo pour une présence
final photoUrl = await imageUploadService.uploadAttendancePhoto(
  imagePath: '/path/to/photo.jpg',
  employeeId: 'EMP001',
);

// Créer la présence avec la photo
if (photoUrl != null) {
  await attendanceService.createAttendance(
    employeeId: 'EMP001',
    employeeName: 'Jean Dupont',
    timestamp: DateTime.now(),
    confidence: 0.95,
    photoUrl: photoUrl,
  );
}
```

#### Upload de Visage Inconnu

```dart
final photoUrl = await imageUploadService.uploadUnknownFacePhoto(
  imagePath: '/path/to/unknown_face.jpg',
);
```

#### Upload Multiple

```dart
final urls = await imageUploadService.uploadMultipleImages(
  imagePaths: [
    '/path/to/image1.jpg',
    '/path/to/image2.jpg',
    '/path/to/image3.jpg',
  ],
);

print('${urls.length} images uploadées');
```

---

## 🎨 Widgets UI Disponibles

### SyncStatusWidget

Affiche le statut de synchronisation avec une carte colorée :

```dart
SyncStatusWidget(showDetails: true)
```

### SyncAppBarIndicator

Indicateur compact pour l'AppBar :

```dart
AppBar(
  title: Text('Mon App'),
  actions: [
    SyncAppBarIndicator(),
  ],
)
```

### SyncFloatingActionButton

Bouton flottant avec badge de notification :

```dart
Scaffold(
  floatingActionButton: SyncFloatingActionButton(),
)
```

### SyncDetailsDialog

Dialog détaillé avec contrôles :

```dart
showDialog(
  context: context,
  builder: (_) => SyncDetailsDialog(),
);
```

---

## 📱 Exemple Complet d'Utilisation

### Scénario : Enregistrer une présence avec photo

```dart
import 'package:provider/provider.dart';

class AttendanceCreationScreen extends StatefulWidget {
  @override
  _AttendanceCreationScreenState createState() => _AttendanceCreationScreenState();
}

class _AttendanceCreationScreenState extends State<AttendanceCreationScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final ImageUploadService _imageUploadService = ImageUploadService();

  bool _isLoading = false;
  String? _photoPath;

  Future<void> _createAttendance() async {
    setState(() => _isLoading = true);

    try {
      // 1. Upload la photo si disponible
      String? photoUrl;
      if (_photoPath != null) {
        photoUrl = await _imageUploadService.uploadAttendancePhoto(
          imagePath: _photoPath!,
          employeeId: 'EMP001',
        );
      }

      // 2. Créer la présence
      final attendance = await _attendanceService.createAttendance(
        employeeId: 'EMP001',
        employeeName: 'Jean Dupont',
        timestamp: DateTime.now(),
        confidence: 0.95,
        photoUrl: photoUrl,
      );

      if (attendance != null) {
        // 3. Déclencher une synchronisation
        final syncProvider = Provider.of<SyncProvider>(context, listen: false);
        await syncProvider.syncAll();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Présence enregistrée avec succès')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nouvelle Présence'),
        actions: [SyncAppBarIndicator()],
      ),
      body: Column(
        children: [
          SyncStatusWidget(),
          // ... formulaire de création
          ElevatedButton(
            onPressed: _isLoading ? null : _createAttendance,
            child: _isLoading
                ? CircularProgressIndicator()
                : Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
```

---

## ⚙️ Configuration de l'API

Assurez-vous que votre API expose les endpoints suivants :

### Endpoints Requis

```
POST   /api/attendances           - Créer une présence
GET    /api/attendances           - Récupérer les présences
PUT    /api/attendances/:id       - Modifier une présence
DELETE /api/attendances/:id       - Supprimer une présence
POST   /api/upload                - Upload générique d'image
POST   /api/attendances/upload    - Upload photo de présence
POST   /api/unknown-faces/upload  - Upload visage inconnu
```

### Format de Réponse Attendu

#### Création de Présence
```json
{
  "id": 123,
  "employee_id": "EMP001",
  "employee_name": "Jean Dupont",
  "timestamp": "2025-01-15T08:30:00Z",
  "confidence": 0.95,
  "photo_url": "https://example.com/photo.jpg"
}
```

#### Upload d'Image
```json
{
  "url": "https://example.com/uploads/image123.jpg",
  "file_url": "https://example.com/uploads/image123.jpg",
  "path": "/uploads/image123.jpg"
}
```

---

## 🔧 Dépannage

### La synchronisation ne fonctionne pas

1. Vérifiez que l'utilisateur est authentifié :
```dart
final token = await StorageService().getToken();
print('Token: $token');
```

2. Vérifiez la connexion réseau
3. Vérifiez les logs dans la console

### Les images ne s'uploadent pas

1. Vérifiez que le fichier existe :
```dart
final file = File(imagePath);
print('Existe: ${await file.exists()}');
```

2. Vérifiez la taille du fichier (< 10MB généralement)
3. Vérifiez les permissions de l'API

### Données non synchronisées

```dart
// Vérifier les données non synchronisées
final repo = AttendanceRepository();
final unsynced = await repo.getUnsyncedAttendances();
print('${unsynced.length} données non synchronisées');

// Forcer la synchronisation
final syncProvider = Provider.of<SyncProvider>(context, listen: false);
await syncProvider.syncAll();
```

---

## 📦 Packages Recommandés

Pour améliorer l'expérience utilisateur, ajoutez ces packages dans `pubspec.yaml` :

```yaml
dependencies:
  # Pour capturer des photos
  image_picker: ^1.0.7
  camera: ^0.10.5+9

  # Pour la compression d'images
  image: ^4.1.7
  flutter_image_compress: ^2.1.0

  # Pour les notifications
  flutter_local_notifications: ^16.3.2

  # Pour la connectivité réseau
  connectivity_plus: ^5.0.2
```

---

## ✅ Checklist d'Intégration

- [ ] Ajouter `SyncProvider` dans `main.dart`
- [ ] Initialiser la synchronisation dans l'écran principal
- [ ] Ajouter les widgets de statut de synchronisation
- [ ] Tester la création de présences en ligne
- [ ] Tester la création de présences hors ligne
- [ ] Tester l'upload d'images
- [ ] Tester la synchronisation automatique
- [ ] Configurer les endpoints de l'API
- [ ] Ajouter les packages recommandés
- [ ] Tester en conditions réelles (réseau instable)

---

## 📞 Support

Pour toute question ou problème, consultez les logs dans la console :
- ✅ = Succès
- ❌ = Erreur
- 📤 = Upload
- 📥 = Download
- 💾 = Sauvegarde locale
- 🔄 = Synchronisation

Les services utilisent des emoji pour faciliter le débogage !
