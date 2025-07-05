# Forking Food

A Tinder-like app for culinary recipes! Discover, rate, and share recipes with a unique swiping experience.

## 🍽️ Features

### Core Functionality
- **Fork In / Fork Out**: Swipe right to "fork in" (like) a recipe, or left to "fork out" (pass)
- **Recipe Discovery**: Browse through personalized recipe recommendations
- **Recipe Upload**: Share your own recipes with detailed ingredients, instructions, and photos
- **User Authentication**: Secure login with email/password, Google Sign-in, and Facebook Sign-in
- **Profile Management**: Track your uploaded recipes, saved recipes, and cooking achievements

### User Experience
- **Smooth Swiping**: Intuitive card-based interface with haptic feedback
- **Recipe Details**: View comprehensive recipe information including ingredients, instructions, and cooking time
- **Filtering System**: Filter recipes by dietary criteria and cooking time
- **Real-time Updates**: Live synchronization between different app sections
- **Offline Support**: Cached recipe data for seamless browsing

### Social Features
- **Recipe Sharing**: Upload recipes with step-by-step instructions and photos
- **Community Interaction**: Like and save recipes from other users
- **Personal Library**: Access your saved and uploaded recipes
- **Recipe Management**: Edit or delete your own recipes

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.2.3)
- Firebase project setup
- Android Studio / Xcode for mobile development

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/forking-food.git
   cd forking-food
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project
   - Enable Authentication (Email/Password, Google, Facebook)
   - Enable Firestore Database
   - Enable Firebase Storage
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

4. **Run the app**
   ```bash
   flutter run
   ```

## 🛠️ Tech Stack

### Frontend
- **Flutter** - Cross-platform UI framework
- **Material Design 3** - Modern UI components
- **Custom Fonts** - EduNSWACTHand for branding

### Backend & Services
- **Firebase Authentication** - User management (Email, Google, Facebook)
- **Cloud Firestore** - NoSQL database for recipes and user data
- **Firebase Storage** - Image storage for recipe photos
- **Firebase Security Rules** - Data access control

### State Management & Architecture
- **Stream-based Architecture** - Real-time data synchronization
- **Event Bus Pattern** - Cross-screen communication
- **Service Layer** - Business logic separation

### Key Dependencies
- `firebase_core` - Firebase initialization
- `firebase_auth` - Authentication services
- `cloud_firestore` - Database operations
- `firebase_storage` - File storage
- `flutter_card_swiper` - Swipeable card interface
- `google_sign_in` - Google authentication
- `flutter_facebook_auth` - Facebook authentication
- `image_picker` - Photo selection
- `cached_network_image` - Image caching
- `vibration` - Haptic feedback

## 📱 App Structure

### Navigation
- **Bottom Navigation Bar** with 3 main sections:
  - **Discover** (🌍): Browse today's favorites and recommendations
  - **Home** (🏠): Swipe through personalized recipe cards
  - **Profile** (👤): Manage your account and recipes

### Screens
```
lib/screens/
├── splash_screen.dart          # App loading screen
├── welcome_screen.dart         # Onboarding and authentication
├── main_screen.dart           # Main navigation container
├── add_recipe_screen.dart     # Recipe creation form
└── auth/                      # Authentication screens
    ├── login_screen.dart
    ├── register_screen.dart
    └── forgot_password_screen.dart
└── tabs/                      # Main app tabs
    ├── discover_screen.dart   # Recipe discovery
    ├── home_screen.dart       # Swipeable recipe cards
    └── profile_screen.dart    # User profile management
```

### Models & Services
```
lib/
├── models/
│   ├── recipe.dart            # Recipe data model
│   └── user_data.dart         # User profile model
├── services/
│   ├── auth_service.dart      # Authentication logic
│   ├── recipe_service.dart    # Recipe CRUD operations
│   ├── user_service.dart      # User data management
│   └── recipe_event_bus.dart  # Cross-screen communication
├── widgets/
│   └── recipe_card.dart       # Recipe display component
└── utils/
    ├── constants.dart         # App constants and colors
    └── haptic_feedback.dart   # Haptic feedback utilities
```

## 🎨 Design System

### Color Palette
- **Primary**: Carrot Yellow (#FF8C00)
- **Secondary**: Dark Green (#2E7D32)
- **Surface**: Light Background (#FAFAFA)
- **Error**: Red (#D32F2F)

### Typography
- **Brand Font**: EduNSWACTHand (Bold, SemiBold)
- **System Font**: Material Design typography

### Components
- **Recipe Cards**: Swipeable cards with recipe information
- **Action Buttons**: Circular buttons for fork in/out actions
- **Navigation**: Material 3 bottom navigation
- **Forms**: Rounded input fields with validation

## 🔧 Configuration

### Firebase Setup
1. Create a new Firebase project
2. Enable Authentication with Email/Password, Google, and Facebook providers
3. Create a Firestore database with security rules
4. Set up Firebase Storage for image uploads
5. Add platform-specific configuration files

### Environment Variables
- Firebase configuration is handled through platform-specific files
- No additional environment variables required

## 📊 Data Models

### Recipe Structure
```dart
class Recipe {
  String id;
  String title;
  String imageUrl;
  String description;
  List<String> ingredients;
  List<InstructionStep> instructions;
  Duration totalEstimatedTime;
  List<String> tags;
  String creatorId;
  String? creatorName;
  String? creatorPhotoURL;
  DateTime createdAt;
  int forkInCount;
  int forkOutCount;
  int forkingoodCount;
  List<String> dietaryCriteria;
}
```

### User Data Structure
```dart
class UserData {
  String id;
  String displayName;
  String? photoURL;
  String? email;
  DateTime createdAt;
  List<String> uploadedRecipes;
  Map<String, String> preferences;
}
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- The open-source community for various packages used in this project

---

**Made with ❤️ for food lovers everywhere**