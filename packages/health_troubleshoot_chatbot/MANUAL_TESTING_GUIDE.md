# Manual Testing Guide - Groq API Integration

## 🎯 Purpose

This guide walks you through manual testing of the LLM integration with the **real Groq API**. After completing this, you'll have verified that:

- ✅ Groq API integration works correctly
- ✅ Conversations are natural and helpful
- ✅ Privacy sanitization protects PHI
- ✅ Context tracking works across multiple turns
- ✅ Sentiment detection influences responses appropriately

---

## 📋 Prerequisites

1. **Groq API Account** (Free tier available)
2. **Dart SDK** (comes with Flutter)
3. **Test files** in this repository

---

## 🔑 Step 1: Get Your Groq API Key

### 1.1 Create Groq Account

1. Go to [https://console.groq.com/](https://console.groq.com/)
2. Click **"Sign Up"** or **"Login"**
3. Complete registration (GitHub or email)

### 1.2 Generate API Key

1. Navigate to [https://console.groq.com/keys](https://console.groq.com/keys)
2. Click **"Create API Key"**
3. Give it a name (e.g., "StepSync Testing")
4. Click **"Create"**
5. **Copy the key immediately** (it won't be shown again)

Example key format: `gsk_1234abcd...` (starts with `gsk_`)

### 1.3 Important: Free Tier Limits

Groq's free tier includes:
- **30 requests per minute**
- **6,000 requests per day**
- **No credit card required**

Perfect for testing! 🎉

---

## 💻 Step 2: Set Up Environment

### Windows (PowerShell)

```powershell
# Set the API key for current session
$env:GROQ_API_KEY="your_key_here"

# Or set permanently (optional)
[Environment]::SetEnvironmentVariable("GROQ_API_KEY", "your_key_here", "User")
```

### Linux/Mac (Terminal)

```bash
# Set for current session
export GROQ_API_KEY="your_key_here"

# Or add to ~/.bashrc or ~/.zshrc for permanent (optional)
echo 'export GROQ_API_KEY="your_key_here"' >> ~/.bashrc
source ~/.bashrc
```

### Verify Setup

```bash
# Windows PowerShell
echo $env:GROQ_API_KEY

# Linux/Mac
echo $GROQ_API_KEY
```

You should see your API key printed. ✅

---

## 🚀 Step 3: Run the Manual Test

### 3.1 Navigate to Project

```bash
cd C:\ChatBot_StepSync\packages\step_sync_chatbot
```

### 3.2 Get Dependencies (if needed)

```bash
C:\flutter\bin\flutter.bat pub get
```

### 3.3 Run the Test Script

```bash
C:\flutter\bin\dart.bat test\manual\groq_api_test.dart
```

### Expected Output

You should see:

```
══════════════════════════════════════════════════════════════════════
  GROQ API MANUAL TEST - LLM Integration Verification
══════════════════════════════════════════════════════════════════════

✅ API key found (gsk_1234...)

Initializing services...
✅ Services initialized

──────────────────────────────────────────────────────────────────────
TEST 1: Basic Conversation Flow
──────────────────────────────────────────────────────────────────────
User: "my steps arent working"
Intent: stepsNotSyncing
Generating response...

Response Time: 847ms
──────────────────────────────────────────────────────────────────────
Bot Response:
Oh no! Let me help you get your steps tracking again. I'll run a quick
diagnostic to see what might be blocking your step sync...
[... continues with helpful response ...]
──────────────────────────────────────────────────────────────────────

[... more tests ...]
```

---

## 📊 Step 4: Evaluate Test Results

For each test, manually verify the response quality:

### Test 1: Basic Conversation ✅

**Check for:**
- [ ] Natural, conversational tone (not robotic)
- [ ] Acknowledges the user's issue
- [ ] Offers specific help or next steps
- [ ] No technical jargon
- [ ] Appropriate length (2-4 sentences)

### Test 2: Frustrated User ✅

**Check for:**
- [ ] Empathy shown first ("I understand", "I get it")
- [ ] Acknowledges frustration explicitly
- [ ] Reassuring tone
- [ ] Action-oriented (quick solution offered)
- [ ] No dismissiveness

### Test 3: Diagnostic Scenario ✅

**Check for:**
- [ ] References diagnostic findings
- [ ] Explains battery optimization issue clearly
- [ ] Provides step-by-step guidance
- [ ] Prioritizes most important issue first

### Test 4: Privacy Sanitization ✅

**Check for:**
- [ ] Specific numbers sanitized (10,000 → [NUMBER])
- [ ] Device names sanitized (iPhone 15 → [DEVICE])
- [ ] App names sanitized (Google Fit → [APP])
- [ ] Response doesn't contain original PHI
- [ ] Response still makes sense

**Example:**
```
Input:      "I walked 10,000 steps yesterday"
Sanitized:  "I walked [NUMBER] steps [TIME]"
✅ Sanitized?: YES
Changes:    10,000 → [NUMBER], yesterday → [TIME]
```

### Test 5: Multi-Turn Conversation ✅

**Check for:**
- [ ] Bot remembers Samsung Health from Turn 1
- [ ] "it" correctly resolves to Samsung Health
- [ ] Response references previous context
- [ ] Natural conversation flow
- [ ] No repetition from previous turn

---

## 🎨 Step 5: Advanced Testing (Optional)

### Test Additional Scenarios

Create a file `test/manual/custom_test.dart`:

```dart
import 'dart:io';
import 'package:step_sync_chatbot/src/services/groq_chat_service.dart';
import 'package:step_sync_chatbot/src/services/phi_sanitizer_service.dart';
import 'package:step_sync_chatbot/src/conversation/llm_response_generator.dart';
import 'package:step_sync_chatbot/src/conversation/conversation_context.dart';
import 'package:step_sync_chatbot/src/core/intents.dart';

void main() async {
  final apiKey = Platform.environment['GROQ_API_KEY']!;
  final groqService = GroqChatService(apiKey: apiKey);
  final phiSanitizer = PHISanitizerService();
  final llmGenerator = LLMResponseGenerator(
    groqService: groqService,
    phiSanitizer: phiSanitizer,
  );

  // YOUR CUSTOM TEST HERE
  final context = ConversationContext();
  context.addUserMessage('your test message');

  final response = await llmGenerator.generate(
    userMessage: 'your test message',
    intent: UserIntent.needHelp, // Choose appropriate intent
    context: context,
  );

  print('Response: $response');
}
```

Run it:
```bash
dart test/manual/custom_test.dart
```

### Test Edge Cases

Try these challenging scenarios:

1. **Very long user message** (test truncation)
2. **Multiple PHI types** (email + phone + numbers)
3. **Rapid back-and-forth** (10+ turns)
4. **Mixed languages** (if applicable)
5. **Profanity/inappropriate content** (test safety)

---

## 📈 Step 6: Monitor API Usage

### Check Your Groq Dashboard

1. Go to [https://console.groq.com/](https://console.groq.com/)
2. Click **"Usage"** in sidebar
3. View your API calls:
   - Requests made
   - Tokens used
   - Response times
   - Error rates

### Expected Usage for Test Suite

- **5 API calls** (one per test)
- **~3,500 tokens total** (prompt + completion)
- **Cost: $0.00** (free tier)
- **Time: ~5 seconds total**

---

## 🔍 Step 7: Troubleshooting

### Issue: "API key not set"

**Solution:**
```bash
# Verify key is set
echo $env:GROQ_API_KEY  # Windows
echo $GROQ_API_KEY      # Linux/Mac

# Re-set if needed
$env:GROQ_API_KEY="your_key"  # Windows
export GROQ_API_KEY="your_key"  # Linux/Mac
```

### Issue: "Rate limit exceeded"

**Solution:**
- Wait 1 minute
- Check Groq dashboard for usage
- Reduce test frequency

### Issue: "Connection timeout"

**Solution:**
- Check internet connection
- Verify Groq status: [https://status.groq.com/](https://status.groq.com/)
- Retry in 30 seconds

### Issue: "Invalid API key"

**Solution:**
- Verify key starts with `gsk_`
- Regenerate key in Groq console
- Check for copy/paste errors (no spaces)

### Issue: "Poor response quality"

**Possible causes:**
- Prompt engineering needs adjustment
- Model temperature too high/low
- Context not being passed correctly
- PHI sanitization too aggressive

**Check:**
1. Review `llm_response_generator.dart` system prompt
2. Verify context is building correctly
3. Test with mock LLM to isolate issue

---

## ✅ Step 8: Success Criteria

After manual testing, you should have:

- [x] **All 5 tests completed** without errors
- [x] **Response quality verified** for each test
- [x] **Privacy sanitization working** correctly
- [x] **Context tracking working** across turns
- [x] **API usage visible** in Groq dashboard
- [x] **Confidence at 98%+** for production readiness

---

## 📝 Step 9: Document Your Results

Fill out this checklist:

```
MANUAL TEST RESULTS
Date: _______________
Tester: _______________
API Key: gsk_________... (first 8 chars)

Test Results:
[ ] Test 1: Basic Conversation - PASS/FAIL
[ ] Test 2: Frustrated User - PASS/FAIL
[ ] Test 3: Diagnostic Scenario - PASS/FAIL
[ ] Test 4: Privacy Sanitization - PASS/FAIL
[ ] Test 5: Multi-Turn Conversation - PASS/FAIL

Response Quality (1-5 scale):
- Natural tone: ___/5
- Helpfulness: ___/5
- Empathy: ___/5
- Actionability: ___/5
- Context awareness: ___/5

Issues Found:
1. ___________________________________
2. ___________________________________
3. ___________________________________

Overall Assessment:
[ ] Ready for production
[ ] Minor improvements needed
[ ] Major issues - not ready

Notes:
_________________________________________
_________________________________________
_________________________________________
```

---

## 🎉 Next Steps After Testing

### If All Tests Pass ✅

1. **Integrate into main app**
   - Add Groq service to your app's dependency injection
   - Wire up chat UI to LLM generator
   - Configure rate limiting

2. **Deploy to beta**
   - Start with 5-10% of users
   - Monitor API costs daily
   - Collect user feedback

3. **Monitor production**
   - Set up alerts for API errors
   - Track response quality metrics
   - Monitor costs (should be ~$0.001/query)

### If Tests Fail ❌

1. **Review error logs**
2. **Check troubleshooting section**
3. **Run unit tests to isolate issue**
4. **Adjust prompts/configuration**
5. **Re-test until passing**

---

## 💡 Tips for Best Results

1. **Test during off-peak hours** to avoid rate limits
2. **Keep API key secure** - never commit to git
3. **Review all responses** - don't just check for errors
4. **Test edge cases** beyond the provided scenarios
5. **Check Groq dashboard** after each test run

---

## 📞 Support

- **Groq Docs:** https://console.groq.com/docs/
- **Groq Community:** https://discord.gg/groq
- **Groq Status:** https://status.groq.com/

---

## 🔒 Security Reminders

- ⚠️ **Never commit API keys to git**
- ⚠️ **Use environment variables only**
- ⚠️ **Rotate keys regularly** (every 90 days)
- ⚠️ **Monitor usage** for suspicious activity
- ⚠️ **Verify PHI sanitization** before production

---

**Good luck with your testing!** 🚀

If all tests pass, your LLM integration is **production-ready**! 🎉
