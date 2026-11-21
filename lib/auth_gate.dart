
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'screens/auth_screen.dart';

class AuthGate extends StatelessWidget {
  final Widget authenticatedScreen;

  const AuthGate({
    super.key,
    required this.authenticatedScreen,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Unable to check login status.'),
            ),
          );
        }

        if (snapshot.hasData) {
          return authenticatedScreen;
        }

        return const AuthScreen();
      },
    );
  }
}
