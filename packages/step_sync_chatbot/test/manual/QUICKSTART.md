# Quick Start - Groq API Manual Testing

## 🚀 5-Minute Setup

### 1. Get API Key
```
https://console.groq.com/keys
```
Click "Create API Key" → Copy key (starts with `gsk_`)

### 2. Set Environment Variable

**Windows PowerShell:**
```powershell
$env:GROQ_API_KEY="gsk_your_key_here"
```

**Linux/Mac:**
```bash
export GROQ_API_KEY="gsk_your_key_here"
```

### 3. Run Test

```bash
cd C:\ChatBot_StepSync\packages\step_sync_chatbot
C:\flutter\bin\dart.bat test\manual\groq_api_test.dart
```

### 4. Expected Output

```
══════════════════════════════════════════════════
  GROQ API MANUAL TEST
══════════════════════════════════════════════════

✅ API key found
✅ Services initialized

TEST 1: Basic Conversation Flow
──────────────────────────────────────────────────
Bot Response:
Oh no! Let me help you get your steps tracking...
──────────────────────────────────────────────────

[... 4 more tests ...]

✅ ALL TESTS COMPLETE
```

---

## ✅ What to Check

For each response, verify:

- **Natural tone** (not robotic)
- **Helpful content** (actionable advice)
- **Privacy** (no PHI in output)
- **Context awareness** (references previous messages)
- **Empathy** (acknowledges frustration)

---

## 🐛 Common Issues

### "API key not set"
```powershell
# Check if set
echo $env:GROQ_API_KEY

# Set again
$env:GROQ_API_KEY="your_key"
```

### "Rate limit exceeded"
Wait 60 seconds, then retry.

### "Connection error"
Check: https://status.groq.com/

---

## 📊 Check Usage

After testing:
1. Go to https://console.groq.com/
2. Click "Usage"
3. View your API calls (~5 calls, ~3500 tokens)

---

## ✨ Success Criteria

- [x] All 5 tests run without errors
- [x] Responses are natural and helpful
- [x] Privacy sanitization working
- [x] Context tracking across turns

**If all pass → You're ready for production!** 🎉

---

For detailed guide, see: `MANUAL_TESTING_GUIDE.md`
