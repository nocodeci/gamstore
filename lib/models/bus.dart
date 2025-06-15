class Bus {
  final String id;
  final String companyId;    // ✅ Selon votre DB
  final String plateNumber;  // ✅ Selon votre DB
  final String busModel;     // ✅ Selon votre DB
  final int seatCount;       // ✅ Selon votre DB
  final SeatMap seatMap;     // ✅ Selon votre DB

  Bus({
    required this.id,
    required this.companyId,
    required this.plateNumber,
    required this.busModel,
    required this.seatCount,
    required this.seatMap,
  });

  factory Bus.fromFirestore(Map<String, dynamic> data, String id) {
    return Bus(
      id: id,
      companyId: data['companyId'] ?? '',        // ✅ Nom exact de votre DB
      plateNumber: data['plateNumber'] ?? '',    // ✅ Nom exact de votre DB
      busModel: data['busModel'] ?? '',          // ✅ Nom exact de votre DB
      seatCount: data['seatCount'] ?? 0,         // ✅ Nom exact de votre DB
      seatMap: SeatMap.fromMap(data['seatMap'] ?? {}), // ✅ Nom exact de votre DB
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'companyId': companyId,        // ✅ Nom exact de votre DB
      'plateNumber': plateNumber,    // ✅ Nom exact de votre DB
      'busModel': busModel,          // ✅ Nom exact de votre DB
      'seatCount': seatCount,        // ✅ Nom exact de votre DB
      'seatMap': seatMap.toMap(),    // ✅ Nom exact de votre DB
    };
  }
}

class SeatMap {
  final int rows;     // ✅ Selon votre DB
  final int columns;  // ✅ Selon votre DB

  SeatMap({required this.rows, required this.columns});

  factory SeatMap.fromMap(Map<String, dynamic> data) {
    return SeatMap(
      rows: data['rows'] ?? 0,        // ✅ Nom exact de votre DB
      columns: data['columns'] ?? 0,  // ✅ Nom exact de votre DB
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rows': rows,        // ✅ Nom exact de votre DB
      'columns': columns,  // ✅ Nom exact de votre DB
    };
  }
}