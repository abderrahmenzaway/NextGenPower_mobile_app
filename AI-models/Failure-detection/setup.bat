@echo off
echo ========================================
echo Predictive Maintenance Backend Setup
echo ========================================
echo.

echo Step 1: Setting up Flask Server...
echo -----------------------------------
cd flask_server
if not exist ".env" (
    echo Creating .env file...
    copy .env.example .env
)
echo.

echo Installing Python dependencies...
pip install -r requirements.txt
echo.

echo Step 2: Setting up Express Server...
echo -----------------------------------
cd ..\express_server
if not exist ".env" (
    echo Creating .env file...
    copy .env.example .env
)
echo.

echo Installing Node.js dependencies...
call npm install
echo.

cd ..

echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo To start the servers:
echo.
echo Terminal 1 (Flask):
echo   cd flask_server
echo   python app.py
echo.
echo Terminal 2 (Express):
echo   cd express_server
echo   npm start
echo.
echo ========================================

pause
