@echo off
REM Quick Test Script - Run tests only (skip dependencies and code generation)

echo ========================================
echo Step Sync ChatBot - Quick Test
echo ========================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter is not installed or not in PATH!
    pause
    exit /b 1
)

REM Navigate to package directory
cd /d "%~dp0"
echo [INFO] Working directory: %CD%
echo.

REM Run tests
echo Running tests...
echo.
flutter test
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Tests failed!
    pause
    exit /b 1
)
echo.
echo [SUCCESS] All tests passed!
echo.
pause
