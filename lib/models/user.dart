import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;          // ✅ Selon votre DB
  final String fullName;     // ✅ Selon votre DB
  final String phoneNumber;  // ✅ Selon votre DB
  final String email;        // ✅ Selon votre DB
  final DateTime createdAt;  // ✅ Selon votre DB

  User({
    required this.uid,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.createdAt,
  });

  factory User.fromFirestore(Map<String, dynamic> data, String id) {
    return User(
      uid: data['uid'] ?? '',                        // ✅ Nom exact de votre DB
      fullName: data['fullName'] ?? '',              // ✅ Nom exact de votre DB
      phoneNumber: data['phoneNumber'] ?? '',        // ✅ Nom exact de votre DB
      email: data['email'] ?? '',                    // ✅ Nom exact de votre DB
      createdAt: (data['createdAt'] as Timestamp).toDate(), // ✅ Nom exact de votre DB
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,                                    // ✅ Nom exact de votre DB
      'fullName': fullName,                          // ✅ Nom exact de votre DB
      'phoneNumber': phoneNumber,                    // ✅ Nom exact de votre DB
      'email': email,                                // ✅ Nom exact de votre DB
      'createdAt': Timestamp.fromDate(createdAt),    // ✅ Nom exact de votre DB
    };
  }
}