# Batch Scripts Guide

This project includes several batch scripts (.bat files) to make development easier on Windows.

## 📁 Available Scripts

### 1. Master Menu (Root Directory)

**Location**: `C:\ChatBot_StepSync\run.bat`

**Usage**: Double-click `run.bat` in the root directory

**Features**: Interactive menu with all common operations:
- Full setup (install + generate + test)
- Quick test
- Phase 4 tests only
- Run example app
- Install dependencies only
- Generate code only
- Open in VS Code
- Open project folder

### 2. Full Setup and Test

**Location**: `packages\step_sync_chatbot\setup_and_test.bat`

**Usage**: Double-click or run from command line

**What it does**:
1. ✅ Checks if Flutter is installed
2. 📦 Installs all dependencies (`flutter pub get`)
3. 🔧 Generates code with build_runner
4. 🧪 Runs all tests (60+ tests)

**When to use**: First time setup or after pulling major changes

### 3. Quick Test

**Location**: `packages\step_sync_chatbot\quick_test.bat`

**Usage**: Double-click or run from command line

**What it does**:
- Runs all tests quickly (skips dependency install and code generation)

**When to use**: After making code changes, want to verify tests still pass

### 4. Phase 4 Diagnostic Tests

**Location**: `packages\step_sync_chatbot\test_phase4.bat`

**Usage**: Double-click or run from command line

**What it does**:
- Runs only Phase 4 diagnostic tests (33 tests)
- Test 1: Diagnostic Service Tests (18 tests)
- Test 2: ChatBot Controller Diagnostic Tests (15 tests)

**When to use**: Verifying Phase 4 implementation or after changing diagnostic code

### 5. Run Example App

**Location**: `packages\step_sync_chatbot\example\run_example.bat`

**Usage**: Double-click or run from command line

**What it does**:
- Shows connected devices/emulators
- Lets you choose where to run the app:
  - Chrome (web)
  - Windows (desktop)
  - Android device/emulator
  - iOS device/simulator
  - Default device

**When to use**: Testing the chatbot UI and features

## 🚀 Quick Start

### First Time Setup

1. **Option A - Using Master Menu** (Recommended):
   ```
   Double-click: C:\ChatBot_StepSync\run.bat
   Select: 1 (Full Setup)
   ```

2. **Option B - Direct Script**:
   ```
   Double-click: C:\ChatBot_StepSync\packages\step_sync_chatbot\setup_and_test.bat
   ```

### After Making Changes

1. **Run tests**:
   ```
   Double-click: packages\step_sync_chatbot\quick_test.bat
   ```

2. **Test Phase 4 only**:
   ```
   Double-click: packages\step_sync_chatbot\test_phase4.bat
   ```

### Run Example App

```
Double-click: packages\step_sync_chatbot\example\run_example.bat
```

## ❓ Troubleshooting

### "Flutter is not installed or not in PATH"

**Solution**:
1. Install Flutter from https://flutter.dev
2. Add Flutter to your System PATH:
   - Right-click "This PC" → Properties
   - Advanced System Settings → Environment Variables
   - Edit "Path" variable
   - Add Flutter bin directory (e.g., `C:\flutter\bin`)
3. Restart Command Prompt
4. Run script again

### "Tests failed"

**Solution**:
1. Check the error message in the console
2. Make sure you ran `flutter pub get` first
3. Make sure you ran `build_runner` to generate code
4. Check if any files are missing

### "Code generation failed"

**Solution**:
1. Delete the `.dart_tool` folder
2. Run `flutter clean`
3. Run `flutter pub get`
4. Run build_runner again

## 🎯 Script Execution Order

For first-time setup, scripts should be run in this order:

1. `flutter pub get` - Install dependencies
2. `flutter pub run build_runner build` - Generate code
3. `flutter test` - Run tests

The **setup_and_test.bat** script does all three automatically.

## 📊 Expected Output

### Successful Full Setup

```
========================================
Step Sync ChatBot - Setup and Test
========================================

[INFO] Flutter found:
Flutter 3.x.x • channel stable

Step 1/3: Installing Dependencies
Running: flutter pub get
✓ Got dependencies!

Step 2/3: Generating Code
Running: flutter pub run build_runner build
✓ Generated 15 outputs

Step 3/3: Running Tests
Running: flutter test
00:05 +60: All tests passed!

========================================
Setup Complete!
========================================

Phase 4 Implementation: COMPLETE
```

### Successful Phase 4 Tests

```
========================================
Phase 4 Diagnostic Tests
========================================

Test 1: Diagnostic Service Tests (18 tests)
00:02 +18: All tests passed!

Test 2: ChatBot Controller Diagnostic Tests (15 tests)
00:03 +15: All tests passed!

========================================
Phase 4 Tests: PASSED
========================================

All 33 Phase 4 diagnostic tests passed!
```

## 🔧 Manual Commands (Alternative)

If batch scripts don't work, use these manual commands:

### Command Prompt / PowerShell

```cmd
cd C:\ChatBot_StepSync\packages\step_sync_chatbot

# Install dependencies
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Run all tests
flutter test

# Run specific test file
flutter test test/core/diagnostic_service_test.dart

# Run example app
cd example
flutter run
```

### Git Bash

```bash
cd /c/ChatBot_StepSync/packages/step_sync_chatbot

# Install dependencies
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Run all tests
flutter test

# Run example app
cd example
flutter run
```

## 🎨 VS Code Integration

If you prefer using VS Code:

1. Open the project in VS Code
2. Open integrated terminal (Ctrl + `)
3. Run commands directly in the terminal

VS Code usually has Flutter in PATH automatically if you have the Flutter extension installed.

## 📝 Notes

- All batch scripts include error checking
- Scripts will pause on error to show the error message
- Press any key to continue after script completes
- Scripts show clear progress indicators
- Master menu (`run.bat`) provides easy access to all operations

## 🎯 Recommended Workflow

1. **First time**: Run `run.bat` → Option 1 (Full Setup)
2. **Daily work**: Make code changes → Run `quick_test.bat`
3. **Before commit**: Run `quick_test.bat` to ensure all tests pass
4. **Testing UI**: Run `example\run_example.bat`
5. **Phase 4 specific**: Run `test_phase4.bat` after diagnostic changes

---

**Need Help?**
- Check Flutter installation: `flutter doctor`
- Check Flutter version: `flutter --version`
- Clean project: `flutter clean`
- Update dependencies: `flutter pub upgrade`
