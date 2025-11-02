@echo off
echo ==========================================
echo Installation progressive des dependances
echo ==========================================
echo.

echo [1/15] Installation FastAPI...
pip install fastapi
if %errorlevel% neq 0 (
    echo ERREUR: FastAPI
    pause
    exit /b 1
)

echo [2/15] Installation Uvicorn...
pip install "uvicorn[standard]"
if %errorlevel% neq 0 (
    echo ERREUR: Uvicorn
    pause
    exit /b 1
)

echo [3/15] Installation Pydantic...
pip install pydantic pydantic-settings
if %errorlevel% neq 0 (
    echo ERREUR: Pydantic
    pause
    exit /b 1
)

echo [4/15] Installation SQLAlchemy...
pip install sqlalchemy
if %errorlevel% neq 0 (
    echo ERREUR: SQLAlchemy
    pause
    exit /b 1
)

echo [5/15] Installation python-dotenv...
pip install python-dotenv
if %errorlevel% neq 0 (
    echo ERREUR: python-dotenv
    pause
    exit /b 1
)

echo [6/15] Installation python-multipart...
pip install python-multipart
if %errorlevel% neq 0 (
    echo ERREUR: python-multipart
    pause
    exit /b 1
)

echo [7/15] Installation NumPy...
pip install numpy
if %errorlevel% neq 0 (
    echo ERREUR: NumPy
    pause
    exit /b 1
)

echo [8/15] Installation Pillow...
pip install pillow
if %errorlevel% neq 0 (
    echo ERREUR: Pillow
    pause
    exit /b 1
)

echo [9/15] Installation OpenCV...
pip install opencv-python
if %errorlevel% neq 0 (
    echo ERREUR: OpenCV
    pause
    exit /b 1
)

echo [10/15] Installation PyTorch (cela peut prendre du temps)...
pip install torch torchvision
if %errorlevel% neq 0 (
    echo ERREUR: PyTorch
    pause
    exit /b 1
)

echo [11/15] Installation Ultralytics YOLO...
pip install ultralytics
if %errorlevel% neq 0 (
    echo ERREUR: Ultralytics
    pause
    exit /b 1
)

echo [12/15] Installation securite (JWT, passlib)...
pip install python-jose[cryptography] passlib[bcrypt]
if %errorlevel% neq 0 (
    echo ERREUR: Securite
    pause
    exit /b 1
)

echo [13/15] Installation utilitaires...
pip install httpx requests python-dateutil pytz aiofiles
if %errorlevel% neq 0 (
    echo ERREUR: Utilitaires
    pause
    exit /b 1
)

echo [14/15] Installation logs...
pip install loguru
if %errorlevel% neq 0 (
    echo ERREUR: Loguru
    pause
    exit /b 1
)

echo [15/15] Installation reconnaissance faciale (optionnel)...
pip install onnxruntime insightface
if %errorlevel% neq 0 (
    echo ATTENTION: InsightFace a echoue (optionnel)
    echo Le systeme peut fonctionner sans
)

echo.
echo ==========================================
echo Installation terminee !
echo ==========================================
echo.
echo Verification des imports...
python -c "import fastapi; import ultralytics; import torch; print('OK: Tous les imports essentiels fonctionnent')"

echo.
echo Vous pouvez maintenant lancer: python run.py
pause
