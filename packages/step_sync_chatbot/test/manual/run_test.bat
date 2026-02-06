@echo off
REM Manual Test Runner for Groq API Integration
REM
REM Usage: run_test.bat

echo ================================================================
echo   Groq API Manual Test Runner
echo ================================================================
echo.

REM Check if GROQ_API_KEY is set
if "%GROQ_API_KEY%"=="" (
    echo [ERROR] GROQ_API_KEY environment variable not set!
    echo.
    echo Please set your API key first:
    echo   $env:GROQ_API_KEY="your_key_here"
    echo.
    echo Get your key from: https://console.groq.com/keys
    echo.
    pause
    exit /b 1
)

echo [1/3] API Key found: %GROQ_API_KEY:~0,12%...
echo.

REM Get Flutter/Dart path
set FLUTTER_PATH=C:\flutter\bin
if not exist "%FLUTTER_PATH%\dart.bat" (
    echo [ERROR] Flutter not found at %FLUTTER_PATH%
    echo.
    echo Please update FLUTTER_PATH in this script or add Flutter to PATH
    echo.
    pause
    exit /b 1
)

echo [2/3] Flutter/Dart found
echo.

REM Navigate to package root
cd /d "%~dp0..\.."

echo [3/3] Running manual tests...
echo.
echo ----------------------------------------------------------------
echo.

REM Run the test
"%FLUTTER_PATH%\dart.bat" test\manual\groq_api_test.dart

echo.
echo ----------------------------------------------------------------
echo.

if %ERRORLEVEL% EQU 0 (
    echo ✓ Tests completed successfully!
    echo.
    echo Next steps:
    echo   1. Review the responses above
    echo   2. Fill out TEST_RESULTS_TEMPLATE.md
    echo   3. Check usage at https://console.groq.com/
) else (
    echo ✗ Tests failed with error code %ERRORLEVEL%
    echo.
    echo Check the output above for error details
)

echo.
pause
