import 'package:cloud_firestore/cloud_firestore.dart';

class Reservation {
  final String id;
  final String tripId;         // ✅ Selon votre DB
  final int seatNumber;        // ✅ Selon votre DB
  final String userId;         // ✅ Selon votre DB
  final DateTime reservedAt;   // ✅ Selon votre DB
  final String paymentStatus;  // ✅ Selon votre DB

  Reservation({
    required this.id,
    required this.tripId,
    required this.seatNumber,
    required this.userId,
    required this.reservedAt,
    required this.paymentStatus,
  });

  factory Reservation.fromFirestore(Map<String, dynamic> data, String id) {
    return Reservation(
      id: id,
      tripId: data['tripId'] ?? '',                  // ✅ Nom exact de votre DB
      seatNumber: data['seatNumber'] ?? 0,           // ✅ Nom exact de votre DB
      userId: data['userId'] ?? '',                  // ✅ Nom exact de votre DB
      reservedAt: (data['reservedAt'] as Timestamp).toDate(), // ✅ Nom exact de votre DB
      paymentStatus: data['paymentStatus'] ?? 'pending', // ✅ Nom exact de votre DB
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tripId': tripId,                              // ✅ Nom exact de votre DB
      'seatNumber': seatNumber,                      // ✅ Nom exact de votre DB
      'userId': userId,                              // ✅ Nom exact de votre DB
      'reservedAt': Timestamp.fromDate(reservedAt),  // ✅ Nom exact de votre DB
      'paymentStatus': paymentStatus,                // ✅ Nom exact de votre DB
    };
  }
}