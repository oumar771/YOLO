# Installation rapide pour Python 3.14 (ou autre version récente)
# Ce script installe les packages dans l'ordre optimal

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installation dépendances YOLO" -ForegroundColor Cyan
Write-Host "Python version: $(python --version)" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Mettre à jour pip
Write-Host "[0/12] Mise à jour de pip..." -ForegroundColor Yellow
python -m pip install --upgrade pip

# 1. NumPy (base pour tout)
Write-Host "[1/12] Installation NumPy..." -ForegroundColor Yellow
pip install numpy

# 2. Pillow (images)
Write-Host "[2/12] Installation Pillow..." -ForegroundColor Yellow
pip install pillow

# 3. OpenCV (IMPORTANT - c'est opencv-python, pas cv2)
Write-Host "[3/12] Installation OpenCV (cv2)..." -ForegroundColor Yellow
pip install opencv-python

# Test OpenCV
Write-Host "Test OpenCV..." -ForegroundColor Cyan
python -c "import cv2; print('  ✓ OpenCV version:', cv2.__version__)"

# 4. FastAPI et Uvicorn
Write-Host "[4/12] Installation FastAPI & Uvicorn..." -ForegroundColor Yellow
pip install fastapi "uvicorn[standard]"

# 5. Pydantic
Write-Host "[5/12] Installation Pydantic..." -ForegroundColor Yellow
pip install pydantic pydantic-settings

# 6. SQLAlchemy
Write-Host "[6/12] Installation SQLAlchemy..." -ForegroundColor Yellow
pip install sqlalchemy

# 7. Python-dotenv
Write-Host "[7/12] Installation python-dotenv..." -ForegroundColor Yellow
pip install python-dotenv

# 8. Multipart
Write-Host "[8/12] Installation python-multipart..." -ForegroundColor Yellow
pip install python-multipart

# 9. Sécurité
Write-Host "[9/12] Installation sécurité..." -ForegroundColor Yellow
pip install "python-jose[cryptography]" "passlib[bcrypt]"

# 10. Utilitaires
Write-Host "[10/12] Installation utilitaires..." -ForegroundColor Yellow
pip install httpx requests python-dateutil pytz aiofiles loguru

# 11. PyTorch (peut échouer sur Python 3.14)
Write-Host "[11/12] Installation PyTorch..." -ForegroundColor Yellow
pip install torch torchvision
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ⚠️ PyTorch installation échouée (normal sur Python 3.14)" -ForegroundColor Red
    Write-Host "  ℹ️ Vous devrez peut-être downgrader vers Python 3.11" -ForegroundColor Yellow
}

# 12. Ultralytics YOLO (peut échouer sur Python 3.14)
Write-Host "[12/12] Installation Ultralytics..." -ForegroundColor Yellow
pip install ultralytics
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ⚠️ Ultralytics installation échouée (normal sur Python 3.14)" -ForegroundColor Red
    Write-Host "  ℹ️ Vous devrez peut-être downgrader vers Python 3.11" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installation terminée !" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Vérification finale
Write-Host "Vérification des imports critiques..." -ForegroundColor Yellow

$imports = @(
    "import cv2",
    "import numpy",
    "import fastapi",
    "import uvicorn",
    "import sqlalchemy",
    "import pydantic",
    "from pydantic_settings import BaseSettings"
)

$allOk = $true
foreach ($import in $imports) {
    try {
        python -c $import
        $moduleName = $import -replace "import ", "" -replace "from ", "" -split " " | Select-Object -First 1
        Write-Host "  ✓ $moduleName OK" -ForegroundColor Green
    } catch {
        $moduleName = $import -replace "import ", "" -replace "from ", "" -split " " | Select-Object -First 1
        Write-Host "  ✗ $moduleName MANQUANT" -ForegroundColor Red
        $allOk = $false
    }
}

Write-Host ""
if ($allOk) {
    Write-Host "✓ Tous les imports essentiels fonctionnent !" -ForegroundColor Green
    Write-Host ""
    Write-Host "Vous pouvez maintenant lancer:" -ForegroundColor Cyan
    Write-Host "  python run.py" -ForegroundColor Yellow
} else {
    Write-Host "⚠️ Certains imports ont échoué" -ForegroundColor Red
    Write-Host ""
    Write-Host "Recommandation: Installer Python 3.11 ou 3.12" -ForegroundColor Yellow
    Write-Host "Python 3.14 est trop récent et instable" -ForegroundColor Yellow
}

Write-Host ""
