# 🚀 INSPECTO

**INSPECTO** is a premium, specialized API testing and debugging toolkit built with Flutter and Node.js. It features a stunning **Pure Black** "Cyber" aesthetic, high-performance request execution, and a robust Clean Architecture.

![INSPECTO Logo](assets/INSPECTO.png)

## ✨ Features

### 🛠️ Professional Request Builder
- **Dynamic URL & Methods**: Fully customizable HTTP requests (GET, POST, PUT, DELETE, etc.) with a streamlined UI.
- **Header & Query Parameters**: Repeatable list interface for managing complex request metadata.
- **Request Body Editor**: Supports `none`, `JSON`, and `Form Data` with real-time syntax highlighting for JSON.

### 📊 Deep Response Viewer
- **Instant Metrics**: Real-time display of Status Codes (color-coded), Response Time (ms), and Content Size.
- **Pretty-Printed JSON**: Automated formatting and syntax highlighting powered by `atom-one-dark`.
- **High Contrast**: Optimized legibility on a true pitch-black background.

### 📁 Collections & Environments
- **Request Management**: Save and organize your API requests into persistent collections (backed by MongoDB).
- **Environment Variables**: Define variables like `{{base_url}}` and resolve them dynamically across your requests.

### 🎨 Pure Black Cyber Aesthetic
- **Immersive UI**: The entire application is locked to a true **Pitch Black** (`0xFF000000`) theme for focus and battery efficiency.
- **Neon Accents**: Vibrant Indigo and Emerald Green highlights provide a high-end "Cyber" feel.
- **Stylish Branding**: A unique, typography-focused splash screen with neon flicker and staggered letter animations.

---

## 🏗️ Technical Architecture

### Frontend (Flutter)
- **Clean Architecture**: Strictly separated into `Domain`, `Data`, and `Presentation` layers for maintainability and scalability.
- **State Management**: Uses `Provider` for clean, reactive state handling.
- **Theming**: Fully custom `ThemeData` optimized for high-contrast dark environments.
- **Animations**: Driven by `flutter_animate` for smooth, jitter-free transitions.

### Backend (Node.js/Express)
- **RESTful API**: Clean endpoint structure for request execution and persistent storage.
- **Variable Resolution**: Advanced service for resolving environment variables in URLs, headers, and bodies.
- **Database**: Integrated with **MongoDB** for secure collection and environment storage.
- **Execution Engine**: Reliable request handling using **Axios**.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.7.2 or higher)
- [Node.js](https://nodejs.org/) (v16+ recommended)
- [MongoDB](https://www.mongodb.com/) (Local or Atlas)

### 1. Backend Setup
```bash
cd backend
npm install
# Create a .env file with:
# PORT=5000
# MONGODB_URI=your_mongodb_connection_string
npm run dev
```

### 2. Frontend Setup
```bash
cd inspecto
flutter pub get
# If running on Android emulator, the API points to 10.0.2.2:5000 automatically
flutter run
```

---

## 🛠️ Key Dependencies

| Frontend | Backend |
| :--- | :--- |
| `provider` (State) | `express` (Server) |
| `http` (Requests) | `axios` (Execution) |
| `flutter_highlight` (Syntax) | `mongoose` (ODM) |
| `flutter_animate` (UX) | `cors` & `morgan` |
| `google_fonts` (Typography) | `dotenv` |

---

## 📝 License
Proprietary tool designed for professional API debugging.

---

Developed with ❤️ by **[Ashish](https://github.com/Ashish6298)** & **Google Deepmind Advanced Agentic Coding Team**.
