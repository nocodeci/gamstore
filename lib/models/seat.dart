import 'package:cloud_firestore/cloud_firestore.dart';

class Seat {
  final String id;
  final int seatNumber;      // ✅ Selon votre DB
  final bool isReserved;     // ✅ Selon votre DB
  final String? reservedBy;  // ✅ Selon votre DB
  final DateTime? reservedAt; // ✅ Selon votre DB

  Seat({
    required this.id,
    required this.seatNumber,
    required this.isReserved,
    this.reservedBy,
    this.reservedAt,
  });

  factory Seat.fromFirestore(Map<String, dynamic> data, String id) {
    return Seat(
      id: id,
      seatNumber: data['seatNumber'] ?? 0,           // ✅ Nom exact de votre DB
      isReserved: data['isReserved'] ?? false,       // ✅ Nom exact de votre DB
      reservedBy: data['reservedBy'],                // ✅ Nom exact de votre DB
      reservedAt: data['reservedAt'] != null 
          ? (data['reservedAt'] as Timestamp).toDate() 
          : null,                                    // ✅ Nom exact de votre DB
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'seatNumber': seatNumber,                      // ✅ Nom exact de votre DB
      'isReserved': isReserved,                      // ✅ Nom exact de votre DB
      'reservedBy': reservedBy,                      // ✅ Nom exact de votre DB
      'reservedAt': reservedAt != null 
          ? Timestamp.fromDate(reservedAt!) 
          : null,                                    // ✅ Nom exact de votre DB
    };
  }
}