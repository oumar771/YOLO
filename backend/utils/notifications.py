"""Notification system for HR alerts."""

import logging
from typing import Dict, List, Optional
from datetime import datetime
from config.settings import get_settings
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.image import MIMEImage
from pathlib import Path

logger = logging.getLogger(__name__)
settings = get_settings()

# SendGrid pour les emails
try:
    from sendgrid import SendGridAPIClient
    from sendgrid.helpers.mail import Mail, Attachment, FileContent, FileName, FileType, Disposition
    import base64
    SENDGRID_AVAILABLE = True
except ImportError:
    SENDGRID_AVAILABLE = False
    logger.warning("SendGrid not available")

# Twilio pour les SMS
try:
    from twilio.rest import Client as TwilioClient
    TWILIO_AVAILABLE = True
except ImportError:
    TWILIO_AVAILABLE = False
    logger.warning("Twilio not available")


class NotificationManager:
    """Manager for sending notifications to HR."""

    def __init__(self):
        """Initialize notification manager."""
        self.sendgrid_enabled = SENDGRID_AVAILABLE and settings.SENDGRID_API_KEY is not None
        self.twilio_enabled = TWILIO_AVAILABLE and settings.TWILIO_ACCOUNT_SID is not None

        if self.sendgrid_enabled:
            self.sendgrid = SendGridAPIClient(settings.SENDGRID_API_KEY)
            logger.info("SendGrid initialized")

        if self.twilio_enabled:
            self.twilio = TwilioClient(
                settings.TWILIO_ACCOUNT_SID,
                settings.TWILIO_AUTH_TOKEN
            )
            logger.info("Twilio initialized")

    async def notify_unknown_person(
        self,
        detection_data: Dict,
        image_path: Optional[str] = None
    ) -> bool:
        """
        Notify HR about an unknown person detected.

        Args:
            detection_data: Detection details
            image_path: Optional path to image

        Returns:
            True if notification sent successfully
        """
        subject = "🚨 Personne inconnue détectée"

        body = f"""
        <html>
        <body>
            <h2>Alerte : Personne inconnue détectée</h2>

            <p><strong>Date et heure :</strong> {detection_data.get('detected_at', datetime.utcnow())}</p>
            <p><strong>Localisation :</strong> {detection_data.get('location', 'Non spécifié')}</p>
            <p><strong>Niveau de confiance :</strong> {detection_data.get('confidence', 0):.2%}</p>

            <h3>Actions recommandées :</h3>
            <ul>
                <li>Vérifier l'identité de la personne</li>
                <li>Consulter les caméras de sécurité</li>
                <li>Contacter le service de sécurité si nécessaire</li>
            </ul>

            <p>Cette notification a été générée automatiquement par le système de reconnaissance faciale.</p>
        </body>
        </html>
        """

        return await self._send_email(
            subject=subject,
            body=body,
            image_path=image_path,
            priority="high"
        )

    async def notify_weapon_detected(
        self,
        detection_data: Dict,
        image_path: Optional[str] = None
    ) -> bool:
        """
        Notify HR/Security about weapon detection.

        Args:
            detection_data: Detection details
            image_path: Optional path to image

        Returns:
            True if notification sent successfully
        """
        weapon_class = detection_data.get('class', 'Arme non identifiée')
        severity = detection_data.get('severity', 'high')

        subject = f"🚨 URGENT - Arme détectée : {weapon_class}"

        body = f"""
        <html>
        <body style="background-color: #ffebee; padding: 20px;">
            <div style="background-color: #d32f2f; color: white; padding: 10px; border-radius: 5px;">
                <h2>⚠️ ALERTE CRITIQUE : ARME DÉTECTÉE</h2>
            </div>

            <div style="background-color: white; padding: 20px; margin-top: 10px; border-radius: 5px;">
                <p><strong>Type d'arme :</strong> {weapon_class}</p>
                <p><strong>Niveau de gravité :</strong> <span style="color: red; font-weight: bold;">{severity.upper()}</span></p>
                <p><strong>Date et heure :</strong> {detection_data.get('detected_at', datetime.utcnow())}</p>
                <p><strong>Localisation :</strong> {detection_data.get('location', 'Non spécifié')}</p>
                <p><strong>Niveau de confiance :</strong> {detection_data.get('confidence', 0):.2%}</p>

                <h3 style="color: #d32f2f;">Actions immédiates :</h3>
                <ol>
                    <li><strong>Contacter immédiatement le service de sécurité</strong></li>
                    <li>Déclencher le protocole de sécurité approprié</li>
                    <li>Vérifier les caméras de surveillance en temps réel</li>
                    <li>Alerter les autorités si nécessaire</li>
                </ol>

                <p style="color: #666; margin-top: 20px; font-size: 12px;">
                    Cette alerte a été générée automatiquement. Temps de réponse critique.
                </p>
            </div>
        </body>
        </html>
        """

        # Envoyer email ET SMS pour les armes
        email_sent = await self._send_email(
            subject=subject,
            body=body,
            image_path=image_path,
            priority="urgent"
        )

        sms_sent = await self._send_sms(
            f"ALERTE CRITIQUE: Arme détectée ({weapon_class}) à {detection_data.get('location', 'localisation inconnue')}. "
            f"Contactez immédiatement la sécurité."
        )

        return email_sent or sms_sent

    async def notify_animal_detected(
        self,
        detection_data: Dict,
        image_path: Optional[str] = None
    ) -> bool:
        """
        Notify about animal detection.

        Args:
            detection_data: Detection details
            image_path: Optional path to image

        Returns:
            True if notification sent successfully
        """
        animal_class = detection_data.get('class', 'Animal non identifié')

        subject = f"🐾 Animal détecté : {animal_class}"

        body = f"""
        <html>
        <body>
            <h2>Notification : Animal détecté dans l'entreprise</h2>

            <p><strong>Type d'animal :</strong> {animal_class}</p>
            <p><strong>Date et heure :</strong> {detection_data.get('detected_at', datetime.utcnow())}</p>
            <p><strong>Localisation :</strong> {detection_data.get('location', 'Non spécifié')}</p>
            <p><strong>Niveau de confiance :</strong> {detection_data.get('confidence', 0):.2%}</p>

            <h3>Actions recommandées :</h3>
            <ul>
                <li>Vérifier la situation via les caméras</li>
                <li>Contacter un service de contrôle animalier si nécessaire</li>
                <li>S'assurer de la sécurité des employés</li>
            </ul>

            <p>Cette notification a été générée automatiquement.</p>
        </body>
        </html>
        """

        return await self._send_email(
            subject=subject,
            body=body,
            image_path=image_path,
            priority="normal"
        )

    async def notify_attendance_summary(
        self,
        date: datetime,
        summary_data: Dict
    ) -> bool:
        """
        Send daily attendance summary to HR.

        Args:
            date: Date of summary
            summary_data: Summary statistics

        Returns:
            True if sent successfully
        """
        subject = f"📊 Rapport de présence - {date.strftime('%d/%m/%Y')}"

        body = f"""
        <html>
        <body>
            <h2>Rapport de présence quotidien</h2>

            <p><strong>Date :</strong> {date.strftime('%d/%m/%Y')}</p>

            <h3>Statistiques :</h3>
            <ul>
                <li><strong>Employés présents :</strong> {summary_data.get('present', 0)}</li>
                <li><strong>Employés absents :</strong> {summary_data.get('absent', 0)}</li>
                <li><strong>Arrivées tardives :</strong> {summary_data.get('late', 0)}</li>
                <li><strong>Départs anticipés :</strong> {summary_data.get('early_departure', 0)}</li>
            </ul>

            <h3>Détections spéciales :</h3>
            <ul>
                <li><strong>Personnes inconnues :</strong> {summary_data.get('unknown_faces', 0)}</li>
                <li><strong>Alertes sécurité :</strong> {summary_data.get('security_alerts', 0)}</li>
            </ul>

            <p style="margin-top: 20px; color: #666;">
                Ce rapport est généré automatiquement chaque jour.
            </p>
        </body>
        </html>
        """

        return await self._send_email(
            subject=subject,
            body=body,
            priority="normal"
        )

    async def _send_email(
        self,
        subject: str,
        body: str,
        image_path: Optional[str] = None,
        priority: str = "normal"
    ) -> bool:
        """
        Send email notification.

        Args:
            subject: Email subject
            body: HTML body
            image_path: Optional image attachment
            priority: Priority level ('normal', 'high', 'urgent')

        Returns:
            True if sent successfully
        """
        if not self.sendgrid_enabled:
            logger.warning("Email notifications disabled")
            return False

        try:
            message = Mail(
                from_email='noreply@company.com',
                to_emails=settings.HR_EMAIL,
                subject=subject,
                html_content=body
            )

            # Ajouter l'image si fournie
            if image_path and Path(image_path).exists():
                with open(image_path, 'rb') as f:
                    image_data = f.read()
                    encoded = base64.b64encode(image_data).decode()

                    attachment = Attachment(
                        FileContent(encoded),
                        FileName(Path(image_path).name),
                        FileType('image/jpeg'),
                        Disposition('attachment')
                    )
                    message.attachment = attachment

            # Définir la priorité
            if priority == "urgent":
                message.add_header("X-Priority", "1")
                message.add_header("Importance", "high")

            # Envoyer
            response = self.sendgrid.send(message)

            if response.status_code in [200, 201, 202]:
                logger.info(f"Email sent successfully: {subject}")
                return True
            else:
                logger.error(f"Email send failed: {response.status_code}")
                return False

        except Exception as e:
            logger.error(f"Failed to send email: {e}")
            return False

    async def _send_sms(self, message: str) -> bool:
        """
        Send SMS notification.

        Args:
            message: SMS text content

        Returns:
            True if sent successfully
        """
        if not self.twilio_enabled:
            logger.warning("SMS notifications disabled")
            return False

        try:
            # Limiter le message à 160 caractères
            if len(message) > 160:
                message = message[:157] + "..."

            sms = self.twilio.messages.create(
                body=message,
                from_=settings.TWILIO_PHONE_NUMBER,
                to=settings.HR_EMAIL  # Devrait être un numéro de téléphone
            )

            logger.info(f"SMS sent successfully: {sms.sid}")
            return True

        except Exception as e:
            logger.error(f"Failed to send SMS: {e}")
            return False


# Instance globale
_notification_manager = None

def get_notification_manager() -> NotificationManager:
    """Get global notification manager."""
    global _notification_manager
    if _notification_manager is None:
        _notification_manager = NotificationManager()
    return _notification_manager
