# 🥔 Mash or Trash

**Mash or Trash** is a Tinder-style mobile app for food lovers, built with **Flutter** as part of a university thesis project.

Users can swipe through recipe cards — **mash** (like) or **trash** (dislike) — and also upload their own recipes with photos, ingredients, and preparation steps. The app features user authentication and a personal profile section.

---

## 🎯 Features (MVP)

- 🔐 **User Authentication** (email & password via Firebase)
- 🍽️ **Swipeable Recipe Cards** (left = trash, right = mash)
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