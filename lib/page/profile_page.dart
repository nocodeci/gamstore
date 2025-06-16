import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user.dart' as app_user;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = false;

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade400 : Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFf32733),
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      setState(() => _isLoading = true);
      HapticFeedback.lightImpact();

      try {
        await AuthService.signOut();
        if (mounted) {
          _showSnackBar('Déconnexion réussie', isError: false);
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Erreur lors de la déconnexion: $e');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.currentUser;
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Utilisateur non connecté'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mon Profil',
          style: TextStyle(
            color: Color(0xFF2d3748),
            fontWeight: FontWeight.w600,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<app_user.User?>(
        future: FirestoreService.getUserById(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFf32733),
              ),
            );
          }

          final userData = snapshot.data;

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildProfileHeader(currentUser, userData),
                const SizedBox(height: 32),
                _buildProfileOptions(),
                const SizedBox(height: 32),
                _buildSignOutButton(),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(user, app_user.User? userData) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFf32733).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.person_rounded,
              size: 40,
              color: const Color(0xFFf32733),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userData?.fullName ?? user.displayName ?? 'Utilisateur',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2d3748),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          if (userData?.phoneNumber != null && userData!.phoneNumber.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              userData.phoneNumber,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileOptions() {
    final options = [
      {
        'icon': Icons.edit_rounded,
        'title': 'Modifier le profil',
        'subtitle': 'Mettre à jour vos informations',
        'onTap': () {
          _showSnackBar('Fonctionnalité à venir', isError: false);
        },
      },
      {
        'icon': Icons.history_rounded,
        'title': 'Historique des voyages',
        'subtitle': 'Voir tous vos voyages passés',
        'onTap': () {
          _showSnackBar('Fonctionnalité à venir', isError: false);
        },
      },
      {
        'icon': Icons.notifications_rounded,
        'title': 'Notifications',
        'subtitle': 'Gérer vos préférences',
        'onTap': () {
          _showSnackBar('Fonctionnalité à venir', isError: false);
        },
      },
      {
        'icon': Icons.help_rounded,
        'title': 'Aide et support',
        'subtitle': 'Obtenir de l\'aide',
        'onTap': () {
          _showSnackBar('Fonctionnalité à venir', isError: false);
        },
      },
      {
        'icon': Icons.info_rounded,
        'title': 'À propos',
        'subtitle': 'Version de l\'application',
        'onTap': () {
          _showSnackBar('KKC Transport v1.0.0', isError: false);
        },
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Column(
        children: options.map((option) {
          final isLast = option == options.last;
          return Container(
            decoration: BoxDecoration(
              border: isLast ? null : Border(
                bottom: BorderSide(color: Colors.grey.shade100, width: 1),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  option['icon'] as IconData,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ),
              title: Text(
                option['title'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: Color(0xFF2d3748),
                ),
              ),
              subtitle: Text(
                option['subtitle'] as String,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey.shade400,
              ),
              onTap: option['onTap'] as VoidCallback,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _signOut,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.logout_rounded, color: Colors.white),
        label: Text(
          _isLoading ? 'Déconnexion...' : 'Se déconnecter',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFf32733),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}