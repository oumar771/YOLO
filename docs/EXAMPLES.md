# 📚 Exemples d'utilisation du système YOLO

Ce document présente des exemples concrets d'utilisation du système de reconnaissance faciale.

---

## 🎯 Scénarios d'utilisation

### 1. Enregistrement de la présence d'un employé

#### Via l'application mobile

```dart
// Dans votre application Flutter
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

Future<void> recordAttendance() async {
  // Prendre une photo
  final ImagePicker picker = ImagePicker();
  final XFile? photo = await picker.pickImage(
    source: ImageSource.camera,
    preferredCameraDevice: CameraDevice.front
  );

  if (photo == null) return;

  // Envoyer au serveur
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('$BASE_URL/api/recognize')
  );

  request.files.add(
    await http.MultipartFile.fromPath('file', photo.path)
  );

  var response = await request.send();
  var responseData = await response.stream.bytesToString();

  // Traiter la réponse
  var result = json.decode(responseData);

  if (result['recognized']) {
    // Employé reconnu
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bienvenue ${result['employee']['name']}!'),
        content: Text('Présence enregistrée à ${result['check_in']}'),
      ),
    );
  } else {
    // Personne inconnue
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Accès refusé'),
        content: Text('Personne non reconnue. RH contactés.'),
      ),
    );
  }
}
```

#### Via cURL

```bash
# Prendre une photo avec la webcam (Linux)
fswebcam -r 1280x720 --no-banner face.jpg

# Envoyer pour reconnaissance
curl -X POST "http://localhost:8000/api/recognize" \
  -F "file=@face.jpg" \
  | jq .

# Réponse attendue:
# {
#   "success": true,
#   "recognized": true,
#   "employee": {
#     "id": "EMP001",
#     "name": "Jean Dupont",
#     "department": "IT",
#     "position": "Développeur"
#   },
#   "confidence": 0.95,
#   "attendance_id": 123,
#   "check_in": "2024-01-15T08:30:00"
# }
```

#### Via Python

```python
import requests
from datetime import datetime

def record_attendance(image_path):
    """Enregistrer la présence via l'API."""
    url = "http://localhost:8000/api/recognize"

    with open(image_path, 'rb') as f:
        files = {'file': f}
        response = requests.post(url, files=files)

    result = response.json()

    if result['recognized']:
        employee = result['employee']
        print(f"✅ Présence enregistrée:")
        print(f"   Nom: {employee['name']}")
        print(f"   Département: {employee['department']}")
        print(f"   Heure: {result['check_in']}")
        print(f"   Confiance: {result['confidence']:.2%}")
    else:
        print("❌ Personne non reconnue")
        print("   Les RH ont été notifiés")

    return result

# Utilisation
result = record_attendance("employee_photo.jpg")
```

---

### 2. Détection de sécurité (armes, animaux)

#### Surveillance en temps réel

```python
import cv2
import requests
import time

def security_monitoring(camera_id=0):
    """
    Surveillance de sécurité en temps réel.

    Args:
        camera_id: ID de la caméra (0 pour webcam)
    """
    cap = cv2.VideoCapture(camera_id)
    last_alert = 0

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        # Vérifier toutes les 5 secondes
        current_time = time.time()
        if current_time - last_alert > 5:
            # Sauvegarder la frame
            cv2.imwrite('temp_frame.jpg', frame)

            # Envoyer pour détection
            with open('temp_frame.jpg', 'rb') as f:
                files = {'file': f}
                response = requests.post(
                    'http://localhost:8000/api/detect',
                    files=files,
                    data={'detection_type': 'all'}
                )

            result = response.json()
            detections = result['detections']

            # Vérifier les alertes
            if detections['weapons']:
                print("🚨 ALERTE CRITIQUE: ARME DÉTECTÉE!")
                for weapon in detections['weapons']:
                    print(f"   Type: {weapon['class']}")
                    print(f"   Sévérité: {weapon['severity']}")
                # Déclencher l'alarme, notifier la sécurité, etc.

            if detections['animals']:
                print("⚠️  Alerte: Animal détecté")
                for animal in detections['animals']:
                    print(f"   Type: {animal['class']}")

            last_alert = current_time

        # Afficher la vidéo
        cv2.imshow('Security Monitoring', frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()

# Lancer la surveillance
security_monitoring()
```

---

### 3. Analyse de vidéo enregistrée

```bash
# Analyser une vidéo
python backend/scripts/test_video.py surveillance.mp4

# Avec sortie personnalisée
python backend/scripts/test_video.py surveillance.mp4 \
  --output analyzed_surveillance.mp4

# Sans prévisualisation (plus rapide)
python backend/scripts/test_video.py surveillance.mp4 \
  --no-preview

# Résultat:
# - analyzed_surveillance.mp4 (vidéo annotée)
# - analyzed_surveillance_detections.json (données structurées)
```

Le fichier JSON contient :

```json
{
  "video_info": {
    "source": "surveillance.mp4",
    "duration": 120.5,
    "fps": 30,
    "total_frames": 3615
  },
  "statistics": {
    "total_face_detections": 45,
    "unique_employees": 3,
    "employees_list": ["Jean Dupont", "Marie Martin", "Pierre Durand"],
    "weapons_detected": 1,
    "animals_detected": 0
  },
  "detections": {
    "faces": [
      {
        "frame": 150,
        "timestamp": 5.0,
        "name": "Jean Dupont",
        "confidence": 0.95
      }
    ],
    "weapons": [
      {
        "frame": 890,
        "timestamp": 29.67,
        "class": "knife",
        "confidence": 0.87,
        "severity": "high"
      }
    ]
  }
}
```

---

### 4. Gestion des employés

#### Ajouter un nouvel employé

```bash
# Avec photos
python backend/scripts/add_employee.py \
  --id "EMP001" \
  --name "Jean Dupont" \
  --email "jean.dupont@entreprise.com" \
  --department "IT" \
  --position "Développeur Senior" \
  --phone "+33612345678" \
  --images photo1.jpg photo2.jpg photo3.jpg photo4.jpg photo5.jpg

# Résultat:
# ✅ Employé créé: Jean Dupont (ID: EMP001)
#   ✓ Image ajoutée: photo1.jpg (qualité: 0.87)
#   ✓ Image ajoutée: photo2.jpg (qualité: 0.92)
#   ✓ Image ajoutée: photo3.jpg (qualité: 0.89)
#   ✓ Image ajoutée: photo4.jpg (qualité: 0.85)
#   ✓ Image ajoutée: photo5.jpg (qualité: 0.91)
# ✅ 5 images traitées
```

#### Via l'API REST

```python
import requests

# 1. Créer l'employé
employee_data = {
    'employee_id': 'EMP002',
    'name': 'Marie Martin',
    'email': 'marie.martin@entreprise.com',
    'department': 'RH',
    'position': 'Responsable RH'
}

response = requests.post(
    'http://localhost:8000/api/employees',
    data=employee_data
)

print(response.json())

# 2. Ajouter des photos
for i, photo_path in enumerate(['photo1.jpg', 'photo2.jpg', 'photo3.jpg']):
    with open(photo_path, 'rb') as f:
        files = {'file': f}
        response = requests.post(
            f'http://localhost:8000/api/employees/EMP002/add-face',
            files=files
        )
        result = response.json()
        print(f"Photo {i+1}: Qualité = {result['quality_score']:.2f}")
```

---

### 5. Rapports et statistiques

#### Rapport de présence quotidien

```python
import requests
from datetime import datetime, timedelta

def daily_attendance_report(date=None):
    """Générer un rapport de présence pour une date."""
    if date is None:
        date = datetime.now().date()

    start = datetime.combine(date, datetime.min.time())
    end = datetime.combine(date, datetime.max.time())

    # Récupérer les présences
    response = requests.get(
        'http://localhost:8000/api/attendances',
        params={
            'start_date': start.isoformat(),
            'end_date': end.isoformat()
        }
    )

    attendances = response.json()['attendances']

    # Analyser
    print(f"\n📊 Rapport de présence - {date}")
    print("=" * 50)
    print(f"Total présences: {len(attendances)}")

    employees = {}
    for att in attendances:
        emp_name = att['employee_name']
        if emp_name not in employees:
            employees[emp_name] = []
        employees[emp_name].append(att)

    print(f"Employés présents: {len(employees)}")
    print("\nDétails:")

    for name, atts in sorted(employees.items()):
        first_checkin = min(atts, key=lambda x: x['check_in'])
        time = datetime.fromisoformat(first_checkin['check_in']).strftime('%H:%M')
        print(f"  • {name}: arrivé à {time}")

# Utilisation
daily_attendance_report()
```

#### Rapport de sécurité

```python
def security_report(days=7):
    """Rapport de sécurité sur les N derniers jours."""
    # Visages inconnus
    unknown_response = requests.get('http://localhost:8000/api/unknown-faces')
    unknown_faces = unknown_response.json()['unknown_faces']

    # Événements de sécurité
    events_response = requests.get('http://localhost:8000/api/detection-events')
    events = events_response.json()['events']

    print(f"\n🔒 Rapport de sécurité - {days} derniers jours")
    print("=" * 50)

    # Personnes inconnues
    print(f"\n👤 Personnes inconnues: {len(unknown_faces)}")
    for face in unknown_faces[:5]:
        date = datetime.fromisoformat(face['detected_at']).strftime('%Y-%m-%d %H:%M')
        notified = "✅" if face['is_notified'] else "❌"
        print(f"  • {date} - RH notifié: {notified}")

    # Armes détectées
    weapons = [e for e in events if e['detection_type'] == 'weapon']
    print(f"\n⚠️  Armes détectées: {len(weapons)}")
    for weapon in weapons:
        date = datetime.fromisoformat(weapon['detected_at']).strftime('%Y-%m-%d %H:%M')
        print(f"  • {date} - {weapon['class_name']} (sévérité: {weapon['severity']})")

    # Animaux
    animals = [e for e in events if e['detection_type'] == 'animal']
    print(f"\n🐾 Animaux détectés: {len(animals)}")

# Utilisation
security_report(days=7)
```

---

### 6. Auto-apprentissage du modèle

```python
from utils.auto_training import get_auto_trainer
from app.database import SessionLocal

def train_new_model():
    """Entraîner un nouveau modèle avec les données actuelles."""
    trainer = get_auto_trainer()

    # Préparer le dataset
    dataset_path = trainer.prepare_dataset(
        dataset_name="employee_faces_v2",
        class_names=["face"]
    )

    print(f"Dataset préparé: {dataset_path}")

    # Vérifier si assez de données
    if not trainer.check_training_criteria(dataset_path):
        print("Pas assez de données pour l'entraînement")
        return

    # Lancer l'entraînement
    db = SessionLocal()
    try:
        results = trainer.train_model(
            dataset_path=dataset_path,
            model_type="face_detection",
            epochs=100,
            batch_size=16,
            db_session=db
        )

        print("\n✅ Entraînement terminé!")
        print(f"mAP50: {results['metrics']['map50']:.4f}")
        print(f"Précision: {results['metrics']['precision']:.4f}")
        print(f"Rappel: {results['metrics']['recall']:.4f}")
        print(f"Modèle sauvegardé: {results['model_path']}")

    finally:
        db.close()

# Utilisation
train_new_model()
```

---

### 7. Mode hors connexion avec synchronisation

```python
import time
import schedule

def sync_offline_data():
    """Synchroniser les données hors connexion avec le cloud."""
    from utils.cloud_storage import get_local_manager, get_azure_manager

    local_mgr = get_local_manager()
    azure_mgr = get_azure_manager()

    if not azure_mgr.enabled:
        print("Azure non configuré, synchronisation ignorée")
        return

    # Récupérer la queue de synchronisation
    queue = local_mgr.get_sync_queue()

    print(f"📤 Synchronisation: {len(queue)} éléments en attente")

    for item in queue:
        try:
            if 'attendance' in item.get('_queue_file', ''):
                success = await azure_mgr.sync_attendance_record(item)
            elif 'unknown_face' in item.get('_queue_file', ''):
                success = await azure_mgr.sync_unknown_face(
                    item,
                    item.get('image_path')
                )
            elif 'detection' in item.get('_queue_file', ''):
                success = await azure_mgr.sync_detection_event(item)

            if success:
                local_mgr.remove_from_queue(item['_queue_file'])
                print(f"  ✓ Synchronisé: {item['_queue_file']}")
            else:
                print(f"  ✗ Échec: {item['_queue_file']}")

        except Exception as e:
            print(f"  ✗ Erreur: {e}")

# Synchroniser toutes les 5 minutes
schedule.every(5).minutes.do(sync_offline_data)

# Boucle principale
while True:
    schedule.run_pending()
    time.sleep(60)
```

---

## 🎯 Cas d'usage avancés

### Intégration avec système d'alarme

```python
def trigger_alarm_if_weapon_detected():
    """Déclencher une alarme en cas de détection d'arme."""
    import gpio  # Pour Raspberry Pi

    def check_and_alert():
        response = requests.get('http://localhost:8000/api/detection-events')
        events = response.json()['events']

        # Chercher les armes dans les dernières minutes
        recent_weapons = [
            e for e in events
            if e['detection_type'] == 'weapon'
            and (datetime.now() - datetime.fromisoformat(e['detected_at'])).seconds < 300
        ]

        if recent_weapons:
            # Activer l'alarme
            gpio.output(ALARM_PIN, gpio.HIGH)
            print("🚨 ALARME DÉCLENCHÉE!")

    schedule.every(10).seconds.do(check_and_alert)
```

### Rapport hebdomadaire automatique aux RH

```python
def send_weekly_hr_report():
    """Envoyer un rapport hebdomadaire aux RH."""
    from utils.notifications import get_notification_manager

    # Récupérer les données de la semaine
    end_date = datetime.now()
    start_date = end_date - timedelta(days=7)

    # ... collecter les statistiques ...

    summary = {
        'present': 45,
        'absent': 5,
        'late': 8,
        'unknown_faces': 3,
        'security_alerts': 1
    }

    # Envoyer le rapport
    notif_mgr = get_notification_manager()
    await notif_mgr.notify_attendance_summary(end_date, summary)

# Programmer pour le lundi matin
schedule.every().monday.at("08:00").do(send_weekly_hr_report)
```

---

## 📝 Notes importantes

- Toujours tester sur des images de bonne qualité
- Minimum 3-5 photos par employé pour une bonne reconnaissance
- Entraîner régulièrement le modèle avec de nouvelles données
- Monitorer les performances et ajuster les seuils de confiance
- Respecter les réglementations RGPD pour les données biométriques

---

Pour plus d'exemples, consultez le dossier `examples/` du projet.
