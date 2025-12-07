# BibleAI

An AI-powered Bible companion app for iOS, designed to enhance Bible study and spiritual growth through intelligent insights and modern technology.

## 🌟 Current Features

### AI Bible Chat (MVP - COMPLETE)
- **Conversational AI Assistant**: Chat with an AI that understands biblical context, history, and theology
- **Multi-perspective Analysis**: Presents interpretations from different Christian traditions (Catholic, Protestant, Orthodox)
- **Cross-references**: Automatically suggests related verses and passages
- **Historical Context**: Explains original Greek/Hebrew meanings and cultural background
- **Conversation Management**:
  - Create multiple conversations
  - Persistent chat history
  - Auto-generated titles from first message
  - Delete and regenerate responses
- **Modern UI**: Beautiful SwiftUI interface with typing indicators and smooth animations
- **NEW:** Verse of the Day - Daily inspirational verse on home screen
- **NEW:** Tappable verse references - Tap any verse mentioned in AI responses to view full text
- **NEW:** Quick verse suggestions - Pre-built prompts to get started

### Settings & Configuration
- OpenAI API key management (secure local storage)
- Bible translation preferences
- Quick links to resources

### Bible Reader (COMPLETE ✅)
- Complete KJV Bible with all 66 books
- Browse by Old Testament and New Testament
- Chapter-by-chapter reading
- Adjustable font size (12-24pt)
- Clean, distraction-free reading experience
- Real-time loading from Bible API
- **NEW:** Verse search functionality - jump to any verse instantly
- **NEW:** Search supports abbreviations (e.g., "Jn 3:16", "Gen 1", "Ps 23:1-4")

### Study Notes & Highlights (NEW ✨)
- **Highlight verses** in 5 colors (yellow, green, blue, purple, orange)
- **Add personal notes** to any verse
- **View all highlights** in dedicated Highlights tab
- **Edit or delete** highlights anytime
- **Persistent storage** - your highlights are saved locally
- **Search highlights** by reference, verse text, or notes
- Tap any verse while reading to highlight it

### Reading Plans (NEW 📖)
- **Pre-built reading plans** to guide your Bible study journey
- **Progress tracking** with visual progress bars and checkmarks
- **4 curated plans included**:
  - Gospel Tour (8 days) - Experience Jesus's life through key moments
  - Psalms in a Month (30 days) - Read all 150 Psalms with worship and reflection
  - New Testament in 30 Days - Complete NT in one month
  - Proverbs Wisdom (31 days) - Daily wisdom from Proverbs
- **One-tap reading** - Jump directly from plan to Bible reader
- **Daily reading organization** with chapter groupings
- **Plan categories**: Overview, Devotional, Topical, Sequential
- Mark days complete as you progress

### Share & Export (NEW 🎨)
- **Simple text sharing** for verses, highlights, and AI insights
- **Share from anywhere**:
  - Tap any verse while reading → Share Verse
  - Long-press AI responses → Share Insight
  - Swipe highlights → Share button
- **Native iOS sharing** - Share to Messages, Email, Notes, etc.
- **Formatted text** with verse references and notes
- Perfect for texting, study groups, and personal notes

### Tab-Based Navigation
- **Home Tab**: Chat interface with Verse of the Day and suggestions
- **Read Tab**: Complete Bible reader with KJV text
- **Plans Tab**: Browse and follow structured reading plans
- **Highlights Tab**: View and manage all your highlighted verses
- **Settings Tab**: Usage tracking and preferences

## 📋 Requirements

- iOS 17.0+
- Xcode 15.0+
- OpenAI API Key (for AI chat functionality)

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/shawn14/BibleAI.git
cd BibleAI
```

### 2. Get an OpenAI API Key
1. Visit [platform.openai.com](https://platform.openai.com/api-keys)
2. Create an account if you don't have one
3. Generate a new API key
4. Copy the key

### 3. Configure the App
1. Open `BibleAI/Config.swift`
2. Replace `YOUR_API_KEY_HERE` with your actual OpenAI API key:
```swift
struct Config {
    static let openAIAPIKey = "sk-proj-YOUR_KEY_HERE"
}
```
3. Save the file

**Important**: Never commit your actual API key to version control! The `Config.private.swift` file is gitignored for this reason.

### 4. Build and Run
1. Open `BibleAI.xcodeproj` in Xcode
2. Select a simulator or device
3. Press `Cmd + R` to build and run

### 5. Start Chatting!
1. Go to Chat tab
2. Tap "Start New Conversation"
3. Ask questions about scripture!

## 💡 Example Questions to Try

- "What does John 3:16 mean?"
- "Explain the context of Romans 8:28"
- "What is the significance of Jesus's conversation with Nicodemus?"
- "Compare different interpretations of Revelation 21"
- "What can Psalm 23 teach me about trust?"

## 🏗 Project Structure

```
BibleAI/
├── BibleAI/
│   ├── BibleAIApp.swift          # App entry point
│   ├── ContentView.swift          # Main tab view
│   ├── Models/                    # Data models
│   │   ├── Message.swift         # Chat message model
│   │   ├── Conversation.swift    # Conversation model
│   │   └── BibleVerse.swift      # Bible verse model
│   ├── Views/                     # SwiftUI views
│   │   ├── ChatView.swift        # Main chat interface
│   │   ├── ConversationListView.swift  # Conversation history
│   │   └── SettingsView.swift    # Settings screen
│   ├── ViewModels/                # Business logic
│   │   └── ChatViewModel.swift   # Chat state management
│   ├── Services/                  # Backend services
│   │   ├── AIService.swift       # OpenAI API integration
│   │   ├── BibleService.swift    # Bible data management
│   │   └── ConversationService.swift  # Conversation persistence
│   └── Assets.xcassets/          # App assets
├── README.md
├── CLAUDE.md                      # Development guidelines
└── .gitignore
```

## 🎯 Architecture

### MVVM Pattern
- **Models**: Data structures (Message, Conversation, BibleVerse)
- **Views**: SwiftUI UI components
- **ViewModels**: Business logic and state management
- **Services**: API calls and data persistence

### Data Flow
```
User Input → ChatViewModel → AIService → OpenAI API
                ↓                          ↓
         ConversationService ← Response ←─┘
                ↓
          UserDefaults (Persistence)
```

### AI System Prompt
The AI is configured to:
- Provide historical and theological context
- Reference original languages (Greek/Hebrew)
- Show multiple Christian perspectives
- Ask Socratic questions to deepen understanding
- Suggest practical applications
- Maintain warmth and accessibility

## 🔮 Planned Features (Roadmap)

### Phase 2: Enhanced Chat (Weeks 4-6)
- [ ] AI-generated daily devotionals
- [ ] Smart prayer journal with AI insights
- [ ] Verse reference detection and inline display
- [ ] Voice input for questions
- [ ] Share conversations

### Phase 3: Bible Reader (COMPLETE ✅)
- [x] Full Bible text with KJV translation
- [x] All 66 books (Old and New Testament)
- [x] Chapter-by-chapter reading
- [x] Adjustable font size
- [ ] Advanced search functionality
- [ ] Highlights and bookmarks
- [ ] Reading plans
- [ ] Notes and annotations

### Phase 4: Community Features (Weeks 10-12)
- [ ] AI-facilitated group Bible studies
- [ ] Discussion forums
- [ ] Prayer request sharing
- [ ] Insight synthesis from group conversations

### Phase 5: Advanced AI Features (Months 4-6)
- [ ] AI-generated visual aids (maps, timelines)
- [ ] Scripture memory system with spaced repetition
- [ ] Theological question answering
- [ ] Personalized study recommendations
- [ ] Cross-tradition dialogue mode

## 🔐 Privacy & Security

- **API Keys**: Stored locally in UserDefaults (not in iCloud)
- **Conversations**: Stored locally on device only
- **No Analytics**: Zero tracking or data collection
- **OpenAI**: Follows OpenAI's data usage policies

## 🛠 Development Commands

### Build for Simulator
```bash
xcodebuild -project BibleAI.xcodeproj -scheme BibleAI -sdk iphonesimulator -configuration Debug build
```

### Build for Device
```bash
xcodebuild -project BibleAI.xcodeproj -scheme BibleAI -sdk iphoneos -configuration Release build
```

### Run Tests
```bash
xcodebuild test -project BibleAI.xcodeproj -scheme BibleAI -destination 'platform=iOS Simulator,name=iPhone 15'
```

## 📊 Competitive Differentiation

Unlike existing Bible apps, BibleAI offers:

1. **Conversational AI**: Not just verse lookup, but deep discussion and understanding
2. **Multi-perspective**: Shows different theological interpretations fairly
3. **Contextual Intelligence**: Understands your questions in context of previous conversation
4. **Socratic Teaching**: Asks questions to deepen understanding
5. **Personalization**: Adapts to your learning style and theological background

## 💰 Monetization Strategy (Future)

### Free Tier
- Basic Bible reading
- Daily verses
- 5 AI conversations per day

### Premium ($9.99/month)
- Unlimited AI conversations
- AI-generated devotionals
- Prayer journal with insights
- Study groups
- Advanced features

### Pro Tier ($19.99/month)
- Everything in Premium
- AI study group facilitator
- Priority responses
- Advanced analytics
- Early access to features

## 📱 App Store Preparation

Before submitting to App Store:
1. Update bundle identifier if needed
2. Configure code signing with your Apple Developer account
3. Create app icon (1024x1024px)
4. Take screenshots for all required device sizes
5. Write App Store description
6. Set up in-app purchases (if using premium features)
7. Archive and submit via Xcode

## 💰 Cost Optimization

The app uses **GPT-4o-mini** (~$0.15 per 1M tokens) instead of GPT-4 (~$30 per 1M tokens) - **200x cheaper!**

### Built-in Cost Controls:
- **Daily Limit**: 50 requests per day (resets at midnight)
- **Rate Limit**: 10 requests per minute
- **Token Limit**: 500 tokens max per response
- **Context Window**: Only last 5 messages sent for context

### Estimated Costs:
- **50 messages/day**: ~$0.60/month
- **1,500 messages/month**: ~$0.60/month (with limits)

See `AI_COST_OPTIMIZATIONS.md` for detailed analysis.

## 🐛 Known Issues / TODO

- [x] Add proper Bible API integration (using bible-api.com)
- [ ] Implement error retry mechanism for failed API calls
- [x] Add loading states for Bible verse lookups
- [ ] Implement conversation export/sharing
- [ ] Add dark mode toggle
- [x] Optimize API token usage (GPT-4o-mini + rate limits)

## 📄 License

Copyright 2025. All rights reserved.

## 🙏 Acknowledgments

- OpenAI for GPT-4 API
- Bible API providers (to be integrated)
- SwiftUI community

---

**Built with ❤️ for Bible study and spiritual growth**
