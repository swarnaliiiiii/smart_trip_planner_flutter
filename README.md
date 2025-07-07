# TalkTrip - AI-Powered Travel Itinerary Planner

An intelligent Flutter application that creates personalized travel itineraries through natural language conversations with Google's Gemini AI, enhanced with real-time web search capabilities.

![Flutter](https://img.shields.io/badge/Flutter-3.27.0-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.6.1-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## 🌟 Features

- **🤖 AI-Powered Planning**: Natural language trip planning using Google Gemini AI
- **🔄 Real-time Refinement**: Iterative conversation to perfect your itinerary
- **🌐 Live Data Integration**: Real-time search for attractions, restaurants, and hotels
- **💾 Offline Storage**: Save and access itineraries without internet
- **🎤 Voice Input**: Speech-to-text for hands-free planning
- **📊 Cost Tracking**: Monitor AI token usage and estimated costs
- **🗺️ Maps Integration**: Direct links to Google Maps for all locations
- **📱 Cross-Platform**: Works on iOS, Android, Web, macOS, Windows, and Linux

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
├─────────────────────────────────────────────────────────────┤
│  HomeScreen  │  ChatScreen  │  ItineraryScreen  │ Profile   │
├─────────────────────────────────────────────────────────────┤
│                     BLoC State Management                   │
├─────────────────────────────────────────────────────────────┤
│   AuthBloc   │   ChatBloc   │  ItineraryBloc   │ UI State   │
├─────────────────────────────────────────────────────────────┤
│                      Data Layer                             │
├─────────────────────────────────────────────────────────────┤
│              │               │                │             │
│   Gemini AI  │   SerpAPI     │   Isar DB      │  Local      │
│   Service    │   Search      │   (Offline)    │  Storage    │
│              │               │                │             │
└─────────────────────────────────────────────────────────────┘
```

### Core Components

1. **AI Agent Chain**:
   - **Prompt Engineering**: Structured prompts for consistent JSON output
   - **Real-time Search**: SerpAPI integration for current information
   - **Response Validation**: JSON parsing and error handling
   - **Context Preservation**: Maintains conversation history for refinements

2. **Data Flow**:
   ```
   User Input → Speech/Text → Gemini AI → JSON Response → 
   Local Storage → UI Rendering → Maps Integration
   ```

3. **Offline-First Design**:
   - Isar database for local storage
   - Graceful degradation when offline
   - Cached itinerary viewing

## 🚀 Setup Instructions

### Prerequisites

```bash
# Install Flutter (3.27.0 or later)
# macOS
brew install flutter

# Verify installation
flutter doctor
```

### 1. Clone and Setup

```bash
git clone <repository-url>
cd talk_trip
flutter pub get
```

### 2. API Keys Configuration

Create a `.env` file in the project root:

```env
# Required: Get from https://makersuite.google.com/app/apikey
GEMINI_API_KEY=your-gemini-api-key-here

# Optional: Get from https://serpapi.com/
SEARCH_API_KEY=your-serpapi-key-here
```

### 3. Platform-Specific Setup

#### iOS Setup
```bash
cd ios
pod install
cd ..

# Add microphone permission to ios/Runner/Info.plist
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for voice input</string>
```

#### Android Setup
```bash
# Microphone permission already configured in android/app/src/main/AndroidManifest.xml
# No additional setup required
```

#### Web Setup
```bash
# Enable web support
flutter config --enable-web
```

### 4. Generate Required Files

```bash
# Generate Isar database schemas
flutter packages pub run build_runner build
```

### 5. Run the Application

```bash
# Development
flutter run

# Specific platform
flutter run -d chrome        # Web
flutter run -d ios          # iOS Simulator
flutter run -d android      # Android Emulator
```

## 🤖 AI Agent Chain Workflow

### 1. Initial Prompt Processing
```
User Input: "Plan a 3-day trip to Tokyo for a couple, budget $2000"
    ↓
Context Building: Extract destination, duration, budget, travel style
    ↓
Search Enhancement: Query SerpAPI for current Tokyo attractions/restaurants
    ↓
Structured Prompt: Combine user request + real-time data + JSON schema
```

### 2. Gemini AI Processing
```
Prompt Template:
- User requirements
- Real-time search results
- Strict JSON schema definition
- Cost estimation guidelines
- Map link generation rules
```

### 3. Response Validation & Storage
```
JSON Response → Schema Validation → Isar Database → UI Rendering
```

### 4. Refinement Loop
```
Follow-up Input → Context Preservation → Incremental Updates → 
Real-time Search (if needed) → Updated JSON → Database Update
```

## 📊 Token Cost Analysis

Based on testing with Gemini 1.5 Flash model:

| Operation Type | Avg Input Tokens | Avg Output Tokens | Est. Cost (USD) |
|----------------|------------------|-------------------|-----------------|
| Initial Itinerary | 1,200 | 2,800 | $0.0024 |
| Simple Refinement | 800 | 1,200 | $0.0015 |
| Complex Changes | 1,500 | 2,200 | $0.0027 |
| Search-Enhanced | 1,800 | 3,200 | $0.0036 |

**Pricing Model** (Gemini 1.5 Flash):
- Input: $0.00015 per 1K tokens
- Output: $0.0006 per 1K tokens

*Note: Costs are estimates and may vary based on actual usage and Google's pricing updates.*

## 🗂️ Project Structure

```
lib/
├── core/
│   ├── constants/          # API keys, environment config
│   ├── database/          # Isar database setup
│   ├── router/            # Navigation and routing
│   ├── themes/            # App theming
│   └── utils/             # Utilities (metrics, network)
├── data/
│   ├── models/            # Data models (User, Itinerary, Message)
│   ├── repo/              # Repository pattern implementation
│   └── sources/
│       └── api/           # External API services
├── presentation/
│   ├── bloc/              # BLoC state management
│   └── screens/           # UI screens and widgets
└── main.dart              # App entry point
```

## 🔧 Key Dependencies

```yaml
# State Management
flutter_bloc: ^9.1.1

# AI Integration  
google_generative_ai: ^0.4.7

# Local Database
isar: ^3.1.0+1
isar_flutter_libs: ^3.1.0+1

# UI & UX
flutter_screenutil: ^5.9.3
speech_to_text: ^7.1.0
url_launcher: ^6.3.1

# Networking
http: ^1.4.0

# Environment
flutter_dotenv: ^5.2.1
```

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Integration tests
flutter drive --target=test_driver/app.dart
```

## 📱 Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| iOS | ✅ | Full support with voice input |
| Android | ✅ | Full support with voice input |
| Web | ✅ | Limited voice input support |
| macOS | ✅ | Desktop optimized |
| Windows | ✅ | Desktop optimized |
| Linux | ✅ | Desktop optimized |

## 🔒 Privacy & Security

- **Local-First**: All itineraries stored locally using Isar database
- **API Key Security**: Environment variables for sensitive data
- **No User Tracking**: No analytics or user behavior tracking
- **Offline Capable**: Core functionality works without internet

## 🚧 Known Limitations

1. **Voice Input**: Limited browser support for speech-to-text on web
2. **Search API**: SerpAPI has rate limits (100 searches/month free tier)
3. **Maps Integration**: Requires Google Maps app or web browser
4. **Token Costs**: Costs can accumulate with extensive usage

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Troubleshooting

### Common Issues

1. **"No API Key" Error**:
   ```bash
   # Ensure .env file exists with valid GEMINI_API_KEY
   cp .env.example .env
   # Edit .env with your actual API key
   ```

2. **Build Runner Issues**:
   ```bash
   flutter packages pub run build_runner clean
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

3. **iOS Build Errors**:
   ```bash
   cd ios && pod deintegrate && pod install && cd ..
   flutter clean && flutter pub get
   ```

4. **Voice Input Not Working**:
   - Check microphone permissions
   - Ensure device has microphone access
   - Web: Use HTTPS or localhost

### Debug Mode

Enable debug metrics overlay in `lib/core/utils/metrics_manager.dart`:
```dart
MetricsManager().setDebugMode(true);
```

## 📞 Support

For issues and questions:
- Create an issue on GitHub
- Check existing issues for solutions
- Review troubleshooting section above

---

**Built with ❤️ using Flutter and Google Gemini AI**