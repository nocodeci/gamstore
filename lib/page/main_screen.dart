import 'package:flutter/material.dart';
import 'package:kkc/page/home.dart';
import 'package:kkc/page/profile.dart';
import 'package:kkc/page/reservation.dart';
import 'package:kkc/page/notificationpage.dart';
import 'package:kkc/widgets/navigation.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const Home(),
    const Reservation(),
    const NotificationPage(),
    const Profile(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}


