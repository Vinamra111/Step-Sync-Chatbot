# Quick Start Guide

## 🚀 Fastest Way to Get Started

### Option 1: Using Batch Scripts (Windows - Recommended)

**Double-click one of these files**:

1. **Full Setup** (First time or after updates):
   ```
   setup_and_test.bat
   ```
   This will install dependencies, generate code, and run all tests.

2. **Quick Test** (After making changes):
   ```
   quick_test.bat
   ```
   This will run all tests without reinstalling dependencies.

3. **Phase 4 Tests Only**:
   ```
   test_phase4.bat
   ```
   This will run only the 33 diagnostic tests from Phase 4.

4. **Run Example App**:
   ```
   example\run_example.bat
   ```
   This will launch the example app on your device/emulator.

### Option 2: Command Line

Open Command Prompt or PowerShell in this directory and run:

```cmd
# Full setup
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter test

# Quick test
flutter test

# Run example
cd example
flutter run
```

## ✅ What to Expect

### After running setup_and_test.bat:

```
✓ Dependencies installed (device_info_plus, url_launcher, etc.)
✓ Code generated (Freezed models for diagnostics)
✓ 60+ tests passed (all phases)
```

### Test Breakdown:
- Phase 1: Core chatbot, intents, templates (~20 tests)
- Phase 2: Real health service integration (~12 tests)
- Phase 3: SQLite conversation persistence (15 tests)
- Phase 4: Enhanced diagnostics (33 tests)

## 📱 Try the Example App

1. Connect an Android device or start an emulator
2. Run `example\run_example.bat`
3. Choose device from menu
4. Try these features:
   - "check status" - Run comprehensive diagnostics
   - "grant permission" - Test permission flow
   - "steps not syncing" - Test troubleshooting flow

## 🐛 Troubleshooting

### "Flutter not found"
- Install Flutter: https://flutter.dev
- Add to PATH: `C:\flutter\bin`
- Restart terminal

### "Build failed"
```cmd
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### "Tests failed"
- Check error message
- Ensure dependencies installed: `flutter pub get`
- Ensure code generated: `flutter pub run build_runner build`

## 📚 Full Documentation

See the complete guide: `..\..\BATCH_SCRIPTS_GUIDE.md`

## 🎯 Phase 4 Features

This package now includes:
- ✅ Platform detection (Android API levels, iOS version)
- ✅ Comprehensive diagnostics (permissions, platform, data sources)
- ✅ Automatic issue detection
- ✅ Actionable quick replies
- ✅ Guided remediation flows
- ✅ 33 comprehensive tests

---

**Ready?** Double-click `setup_and_test.bat` to begin! 🚀
