import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'screens/home.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'services/auth_service.dart';
import 'services/hive_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  await HiveService.init();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(DevicePreview(builder: ((context) => MyApp())));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.light,
      themeMode: ThemeMode.light,
      home: const AuthGate(),
    );
  }
}

/// Routes between the signed-out auth forms and [HomePage] based on Firebase
/// auth state, and hands the signed-in user's uid to [HomePage] so it can be
/// bound to that user's `TransactionRepository`.
///
/// Login/register switching is done with an internal flag rather than
/// [Navigator], because pushing either form as its own route would stack it
/// on top of this widget — leaving it there to hide the swap to [HomePage]
/// that happens right here when [AuthService.authStateChanges] fires.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showLogin = true;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: AppBackground(
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          return HomePage(userId: user.uid);
        }

        return _showLogin
            ? LoginPage(onRegisterTap: () => setState(() => _showLogin = false))
            : RegisterPage(onLoginTap: () => setState(() => _showLogin = true));
      },
    );
  }
}
