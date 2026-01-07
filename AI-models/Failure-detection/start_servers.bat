@echo off
echo Starting Predictive Maintenance Backend Servers...
echo.

echo Starting Flask Server (Port 5002)...
start cmd /k "cd flask_server && venv\Scripts\activate && python app.py"

timeout /t 5 /nobreak >nul

echo Starting Express Server (Port 3002)...
start cmd /k "cd express_server && npm start"

echo.
echo Both servers are starting...
echo Flask:   http://localhost:5002
echo Express: http://localhost:3002
echo API Docs: http://localhost:3002/api/docs
echo.
echo After servers start, run: python test_api.py
echo.

pause
