import 'package:be_there/constants/strings.dart';
import 'package:be_there/screens/Login/authentication_page.dart';
import 'package:be_there/services/database.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/Home/home_page.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Firebase Auth
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/ProgressIndicator/progress_indicator_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(BeThereApp());
}

class BeThereApp extends StatelessWidget {
  const BeThereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: ProgressIndicatorPage(),
          );
        }

        return MaterialApp(
          title: AppTitle,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
          ),
          home: snapshot.hasData ? HomePage() : AuthenticationPage(),
        );
      },
    );
  }
}
