# Step_Sync ChatBot - Production Deployment Guide

## Table of Contents
1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Configuration](#configuration)
3. [Security Hardening](#security-hardening)
4. [Monitoring Setup](#monitoring-setup)
5. [Incident Response](#incident-response)
6. [Performance Tuning](#performance-tuning)
7. [Troubleshooting](#troubleshooting)

---

## Pre-Deployment Checklist

### ✅ Code Quality
- [ ] All tests passing (61 new tests + existing tests)
- [ ] No TODO or FIXME comments in production code
- [ ] Code review completed by security team
- [ ] Static analysis passed (dartanalyzer, flutter analyze)
- [ ] No debug logging in production builds

### ✅ Security Audit
- [ ] PHI sanitization verified (all user input sanitized)
- [ ] Database encryption enabled (SQLCipher with 256-bit AES)
- [ ] Encryption keys stored securely (flutter_secure_storage)
- [ ] No PHI in log files (audit completed)
- [ ] Exception messages sanitized (no PHI in error strings)
- [ ] API keys stored securely (never in code)

### ✅ HIPAA Compliance
- [ ] Business Associate Agreement (BAA) signed with LLM provider
- [ ] Data retention policy configured (90 days default)
- [ ] Audit logging enabled for all PHI access
- [ ] Access controls implemented
- [ ] Breach notification procedures documented

### ✅ Performance Validation
- [ ] Load testing completed (100+ concurrent users)
- [ ] Chaos testing passed (14/14 tests)
- [ ] Memory leak testing passed
- [ ] Database performance validated
- [ ] Circuit breaker tested under failures

---

## Configuration

### 1. Environment Variables

Create a `.env.production` file with the following variables:

```bash
# LLM API Configuration
GROQ_API_KEY=your_production_api_key_here
GROQ_API_BASE_URL=https://api.groq.com/openai/v1
GROQ_MODEL=mixtral-8x7b-32768

# Database Configuration
DATABASE_NAME=step_sync_conversations_prod.db
DATABASE_ENCRYPTION_ENABLED=true
DATABASE_VERSION=1

# Security Configuration
PHI_SANITIZER_STRICT_MODE=true
ENABLE_WAL_MODE=true

# Performance Configuration
MAX_MESSAGES_PER_SESSION=20
CLEANUP_INTERVAL_MINUTES=60
SESSION_TIMEOUT_HOURS=24

# Circuit Breaker Configuration
CIRCUIT_BREAKER_FAILURE_THRESHOLD=5
CIRCUIT_BREAKER_SUCCESS_THRESHOLD=2
CIRCUIT_BREAKER_TIMEOUT_SECONDS=60

# Rate Limiting
RATE_LIMIT_CALLS_PER_HOUR=100
RATE_LIMIT_CALLS_PER_USER_HOUR=50
```

### 2. Groq Chat Service Configuration

```dart
final groqService = GroqChatService(
  config: GroqConfig(
    apiKey: Platform.environment['GROQ_API_KEY']!,
    model: 'mixtral-8x7b-32768', // Production model
    maxTokens: 1024,
    temperature: 0.7,
    timeout: Duration(seconds: 30),
    maxRetries: 3,
  ),
  logger: Logger(
    level: Level.warning, // Only warnings and errors in production
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: false, // Disable colors for log aggregation
      printEmojis: false,
    ),
  ),
);
```

### 3. Database Persistence Configuration

```dart
final persistenceService = ConversationPersistenceService(
  config: PersistenceConfig(
    databaseName: 'step_sync_conversations_prod.db',
    databaseVersion: 1,
    enableWAL: true, // Write-Ahead Logging for better concurrency
    maxRetries: 3,
    enableEncryption: true, // MUST be true for HIPAA
  ),
);
await persistenceService.initialize();
```

### 4. Memory Manager Configuration

```dart
final memoryManager = ThreadSafeMemoryManager(
  memoryManager: ConversationMemoryManager(
    config: MemoryConfig(
      maxMessages: 20, // Limit per session
      cleanupInterval: Duration(hours: 1),
      sessionTimeout: Duration(hours: 24),
    ),
  ),
  persistenceService: persistenceService,
);
```

### 5. Circuit Breaker Configuration

```dart
final circuitBreaker = CircuitBreaker(
  config: CircuitBreakerConfig(
    failureThreshold: 5, // Open after 5 failures
    successThreshold: 2, // Close after 2 successes
    timeout: Duration(seconds: 60), // Try again after 60s
  ),
);
```

---

## Security Hardening

### 1. Encryption Key Management

**CRITICAL**: Never hardcode encryption keys. Use `flutter_secure_storage`.

```dart
// ✅ CORRECT - Production
final keyManager = EncryptionKeyManager(
  storage: FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  ),
);

// ❌ INCORRECT - Never do this!
// final key = 'hardcoded_key_123';
```

### 2. API Key Security

**Store API keys securely**:

1. **Android**: Use ProGuard/R8 for obfuscation
   ```gradle
   buildTypes {
     release {
       minifyEnabled true
       proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
     }
   }
   ```

2. **iOS**: Use Keychain for API key storage
   ```swift
   // Store in Keychain, never in Info.plist or code
   ```

3. **Backend Proxy**: Recommended approach
   ```
   Flutter App → Your Backend → Groq API
   (No API key) (API key stored) (API call)
   ```

### 3. Network Security

**Enable certificate pinning** for API calls:

```dart
final client = HttpClient()
  ..badCertificateCallback = (X509Certificate cert, String host, int port) {
    // Implement certificate pinning
    return cert.sha256.toString() == expectedCertFingerprint;
  };
```

**Use HTTPS only**:
```dart
// ✅ Always HTTPS
const apiUrl = 'https://api.groq.com/openai/v1';

// ❌ Never HTTP
// const apiUrl = 'http://api.groq.com/openai/v1';
```

### 4. Input Validation

**Always sanitize user input** before processing:

```dart
final sanitizer = PHISanitizerService(
  strictMode: true, // Throw exception if PHI detected
);

try {
  final result = sanitizer.sanitize(userInput);
  // Use result.sanitizedText for LLM
} catch (e) {
  if (e is PHIDetectedException) {
    // Log incident (without PHI!)
    logger.e('PHI detected in user input - content blocked');
    // Show user-friendly error
    return 'Please avoid sharing personal information';
  }
}
```

---

## Monitoring Setup

### 1. Key Metrics to Monitor

#### Performance Metrics
- **Response Time**: P50, P95, P99 latency for LLM calls
- **Throughput**: Messages processed per second
- **Error Rate**: Failed API calls / Total calls
- **Circuit Breaker State**: Open/Closed/Half-Open duration

#### Resource Metrics
- **Memory Usage**: Total allocated memory, session count
- **Database Size**: Growth rate, query performance
- **API Usage**: Calls per hour, token consumption
- **Rate Limit Hits**: How often limits are reached

#### Security Metrics
- **PHI Detection Rate**: How often PHI is sanitized
- **Strict Mode Violations**: Blocked inputs with critical PHI
- **Failed Auth Attempts**: Invalid API keys
- **Database Encryption Status**: Verify always enabled

### 2. Logging Configuration

**Production Logger Setup**:

```dart
final logger = Logger(
  level: Level.warning, // Only warnings and errors
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 120,
    colors: false,
    printEmojis: false,
    printTime: true,
  ),
  output: MultiOutput([
    ConsoleOutput(),
    FileOutput(file: File('logs/chatbot_${DateTime.now().millisecondsSinceEpoch}.log')),
  ]),
);
```

**Log Levels**:
- `FATAL`: System-critical failures (database corruption, encryption failure)
- `ERROR`: Recoverable errors (API failures, timeout errors)
- `WARN`: Performance degradation, approaching limits
- `INFO`: Disabled in production (use only for deployment verification)
- `DEBUG`: Disabled in production

### 3. Alerting Rules

**Critical Alerts** (Page on-call engineer):
- Database encryption disabled
- PHI detected in logs
- Circuit breaker open for > 5 minutes
- Memory usage > 90%
- Error rate > 10%

**Warning Alerts** (Email/Slack):
- Response time P95 > 3 seconds
- API rate limit hit
- Session capacity > 80%
- Database size > 80% of allocated storage

**Info Notifications**:
- Circuit breaker state changes
- Deployment completed
- Configuration changes

### 4. Health Check Endpoint

Create a health check endpoint for monitoring tools:

```dart
Future<Map<String, dynamic>> healthCheck() async {
  final stats = await memoryManager.getStats();
  final circuitState = circuitBreaker.state;

  return {
    'status': 'healthy',
    'timestamp': DateTime.now().toIso8601String(),
    'database': {
      'encrypted': persistenceService.config.enableEncryption,
      'sessions': stats.activeSessions,
      'messages': stats.totalMessages,
    },
    'circuitBreaker': {
      'state': circuitState.toString(),
      'consecutiveFailures': circuitBreaker.consecutiveFailures,
    },
    'memory': {
      'capacityUsed': stats.capacityUsedPercent.toStringAsFixed(1),
      'isApproachingCapacity': stats.isApproachingCapacity,
    },
  };
}
```

---

## Incident Response

### 1. PHI Exposure Incident

**If PHI is detected in logs or errors**:

1. **IMMEDIATE**:
   - Disable affected service
   - Isolate affected logs/databases
   - Notify security team and legal

2. **Within 24 Hours**:
   - Identify scope of exposure (how many users affected)
   - Determine root cause
   - Document timeline of incident

3. **Within 60 Days** (HIPAA requirement):
   - Notify affected individuals if > 500 people
   - File breach report to HHS
   - Implement corrective measures

**Incident Template**:
```
INCIDENT REPORT: PHI-2026-001

Severity: CRITICAL
Detected: 2026-01-14 10:30 UTC
Resolved: 2026-01-14 11:45 UTC

Description:
PHI detected in exception log file due to detectedContent
field being included in PHIDetectedException.toString().

Scope:
- Affected logs: chatbot_prod_20260114.log
- Users affected: 0 (no external exposure)
- Data exposed: Exception messages (internal only)

Root Cause:
Exception toString() method included sanitized content
which may contain residual PHI.

Fix Applied:
Modified PHIDetectedException.toString() to only include
content length, not actual content.

Lessons Learned:
- All exception messages must be audited for PHI
- Automated testing for exception string safety
```

### 2. Database Encryption Failure

**If encryption key is lost or corrupted**:

1. **IMMEDIATE**:
   - Stop all writes to database
   - Verify backup integrity
   - Check key manager logs

2. **Recovery Steps**:
   ```dart
   // Attempt key recovery
   try {
     final key = await keyManager.getOrGenerateKey();
   } catch (e) {
     // Key unrecoverable - restore from backup
     await restoreFromBackup(latestBackup);
   }
   ```

3. **Prevention**:
   - Daily encrypted backups
   - Key rotation every 90 days
   - Test recovery procedures monthly

### 3. Circuit Breaker Stuck Open

**If circuit breaker won't close**:

1. **Diagnosis**:
   ```dart
   final state = circuitBreaker.state;
   final failures = circuitBreaker.consecutiveFailures;
   final nextAttempt = circuitBreaker.nextAttemptTime;

   logger.e('Circuit breaker analysis: state=$state, failures=$failures, nextAttempt=$nextAttempt');
   ```

2. **Mitigation**:
   - Check LLM API status
   - Verify network connectivity
   - Review recent error logs
   - Consider manual reset: `circuitBreaker.reset()`

3. **User Communication**:
   ```dart
   return ChatResponse(
     content: 'Our AI service is temporarily unavailable. '
              'We\'re working to restore it. Please try again in a few minutes.',
     metadata: {'circuitBreakerOpen': true},
   );
   ```

---

## Performance Tuning

### 1. Database Optimization

**Enable Write-Ahead Logging**:
```dart
await database.execute('PRAGMA journal_mode=WAL');
```

**Optimize Query Performance**:
```sql
-- Already created in schema:
CREATE INDEX idx_messages_session ON messages(session_id);
CREATE INDEX idx_messages_timestamp ON messages(timestamp);
CREATE INDEX idx_sessions_activity ON sessions(last_activity_time);
```

**Regular Maintenance**:
```dart
// Run monthly
await database.execute('VACUUM');
await database.execute('ANALYZE');
```

### 2. Memory Management

**Tune session limits**:
```dart
// For high-volume production (many users, short sessions)
MemoryConfig(
  maxMessages: 20,
  sessionTimeout: Duration(hours: 12),
  cleanupInterval: Duration(minutes: 30),
)

// For enterprise (fewer users, long sessions)
MemoryConfig(
  maxMessages: 50,
  sessionTimeout: Duration(hours: 48),
  cleanupInterval: Duration(hours: 2),
)
```

**Monitor memory growth**:
```dart
Timer.periodic(Duration(minutes: 15), (timer) async {
  final stats = await memoryManager.getStats();

  if (stats.capacityUsedPercent > 80) {
    logger.w('Memory usage high: ${stats.capacityUsedPercent}%');

    // Trigger early cleanup
    await memoryManager.cleanup();
  }
});
```

### 3. API Rate Limiting

**Implement exponential backoff**:
```dart
// Already implemented in GroqChatService
int getBackoffDelay(int attempt) {
  return min(
    config.initialBackoffMs * pow(2, attempt).toInt(),
    config.maxBackoffMs,
  );
}
```

**Monitor rate limit usage**:
```dart
if (callsThisHour >= config.maxCallsPerHour) {
  logger.w('Approaching rate limit: $callsThisHour/${config.maxCallsPerHour}');

  // Notify monitoring
  await metricsClient.incrementCounter('rate_limit_warnings');
}
```

---

## Troubleshooting

### Common Issues

#### 1. "PHI detected after sanitization" Exception

**Symptoms**: `PHIDetectedException` thrown in production

**Causes**:
- User input contains email address, phone number, or SSN
- Sanitization regex not matching new PHI pattern

**Solutions**:
```dart
// Option 1: Use non-strict mode (not recommended for HIPAA)
final sanitizer = PHISanitizerService(strictMode: false);

// Option 2: Add additional sanitization rules
sanitized = sanitized.replaceAll(
  RegExp(r'new_phi_pattern'),
  '[REDACTED]',
);

// Option 3: Catch and handle gracefully
try {
  final result = sanitizer.sanitize(userInput);
} catch (e) {
  if (e is PHIDetectedException) {
    return 'Please rephrase without personal information';
  }
}
```

#### 2. Database Lock Errors

**Symptoms**: `DatabaseException: database is locked`

**Causes**:
- Too many concurrent writes
- Long-running transactions
- WAL mode not enabled

**Solutions**:
```dart
// Enable WAL mode
await database.execute('PRAGMA journal_mode=WAL');

// Increase busy timeout
await database.execute('PRAGMA busy_timeout=5000');

// Use thread-safe wrapper (already implemented)
final threadSafeManager = ThreadSafeMemoryManager(...);
```

#### 3. Memory Leaks

**Symptoms**: Memory usage grows unbounded over time

**Diagnosis**:
```dart
// Check session count over time
Timer.periodic(Duration(minutes: 10), (timer) async {
  final stats = await memoryManager.getStats();
  print('Sessions: ${stats.activeSessions}, Messages: ${stats.totalMessages}');

  // Expected: Both should plateau, not grow linearly
});
```

**Solutions**:
- Verify cleanup is running: Check logs for "Cleaning up X expired sessions"
- Reduce session timeout if needed
- Increase cleanup frequency

#### 4. Circuit Breaker Stuck Open

**Symptoms**: All LLM calls fail with "Circuit breaker open"

**Diagnosis**:
```dart
print('Circuit State: ${circuitBreaker.state}');
print('Failures: ${circuitBreaker.consecutiveFailures}');
print('Next Attempt: ${circuitBreaker.nextAttemptTime}');
```

**Solutions**:
- Wait for timeout to expire (default 60s)
- Check LLM API status
- Manually reset if API is healthy: `circuitBreaker.reset()`

---

## Deployment Checklist

### Pre-Deployment
- [ ] All configuration reviewed and updated
- [ ] Environment variables set correctly
- [ ] Database encryption verified enabled
- [ ] API keys rotated and stored securely
- [ ] Logging configured for production (WARNING level)
- [ ] Monitoring dashboards created
- [ ] Alerting rules configured
- [ ] On-call engineer assigned

### Deployment
- [ ] Deploy to staging environment first
- [ ] Run integration tests on staging
- [ ] Run load tests on staging
- [ ] Verify health check endpoint
- [ ] Deploy to production with blue-green deployment
- [ ] Monitor error rates for 30 minutes
- [ ] Verify no PHI in logs

### Post-Deployment
- [ ] Verify all services healthy
- [ ] Check database encryption status
- [ ] Monitor performance metrics (first 24 hours)
- [ ] Review logs for anomalies
- [ ] Document any incidents
- [ ] Update runbook with new learnings

---

## Support Contacts

### Critical Issues (24/7)
- **Security/PHI Breach**: security@yourcompany.com, +1-XXX-XXX-XXXX
- **On-Call Engineer**: oncall@yourcompany.com, PagerDuty

### Business Hours
- **DevOps**: devops@yourcompany.com
- **Backend Team**: backend@yourcompany.com
- **Product Manager**: pm@yourcompany.com

### External
- **Groq Support**: support@groq.com
- **Flutter Support**: flutter.dev/community

---

## Version History

- **v1.0** (2026-01-14): Initial production deployment guide
  - Added security hardening section
  - Added incident response procedures
  - Added performance tuning guidelines
  - Fixed PHIDetectedException security vulnerability

---

**Document Maintained By**: Engineering Team
**Last Updated**: 2026-01-14
**Next Review**: 2026-04-14 (Quarterly)
