@echo off
REM Test Phase 4 Diagnostic Features Only

echo ========================================
echo Phase 4 Diagnostic Tests
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

REM Run Phase 4 tests
echo Running Phase 4 diagnostic tests...
echo.
echo Test 1: Diagnostic Service Tests (18 tests)
echo ----------------------------------------
flutter test test/core/diagnostic_service_test.dart
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Diagnostic service tests failed!
    pause
    exit /b 1
)
echo.

echo Test 2: ChatBot Controller Diagnostic Tests (15 tests)
echo --------------------------------------------------------
flutter test test/core/chatbot_controller_diagnostic_test.dart
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Controller diagnostic tests failed!
    pause
    exit /b 1
)
echo.

echo ========================================
echo Phase 4 Tests: PASSED
echo ========================================
echo.
echo All 33 Phase 4 diagnostic tests passed!
echo.
pause
