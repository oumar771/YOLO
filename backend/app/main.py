"""Main FastAPI application for YOLO face recognition system."""

from fastapi import FastAPI, File, UploadFile, Depends, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from typing import List, Optional
import cv2
import numpy as np
from datetime import datetime
import logging
from pathlib import Path
import json

from config.settings import get_settings
from app.database import get_db, init_db, Employee, FaceEncoding, Attendance, UnknownFace, DetectionEvent
from utils import (
    get_detector,
    get_face_engine,
    get_azure_manager,
    get_local_manager,
    get_notification_manager
)

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

settings = get_settings()

# Créer l'application FastAPI
app = FastAPI(
    title="YOLO Face Recognition API",
    description="API for facial recognition with YOLO detection",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En production, spécifier les domaines autorisés
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialiser la base de données au démarrage
@app.on_event("startup")
async def startup_event():
    """Initialize application on startup."""
    logger.info("Starting YOLO Face Recognition API...")
    init_db()
    logger.info("Database initialized")

    # Charger les visages connus
    db = next(get_db())
    try:
        employees = db.query(Employee).filter(Employee.is_active == True).all()

        employees_data = []
        for emp in employees:
            encodings = [enc.encoding for enc in emp.face_encodings]
            employees_data.append({
                'employee_id': emp.employee_id,
                'name': emp.name,
                'department': emp.department,
                'position': emp.position,
                'encodings': encodings
            })

        face_engine = get_face_engine()
        face_engine.load_known_faces(employees_data)
        logger.info(f"Loaded {len(employees_data)} known faces")
    finally:
        db.close()

    logger.info("Application startup complete")


@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "message": "YOLO Face Recognition API",
        "version": "1.0.0",
        "status": "running"
    }


@app.post("/api/detect")
async def detect_objects(
    file: UploadFile = File(...),
    detection_type: Optional[str] = "all",
    background_tasks: BackgroundTasks = None,
    db: Session = Depends(get_db)
):
    """
    Detect objects in an uploaded image.

    Args:
        file: Image file
        detection_type: Type of detection ('face', 'weapon', 'animal', 'all')
        background_tasks: Background tasks handler
        db: Database session

    Returns:
        Detection results
    """
    try:
        # Lire l'image
        contents = await file.read()
        nparr = np.frombuffer(contents, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if image is None:
            raise HTTPException(status_code=400, detail="Invalid image file")

        # Sauvegarder localement
        local_manager = get_local_manager()
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        filename = f"{timestamp}_{file.filename}"
        image_path = local_manager.save_image(contents, filename, "detections")

        detector = get_detector()

        # Effectuer les détections
        if detection_type == "all":
            detections = detector.detect_all(image)
        elif detection_type == "face":
            detections = {'faces': detector.detect_faces(image)}
        elif detection_type == "weapon":
            detections = {'weapons': detector.detect_weapons(image)}
        elif detection_type == "animal":
            detections = {'animals': detector.detect_animals(image)}
        else:
            raise HTTPException(status_code=400, detail="Invalid detection type")

        # Traiter les détections
        result = {
            'timestamp': datetime.utcnow().isoformat(),
            'image_path': image_path,
            'detections': detections
        }

        # Gérer les notifications en arrière-plan
        if background_tasks:
            notif_manager = get_notification_manager()

            if detections.get('weapons'):
                for weapon in detections['weapons']:
                    event = DetectionEvent(
                        detection_type='weapon',
                        class_name=weapon['class'],
                        confidence=weapon['confidence'],
                        image_path=image_path,
                        severity=weapon['severity'],
                        detected_at=datetime.utcnow()
                    )
                    db.add(event)
                    background_tasks.add_task(
                        notif_manager.notify_weapon_detected,
                        weapon,
                        image_path
                    )

            if detections.get('animals'):
                for animal in detections['animals']:
                    event = DetectionEvent(
                        detection_type='animal',
                        class_name=animal['class'],
                        confidence=animal['confidence'],
                        image_path=image_path,
                        detected_at=datetime.utcnow()
                    )
                    db.add(event)
                    background_tasks.add_task(
                        notif_manager.notify_animal_detected,
                        animal,
                        image_path
                    )

            db.commit()

        return JSONResponse(content=result)

    except Exception as e:
        logger.error(f"Detection error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/recognize")
async def recognize_face(
    file: UploadFile = File(...),
    background_tasks: BackgroundTasks = None,
    db: Session = Depends(get_db)
):
    """
    Recognize a face and record attendance.

    Args:
        file: Image file containing a face
        background_tasks: Background tasks handler
        db: Database session

    Returns:
        Recognition result with attendance record
    """
    try:
        # Lire l'image
        contents = await file.read()
        nparr = np.frombuffer(contents, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if image is None:
            raise HTTPException(status_code=400, detail="Invalid image file")

        # Sauvegarder localement
        local_manager = get_local_manager()
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        filename = f"{timestamp}_{file.filename}"
        image_path = local_manager.save_image(contents, filename, "attendance")

        # Détecter le visage
        detector = get_detector()
        faces = detector.detect_faces(image)

        if not faces:
            return JSONResponse(
                content={
                    'success': False,
                    'message': 'Aucun visage détecté',
                    'timestamp': datetime.utcnow().isoformat()
                },
                status_code=200
            )

        # Prendre le visage le plus confiant
        best_face = max(faces, key=lambda x: x['confidence'])
        face_region = best_face['face_region']

        # Extraire l'encodage
        face_engine = get_face_engine()
        encoding = face_engine.extract_face_encoding(face_region)

        if encoding is None:
            return JSONResponse(
                content={
                    'success': False,
                    'message': 'Impossible d\'extraire l\'encodage du visage',
                    'timestamp': datetime.utcnow().isoformat()
                }
            )

        # Reconnaître le visage
        recognition_result = face_engine.recognize_face(encoding)

        if recognition_result:
            # Employé reconnu - Enregistrer la présence
            employee = db.query(Employee).filter(
                Employee.employee_id == recognition_result['employee_id']
            ).first()

            if employee:
                # Créer un enregistrement de présence
                attendance = Attendance(
                    employee_id=employee.id,
                    check_in=datetime.utcnow(),
                    confidence=recognition_result['confidence'],
                    image_path=image_path,
                    synced=False
                )
                db.add(attendance)
                db.commit()

                # Synchroniser avec le cloud en arrière-plan
                if background_tasks:
                    azure_manager = get_azure_manager()
                    background_tasks.add_task(
                        azure_manager.sync_attendance_record,
                        {
                            'id': attendance.id,
                            'employee_id': employee.employee_id,
                            'employee_name': employee.name,
                            'check_in': attendance.check_in.isoformat(),
                            'confidence': attendance.confidence
                        }
                    )
                    background_tasks.add_task(
                        azure_manager.upload_image,
                        image_path,
                        f"attendance/{datetime.utcnow().strftime('%Y%m%d')}/{filename}"
                    )

                return JSONResponse(content={
                    'success': True,
                    'recognized': True,
                    'employee': {
                        'id': employee.employee_id,
                        'name': employee.name,
                        'department': employee.department,
                        'position': employee.position
                    },
                    'confidence': recognition_result['confidence'],
                    'attendance_id': attendance.id,
                    'check_in': attendance.check_in.isoformat(),
                    'timestamp': datetime.utcnow().isoformat()
                })

        else:
            # Personne inconnue - Enregistrer et notifier
            unknown_face = UnknownFace(
                image_path=image_path,
                encoding=face_engine.encode_to_json(encoding),
                detected_at=datetime.utcnow(),
                confidence=best_face['confidence'],
                detection_type='person',
                synced=False
            )
            db.add(unknown_face)
            db.commit()

            # Notifier les RH en arrière-plan
            if background_tasks:
                notif_manager = get_notification_manager()
                background_tasks.add_task(
                    notif_manager.notify_unknown_person,
                    {
                        'id': unknown_face.id,
                        'detected_at': unknown_face.detected_at,
                        'confidence': unknown_face.confidence,
                        'location': unknown_face.location
                    },
                    image_path
                )

                azure_manager = get_azure_manager()
                background_tasks.add_task(
                    azure_manager.sync_unknown_face,
                    {
                        'id': unknown_face.id,
                        'detected_at': unknown_face.detected_at.isoformat(),
                        'confidence': unknown_face.confidence
                    },
                    image_path
                )

            return JSONResponse(content={
                'success': True,
                'recognized': False,
                'message': 'Personne inconnue détectée. RH notifiés.',
                'unknown_id': unknown_face.id,
                'timestamp': datetime.utcnow().isoformat()
            })

    except Exception as e:
        logger.error(f"Recognition error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/employees")
async def add_employee(
    name: str,
    email: str,
    employee_id: str,
    department: Optional[str] = None,
    position: Optional[str] = None,
    phone: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Add a new employee to the system."""
    try:
        # Vérifier si l'employé existe déjà
        existing = db.query(Employee).filter(
            (Employee.employee_id == employee_id) | (Employee.email == email)
        ).first()

        if existing:
            raise HTTPException(status_code=400, detail="Employee already exists")

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

        return JSONResponse(content={
            'success': True,
            'employee': {
                'id': employee.id,
                'employee_id': employee.employee_id,
                'name': employee.name,
                'email': employee.email
            }
        })

    except Exception as e:
        logger.error(f"Error adding employee: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/employees/{employee_id}/add-face")
async def add_employee_face(
    employee_id: str,
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    """Add a face image for an employee."""
    try:
        # Trouver l'employé
        employee = db.query(Employee).filter(
            Employee.employee_id == employee_id
        ).first()

        if not employee:
            raise HTTPException(status_code=404, detail="Employee not found")

        # Lire l'image
        contents = await file.read()
        nparr = np.frombuffer(contents, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if image is None:
            raise HTTPException(status_code=400, detail="Invalid image file")

        # Sauvegarder l'image
        local_manager = get_local_manager()
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        filename = f"{employee_id}_{timestamp}_{file.filename}"
        image_path = local_manager.save_image(contents, filename, "employees")

        # Extraire l'encodage
        face_engine = get_face_engine()
        encoding = face_engine.extract_face_encoding(image)

        if encoding is None:
            raise HTTPException(
                status_code=400,
                detail="No face detected or unable to extract face encoding"
            )

        # Évaluer la qualité
        quality = face_engine.assess_face_quality(image)

        # Sauvegarder l'encodage
        face_encoding = FaceEncoding(
            employee_id=employee.id,
            encoding=face_engine.encode_to_json(encoding),
            image_path=image_path,
            quality_score=quality['overall_score']
        )
        db.add(face_encoding)
        db.commit()

        # Recharger les visages connus
        await startup_event()

        return JSONResponse(content={
            'success': True,
            'message': f'Face added for {employee.name}',
            'quality_score': quality['overall_score'],
            'quality_details': quality
        })

    except Exception as e:
        logger.error(f"Error adding face: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/attendances")
async def get_attendances(
    employee_id: Optional[str] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Get attendance records."""
    try:
        query = db.query(Attendance).join(Employee)

        if employee_id:
            query = query.filter(Employee.employee_id == employee_id)

        if start_date:
            start = datetime.fromisoformat(start_date)
            query = query.filter(Attendance.check_in >= start)

        if end_date:
            end = datetime.fromisoformat(end_date)
            query = query.filter(Attendance.check_in <= end)

        attendances = query.order_by(Attendance.check_in.desc()).limit(100).all()

        result = []
        for att in attendances:
            result.append({
                'id': att.id,
                'employee_id': att.employee.employee_id,
                'employee_name': att.employee.name,
                'check_in': att.check_in.isoformat(),
                'check_out': att.check_out.isoformat() if att.check_out else None,
                'confidence': att.confidence,
                'synced': att.synced
            })

        return JSONResponse(content={'attendances': result})

    except Exception as e:
        logger.error(f"Error fetching attendances: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/unknown-faces")
async def get_unknown_faces(
    limit: int = 50,
    db: Session = Depends(get_db)
):
    """Get unknown face detections."""
    try:
        unknown_faces = db.query(UnknownFace).order_by(
            UnknownFace.detected_at.desc()
        ).limit(limit).all()

        result = []
        for face in unknown_faces:
            result.append({
                'id': face.id,
                'detected_at': face.detected_at.isoformat(),
                'confidence': face.confidence,
                'is_notified': face.is_notified,
                'notes': face.notes,
                'image_path': face.image_path
            })

        return JSONResponse(content={'unknown_faces': result})

    except Exception as e:
        logger.error(f"Error fetching unknown faces: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/detection-events")
async def get_detection_events(
    detection_type: Optional[str] = None,
    limit: int = 50,
    db: Session = Depends(get_db)
):
    """Get detection events (weapons, animals, etc.)."""
    try:
        query = db.query(DetectionEvent)

        if detection_type:
            query = query.filter(DetectionEvent.detection_type == detection_type)

        events = query.order_by(
            DetectionEvent.detected_at.desc()
        ).limit(limit).all()

        result = []
        for event in events:
            result.append({
                'id': event.id,
                'detection_type': event.detection_type,
                'class_name': event.class_name,
                'confidence': event.confidence,
                'severity': event.severity,
                'detected_at': event.detected_at.isoformat(),
                'is_notified': event.is_notified,
                'notes': event.notes
            })

        return JSONResponse(content={'events': result})

    except Exception as e:
        logger.error(f"Error fetching detection events: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/process-video")
async def process_video(
    file: UploadFile = File(...),
    background_tasks: BackgroundTasks = None,
    db: Session = Depends(get_db)
):
    """Process a video file for detections."""
    try:
        # Sauvegarder la vidéo
        local_manager = get_local_manager()
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        filename = f"{timestamp}_{file.filename}"

        contents = await file.read()
        video_path = local_manager.save_image(contents, filename, "videos")

        # Traiter la vidéo en arrière-plan
        if background_tasks:
            background_tasks.add_task(process_video_background, video_path, db)

        return JSONResponse(content={
            'success': True,
            'message': 'Video processing started',
            'video_path': video_path
        })

    except Exception as e:
        logger.error(f"Error processing video: {e}")
        raise HTTPException(status_code=500, detail=str(e))


async def process_video_background(video_path: str, db: Session):
    """Background task to process video."""
    try:
        detector = get_detector()
        output_path = video_path.replace('.', '_annotated.')

        detections = detector.process_video(video_path, output_path)

        logger.info(f"Video processing complete: {len(detections)} detections")

        # Sauvegarder les événements significatifs
        for detection in detections:
            if detection.get('type') in ['weapon', 'animal']:
                event = DetectionEvent(
                    detection_type=detection['type'],
                    class_name=detection.get('class', 'unknown'),
                    confidence=detection['confidence'],
                    video_path=video_path,
                    severity=detection.get('severity', 'normal'),
                    detected_at=datetime.utcnow()
                )
                db.add(event)

        db.commit()

    except Exception as e:
        logger.error(f"Background video processing error: {e}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG
    )
