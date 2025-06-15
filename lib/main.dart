import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kkc/page/home.dart';
import 'services/firestore_service.dart';
import 'package:logger/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Initialiser Firebase
  await Firebase.initializeApp();

  final logger = Logger();
  
  // ✅ Tester la connexion (optionnel)
  final isConnected = await FirestoreService.testConnection();
  if (isConnected) {
    logger.i('✅ Firestore connecté');
  } else {
    logger.e('❌ Erreur Firestore');
  }
  
  // ✅ Initialiser les données par défaut (décommentez lors du premier lancement)
  // await FirestoreService.initializeDefaultData();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KKC Transport',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const Home(),
      debugShowCheckedModeBanner: false,
    );
  }
}