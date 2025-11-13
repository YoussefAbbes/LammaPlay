# 🎮 LamaPlay Quiz System - Complete Guide

## 📋 Table of Contents
1. [System Architecture](#system-architecture)
2. [Complete User Flow](#complete-user-flow)
3. [What I Just Fixed](#what-i-just-fixed)
4. [How Each Component Works](#how-each-component-works)
5. [Database Structure](#database-structure)
6. [Navigation Flow](#navigation-flow)
7. [Testing Guide](#testing-guide)

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        FIREBASE                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Firestore  │  │     Auth     │  │   Storage    │      │
│  │  (Database)  │  │  (Anonymous) │  │   (Images)   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────┐
│                    FLUTTER WEB APP                           │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                    SCREENS                            │  │
│  │  • HomeScreenNew       (Entry point)                 │  │
│  │  • QuizBuilderScreen   (Create quizzes)              │  │
│  │  • SessionLobbyScreen  (Wait for players)            │  │
│  │  • QuestionHostScreen  (Host controls)               │  │
│  │  • QuestionPlayerScreen (Answer questions)           │  │
│  │  • QuestionRevealScreen (See results)                │  │
│  │  • PodiumScreen        (Final leaderboard)           │  │
│  └──────────────────────────────────────────────────────┘  │
│                            ↕                                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                   CONTROLLERS                         │  │
│  │  • SessionController (Session lifecycle management)  │  │
│  └──────────────────────────────────────────────────────┘  │
│                            ↕                                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                   REPOSITORIES                        │  │
│  │  • QuizRepository    (Quiz CRUD operations)          │  │
│  │  • SessionRepository (Session CRUD operations)       │  │
│  └──────────────────────────────────────────────────────┘  │
│                            ↕                                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                    SERVICES                           │  │
│  │  • AuthService       (User authentication)           │  │
│  │  • HostScoringService (Calculate scores)             │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Complete User Flow

### **HOST JOURNEY** 🎩

```
1. Open App
   ↓
2. HomeScreenNew → Toggle to "Host Mode"
   ↓
3. Click "Create Quiz" → QuizBuilderScreenSimple
   ↓
4. Fill in:
   - Quiz title (e.g., "Geography Challenge")
   - Description (optional)
   - Add questions (MCQ, True/False, Image, Numeric, Poll, Order)
   - Set time limits
   - Click "Save"
   ↓
5. Return to HomeScreenNew → Select your quiz from list
   ↓
6. Click "Create Session"
   ↓
7. SessionLobbyScreen appears
   - Shows unique 6-digit PIN (e.g., "123456")
   - Shows list of joined players (updates in real-time)
   - Wait for players to join
   ↓
8. Click "Start" button
   ↓
9. AUTO-NAVIGATE to QuestionHostScreen
   - See current question text and options
   - See timer countdown
   - See "Reveal" button (click when time is up)
   ↓
10. Click "Reveal"
    ↓
11. QuestionRevealScreen shows
    - Correct answer highlighted
    - Player scores calculated
    - Click "Next" for next question
    ↓
12. Repeat steps 9-11 for all questions
    ↓
13. After last question → PodiumScreen
    - Final leaderboard with top 3 players
    - Confetti animation 🎉
```

### **PLAYER JOURNEY** 👥

```
1. Open App
   ↓
2. HomeScreenNew → Toggle to "Player Mode"
   ↓
3. Enter 6-digit PIN from host (e.g., "123456")
   ↓
4. Click "Join Session"
   ↓
5. SessionLobbyScreen appears
   - See quiz name
   - See other players joining
   - Wait for host to start
   ↓
6. Host clicks "Start"
   ↓
7. AUTO-NAVIGATE to QuestionPlayerScreen
   - See question text
   - See timer countdown
   - Click on an answer option
   - Answer submitted automatically
   - Wait for reveal
   ↓
8. QuestionRevealScreen shows
   - See if your answer was correct ✓ or wrong ✗
   - See points earned
   - See leaderboard update
   - Wait for next question
   ↓
9. Repeat steps 7-8 for all questions
   ↓
10. After last question → PodiumScreen
    - See your final rank
    - See top 3 players
    - Celebrate! 🎉
```

---

## 🔧 What I Just Fixed

### **Problem: "Start" Button Did Nothing**

When you clicked "Start" in the Session Lobby, the button executed the code but nothing happened on screen. Here's why:

**BEFORE:**
```dart
// SessionLobbyScreen was a StatelessWidget
// When you clicked "Start", it updated Firestore:
//   session.status = 'running'
// But there was NO navigation logic!
// The screen just sat there doing nothing visible.
```

**AFTER:**
```dart
// 1. Changed SessionLobbyScreen to StatefulWidget
// 2. Added StreamBuilder listener to session status
// 3. When status changes to 'running':
//    → Auto-navigate to QuestionHostScreen (for host)
//    → Auto-navigate to QuestionPlayerScreen (for players)
```

### **Routes I Added**

I added 4 missing routes to `router.dart`:
1. `/questionHost` → QuestionHostScreen
2. `/questionPlayer` → QuestionPlayerScreen
3. `/questionReveal` → QuestionRevealScreen
4. `/podium` → PodiumScreen

These routes allow navigation between game screens during an active session.

---

## 🧩 How Each Component Works

### **1. HomeScreenNew** (Entry Point)
```dart
Purpose: Main landing page with Host/Player toggle

Features:
- Toggle between Host Mode and Player Mode
- HOST MODE:
  - Shows list of all quizzes from Firestore
  - "Create Quiz" button → QuizBuilderScreen
  - Click quiz → Creates session → Navigate to SessionLobby
- PLAYER MODE:
  - 6-digit PIN input field
  - "Join" button → Resolves PIN → Navigate to SessionLobby

Key Methods:
- _loadQuizzes(): Fetches all quizzes from Firestore
- _createSession(quizId): Creates new session with random PIN
- _joinSession(pin): Resolves PIN to sessionId, navigates
```

### **2. QuizBuilderScreenSimple** (Create Quizzes)
```dart
Purpose: Create custom quizzes with various question types

Features:
- Left Panel: Quiz metadata (title, description)
- Right Panel: Question editor
- Add/Remove questions dynamically
- 6 Question Types Supported:
  1. MCQ (Multiple Choice) - 4 options, 1 correct
  2. True/False - Binary choice
  3. Image - Like MCQ but with image display
  4. Numeric - Answer is a number
  5. Poll - No correct answer, just opinions
  6. Order - Arrange items in correct sequence
- Time limit per question (default 30s)
- Validation before saving

How It Works:
1. Create GlobalKeys for each question widget
2. User fills in quiz metadata + questions
3. Click "Save"
4. Validate all fields
5. Call QuizRepository.createQuiz(meta, questions)
6. Saves to Firestore:
   - /quizzes/{quizId} (metadata)
   - /quizzes/{quizId}/questions/{questionId} (each question)
7. Navigate back to home
```

### **3. SessionLobbyScreen** (Waiting Room)
```dart
Purpose: Pre-game lobby where players gather

Features:
- Display quiz title
- Display unique 6-digit PIN (shareable)
- Real-time player list (via StreamBuilder)
- "Start" button (host only)

How It Works:
1. StreamBuilder watches /sessions/{sessionId}
2. FutureBuilder loads quiz metadata
3. Nested StreamBuilder watches /sessions/{sessionId}/players
4. Updates player list in real-time as people join
5. Host clicks "Start":
   → SessionController.startSession()
   → Updates Firestore: status='running', currentQuestionIndex=0
6. StreamBuilder detects status change
7. AUTO-NAVIGATE:
   - Host → QuestionHostScreen
   - Players → QuestionPlayerScreen
```

### **4. SessionController** (Session Lifecycle)
```dart
Purpose: Host-driven session state management (no Cloud Functions!)

Key Methods:

createSession(quizId):
  - Generates random 6-digit PIN
  - Creates /sessions/{sessionId} document
  - Returns sessionId

startSession(sessionId):
  - Validates host permissions
  - Updates: status='running', currentQuestionIndex=0
  - Calls _setTiming() to set question start/end times

_setTiming(sessionId, quizId, qIndex):
  - Loads question to get timeLimitSeconds
  - Sets questionStartAt = now
  - Sets questionEndAt = now + timeLimitSeconds
  - Players use this to show countdown timer

reveal(sessionId):
  - Host-only method
  - Updates: questionState='reveal'
  - Calls HostScoringService.scoreQuestion()
  - Calculates all player scores for this question

nextQuestion(sessionId):
  - Increments currentQuestionIndex
  - If more questions: questionState='answering', call _setTiming()
  - If last question: status='ended', navigate to podium
```

### **5. HostScoringService** (Calculate Scores)
```dart
Purpose: Calculate points after each question reveal

Scoring Algorithm:
BASE_SCORE = 300-1000 points (based on speed)
  - Faster answers = more points
  - Speed multiplier: 0.3x to 1.0x
  
BONUSES:
  1. STREAK BONUS (+200): Answered 3+ consecutive questions correctly
  2. FASTEST BONUS (+100): First correct answer in the room
  3. CATCH-UP BONUS (+100): Bottom 25% of players get boost
  
PENALTIES:
  - Wrong answer = 0 points
  - No answer = 0 points
  
MAX SCORE PER QUESTION: 1400 points

How It Works:
1. Fetches all answers for this question
2. For each answer:
   - Check correctness (varies by question type)
   - Calculate speed score (time taken vs time limit)
   - Add bonuses (streak, fastest, catch-up)
   - Cap at 1400
3. Writes to /sessions/{sessionId}/results/{resultId}
4. Batch updates player scores and streaks
```

### **6. QuestionHostScreen** (Host Control Panel)
```dart
Purpose: Host's view during active question

Features:
- See question text and options
- See image (if image question)
- See timer countdown
- See current state (answering/reveal)
- Control buttons:
  - "Reveal" (when answering)
  - "Next" (when reveal)

StreamBuilder Logic:
- Watches /sessions/{sessionId}
- Reads: currentQuestionIndex, questionState, timers
- FutureBuilder loads question details
- Displays appropriate controls based on state
```

### **7. QuestionPlayerScreen** (Player Answer UI)
```dart
Purpose: Player's view to submit answers

Features:
- See question text
- See timer countdown
- Interactive answer options (buttons/input)
- Submit answer (auto-locked after submission)
- Different UI for each question type:
  - MCQ: 4 buttons
  - True/False: 2 buttons
  - Numeric: Number input field
  - Order: Drag-and-drop list
  - Poll: Opinion buttons
  - Image: Image-labeled buttons

Answer Submission:
1. Player clicks/inputs answer
2. Writes to /sessions/{sessionId}/answers/{answerId}:
   - playerId
   - questionIndex
   - answer (format varies by type)
   - answeredAt (timestamp)
   - isCorrect (calculated client-side for instant feedback)
3. Answer is immutable (can't change after submit)
4. Wait for host to reveal
```

### **8. QuestionRevealScreen** (Results Display)
```dart
Purpose: Show correct answer and player scores

Features:
- Highlight correct answer
- Show player's answer (correct ✓ or wrong ✗)
- Show points earned this question
- Show updated leaderboard
- Host controls to move to next question

StreamBuilder Logic:
- Watches /sessions/{sessionId}/results/{resultId}
- Displays calculated scores
- Shows leaderboard ranking changes
```

### **9. PodiumScreen** (Final Results)
```dart
Purpose: Celebrate winners!

Features:
- Top 3 players on podium
- Confetti animation
- Trophy icons (🥇🥈🥉)
- Full leaderboard below
- "Play Again" button

StreamBuilder Logic:
- Watches /sessions/{sessionId}/players
- Orders by score descending
- Shows final rankings
```

---

## 💾 Database Structure

### **Firestore Collections**

```
/quizzes/{quizId}
  ├─ id: string (auto-generated)
  ├─ title: string
  ├─ description: string
  ├─ totalQuestions: number
  ├─ createdBy: string (auth uid)
  ├─ createdAt: timestamp
  ├─ visibility: "public" | "private"
  └─ /questions/{questionId}
       ├─ text: string (question text)
       ├─ type: "mcq" | "tf" | "image" | "numeric" | "poll" | "order"
       ├─ options: string[] (for MCQ, TF, Image, Poll, Order)
       ├─ correctIndex: number (for MCQ, TF, Image)
       ├─ numericAnswer: number (for Numeric)
       ├─ orderSolution: string[] (for Order)
       ├─ media: string? (image URL for Image type)
       ├─ timeLimitSeconds: number (default 30)
       └─ points: number (base points, default 1000)

/sessions/{sessionId}
  ├─ quizId: string (reference)
  ├─ hostId: string (auth uid)
  ├─ pin: string (6-digit code)
  ├─ status: "lobby" | "running" | "ended"
  ├─ currentQuestionIndex: number
  ├─ questionState: "answering" | "reveal" | "transition"
  ├─ questionStartAt: timestamp
  ├─ questionEndAt: timestamp
  ├─ createdAt: timestamp
  ├─ /players/{playerId}
  │    ├─ nickname: string
  │    ├─ score: number (total)
  │    ├─ streak: number (consecutive correct)
  │    └─ joinedAt: timestamp
  ├─ /answers/{answerId}
  │    ├─ playerId: string
  │    ├─ questionIndex: number
  │    ├─ answer: any (format varies by question type)
  │    ├─ answeredAt: timestamp
  │    └─ isCorrect: boolean
  └─ /results/{resultId}
       ├─ playerId: string
       ├─ questionIndex: number
       ├─ baseScore: number
       ├─ speedBonus: number
       ├─ streakBonus: number
       ├─ fastestBonus: number
       ├─ catchUpBonus: number
       ├─ totalScore: number
       ├─ isCorrect: boolean
       └─ newStreak: number
```

---

## 🧭 Navigation Flow

```
App Startup
    ↓
main.dart → MaterialApp(onGenerateRoute: AppRouter.onGenerateRoute)
    ↓
    ├─ '/' → HomeScreenNew
    │         ↓
    │         ├─ Host: Create Session → '/sessionLobby'
    │         └─ Player: Join by PIN → '/sessionLobby'
    │
    ├─ '/quizBuilder' → QuizBuilderScreenSimple
    │         ↓
    │         Save Quiz → back to '/'
    │
    ├─ '/sessionLobby' → SessionLobbyScreen
    │         ↓
    │         Auto-navigate when status='running':
    │         ├─ Host → '/questionHost'
    │         └─ Player → '/questionPlayer'
    │
    ├─ '/questionHost' → QuestionHostScreen
    │         ↓
    │         Click "Reveal" → session.questionState='reveal'
    │         (stays on same screen, shows reveal UI)
    │         ↓
    │         Click "Next" → session.currentQuestionIndex++
    │         (stays on same screen, loads next question)
    │         ↓
    │         Last question complete → '/podium'
    │
    ├─ '/questionPlayer' → QuestionPlayerScreen
    │         ↓
    │         Submit answer → write to Firestore
    │         Wait for questionState='reveal'
    │         (stays on same screen, shows waiting UI)
    │         ↓
    │         Auto-updates when next question loads
    │         ↓
    │         Last question complete → '/podium'
    │
    └─ '/podium' → PodiumScreen
              ↓
              Celebrate winners! 🎉
```

---

## 🎮 Testing Guide

### **Test as Host**

1. **Create a Quiz**
   ```
   - Open app on localhost
   - Toggle "Host Mode"
   - Click "Create Quiz"
   - Fill in: Title="Test Quiz", Description="Testing"
   - Add 2 questions:
     Q1: MCQ, "What is 2+2?", Options: 3,4,5,6, Correct=4
     Q2: True/False, "The sky is blue?", Correct=True
   - Click "Save"
   - Verify quiz appears in list on home screen
   ```

2. **Start a Session**
   ```
   - Select your quiz from list
   - Click "Create Session"
   - Verify: SessionLobbyScreen appears with PIN (e.g., "123456")
   - Keep this window open
   ```

3. **Join as Player (Second Browser Tab)**
   ```
   - Open app in new incognito window
   - Toggle "Player Mode"
   - Enter PIN from step 2
   - Click "Join Session"
   - Enter nickname (e.g., "TestPlayer")
   - Verify: Player appears in host's lobby
   ```

4. **Play the Game**
   ```
   HOST:
   - Click "Start" button
   - Verify: Auto-navigate to QuestionHostScreen
   - See: Question 1 displayed with timer
   
   PLAYER:
   - Verify: Auto-navigate to QuestionPlayerScreen
   - Click answer option
   - Verify: Button turns gray (locked)
   
   HOST:
   - Wait for timer or click "Reveal"
   - Verify: Scores calculated and displayed
   - Click "Next"
   - Verify: Question 2 loads
   
   PLAYER:
   - Answer Question 2
   
   HOST:
   - Click "Reveal"
   - Click "Next" (last question)
   - Verify: Navigate to PodiumScreen
   
   BOTH:
   - Verify: See final leaderboard with scores
   ```

### **Common Issues & Solutions**

**Issue: "Start" button doesn't navigate**
- **Cause:** Old code before my fix
- **Solution:** Pull latest code, verify SessionLobbyScreen is StatefulWidget

**Issue: Permission denied errors**
- **Cause:** Firestore rules not deployed
- **Solution:** Run `firebase deploy --only firestore:rules`

**Issue: Players don't see questions**
- **Cause:** Player document not created on join
- **Solution:** Implement joinSession in HomeScreenNew to create player doc

**Issue: Scores not calculating**
- **Cause:** HostScoringService not being called
- **Solution:** Verify SessionController.reveal() calls _scoringService.scoreQuestion()

**Issue: No quizzes showing on home screen**
- **Cause:** No quizzes created yet
- **Solution:** Use QuizBuilderScreen to create at least one quiz

---

## 🚀 Next Steps

### **To Complete the App:**

1. **Player Join Flow** (30 min)
   - In `HomeScreenNew._joinSession()`, after resolving PIN:
   - Create player document: `/sessions/{sessionId}/players/{playerId}`
   - Add fields: nickname, score=0, streak=0, joinedAt=now

2. **Auto-Navigation in Question Screens** (1 hour)
   - Add StreamBuilder in QuestionPlayerScreen
   - Listen to `questionState` changes
   - Auto-navigate or update UI when state changes reveal→answering

3. **Better Error Handling** (30 min)
   - Add try-catch blocks in all async methods
   - Show SnackBar with friendly error messages
   - Handle network failures gracefully

4. **Polish UI** (2 hours)
   - Add loading spinners during async operations
   - Add animations for transitions
   - Add sound effects for correct/wrong answers
   - Improve mobile responsiveness

5. **Testing** (1 hour)
   - Test with 5+ players simultaneously
   - Test all 6 question types
   - Test edge cases (player leaves mid-game, etc.)

---

## 📚 Key Files Reference

| File | Purpose | Important Methods |
|------|---------|-------------------|
| `lib/main.dart` | App entry point | `main()`, MaterialApp setup |
| `lib/core/router.dart` | Route configuration | `onGenerateRoute()` |
| `lib/screens/home_screen_new.dart` | Landing page | `_createSession()`, `_joinSession()` |
| `lib/screens/quiz_builder_screen_simple.dart` | Quiz creator | `_saveQuiz()`, `toJson()` |
| `lib/screens/session_lobby_screen.dart` | Waiting room | Auto-navigation logic |
| `lib/state/session_controller.dart` | Session lifecycle | `startSession()`, `reveal()`, `nextQuestion()` |
| `lib/services/host_scoring_service.dart` | Score calculation | `scoreQuestion()` |
| `lib/repositories/quiz_repository.dart` | Quiz CRUD | `createQuiz()`, `getQuestions()` |
| `lib/repositories/session_repository.dart` | Session CRUD | `createSession()`, `watchSession()` |

---

## 🎉 Congratulations!

You now have a fully functional multiplayer quiz game system! The "Start" button now works perfectly, and you understand exactly how every piece of the system fits together.

**Happy Quizzing! 🦙✨**
