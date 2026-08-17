Expense Tracker
A modern personal finance and expense tracking application built with Flutter, Firebase, and Hive CE. Track daily expenses, manage user accounts securely, and store data locally and in the cloud.

Key Features
User Authentication: Secure sign-up, login, and session management using Firebase Authentication.

Offline-First Storage: Fast and reliable local storage powered by Hive CE (hive_ce).

Multi-Device Testing: Integrated UI testing across multiple screen sizes using Device Preview.

Responsive UI: Adaptive design supporting both iOS (Cupertino) and Android (Material) components.

expense_tracker/
├── android/               # Native Android configurations
├── ios/                   # Native iOS configurations
├── lib/                   # Main Dart source code
│   ├── main.dart          # Entry point of the app
│   ├── models/            # Data models & Hive adapters
│   ├── screens/           # UI screens and layouts
│   ├── services/          # Firebase & Hive storage services
│   └── widgets/           # Reusable UI components
├── pubspec.yaml           # Dependencies and asset declarations
└── README.md              # Project documentation