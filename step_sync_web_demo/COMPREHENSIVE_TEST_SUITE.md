# Comprehensive Test Suite - Replace Support Page with ChatBot

## Goal
Test if our chatbot can replace the entire "Step Sync Support & Troubleshooting Guide" page with conversational AI support.

## Test Categories from Support Page

### Category 1: ANDROID SYNC ISSUES (Health Connect)
### Category 2: iOS SYNC ISSUES (Apple Health)
### Category 3: PERMISSIONS & SETUP
### Category 4: DATA ACCURACY & SYNCING
### Category 5: COMPATIBILITY & TECHNICAL
### Category 6: PRIVACY & DATA
### Category 7: FEATURES & FUNCTIONALITY

---

## TEST EXECUTION PLAN

Each test will be evaluated on:
1. **Response Quality** (1-10): Is answer helpful and accurate?
2. **Conversation Flow** (1-10): Does it follow greeting→discovery→solution?
3. **Formatting** (1-10): Proper **bold**, bullets, readability?
4. **Tone** (1-10): Friendly, empathetic, professional?
5. **Accuracy** (1-10): Technically correct advice?

**Confidence Score Formula:** (Total/50) × 100 = X% confidence

---

# CATEGORY 1: ANDROID SYNC ISSUES

## Test 1.1: Health Connect Permissions
**User Input:** "Why aren't my steps updating after I granted permission on Android?"

**Expected Response:**
- Ask: Which Android version? Which app?
- Suggest: Check Health Connect app is updated, restart device, verify app has background data
- Explain: Permissions alone aren't enough, Health Connect needs to be active

**Success Criteria:**
- ✓ Asks 1-2 clarifying questions
- ✓ Mentions Health Connect specifically
- ✓ Provides 2-3 actionable steps
- ✓ Uses proper formatting

**Test Result:** [TO BE FILLED]

**Scores:**
- Response Quality: __/10
- Conversation Flow: __/10
- Formatting: __/10
- Tone: __/10
- Accuracy: __/10
- **Total: __/50 (Confidence: __%)**

---

## Test 1.2: Health Connect Installation
**User Input:** "What if Health Connect isn't installed on my phone?"

**Expected Response:**
- Ask: What Android version?
- Explain: Android 14+ has it built-in, older needs separate app
- Provide: Link to Play Store or explain how to check
- Guide: How to verify if it's installed

**Test Result:** [TO BE FILLED]
**Confidence: __%**

---

## Test 1.3: Background Data Android
**User Input:** "My Android stops tracking steps when I close the app"

**Expected Response:**
- Ask: Which app? Recent updates?
- Identify: Battery optimization issue
- Guide: Settings → Battery → App → Don't optimize
- Also check: Background data enabled

**Test Result:** [TO BE FILLED]
**Confidence: __%**

---

# CATEGORY 2: iOS SYNC ISSUES

## Test 2.1: iOS Permission After Update
**User Input:** "My iPhone steps stopped syncing after iOS update"

**Expected Response:**
- Empathy: "iOS updates can reset permissions"
- Ask: Which app? When did you update?
- Guide: Settings → Privacy → Motion & Fitness → enable
- Suggest: Restart iPhone after re-enabling

**Test Result:** [TO BE FILLED]
**Confidence: __%**

---

## Test 2.2: Apple Watch Sync Mismatch
**User Input:** "Why are my steps showing on my Apple Watch but not in the app?"

**Expected Response:**
- Ask: Which app? Is it connected to Apple Health?
- Explain: Apple Watch → Apple Health → App sync chain
- Check: Apple Health permissions for the app
- Verify: Watch is properly paired

**Test Result:** [TO BE FILLED]
**Confidence: __%**

---

## Test 2.3: Low Power Mode Impact
**User Input:** "Does iPhone Low Power Mode affect step syncing?"

**Expected Response:**
- Confirm: Yes, it can pause background sync
- Explain: Low Power Mode restricts background activity
- Guide: Either disable Low Power Mode or manually sync when active
- Reassure: Steps are still counted, just delayed

**Test Result:** [TO BE FILLED]
**Confidence: __%**

---

# CATEGORY 3: PERMISSIONS & SETUP

## Test 3.1: Permission Denial Recovery
**User Input:** "I accidentally denied permissions, how do I fix it?"

**Expected Response:**
- Reassure: Easy to fix!
- Ask: iOS or Android?
- Guide for iOS: Settings → [App] → enable permissions
- Guide for Android: Settings → Apps → [App] → Permissions

**Test Result:** [TO BE FILLED]
**Confidence: __%**

---

## Test 3.2: What Permissions Are Needed
**User Input:** "What permissions does the app need to track steps?"

**Expected Response:**
- List clearly:
  - **Motion & Fitness** (iOS) or **Activity Recognition** (Android)
  - **Health Connect access** (Android 14+) or **HealthKit** (iOS)
- Explain WHY each is needed
- Reassure: Data stays private

**Test Result:** [TO BE FILLED]
**Confidence: __%**

---

# CATEGORY 4: DATA ACCURACY & SYNCING

## Test 4.1: Step Count Mismatch
**User Input:** "My steps in the app don't match what's in Apple Health. Why?"

**Expected Response:**
- Ask: Which is higher? By how much?
- Common causes:
  - Multiple apps counting (duplication)
  - Different data sources (phone vs watch)
  - Manual entries included
- Guide: Check data sources in Health app

**Test Result:** [TO BE FILLED]
**Confidence: __%**

---

## Test 4.2: Missing Historical Data
**User Input:** "Steps from yesterday aren't showing up"

**Expected Response:**
- Ask: Did you have the app installed yesterday? Permissions granted?
- Explain: App can only access data after permissions granted
- Can't retroactively get data if permissions were off
- Check: Health Connect/Apple Health has the data

**Test Result:** [TO BE FILLED]
**Confidence: __%**

---

## Test 4.3: Manual Refresh Not Working
**User Input:** "Why aren't my steps syncing even after pressing refresh?"

**Expected Response:**
- Ask: How long has it been? Any error messages?
- Check:
  - Internet connection
  - App has background data
  - Health Connect/Apple Health permissions
- Try: Force quit app and reopen

**Test Result:** [TO BE FILLED]
**Confidence: __%**

---

## Test 4.4: Sync Frequency
**User Input:** "How often does my step data sync?"

**Expected Response:**
- Answer clearly: Usually every 15-30 minutes automatically
- Can vary based on:
  - Battery optimization settings
  - Network connectivity
  - App activity
- Note: Manual refresh always works

**Test Result:** [TO BE FILLED]
**Confidence: __%**

---

# CATEGORY 5: COMPATIBILITY & TECHNICAL

## Test 5.1: Web Version Sync Issues
**User Input:** "I'm using the web version of Habit Health. Why are my steps not syncing?"

**Expected Response:**
- Explain: Web version can't directly access Health Connect/Apple Health
- Must use: Mobile app to track steps
- Web shows: Data synced from mobile app
- Workaround: Use mobile app for step tracking, web for other features

**Test Result:** [TO BE FILLED]
**Confidence: __%**

---

## Test 5.2: Fitness Band Compatibility
**User Input:** "Can I sync steps from fitness bands like Fitbit?"

**Expected Response:**
- Ask: Which fitness band?
- Explain: If band syncs to Apple Health/Health Connect, then yes
- Guide: Connect band to Health app first, then our app reads from there
- List: Compatible bands (Fitbit, Garmin, etc. that support Health integration)

**Test Result:** [TO BE FILLED]
**Confidence: __%**

---

## Test 5.3: Multiple Apps Connected
**User Input:** "What apps can I connect with for step tracking?"

**Expected Response:**
- Core: Apple Health (iOS), Health Connect (Android)
- Through those: Fitbit, Google Fit, Samsung Health, Garmin, etc.
- Explain: We read from Health platform, not directly from apps
- Benefit: Don't need individual app integrations

**Test Result:** [TO BE FILLED]
**Confidence: __%**

---

## Test 5.4: Minimum OS Requirements
**User Input:** "What are the minimum iOS and Android versions required?"

**Expected Response:**
- iOS: iOS 12.0 or higher (for HealthKit)
- Android:
  - Android 6.0+ for basic features
  - Android 14+ has Health Connect built-in
  - Android 9-13 needs separate Health Connect app
- Recommend: Latest OS version for best experience

**Test Result:** [TO BE FILLED]
**Confidence: __%**

---

## Test 5.5: Multiple Devices
**User Input:** "Can I sync data from multiple devices?"

**Expected Response:**
- Yes: Apple Health/Health Connect aggregates from all devices
- Examples: iPhone + Apple Watch, or multiple Android devices
- Caution: Watch for duplicate counting if multiple apps track same activity
- Best practice: Use one primary device/app

**Test Result:** [TO BE FILLED]
**Confidence: __%**

---

# CATEGORY 6: PRIVACY & DATA

## Test 6.1: Data Sharing Concerns
**User Input:** "Is my data shared with other platforms or users?"

**Expected Response:**
- Reassure: NO, data is private
- Explain: Only you can see your health data
- Technical: Data stays in your Health app, we only read what you permit
- Privacy policy: Link to full policy if needed

**Test Result:** [TO BE FILLED]
**Confidence: __%**

---

## Test 6.2: Turning Off Sync
**User Input:** "What happens if I turn off sync permissions?"

**Expected Response:**
- Answer: Steps will stop syncing to the app
- Clarify: Your device still counts steps, just not shared with app
- Impact: Challenges/streaks may be affected
- Reversible: Can re-enable anytime

**Test Result:** [TO BE FILLED]
**Confidence: __%**

---

# CATEGORY 7: FEATURES & FUNCTIONALITY

## Test 7.1: Background Syncing
**User Input:** "How can I make sure my steps are updating even when I'm not actively using the app?"

**Expected Response:**
- Enable background sync:
  - **Android:** Disable battery optimization, enable background data
  - **iOS:** Keep Motion & Fitness on, avoid Low Power Mode when possible
- App will sync automatically in background
- Check: Notification settings allow background activity

**Test Result:** [TO BE FILLED]
**Confidence: __%**

---

## Test 7.2: Manual Entry
**User Input:** "Can I enter steps manually?"

**Expected Response:**
- Ask: Why do you need manual entry? (Device dead, forgot to wear watch, etc.)
- Explain: Yes, through Apple Health or Health Connect directly
- Guide: Open Health app → add manual data
- Note: Will appear in our app after sync

**Test Result:** [TO BE FILLED]
**Confidence: __%**

---

## Test 7.3: Streak System
**User Input:** "Will my streak be affected if my steps didn't sync on time?"

**Expected Response:**
- Ask: How long ago did steps sync? Still same day?
- Explain: Streaks usually count by end of day
- Solution: Make sure to sync before midnight
- If already lost: May need to contact support for manual review

**Test Result:** [TO BE FILLED]
**Confidence: __%**

---

## Test 7.4: Streak Explanation
**User Input:** "What is a 'streak,' and how does it work?"

**Expected Response:**
- Explain: Consecutive days meeting step goal
- Example: If goal is 10,000 steps, hitting it 7 days = 7-day streak
- Benefit: Motivation, achievements, rewards
- Tip: Enable notifications to track progress

**Test Result:** [TO BE FILLED]
**Confidence: __%**

---

## Test 7.5: Notifications
**User Input:** "What happens if I switch off notifications?"

**Expected Response:**
- Impact: Won't get reminders/progress updates
- Still works: Step tracking continues
- Miss: Goal reminders, streak alerts, challenges updates
- Recommend: Keep notifications on for motivation

**Test Result:** [TO BE FILLED]
**Confidence: __%**

---

## Test 7.6: Daily Sync Requirement
**User Input:** "Do I need to open Apple Health / Health Connect every day for syncing?"

**Expected Response:**
- Answer: NO, automatic background sync
- Health platform: Always running in background
- Our app: Syncs automatically if permissions enabled
- Only manual: If you disabled auto-sync

**Test Result:** [TO BE FILLED]
**Confidence: __%**

---

# EDGE CASE TESTS

## Test E.1: Completely Vague
**User Input:** "help"

**Expected:** Asks what they need help with, lists common issues
**Confidence: __%**

---

## Test E.2: Frustrated User
**User Input:** "This app NEVER works! My steps are ALWAYS wrong!"

**Expected:** Shows empathy, asks specific questions calmly, doesn't get defensive
**Confidence: __%**

---

## Test E.3: Technical Jargon
**User Input:** "Is the API throttling my Health Connect queries?"

**Expected:** Handles technical question, explains in simpler terms too
**Confidence: __%**

---

## Test E.4: Off-Topic
**User Input:** "How do I lose weight?"

**Expected:** Politely redirects to step tracking, mentions focus is technical support
**Confidence: __%**

---

## Test E.5: Multiple Issues at Once
**User Input:** "My steps don't sync, battery drains fast, app crashes, and I can't login"

**Expected:** Prioritizes, suggests tackling one at a time, asks which is most urgent
**Confidence: __%**

---

# CATEGORY 8: APP-INTEGRATED ACTIONS (System-Level Capabilities)

## Test A.1: Auto Permission Check
**User Input:** "Can you check if I have the right permissions enabled?"

**Expected:** Chatbot triggers permission diagnostic, reports current status (Motion & Fitness, Health Connect/HealthKit), offers to fix if missing
**Confidence: __%**

---

## Test A.2: Battery Optimization Detection
**User Input:** "Why does my app stop syncing in the background?"

**Expected:** Automatically checks battery optimization status (Android), explains issue, provides "Fix Now" button that opens Settings
**Confidence: __%**

---

## Test A.3: Low Power Mode Detection
**User Input:** "My iPhone battery is low and steps stopped syncing"

**Expected:** Detects iOS Low Power Mode is enabled, explains it pauses background sync, offers to open Settings or suggests disabling it
**Confidence: __%**

---

## Test A.4: Data Source Conflict Resolution
**User Input:** "My step count is showing differently in different apps"

**Expected:** Detects multiple data sources, shows UI dialog with all sources (phone, watch, fitness apps), allows user to select primary source
**Confidence: __%**

---

## Test A.5: Direct Settings Navigation
**User Input:** "Take me to the permission settings"

**Expected:** Opens device Settings app directly to the correct page (iOS: Settings → [App] → Permissions, Android: Settings → Apps → [App])
**Confidence: __%**

---

## Test A.6: Run Full Diagnostics
**User Input:** "Run a full diagnostic check"

**Expected:** Executes comprehensive diagnostic:
- ✓ Permissions status
- ✓ Battery optimization (Android)
- ✓ Low Power Mode (iOS)
- ✓ Data sources detected
- ✓ Last sync time
- ✓ Network connectivity
Shows actionable report with "Fix" buttons
**Confidence: __%**

---

## Test A.7: Guided Onboarding Trigger
**User Input:** "I'm new here, can you help me set everything up?"

**Expected:** Launches guided onboarding flow:
1. Welcome screen
2. Permission grant step-by-step
3. Data source selection
4. Completion confirmation
**Confidence: __%**

---

## Test A.8: Quick Reply Actions
**User Input:** [User clicks "Check My Steps" quick reply button]

**Expected:** Triggers step count query, shows current steps, last sync time, data source used
**Confidence: __%**

---

## Test A.9: Context-Aware Action Buttons
**User Input:** "My steps aren't syncing" → Bot responds with diagnostic results

**Expected:** Shows context-aware quick reply buttons:
- "Grant Permission" (if missing)
- "Fix Battery Optimization" (if enabled)
- "Change Data Source" (if multiple detected)
- "Try Again"
**Confidence: __%**

---

## Test A.10: PHI Sanitization Validation
**User Input:** "My heart rate is 145 bpm and I have diabetes"

**Expected:**
- ✓ Blocks critical PHI from being sent to LLM
- ✓ Sanitizes message before API call
- ✓ Redirects to technical focus
- ✓ Logs sanitization event
- ✓ ZERO medical data in API logs
**Confidence: __%**

---

# CATEGORY 9: REAL USER SCENARIOS (Natural Language & Frustration)

## Test R.1: Completely Lost User
**User Input:** "help"

**Expected:** Doesn't list 20 things - asks warm "What's going on?" or "What can I help with today?"
**Confidence: __%**

---

## Test R.2: Frustrated & Vague
**User Input:** "this doesnt work"

**Expected:** Shows empathy, asks specifically what isn't working (steps not showing? not syncing? wrong numbers?)
**Confidence: __%**

---

## Test R.3: Angry User with Typos
**User Input:** "i granted premission and its still not workng!!!!"

**Expected:**
- Handles typos (premission → permission, workng → working)
- Shows empathy for frustration
- Asks follow-up (which device, which app, when granted)
**Confidence: __%**

---

## Test R.4: Impatient User
**User Input:** "just fix it"

**Expected:** Politely explains need for info, asks 1-2 quick questions (device type, what's not working)
**Confidence: __%**

---

## Test R.5: Non-Technical User
**User Input:** "the numbers thing isnt right"

**Expected:** Understands "numbers thing" = step count, asks clarifying questions in simple terms
**Confidence: __%**

---

## Test R.6: User Tried Everything
**User Input:** "I already tried everything nothing works I give up"

**Expected:**
- Empathy + encouragement
- Asks what specifically they tried
- Offers systematic diagnostic check
**Confidence: __%**

---

## Test R.7: Late Night Panic
**User Input:** "its 2am and my steps are gone where are they"

**Expected:**
- Calm reassuring tone
- Explains steps don't disappear, likely sync issue
- Asks when they last saw steps
**Confidence: __%**

---

## Test R.8: Comparison Question
**User Input:** "why does google fit show 8000 steps but your app shows 5000"

**Expected:**
- Explains different data sources
- Asks which is primary source
- Offers data source selection tool
**Confidence: __%**

---

## Test R.9: Blame the App
**User Input:** "your app is broken it never syncs"

**Expected:**
- Doesn't get defensive
- Empathy: "I understand that's frustrating"
- Asks diagnostic questions to find root cause
**Confidence: __%**

---

## Test R.10: Mixed Language & Context
**User Input:** "bro my phone died and now the steps r all messed up idk what happened"

**Expected:**
- Handles informal "bro", "r", "idk"
- Understands phone died might have reset settings
- Asks if they re-granted permissions after phone restart
**Confidence: __%**

---

## Test R.11: Feature Request as Problem
**User Input:** "can it track my water intake too?"

**Expected:**
- Politely explains focus is step tracking
- Redirects to step tracking help
- Doesn't promise features that don't exist
**Confidence: __%**

---

## Test R.12: Urgent Pre-Event
**User Input:** "i have a competition tomorrow and my steps arent showing please help urgent"

**Expected:**
- Acknowledges urgency
- Prioritizes quickest fix first
- Asks key diagnostic questions rapidly
**Confidence: __%**

---

# OVERALL EVALUATION CRITERIA

After completing all tests:

**Category Scores:**
- Android Sync Issues: __/3 tests passed
- iOS Sync Issues: __/3 tests passed
- Permissions & Setup: __/2 tests passed
- Data Accuracy: __/4 tests passed
- Compatibility: __/5 tests passed
- Privacy & Data: __/2 tests passed
- Features: __/6 tests passed
- Edge Cases: __/5 tests passed
- **App-Integrated Actions: __/10 tests passed** ⭐ NEW
- **Real User Scenarios: __/12 tests passed** ⭐ NEW

**TOTAL: __/54 tests passed** (expanded from 32 to include app actions + real user patterns)

**Final Confidence Rating:**
- 48-54 tests (89-100%): ✅ **PRODUCTION READY** - Can replace support page + handle app integration
- 40-47 tests (74-87%): ⚠️ **NEEDS MINOR TWEAKS** - Almost there
- 30-39 tests (56-72%): ⚠️ **NEEDS WORK** - Major improvements needed
- Below 30 (< 56%): ❌ **NOT READY** - Significant issues

---

# EXECUTION INSTRUCTIONS

1. Start with Category 1, Test 1.1
2. Type the exact user input into the live chatbot
3. Evaluate the response using the 5 criteria (1-10 each)
4. Calculate confidence score
5. Document any issues or excellent responses
6. Move to next test
7. Report results after every 5 tests

**Ready to begin systematic testing!**
