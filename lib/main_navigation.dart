import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'page/home.dart';
import 'page/search_page.dart';
import 'page/bookings_page.dart';
import 'page/profile_page.dart';
import 'page/login_page.dart';
import 'services/auth_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    // ✅ Vérifier si l'utilisateur est connecté pour certaines pages
    if (!AuthService.isLoggedIn && _isProtectedPage(index)) {
      _showLoginDialog(index);
      return;
    }

    if (index != _currentIndex) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _isProtectedPage(int index) {
    // Pages qui nécessitent une connexion
    return index == 2 || index == 3; // Réservations et Profil
  }

  void _showLoginDialog(int targetIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connexion requise'),
        content: const Text(
          'Vous devez vous connecter pour accéder à cette section.\n\nSouhaitez-vous vous connecter maintenant ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFf32733),
            ),
            child: const Text(
              'Se connecter',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getPageForIndex(int index) {
    switch (index) {
      case 0:
        return const Home();
      case 1:
        return const SearchPage();
      case 2:
        return AuthService.isLoggedIn 
            ? const BookingsPage() 
            : const _LoginRequiredPage(pageName: 'Réservations');
      case 3:
        return AuthService.isLoggedIn 
            ? const ProfilePage() 
            : const _LoginRequiredPage(pageName: 'Profil');
      default:
        return const Home();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          if (!AuthService.isLoggedIn && _isProtectedPage(index)) {
            // Revenir à la page précédente si pas connecté
            _pageController.animateToPage(
              _currentIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            return;
          }
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: 4,
        itemBuilder: (context, index) => _getPageForIndex(index),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: 'Accueil',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.search_rounded,
                  label: 'Recherche',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.bookmark_rounded,
                  label: 'Réservations',
                  index: 2,
                  isProtected: true,
                ),
                _buildNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profil',
                  index: 3,
                  isProtected: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    bool isProtected = false,
  }) {
    final isSelected = _currentIndex == index;
    final isAccessible = !isProtected || AuthService.isLoggedIn;
    
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFf32733).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  color: isSelected 
                      ? const Color(0xFFf32733)
                      : isAccessible 
                          ? Colors.grey.shade600
                          : Colors.grey.shade400,
                  size: 24,
                ),
                if (isProtected && !AuthService.isLoggedIn)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFf32733),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? const Color(0xFFf32733)
                    : isAccessible 
                        ? Colors.grey.shade600
                        : Colors.grey.shade400,
                fontSize: 12,
                fontWeight: isSelected 
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget pour les pages qui nécessitent une connexion
class _LoginRequiredPage extends StatelessWidget {
  final String pageName;

  const _LoginRequiredPage({required this.pageName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Connexion requise',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connectez-vous pour accéder à $pageName',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              icon: const Icon(Icons.login_rounded, color: Colors.white),
              label: const Text(
                'Se connecter',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFf32733),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}