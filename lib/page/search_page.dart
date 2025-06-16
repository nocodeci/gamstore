import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Recherche',
          style: TextStyle(
            color: Color(0xFF2d3748),
            fontWeight: FontWeight.w600,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 64,
              color: Color(0xFFf32733),
            ),
            SizedBox(height: 16),
            Text(
              'Page de recherche',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2d3748),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Fonctionnalité à venir',
              style: TextStyle(
                color: Color(0xFF718096),
              ),
            ),
          ],
        ),
      ),
    );
  }
}