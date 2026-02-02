# OnePercent - AI Dating Message Keyboard

An AI-powered iOS keyboard that helps you craft personalized, engaging messages for dating apps.

## Features

- **Smart Profile Import**: Take screenshots of dating profiles and let AI extract the key details
- **Personalized Messages**: Generate tailored openers and follow-ups based on their profile
- **Custom Keyboard**: Insert messages directly in any dating app with our custom keyboard
- **Privacy-First**: Screenshots processed on-device, no keystroke logging

## Project Structure

```
onepercent/
├── OnePercent/              # Main iOS App (SwiftUI)
├── OnePercentKeyboard/      # Custom Keyboard Extension
├── OnePercentShare/         # Share Extension for Photos
├── Shared/                  # SharedKit Swift Package
└── backend/                 # Node.js API Server
```

## Prerequisites

- Xcode 15.0+
- iOS 17.0+
- Node.js 18+
- OpenAI API Key

## Setup

### 1. Generate Xcode Project

Install XcodeGen if you haven't:
```bash
brew install xcodegen
```

Generate the project:
```bash
cd /path/to/onepercent
xcodegen generate
```

### 2. Configure Signing

1. Open `OnePercent.xcodeproj` in Xcode
2. Select the OnePercent target
3. Go to Signing & Capabilities
4. Select your Team
5. Repeat for OnePercentKeyboard and OnePercentShare targets

### 3. Setup Backend

```bash
cd backend
npm install
cp .env.example .env
```

Edit `.env` and add your OpenAI API key:
```
OPENAI_API_KEY=sk-your-api-key-here
```

Run the backend:
```bash
npm run dev
```

### 4. Update API URL

Edit `OnePercent/Services/APIClient.swift` and update the `baseURL`:
```swift
private let baseURL = "https://your-server.com"  // Your deployed backend URL
```

For local development, use:
```swift
private let baseURL = "http://localhost:3000"
```

### 5. Build and Run

1. Select the OnePercent scheme in Xcode
2. Choose an iOS Simulator or device
3. Press ⌘R to build and run

## Enabling the Keyboard

1. Open Settings → General → Keyboard → Keyboards
2. Tap "Add New Keyboard..."
3. Select "OnePercent"
4. Tap OnePercent → Enable "Allow Full Access" (optional, for AI regeneration)

## App Store Submission Checklist

- [ ] Privacy Policy URL hosted
- [ ] App icons (1024x1024)
- [ ] Screenshots for all device sizes
- [ ] App Review notes explaining keyboard functionality
- [ ] TestFlight beta testing completed
- [ ] Bundle IDs registered in Apple Developer Portal
- [ ] Provisioning profiles configured

## Privacy & Security

- Screenshots are processed on-device using Vision OCR
- Only extracted text is sent to the server (not images)
- The keyboard does NOT log keystrokes
- All data is encrypted at rest using AES-256
- Users can delete all data at any time

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        iOS Device                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Main App   │  │  Keyboard   │  │   Share     │         │
│  │  (SwiftUI)  │  │  Extension  │  │  Extension  │         │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘         │
│         │                │                │                 │
│         └────────────────┼────────────────┘                 │
│                          │                                  │
│              ┌───────────▼───────────┐                     │
│              │   App Group Storage   │                     │
│              │   (Encrypted JSON)    │                     │
│              └───────────────────────┘                     │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ HTTPS
                           ▼
              ┌───────────────────────┐
              │    Backend Server     │
              │   (Node.js + OpenAI)  │
              └───────────────────────┘
```

## License

Proprietary - All rights reserved
