# Manual Testing Suite - Groq API Integration

## 📁 What's in This Folder

This directory contains everything you need to manually test the LLM integration with the real Groq API.

### Files Overview

| File | Purpose |
|------|---------|
| **`groq_api_test.dart`** | Main test script - runs 5 comprehensive tests |
| **`QUICKSTART.md`** | 5-minute quick start guide |
| **`MANUAL_TESTING_GUIDE.md`** | Complete testing guide (detailed) |
| **`TEST_RESULTS_TEMPLATE.md`** | Template to record your test results |
| **`run_test.bat`** | Windows batch script to run tests easily |
| **`README.md`** | This file |

---

## 🚀 Quick Start (30 seconds)

### 1. Get API Key
Visit: https://console.groq.com/keys

### 2. Set Environment Variable
```powershell
$env:GROQ_API_KEY="gsk_your_key_here"
```

### 3. Run Tests

**Option A: Use the batch script (easiest)**
```bash
cd C:\ChatBot_StepSync\packages\step_sync_chatbot\test\manual
run_test.bat
```

**Option B: Run directly**
```bash
cd C:\ChatBot_StepSync\packages\step_sync_chatbot
C:\flutter\bin\dart.bat test\manual\groq_api_test.dart
```

---

## 📚 Which Guide to Use?

### For First-Time Users
👉 Start with **`QUICKSTART.md`**
- 5-minute setup
- Minimal explanations
- Get running fast

### For Detailed Testing
👉 Use **`MANUAL_TESTING_GUIDE.md`**
- Complete setup instructions
- Troubleshooting guide
- Evaluation criteria
- API monitoring
- Security best practices

### For Recording Results
👉 Use **`TEST_RESULTS_TEMPLATE.md`**
- Structured evaluation form
- Quality metrics
- Issue tracking
- Sign-off section

---

## 🧪 What the Tests Do

The test suite (`groq_api_test.dart`) runs 5 comprehensive scenarios:

### Test 1: Basic Conversation Flow ✅
Tests standard troubleshooting interaction.

**User:** "my steps arent working"
**Validates:** Natural tone, helpful content, actionable advice

---

### Test 2: Frustrated User (Empathy) ✅
Tests emotional intelligence and empathy.

**User:** "this is so annoying!!! nothing works!!!"
**Validates:** Empathy first, reassurance, quick solution

---

### Test 3: Diagnostic Scenario ✅
Tests integration with diagnostic results.

**User:** "check my step tracking status"
**Validates:** References diagnostics, explains findings, provides steps

---

### Test 4: Privacy & PHI Sanitization ✅
Tests data sanitization before sending to API.

**Examples:**
- "10,000 steps" → "[NUMBER] steps"
- "iPhone 15" → "[DEVICE]"
- "john@example.com" → **[BLOCKED]**

**Validates:** No PHI leaks to Groq API

---

### Test 5: Multi-Turn Conversation ✅
Tests context tracking across multiple messages.

**Turn 1:** "I use Samsung Health"
**Turn 2:** "it is not syncing" ← (references "it")
**Validates:** Pronoun resolution, context memory

---

## ✅ Success Criteria

After testing, you should have:

- [x] All 5 tests passing
- [x] Natural, helpful responses
- [x] No PHI leakage
- [x] Context working across turns
- [x] Response times < 2 seconds
- [x] API usage visible in Groq dashboard

**If all checked → Ready for production!** 🎉

---

## 📊 Expected Results

### API Usage
- **Calls:** 5
- **Tokens:** ~3,500 total
- **Cost:** $0.00 (free tier)
- **Time:** ~5 seconds

### Response Times
- Average: 500-1000ms
- P95: < 2000ms
- Timeout: 10000ms

---

## 🐛 Common Issues

### "GROQ_API_KEY not set"
```powershell
$env:GROQ_API_KEY="your_key"
```

### "Connection timeout"
Check: https://status.groq.com/

### "Rate limit exceeded"
Wait 60 seconds, then retry.

### "Flutter not found"
Update `FLUTTER_PATH` in `run_test.bat`

---

## 📈 After Testing

### If All Tests Pass ✅
1. Fill out `TEST_RESULTS_TEMPLATE.md`
2. Review responses for quality
3. Check Groq dashboard for usage
4. Get stakeholder approval
5. Deploy to beta

### If Tests Fail ❌
1. Review error messages
2. Check `MANUAL_TESTING_GUIDE.md` troubleshooting
3. Run unit tests: `flutter test test/conversation/`
4. Fix issues and retest

---

## 🔒 Security Reminders

⚠️ **Important:**
- Never commit API keys to git
- Use environment variables only
- Rotate keys every 90 days
- Monitor usage for anomalies
- Verify PHI sanitization before production

---

## 📞 Support Resources

- **Groq Docs:** https://console.groq.com/docs/
- **Groq Discord:** https://discord.gg/groq
- **Groq Status:** https://status.groq.com/
- **API Keys:** https://console.groq.com/keys

---

## 🎯 Testing Checklist

Use this as your testing workflow:

- [ ] **Read** `QUICKSTART.md`
- [ ] **Get** Groq API key
- [ ] **Set** environment variable
- [ ] **Run** `groq_api_test.dart`
- [ ] **Review** all 5 test responses
- [ ] **Fill out** `TEST_RESULTS_TEMPLATE.md`
- [ ] **Check** Groq dashboard usage
- [ ] **Evaluate** readiness for production
- [ ] **Get** stakeholder sign-off

---

## 💡 Pro Tips

1. **Test during off-peak hours** to avoid rate limits
2. **Save your results** - use the template!
3. **Test edge cases** beyond the 5 scenarios
4. **Review Groq dashboard** after every run
5. **Keep API key secure** - never share or commit

---

## 📝 Example Test Run

Here's what you'll see when running the tests:

```
══════════════════════════════════════════════════════════════
  GROQ API MANUAL TEST - LLM Integration Verification
══════════════════════════════════════════════════════════════

✅ API key found (gsk_1234...)

Initializing services...
✅ Services initialized

──────────────────────────────────────────────────────────────
TEST 1: Basic Conversation Flow
──────────────────────────────────────────────────────────────
User: "my steps arent working"
Intent: stepsNotSyncing
Generating response...

Response Time: 847ms
──────────────────────────────────────────────────────────────
Bot Response:
Oh no! Let me help you get your steps tracking again. First,
I'll run a quick diagnostic to see what might be blocking your
sync. This usually takes just a moment...
──────────────────────────────────────────────────────────────

Quality Checks:
  • Should acknowledge the issue
  • Should offer help
  • Should be conversational (not robotic)

[... continues with 4 more tests ...]

══════════════════════════════════════════════════════════════
  ALL TESTS COMPLETE
══════════════════════════════════════════════════════════════

✅ Manual verification successful!

Next steps:
1. Review the responses above for quality
2. Verify privacy sanitization worked correctly
3. Check Groq dashboard for API usage
4. Test with edge cases in your app
```

---

**Ready to start testing?** 🚀

👉 Open `QUICKSTART.md` to begin!

---

Last Updated: 2026-01-14
Test Suite Version: 1.0
