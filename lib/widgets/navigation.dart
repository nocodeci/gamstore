import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 20,
            offset: const Offset(0, -8),
            spreadRadius: 0,
          ),
        ],
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            HapticFeedback.lightImpact();
            onTap(index);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFf32733),
          unselectedItemColor: Colors.grey.shade500,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(
                Icons.home_rounded,
                Icons.home_outlined,
                0,
              ),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(
                Icons.event_seat_rounded,
                Icons.event_seat_outlined,
                1,
              ),
              label: 'Réservation',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(
                Icons.notifications_rounded,
                Icons.notifications_outlined,
                2,
              ),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(
                Icons.person_rounded,
                Icons.person_outline_rounded,
                3,
              ),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData selectedIcon, IconData unselectedIcon, int index) {
    final isSelected = currentIndex == index;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected 
          ? const Color(0xFFf32733).withValues(alpha: 0.1)
          : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isSelected ? selectedIcon : unselectedIcon,
        size: 24,
        color: isSelected 
          ? const Color(0xFFf32733)
          : Colors.grey.shade500,
      ),
    );
  }
}
