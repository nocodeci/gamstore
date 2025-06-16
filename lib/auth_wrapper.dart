import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'main_navigation.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        // En cours de chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFFf32733),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Chargement...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF718096),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ✅ Toujours afficher MainNavigation (connecté ou pas)
        return const MainNavigation();
      },
    );
  }
}