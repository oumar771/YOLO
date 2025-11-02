# Installation progressive des dépendances (PowerShell)
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Installation progressive des dependances" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

function Install-Package {
    param($Name, $Package, $Step, $Total)

    Write-Host "[$Step/$Total] Installation $Name..." -ForegroundColor Yellow
    pip install $Package

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERREUR: $Name" -ForegroundColor Red
        return $false
    }
    Write-Host "✓ $Name installe" -ForegroundColor Green
    return $true
}

# 1. FastAPI
if (-not (Install-Package "FastAPI" "fastapi" 1 15)) { exit 1 }

# 2. Uvicorn
if (-not (Install-Package "Uvicorn" "uvicorn[standard]" 2 15)) { exit 1 }

# 3. Pydantic
if (-not (Install-Package "Pydantic" "pydantic pydantic-settings" 3 15)) { exit 1 }

# 4. SQLAlchemy
if (-not (Install-Package "SQLAlchemy" "sqlalchemy" 4 15)) { exit 1 }

# 5. python-dotenv
if (-not (Install-Package "python-dotenv" "python-dotenv" 5 15)) { exit 1 }

# 6. python-multipart
if (-not (Install-Package "python-multipart" "python-multipart" 6 15)) { exit 1 }

# 7. NumPy
if (-not (Install-Package "NumPy" "numpy" 7 15)) { exit 1 }

# 8. Pillow
if (-not (Install-Package "Pillow" "pillow" 8 15)) { exit 1 }

# 9. OpenCV
if (-not (Install-Package "OpenCV" "opencv-python" 9 15)) { exit 1 }

# 10. PyTorch
Write-Host "[10/15] Installation PyTorch (cela peut prendre 5-10 minutes)..." -ForegroundColor Yellow
pip install torch torchvision
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERREUR: PyTorch" -ForegroundColor Red
    exit 1
}
Write-Host "✓ PyTorch installe" -ForegroundColor Green

# 11. Ultralytics
if (-not (Install-Package "Ultralytics YOLO" "ultralytics" 11 15)) { exit 1 }

# 12. Sécurité
if (-not (Install-Package "Securite (JWT, passlib)" "python-jose[cryptography] passlib[bcrypt]" 12 15)) { exit 1 }

# 13. Utilitaires
if (-not (Install-Package "Utilitaires" "httpx requests python-dateutil pytz aiofiles" 13 15)) { exit 1 }

# 14. Logs
if (-not (Install-Package "Loguru" "loguru" 14 15)) { exit 1 }

# 15. Reconnaissance faciale (optionnel)
Write-Host "[15/15] Installation reconnaissance faciale (optionnel)..." -ForegroundColor Yellow
pip install onnxruntime insightface
if ($LASTEXITCODE -ne 0) {
    Write-Host "ATTENTION: InsightFace a echoue (optionnel)" -ForegroundColor Yellow
    Write-Host "Le systeme peut fonctionner sans" -ForegroundColor Yellow
} else {
    Write-Host "✓ Reconnaissance faciale installee" -ForegroundColor Green
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Installation terminee !" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Verification des imports..." -ForegroundColor Yellow
python -c "import fastapi; import ultralytics; import torch; print('✓ Tous les imports essentiels fonctionnent')"

Write-Host ""
Write-Host "Vous pouvez maintenant lancer: python run.py" -ForegroundColor Green
Write-Host ""
