"""Script pour ajouter des employés et leurs images de visage."""

import argparse
import cv2
import numpy as np
from pathlib import Path
import sys

# Ajouter le dossier parent au path
sys.path.append(str(Path(__file__).parent.parent))

from app.database import SessionLocal, Employee, FaceEncoding
from utils.face_recognition import get_face_engine
from utils.cloud_storage import get_local_manager


def add_employee(
    employee_id: str,
    name: str,
    email: str,
    department: str = None,
    position: str = None,
    phone: str = None,
    image_paths: list = None
):
    """Ajouter un employé avec ses images de visage."""
    db = SessionLocal()

    try:
        # Vérifier si l'employé existe déjà
        existing = db.query(Employee).filter(
            (Employee.employee_id == employee_id) | (Employee.email == email)
        ).first()

        if existing:
            print(f"❌ Employé déjà existant: {existing.name}")
            return False

        # Créer l'employé
        employee = Employee(
            employee_id=employee_id,
            name=name,
            email=email,
            department=department,
            position=position,
            phone=phone,
            is_active=True
        )
        db.add(employee)
        db.commit()
        db.refresh(employee)

        print(f"✅ Employé créé: {name} (ID: {employee_id})")

        # Ajouter les images de visage
        if image_paths:
            face_engine = get_face_engine()
            local_manager = get_local_manager()

            for image_path in image_paths:
                if not Path(image_path).exists():
                    print(f"⚠️  Image introuvable: {image_path}")
                    continue

                # Lire l'image
                image = cv2.imread(image_path)
                if image is None:
                    print(f"⚠️  Impossible de lire: {image_path}")
                    continue

                # Extraire l'encodage
                encoding = face_engine.extract_face_encoding(image)
                if encoding is None:
                    print(f"⚠️  Aucun visage détecté dans: {image_path}")
                    continue

                # Évaluer la qualité
                quality = face_engine.assess_face_quality(image)

                # Sauvegarder l'image
                with open(image_path, 'rb') as f:
                    image_data = f.read()

                saved_path = local_manager.save_image(
                    image_data,
                    f"{employee_id}_{Path(image_path).name}",
                    "employees"
                )

                # Sauvegarder l'encodage
                face_encoding = FaceEncoding(
                    employee_id=employee.id,
                    encoding=face_engine.encode_to_json(encoding),
                    image_path=saved_path,
                    quality_score=quality['overall_score']
                )
                db.add(face_encoding)

                print(f"  ✓ Image ajoutée: {Path(image_path).name} (qualité: {quality['overall_score']:.2f})")

            db.commit()
            print(f"✅ {len(image_paths)} images traitées")

        return True

    except Exception as e:
        print(f"❌ Erreur: {e}")
        db.rollback()
        return False

    finally:
        db.close()


def main():
    parser = argparse.ArgumentParser(description="Ajouter un employé au système")

    parser.add_argument("--id", required=True, help="ID de l'employé")
    parser.add_argument("--name", required=True, help="Nom complet")
    parser.add_argument("--email", required=True, help="Email")
    parser.add_argument("--department", help="Département")
    parser.add_argument("--position", help="Poste")
    parser.add_argument("--phone", help="Téléphone")
    parser.add_argument(
        "--images",
        nargs="+",
        help="Chemins vers les images de visage (minimum 3 recommandé)"
    )

    args = parser.parse_args()

    print("\n" + "=" * 50)
    print("Ajout d'un employé")
    print("=" * 50)

    success = add_employee(
        employee_id=args.id,
        name=args.name,
        email=args.email,
        department=args.department,
        position=args.position,
        phone=args.phone,
        image_paths=args.images
    )

    if success:
        print("\n✅ Employé ajouté avec succès!")
        print("\nRedémarrez le serveur pour charger les nouveaux visages.")
    else:
        print("\n❌ Échec de l'ajout de l'employé")

    print("=" * 50 + "\n")


if __name__ == "__main__":
    main()
