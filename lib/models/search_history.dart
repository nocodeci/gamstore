import 'package:cloud_firestore/cloud_firestore.dart';

class SearchHistory {
  final String id;
  final String fromCity;
  final String toCity;
  final DateTime travelDate;
  final DateTime searchedAt;
  final String? userId;

  SearchHistory({
    required this.id,
    required this.fromCity,
    required this.toCity,
    required this.travelDate,
    required this.searchedAt,
    this.userId,
  });

  factory SearchHistory.fromFirestore(Map<String, dynamic> data, String id) {
    return SearchHistory(
      id: id,
      fromCity: data['fromCity'] ?? '',
      toCity: data['toCity'] ?? '',
      travelDate: (data['travelDate'] as Timestamp).toDate(),
      searchedAt: (data['searchedAt'] as Timestamp).toDate(),
      userId: data['userId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fromCity': fromCity,
      'toCity': toCity,
      'travelDate': Timestamp.fromDate(travelDate),
      'searchedAt': Timestamp.fromDate(searchedAt),
      'userId': userId,
    };
  }
}