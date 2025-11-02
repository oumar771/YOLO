"""Script pour tester la détection sur une vidéo."""

import argparse
import cv2
import sys
from pathlib import Path
import json
from datetime import datetime

# Ajouter le dossier parent au path
sys.path.append(str(Path(__file__).parent.parent))

from utils.yolo_detector import get_detector
from utils.face_recognition import get_face_engine
from app.database import SessionLocal, Employee


def process_video_with_detection(
    video_path: str,
    output_path: str = None,
    show_preview: bool = True,
    save_detections: bool = True
):
    """
    Traiter une vidéo avec détection YOLO.

    Args:
        video_path: Chemin vers la vidéo
        output_path: Chemin de sortie (optionnel)
        show_preview: Afficher la prévisualisation
        save_detections: Sauvegarder les détections en JSON
    """
    if not Path(video_path).exists():
        print(f"❌ Vidéo introuvable: {video_path}")
        return

    print("\n" + "=" * 60)
    print("🎬 Traitement vidéo avec détection YOLO")
    print("=" * 60)
    print(f"Vidéo: {video_path}")

    # Charger les détecteurs
    detector = get_detector()
    face_engine = get_face_engine()

    # Charger les employés connus
    db = SessionLocal()
    try:
        employees = db.query(Employee).filter(Employee.is_active == True).all()
        employees_data = []
        for emp in employees:
            encodings = [enc.encoding for enc in emp.face_encodings]
            if encodings:
                employees_data.append({
                    'employee_id': emp.employee_id,
                    'name': emp.name,
                    'encodings': encodings
                })
        face_engine.load_known_faces(employees_data)
        print(f"✅ {len(employees_data)} employés chargés")
    finally:
        db.close()

    # Ouvrir la vidéo
    cap = cv2.VideoCapture(video_path)

    if not cap.isOpened():
        print(f"❌ Impossible d'ouvrir la vidéo: {video_path}")
        return

    # Propriétés de la vidéo
    fps = int(cap.get(cv2.CAP_PROP_FPS))
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    duration = total_frames / fps

    print(f"\nInformations vidéo:")
    print(f"  - Résolution: {width}x{height}")
    print(f"  - FPS: {fps}")
    print(f"  - Frames: {total_frames}")
    print(f"  - Durée: {duration:.2f}s")

    # Préparer la sortie
    if output_path is None:
        output_path = Path(video_path).stem + "_detected.mp4"

    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))

    # Statistiques
    all_detections = {
        'faces': [],
        'weapons': [],
        'animals': [],
        'recognized_employees': set()
    }

    frame_count = 0
    print("\n⏳ Traitement en cours...")

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        # Traiter toutes les N frames pour optimiser (traiter 1 frame sur 5)
        if frame_count % 5 == 0:
            # Détection
            detections = detector.detect_all(frame)

            # Annoter la frame
            annotated_frame = frame.copy()

            # Traiter les visages détectés
            for face in detections.get('faces', []):
                bbox = face['bbox']
                face_region = face['face_region']

                # Essayer de reconnaître
                encoding = face_engine.extract_face_encoding(face_region)
                if encoding is not None:
                    recognition = face_engine.recognize_face(encoding)

                    if recognition:
                        # Employé reconnu
                        name = recognition['name']
                        confidence = recognition['confidence']
                        all_detections['recognized_employees'].add(name)

                        # Dessiner en vert
                        cv2.rectangle(annotated_frame,
                                     (bbox[0], bbox[1]),
                                     (bbox[2], bbox[3]),
                                     (0, 255, 0), 2)

                        label = f"{name} ({confidence:.2f})"
                        cv2.putText(annotated_frame, label,
                                   (bbox[0], bbox[1] - 10),
                                   cv2.FONT_HERSHEY_SIMPLEX,
                                   0.5, (0, 255, 0), 2)

                        all_detections['faces'].append({
                            'frame': frame_count,
                            'timestamp': frame_count / fps,
                            'name': name,
                            'confidence': confidence
                        })
                    else:
                        # Personne inconnue - rouge
                        cv2.rectangle(annotated_frame,
                                     (bbox[0], bbox[1]),
                                     (bbox[2], bbox[3]),
                                     (0, 0, 255), 2)

                        cv2.putText(annotated_frame, "Inconnu",
                                   (bbox[0], bbox[1] - 10),
                                   cv2.FONT_HERSHEY_SIMPLEX,
                                   0.5, (0, 0, 255), 2)

                        all_detections['faces'].append({
                            'frame': frame_count,
                            'timestamp': frame_count / fps,
                            'name': 'Unknown',
                            'confidence': face['confidence']
                        })

            # Traiter les armes détectées
            for weapon in detections.get('weapons', []):
                bbox = weapon['bbox']
                class_name = weapon['class']
                confidence = weapon['confidence']

                # Dessiner en rouge vif
                cv2.rectangle(annotated_frame,
                             (bbox[0], bbox[1]),
                             (bbox[2], bbox[3]),
                             (0, 0, 255), 3)

                label = f"⚠️ ARME: {class_name} ({confidence:.2f})"
                cv2.putText(annotated_frame, label,
                           (bbox[0], bbox[1] - 10),
                           cv2.FONT_HERSHEY_SIMPLEX,
                           0.6, (0, 0, 255), 2)

                all_detections['weapons'].append({
                    'frame': frame_count,
                    'timestamp': frame_count / fps,
                    'class': class_name,
                    'confidence': confidence,
                    'severity': weapon['severity']
                })

            # Traiter les animaux détectés
            for animal in detections.get('animals', []):
                bbox = animal['bbox']
                class_name = animal['class']
                confidence = animal['confidence']

                # Dessiner en bleu
                cv2.rectangle(annotated_frame,
                             (bbox[0], bbox[1]),
                             (bbox[2], bbox[3]),
                             (255, 0, 0), 2)

                label = f"Animal: {class_name} ({confidence:.2f})"
                cv2.putText(annotated_frame, label,
                           (bbox[0], bbox[1] - 10),
                           cv2.FONT_HERSHEY_SIMPLEX,
                           0.5, (255, 0, 0), 2)

                all_detections['animals'].append({
                    'frame': frame_count,
                    'timestamp': frame_count / fps,
                    'class': class_name,
                    'confidence': confidence
                })

            # Ajouter des informations sur la frame
            info_text = f"Frame: {frame_count}/{total_frames} | Time: {frame_count/fps:.1f}s"
            cv2.putText(annotated_frame, info_text,
                       (10, 30),
                       cv2.FONT_HERSHEY_SIMPLEX,
                       0.7, (255, 255, 255), 2)

            # Utiliser la frame annotée
            frame = annotated_frame

        # Écrire la frame
        out.write(frame)

        # Afficher la prévisualisation
        if show_preview:
            cv2.imshow('Detection', frame)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                print("\n⏹️  Arrêt demandé par l'utilisateur")
                break

        # Progression
        frame_count += 1
        if frame_count % 30 == 0:
            progress = (frame_count / total_frames) * 100
            print(f"  Progression: {progress:.1f}% ({frame_count}/{total_frames})")

    # Nettoyage
    cap.release()
    out.release()
    cv2.destroyAllWindows()

    print(f"\n✅ Traitement terminé!")
    print(f"📁 Vidéo sauvegardée: {output_path}")

    # Afficher les statistiques
    print("\n" + "=" * 60)
    print("📊 STATISTIQUES DE DÉTECTION")
    print("=" * 60)

    # Visages
    unique_faces = len(all_detections['recognized_employees'])
    total_face_detections = len(all_detections['faces'])
    print(f"\n👥 Visages:")
    print(f"  - Détections totales: {total_face_detections}")
    print(f"  - Employés reconnus: {unique_faces}")
    if all_detections['recognized_employees']:
        print("  - Liste:")
        for name in sorted(all_detections['recognized_employees']):
            count = sum(1 for f in all_detections['faces'] if f.get('name') == name)
            print(f"    • {name}: {count} détections")

    # Armes
    weapons_count = len(all_detections['weapons'])
    print(f"\n⚠️  Armes: {weapons_count}")
    if weapons_count > 0:
        print("  ⚠️  ALERTE SÉCURITÉ!")
        for weapon in all_detections['weapons']:
            print(f"    • {weapon['class']} à {weapon['timestamp']:.1f}s (sévérité: {weapon['severity']})")

    # Animaux
    animals_count = len(all_detections['animals'])
    print(f"\n🐾 Animaux: {animals_count}")
    if animals_count > 0:
        animal_types = set(a['class'] for a in all_detections['animals'])
        print(f"  - Types détectés: {', '.join(animal_types)}")

    # Sauvegarder les détections en JSON
    if save_detections:
        json_path = Path(output_path).stem + "_detections.json"

        # Convertir le set en list pour JSON
        detections_data = {
            'video_info': {
                'source': video_path,
                'output': output_path,
                'width': width,
                'height': height,
                'fps': fps,
                'total_frames': total_frames,
                'duration': duration,
                'processed_at': datetime.now().isoformat()
            },
            'statistics': {
                'total_face_detections': total_face_detections,
                'unique_employees': unique_faces,
                'employees_list': list(all_detections['recognized_employees']),
                'weapons_detected': weapons_count,
                'animals_detected': animals_count
            },
            'detections': {
                'faces': all_detections['faces'],
                'weapons': all_detections['weapons'],
                'animals': all_detections['animals']
            }
        }

        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(detections_data, f, indent=2, ensure_ascii=False)

        print(f"\n📄 Détections sauvegardées: {json_path}")

    print("=" * 60 + "\n")


def main():
    parser = argparse.ArgumentParser(
        description="Tester la détection YOLO sur une vidéo"
    )

    parser.add_argument(
        "video",
        help="Chemin vers la vidéo à traiter"
    )
    parser.add_argument(
        "-o", "--output",
        help="Chemin de sortie (par défaut: video_detected.mp4)"
    )
    parser.add_argument(
        "--no-preview",
        action="store_true",
        help="Désactiver la prévisualisation"
    )
    parser.add_argument(
        "--no-json",
        action="store_true",
        help="Ne pas sauvegarder les détections en JSON"
    )

    args = parser.parse_args()

    process_video_with_detection(
        video_path=args.video,
        output_path=args.output,
        show_preview=not args.no_preview,
        save_detections=not args.no_json
    )


if __name__ == "__main__":
    main()
