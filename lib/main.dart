import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:kkc/onboarding/onboarding_view.dart';
import 'package:kkc/page/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const KKCApp());
}

class KKCApp extends StatelessWidget {
  const KKCApp({super.key});

  Future<bool> loadOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("onboarding") ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KKC Transport',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFf32733),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
      ),
      home: FutureBuilder<bool>(
        future: loadOnboardingStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else {
            final onboardingDone = snapshot.data ?? false;
            return onboardingDone ? const MainScreen() : const OnboardingView();
          }
        },
      ),
    );
  }
}
