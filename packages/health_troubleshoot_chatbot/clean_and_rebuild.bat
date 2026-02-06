@echo off
REM Clean and Rebuild Script
REM Use this if you're having build issues or want a fresh start

echo ========================================
echo Step Sync ChatBot - Clean and Rebuild
echo ========================================
echo.
echo WARNING: This will delete generated files and cache
echo.
set /p confirm="Are you sure you want to continue? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo Cancelled.
    pause
    exit /b 0
)
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

REM Step 1: Flutter clean
echo ========================================
echo Step 1/5: Running Flutter Clean
echo ========================================
flutter clean
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter clean failed!
    pause
    exit /b 1
)
echo [SUCCESS] Flutter clean complete
echo.

REM Step 2: Delete build_runner cache
echo ========================================
echo Step 2/5: Deleting Build Runner Cache
echo ========================================
if exist .dart_tool\build (
    rmdir /s /q .dart_tool\build
    echo [SUCCESS] Build runner cache deleted
) else (
    echo [INFO] No build runner cache found
)
echo.

REM Step 3: Delete generated files
echo ========================================
echo Step 3/5: Deleting Generated Files
echo ========================================
echo Deleting *.freezed.dart and *.g.dart files...
for /r %%f in (*.freezed.dart) do (
    del /q "%%f"
    echo Deleted: %%f
)
for /r %%f in (*.g.dart) do (
    del /q "%%f"
    echo Deleted: %%f
)
echo [SUCCESS] Generated files deleted
echo.

REM Step 4: Install dependencies
echo ========================================
echo Step 4/5: Installing Dependencies
echo ========================================
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to install dependencies!
    pause
    exit /b 1
)
echo [SUCCESS] Dependencies installed
echo.

REM Step 5: Generate code
echo ========================================
echo Step 5/5: Generating Code
echo ========================================
echo This may take 10-30 seconds...
flutter pub run build_runner build --delete-conflicting-outputs
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to generate code!
    pause
    exit /b 1
)
echo [SUCCESS] Code generation complete
echo.

REM Summary
echo ========================================
echo Clean and Rebuild Complete!
echo ========================================
echo.
echo All steps completed successfully:
echo   [x] Flutter clean
echo   [x] Cache deleted
echo   [x] Generated files deleted
echo   [x] Dependencies reinstalled
echo   [x] Code regenerated
echo.
echo You can now run tests with: quick_test.bat
echo.
pause
