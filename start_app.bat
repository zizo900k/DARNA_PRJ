@echo off
title DARNA Project Launcher
echo Starting DARNA Project...

echo Starting Backend (port 8888)...
start "Backend" cmd /k "cd backend && php artisan serve --port=8888"

echo Starting Reverb...
start "Reverb" cmd /k "cd backend && php artisan reverb:start"

echo Starting Queue Worker...
start "Queue Worker" cmd /k "cd backend && php artisan queue:work --tries=3 --timeout=60"

echo Starting Frontend (port 3000)...
start "Frontend" cmd /k "cd frontend && flutter run -d chrome --web-port 3000 --web-hostname localhost"

echo All services started in separate windows!
exit
