# LamaPlay - Interactive Quiz Game Platform

A Flutter + Firebase multiplayer quiz game application supporting real-time gameplay, custom quiz creation with image support, and live leaderboards. Targets Android, iOS, and Web platforms.

## 🎮 Features

### Quiz Creation & Management
- **Custom Quiz Builder**: Create quizzes with multiple question types
  - Multiple Choice Questions (MCQ)
  - True/False
  - Image-based questions with gallery upload
  - Numeric answers
  - Poll questions
  - Order/Ranking questions
- **Image Upload**: Integrated with ImgBB API for free image hosting
- **Quiz Library**: Browse and manage all created quizzes
- **Real-time Sync**: All quiz data stored in Firebase Firestore

### Live Quiz Gameplay
- **Host Controls**: 
  - Start quiz sessions with unique session codes
  - Manual control over question progression
  - Real-time answer monitoring
  - Reveal answers and advance questions
- **Player Experience**:
  - Join sessions via session codes
  - Real-time question display
  - Interactive answer selection
  - Instant feedback on correct/incorrect answers
- **Dual Mode**: Host can also play alongside participants

### Scoring & Leaderboards
- **Dynamic Scoring**: Points awarded based on:
  - Answer correctness
  - Response time
  - Streak bonuses
- **Live Leaderboards**: After each question showing:
  - Current rankings
  - Points gained per question
  - Total scores
  - Visual indicators (🥇🥈🥉) for top 3
- **Final Podium**: End-of-quiz celebration screen

### Session Management
- **Session Lobby**: Pre-game waiting room
- **Player List**: Real-time player join/leave tracking
- **Session States**: Managed progression (lobby → answering → reveal → leaderboard)
- **Presence System**: Track online/offline players

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (stable channel, version 3.9.2 or higher)
- Firebase CLI
- Dart SDK (bundled with Flutter)
- ImgBB API key (free at https://api.imgbb.com/)

### 1. Install Flutter
```powershell
flutter channel stable
flutter upgrade
flutter --version
```

### 2. Clone and Install Dependencies
```powershell
git clone https://github.com/YoussefAbbes/LammaPlay.git
cd lamaplay
flutter pub get
```

### 3. Firebase Setup

**IMPORTANT**: Firebase configuration files contain sensitive API keys and should NOT be committed to version control.

#### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing one
3. Enable the following services:
   - **Authentication**: Anonymous sign-in
   - **Firestore Database**: NoSQL database
   - **Realtime Database**: For presence system

#### Configure FlutterFire
```powershell
flutterfire configure --project=<YOUR_FIREBASE_PROJECT_ID> --platforms=android,ios,web
```

This generates:
- `lib/firebase_options.dart` (⚠️ DO NOT COMMIT)
- `android/app/google-services.json` (⚠️ DO NOT COMMIT)
- iOS configuration in Xcode project (⚠️ DO NOT COMMIT)

#### Initialize Firebase Services
```powershell
firebase login
firebase init firestore database --project <YOUR_FIREBASE_PROJECT_ID>
```

Select:
- Firestore: Yes
- Realtime Database: Yes
- Emulators: No
- Functions: No

### 4. Configure ImgBB API Key

1. Get a free API key from [ImgBB](https://api.imgbb.com/)
2. Create `lib/config/api_keys.dart`:
```dart
class ApiKeys {
  static const String imgbbApiKey = 'YOUR_IMGBB_API_KEY_HERE';
}
```
3. Update the API key reference in:
   - `lib/screens/quiz_builder_screen_simple.dart` (line 413)
   - `lib/screens/quiz_builder_screen.dart` (line 358)

**Note**: The `api_keys.dart` file is already in `.gitignore`

### 5. Run the App

**Android/iOS:**
```powershell
flutter run
```

**Web:**
```powershell
flutter run -d chrome
```

**Specific Device:**
```powershell
flutter devices  # List available devices
flutter run -d <device-id>
```

## 📱 How to Use

### Creating a Quiz
1. Open the app and navigate to "Quiz Builder"
2. Enter quiz title and description
3. Add questions:
   - Select question type
   - Enter question text
   - Add answer options
   - For image questions: tap "Pick Image" to upload from gallery
   - Mark the correct answer
4. Save the quiz

### Starting a Quiz Session
1. Go to "My Quizzes" and select a quiz
2. Tap "Start Session"
3. Share the session code with players
4. Wait for players in the lobby
5. Start the quiz when ready

### Playing as Host
1. Start a session and join as a player
2. Answer questions alongside participants
3. After answering, click "Reveal Answers"
4. View leaderboard after each question
5. Click "Next Question" to proceed
6. View final podium after all questions

### Joining as Player
1. Enter the session code
2. Choose a nickname
3. Wait in lobby for host to start
4. Answer questions as they appear
5. View your score after each question
6. See final rankings on podium

## 🏗️ Architecture

### Project Structure
```
lib/
├── core/
│   ├── router.dart              # Navigation routes
│   ├── design_tokens.dart       # UI design system
│   └── flags.dart               # Feature flags
├── models/
│   ├── question.dart            # Question data models
│   ├── quiz.dart                # Quiz metadata
│   └── room.dart                # Session/room models
├── screens/
│   ├── home_screen_new.dart     # Main landing page
│   ├── quiz_builder_screen_simple.dart  # Quiz creation UI
│   ├── session_lobby_screen.dart        # Pre-game lobby
│   ├── question_host_screen.dart        # Host control panel
│   ├── question_player_screen.dart      # Player answer UI
│   ├── question_leaderboard_screen.dart # Post-question scores
│   └── podium_screen.dart               # Final results
├── services/
│   ├── auth_service.dart        # Firebase Authentication
│   ├── presence_service.dart    # Online/offline tracking
│   └── firestore_refs.dart      # Database references
├── repositories/
│   └── quiz_repository.dart     # Quiz data access layer
├── state/
│   └── session_controller.dart  # Game state management
└── widgets/
    └── [reusable UI components]
```

### Data Models

**Firestore Collections:**
- `quizzes/` - Quiz metadata and settings
  - `questions/` - Individual quiz questions
- `sessions/` - Active game sessions
  - `players/` - Session participants
  - `answers/` - Player responses
  - `results/` - Calculated scores

**Question Types:**
```dart
enum QuestionType {
  mcq,      // Multiple choice
  tf,       // True/False
  numeric,  // Number input
  image,    // Image-based MCQ
  poll,     // Opinion poll
  order,    // Ranking/ordering
}
```

### Key Features Implementation

#### Real-time Synchronization
- Uses Firestore `StreamBuilder` for live updates
- Session state changes propagate to all clients instantly
- Answer submissions trigger automatic score calculations

#### Image Handling
- Cross-platform support (Web uses `Uint8List`, Mobile uses `File`)
- Images uploaded to ImgBB for permanent hosting
- Returns public URLs stored in Firestore
- Platform detection via `kIsWeb` flag

#### Session Flow
```
Lobby → Answering → Reveal → Leaderboard → Next Question
  ↓                                            ↓
  └────────────────────────────────────────────┘
                      ↓ (after last question)
                   Podium
```

## 🔒 Security Considerations

### Sensitive Files (Already in .gitignore)
- `lib/firebase_options.dart` - Firebase API keys
- `android/app/google-services.json` - Android Firebase config
- `ios/Runner/GoogleService-Info.plist` - iOS Firebase config
- `lib/config/api_keys.dart` - Third-party API keys
- `.env` files - Environment variables

### Firestore Security Rules
Ensure proper rules are set in `firestore.rules`:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Quizzes: Read by all, write by authenticated users
    match /quizzes/{quizId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Sessions: Participants only
    match /sessions/{sessionId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### Best Practices
1. **Never commit Firebase config files** to version control
2. **Use environment variables** for API keys in production
3. **Implement rate limiting** for quiz creation/session starts
4. **Validate data** on both client and server side
5. **Monitor Firebase usage** to stay within free tier limits

## 🐛 Troubleshooting

### Images not loading
- Check ImgBB API key is correct
- Verify internet connection
- Check browser console for CORS errors (Web)

### Firebase connection issues
- Verify `firebase_options.dart` exists and is configured
- Check Firebase project is active
- Ensure Authentication is enabled

### Layout overflow errors
- Fixed in recent updates with `SingleChildScrollView`
- Restart app with hot restart: `flutter run --hot`

### Players not seeing questions
- Verify session state in Firebase console
- Check all clients are on same Flutter version
- Ensure Firestore rules allow read access

## 📦 Dependencies

Key packages used:
- `firebase_core` - Firebase initialization
- `cloud_firestore` - NoSQL database
- `firebase_auth` - Authentication
- `firebase_database` - Realtime Database
- `image_picker` - Gallery/camera access
- `http` - API requests (ImgBB)
- `flutter_animate` - UI animations

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- ImgBB for free image hosting
- Community contributors

## 📞 Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Contact: [Your Contact Information]

---

**Note**: This app is designed for educational and entertainment purposes. Ensure compliance with your region's data protection laws when deploying to production.
