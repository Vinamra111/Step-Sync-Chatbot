# Contributing to Step Sync ChatBot

Thank you for your interest in contributing to Step Sync ChatBot! This document provides guidelines and instructions for contributing to this project.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Process](#development-process)
- [Pull Request Process](#pull-request-process)
- [Coding Guidelines](#coding-guidelines)
- [Testing Guidelines](#testing-guidelines)
- [Documentation Guidelines](#documentation-guidelines)
- [Privacy & Security Guidelines](#privacy--security-guidelines)

## 🤝 Code of Conduct

### Our Pledge

We pledge to make participation in our project a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, gender identity and expression, level of experience, nationality, personal appearance, race, religion, or sexual identity and orientation.

### Our Standards

**Positive behaviors**:
- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

**Unacceptable behaviors**:
- Trolling, insulting/derogatory comments, personal or political attacks
- Public or private harassment
- Publishing others' private information without permission
- Other conduct which could reasonably be considered inappropriate

## 🚀 Getting Started

### Prerequisites

- Flutter 3.10 or higher
- Dart 3.0 or higher
- Git
- A GitHub account
- Android Studio / VS Code (recommended)

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork:

```bash
git clone https://github.com/YOUR_USERNAME/ChatBot_StepSync.git
cd ChatBot_StepSync
```

3. Add upstream remote:

```bash
git remote add upstream https://github.com/ORIGINAL_OWNER/ChatBot_StepSync.git
```

### Setup Development Environment

```bash
# Navigate to package
cd packages/step_sync_chatbot

# Install dependencies
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Run tests
flutter test

# Run example
cd example
flutter run
```

Or use batch scripts (Windows):

```bash
# Full setup
setup_and_test.bat
```

## 🔄 Development Process

### 1. Create a Branch

```bash
# Update your fork
git fetch upstream
git checkout main
git merge upstream/main

# Create feature branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/bug-description
```

### Branch Naming Conventions

- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation updates
- `test/description` - Test additions/fixes
- `refactor/description` - Code refactoring
- `perf/description` - Performance improvements

### 2. Make Changes

- Write clean, readable code
- Follow Dart/Flutter best practices
- Add tests for new functionality
- Update documentation as needed
- Keep commits atomic and well-described

### 3. Commit Changes

```bash
# Stage changes
git add .

# Commit with descriptive message
git commit -m "feat: add LLM cost tracking feature

- Implement cost calculation per query
- Add monthly cost projections
- Update usage statistics
- Add tests for cost tracking

Closes #123"
```

### Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation only
- `style` - Code style changes (formatting, etc.)
- `refactor` - Code refactoring
- `test` - Adding or updating tests
- `chore` - Maintenance tasks

**Examples**:

```bash
feat(llm): add Azure OpenAI provider integration

fix(privacy): correct PII detection for phone numbers

docs(readme): update installation instructions

test(diagnostics): add tests for battery optimization detection
```

### 4. Push Changes

```bash
git push origin feature/your-feature-name
```

## 📬 Pull Request Process

### Before Submitting

1. **Run Tests**: Ensure all tests pass

```bash
flutter test
```

2. **Format Code**: Format your code

```bash
flutter format .
```

3. **Analyze Code**: Check for issues

```bash
flutter analyze
```

4. **Update Documentation**: Update relevant docs

5. **Update CHANGELOG**: Add entry to CHANGELOG.md

### Submitting Pull Request

1. Go to your fork on GitHub
2. Click "New Pull Request"
3. Select your branch
4. Fill out the PR template:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## How Has This Been Tested?
Describe the tests you ran

## Checklist
- [ ] My code follows the style guidelines
- [ ] I have performed a self-review
- [ ] I have commented my code where necessary
- [ ] I have updated the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or feature works
- [ ] New and existing unit tests pass locally
- [ ] Any dependent changes have been merged

## Screenshots (if applicable)
Add screenshots to demonstrate changes

## Related Issues
Closes #123
```

### Review Process

1. **Automated Checks**: CI/CD runs tests automatically
2. **Code Review**: Maintainers review your code
3. **Feedback**: Address any requested changes
4. **Approval**: Once approved, your PR will be merged

## 📝 Coding Guidelines

### Dart Style Guide

Follow [Effective Dart](https://dart.dev/guides/language/effective-dart):

**Good**:
```dart
// Clear, descriptive names
Future<List<StepData>> getStepData({
  required DateTime startDate,
  required DateTime endDate,
}) async {
  // Implementation
}

// Proper documentation
/// Fetches step data for the specified date range.
///
/// Returns a list of [StepData] objects, one per day.
/// Throws [HealthServiceException] if data cannot be fetched.
Future<List<StepData>> getStepData(...) async { ... }
```

**Bad**:
```dart
// Unclear names, no docs
Future<List<StepData>> getData(DateTime d1, DateTime d2) async {
  // No documentation
}
```

### Code Organization

```dart
// 1. Imports (sorted)
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';

import '../models/step_data.dart';
import '../services/health_service.dart';

// 2. Class definition
class MyWidget extends StatelessWidget {
  // 3. Static constants
  static const double padding = 16.0;

  // 4. Instance fields
  final String title;
  final VoidCallback? onTap;

  // 5. Constructor
  const MyWidget({
    Key? key,
    required this.title,
    this.onTap,
  }) : super(key: key);

  // 6. Overrides
  @override
  Widget build(BuildContext context) {
    return Container(...);
  }

  // 7. Private methods
  void _handleTap() {
    onTap?.call();
  }
}
```

### Naming Conventions

```dart
// Classes: PascalCase
class ChatBotController { }

// Methods/Functions: camelCase
void handleUserMessage() { }

// Variables: camelCase
final userName = 'John';

// Constants: lowerCamelCase
const maxRetries = 3;

// Private members: _leadingUnderscore
String _apiKey;
void _internalMethod() { }

// Enums: PascalCase
enum UserIntent { greeting, help }
```

### Error Handling

```dart
// Use try-catch for expected errors
try {
  final data = await healthService.getStepData(...);
  return data;
} on HealthServiceException catch (e) {
  logger.error('Failed to fetch step data: $e');
  return <StepData>[];
} catch (e) {
  logger.error('Unexpected error: $e');
  rethrow;
}

// Use assert for development checks
assert(userId.isNotEmpty, 'userId cannot be empty');

// Return error objects instead of throwing (when appropriate)
class Result<T> {
  final T? data;
  final String? error;
  bool get isSuccess => error == null;
}
```

## 🧪 Testing Guidelines

### Test Coverage Requirements

- **Minimum**: 80% code coverage
- **Critical paths**: 100% coverage
- **Privacy/security code**: 100% coverage

### Test Structure

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:step_sync_chatbot/step_sync_chatbot.dart';

void main() {
  group('FeatureName', () {
    late DependencyA dependencyA;
    late SystemUnderTest sut;

    setUp(() {
      // Arrange - Set up test dependencies
      dependencyA = MockDependencyA();
      sut = SystemUnderTest(dependencyA: dependencyA);
    });

    tearDown(() {
      // Clean up if needed
      sut.dispose();
    });

    group('specificMethod', () {
      test('should do expected behavior when condition', () {
        // Arrange
        final input = 'test input';

        // Act
        final result = sut.specificMethod(input);

        // Assert
        expect(result, expectedOutput);
      });

      test('should throw exception when invalid input', () {
        // Arrange
        final invalidInput = '';

        // Act & Assert
        expect(
          () => sut.specificMethod(invalidInput),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
```

### Test Types

**Unit Tests** - Test individual functions/methods:
```dart
test('sanitizes step counts correctly', () {
  final detector = PIIDetector();
  final result = detector.sanitize('I walked 10000 steps');
  expect(result.sanitizedText, 'I walked [NUMBER] steps');
});
```

**Widget Tests** - Test UI components:
```dart
testWidgets('displays user message correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ChatMessageWidget(
        message: ChatMessage.user(text: 'Hello'),
      ),
    ),
  );

  expect(find.text('Hello'), findsOneWidget);
});
```

**Integration Tests** - Test feature flows:
```dart
testWidgets('full conversation flow', (tester) async {
  // Test complete user interaction
});
```

### Running Tests

```bash
# All tests
flutter test

# Specific file
flutter test test/privacy/pii_detector_test.dart

# With coverage
flutter test --coverage

# Watch mode (re-run on changes)
flutter test --watch
```

## 📚 Documentation Guidelines

### Code Documentation

**Public APIs** - Always document:
```dart
/// Detects and sanitizes PHI/PII from text.
///
/// This service ensures that no sensitive information is sent to
/// external AI services by detecting and removing or replacing
/// personal health information.
///
/// Example:
/// ```dart
/// final detector = PIIDetector();
/// final result = detector.sanitize('I walked 10000 steps yesterday');
/// print(result.sanitizedText); // "I walked [NUMBER] steps recently"
/// ```
///
/// See also:
/// - [SanitizationResult] for detailed results
/// - [EntityType] for types of detected entities
class PIIDetector {
  /// Sanitize the given [text] and return results.
  ///
  /// Returns [SanitizationResult] containing:
  /// - Sanitized text safe for transmission
  /// - List of detected entities
  /// - Safety flag indicating if text can be sent
  ///
  /// Throws [ArgumentError] if [text] is null.
  SanitizationResult sanitize(String text) { ... }
}
```

**Internal methods** - Document complex logic:
```dart
// Cleans timestamps older than 1 hour for rate limiting
void _cleanOldTimestamps(List<DateTime> timestamps, DateTime now) {
  final oneHourAgo = now.subtract(const Duration(hours: 1));
  timestamps.removeWhere((timestamp) => timestamp.isBefore(oneHourAgo));
}
```

### README Updates

When adding features, update relevant READMEs:

- Main README.md - If it affects overall project
- Package README.md - If it affects package usage
- CHANGELOG.md - Always update with changes

### Example Code

Provide working examples:

```dart
/// Example usage:
/// ```dart
/// // Create Azure OpenAI provider
/// final provider = AzureOpenAIProvider(
///   endpoint: 'https://your-resource.openai.azure.com',
///   apiKey: 'your-api-key',
///   deploymentName: 'gpt-4o-mini',
/// );
///
/// // Generate response
/// final response = await provider.generateResponse(
///   prompt: 'Help me with step syncing',
/// );
///
/// print(response.text);
/// ```
```

## 🔒 Privacy & Security Guidelines

### Critical Rules

1. **NEVER commit secrets**:
   - API keys
   - Passwords
   - Private keys
   - Credentials

2. **NEVER log sensitive data**:
   - PHI/PII
   - API keys
   - User credentials

3. **ALWAYS sanitize before sending to cloud**:
   - Use PIIDetector
   - Verify isSafe flag
   - Block critical PII

### Security Checklist

Before submitting code with security implications:

- [ ] No hardcoded secrets
- [ ] Input validation for all user data
- [ ] Proper error handling (no info leakage)
- [ ] HTTPS only for API calls
- [ ] Sensitive data encrypted at rest
- [ ] PHI/PII sanitization tested
- [ ] Rate limiting in place
- [ ] Audit logging (if applicable)

### Testing Privacy Code

```dart
test('blocks sending when critical PII detected', () {
  final detector = PIIDetector();

  // Test cases that should be blocked
  final criticalCases = [
    'john@example.com',
    '123-456-7890',
    'I\'m John Doe',
  ];

  for (final input in criticalCases) {
    final result = detector.sanitize(input);
    expect(result.isSafe, isFalse, reason: 'Should block: $input');
  }
});
```

## 🐛 Reporting Bugs

### Security Vulnerabilities

**DO NOT** open a public issue for security vulnerabilities.

Instead:
1. Email: security@example.com
2. Include:
   - Description of vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### Regular Bugs

Open a GitHub issue with:

```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce:
1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots.

**Environment:**
- Flutter version: [e.g., 3.10.0]
- Dart version: [e.g., 3.0.0]
- Platform: [e.g., Android 13, iOS 16]
- Package version: [e.g., 0.5.0]

**Additional context**
Any other relevant information.
```

## 💡 Suggesting Features

Open a GitHub issue with:

```markdown
**Is your feature request related to a problem?**
A clear description of the problem.

**Describe the solution you'd like**
A clear description of what you want to happen.

**Describe alternatives you've considered**
Other solutions you've thought about.

**Additional context**
Mockups, examples, or other information.
```

## ❓ Questions

Have questions? Here's how to get help:

1. **Check Documentation**: README, phase summaries, code comments
2. **Search Issues**: Someone may have asked before
3. **GitHub Discussions**: Ask the community
4. **Open an Issue**: Use the "question" label

## 🎉 Recognition

Contributors will be recognized in:

- CONTRIBUTORS.md file
- Release notes
- GitHub contributors page

Thank you for contributing to Step Sync ChatBot! 🚀

---

**Last Updated**: January 12, 2026
