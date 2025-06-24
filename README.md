# Forking

A recipe rating app with a twist! Rate recipes by forking them in or out.

## Features

- **Fork In / Fork Out**: Swipe right to "fork in" (like) a recipe, or left to "fork out" (pass).
- **Forkingood**: Super-like a recipe to give both the recipe and its creator a special "good" status.
- **Recipe Upload**: Share your own recipes with the community.
- **Profile**: Track your forked recipes and cooking achievements.
- **Authentication**: Secure login with email/password and Google Sign-in.

## Getting Started

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure Firebase (follow instructions in `firebase_setup.md`)
4. Run the app with `flutter run`

## Tech Stack

- Flutter
- Firebase (Authentication, Firestore)
- Provider for state management

## Contributing

Feel free to fork (pun intended!) and submit pull requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🎯 Features (MVP)

- 🔐 **User Authentication** (email & password via Firebase)
- 🍽️ **Swipeable Recipe Cards** (left = fork-out, right = fork-in)
- 📸 **Add Recipes** (with images, ingredients, instructions)
- 👤 **User Profile** (view uploaded recipes, basic stats)
- 📱 **Bottom Navigation Bar** with 3 main sections:
  - **Home**: Swipe recipes
  - **Add**: Submit new recipe
  - **Me**: View/edit your profile and uploads

---

## 🧱 Folder Structure

```plaintext
lib/
├── main.dart
├── screens/
│   ├── auth_screen.dart
│   ├── home_screen.dart
│   └── profile_screen.dart
├── models/
│   ├── recipe.dart
│   └── user.dart
├── widgets/
│   └── recipe_card.dart
├── services/
│   ├── auth_service.dart
│   └── database_service.dart
├── providers/
│   └── auth_provider.dart