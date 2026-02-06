# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

### iOS App (Main Development)
```bash
# Generate Xcode project (required after modifying project.yml)
xcodegen generate

# Open in Xcode, then ⌘R to build and run
open OnePercent.xcodeproj
```

### Backend
```bash
cd backend
npm install
npm run dev      # Development with hot reload (tsx watch)
npm run build    # TypeScript compilation
npm run start    # Production server
npm run lint     # ESLint
```

### Root (Next.js/Capacitor - minimal usage)
```bash
npm run dev          # Next.js dev server
npm run lint         # ESLint
npm run build:ios    # Build Next + sync Capacitor + open Xcode
```

## Architecture

This is an AI-powered iOS dating message keyboard with three targets sharing data via App Group:

```
┌──────────────────────────────────────────────────────────────┐
│  OnePercent (Main App)     │  Keyboard Extension  │  Share  │
│  - Onboarding & settings   │  - Message insertion │  Ext.   │
│  - Match management        │  - Match selection   │  - Photo│
│  - Message generation UI   │                      │  import │
└──────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              │  SharedKit (Swift Package)    │
              │  - Models (UserProfile,       │
              │    MatchProfile, Messages)    │
              │  - MatchStore (persistence)   │
              │  - SecureStore (AES-256)      │
              └───────────────┬───────────────┘
                              │
              ┌───────────────┴───────────────┐
              │  App Group Container          │
              │  group.com.blakemartin.       │
              │  onepercent.app               │
              └───────────────────────────────┘
                              │ HTTPS
              ┌───────────────┴───────────────┐
              │  Backend (Node.js + Express)  │
              │  POST /v1/profile/parse       │
              │  POST /v1/message/generate    │
              │  (OpenAI GPT-4o integration)  │
              └───────────────────────────────┘
```

## Key Patterns

### Multi-Target Data Sharing
All three iOS targets share `SharedKit` package and access the same App Group container. When modifying models in `Shared/Sources/SharedKit/Models/`, changes affect all targets.

### State Management
- `AppState` (in `OnePercentApp.swift`) is the global observable state injected via `@EnvironmentObject`
- `MatchStore` singleton handles all persistence, accessed from any target
- Data encrypted at rest using `SecureStore` (AES-256 via CryptoKit)

### APIClient
Actor-based (`APIClient.swift`) with automatic retry logic (3 attempts, exponential backoff). Handles 429/5xx retries transparently.

### Defensive Decoding
Models use `decodeIfPresent()` with fallbacks for schema evolution. When adding new fields to models, provide defaults for backward compatibility.

### XcodeGen
The Xcode project is generated from `project.yml`. After modifying targets, dependencies, or build settings, run `xcodegen generate`.

## Key Files

| Purpose | Path |
|---------|------|
| App entry + AppState | `OnePercent/App/OnePercentApp.swift` |
| API client | `OnePercent/Services/APIClient.swift` |
| Data models | `Shared/Sources/SharedKit/Models/` |
| Persistence | `Shared/Sources/SharedKit/Storage/MatchStore.swift` |
| Design tokens | `OnePercent/Brand.swift` |
| Backend entry | `backend/src/index.ts` |
| OpenAI service | `backend/src/services/openai.ts` |
| AI prompts | `backend/src/prompts/index.ts` |
| Keyboard UI | `OnePercentKeyboard/Views/KeyboardMainView.swift` |

## API Endpoints

- `POST /v1/profile/parse` - Extract structured profile from OCR text
- `POST /v1/message/generate` - Generate personalized messages (requires userProfile + matchProfile)

## Environment

Backend requires `.env` with:
```
OPENAI_API_KEY=sk-...
PORT=3000  # optional
```

For local iOS development, update `baseURL` in `APIClient.swift` to `http://localhost:3000`.
