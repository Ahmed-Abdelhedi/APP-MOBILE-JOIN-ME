@echo off
REM Docker Compose - Build and run in one command
REM Simplest way to get started

echo.
echo ========================================
echo  Starting Flutter Dev with Docker Compose
echo ========================================
echo.

docker-compose up --build -d
docker-compose exec flutter-app /bin/bash

echo.
echo To stop the container, run: docker-compose down
