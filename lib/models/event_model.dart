import 'package:cloud_firestore/cloud_firestore.dart';

/// Wesak event data model
/// Firestore document structure mirror කරනවා
class EventModel {
  final String id;
  final String name;
  final String type; // dansal | thorana | kudu | geetha
  final String description;
  final double lat;
  final double lng;
  final String city;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> photos; // Firebase Storage download URLs
  final double rating;
  final bool verified; // Admin approved -> true
  final String status; // pending | approved | rejected
  final String addedBy; // Firebase Auth user UID
  final String foodItems; // Dansal ෙකදී දෙන ආහාර list (dansal only)

  const EventModel({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.lat,
    required this.lng,
    required this.city,
    required this.startTime,
    required this.endTime,
    this.photos = const [],
    this.rating = 0.0,
    this.verified = false,
    this.status = 'pending',
    required this.addedBy,
    this.foodItems = '',
  });

  /// Firestore document snapshot -> EventModel
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      name: data['name'] as String,
      type: data['type'] as String,
      description: data['description'] as String? ?? '',
      lat: (data['location']?['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['location']?['lng'] as num?)?.toDouble() ?? 0.0,
      city: data['city'] as String? ?? '',
      // Firestore Timestamp හෝ String දෙකම handle කරනවා
      startTime: _toDateTime(data['startTime']),
      endTime: _toDateTime(data['endTime']),
      photos: List<String>.from(data['photos'] ?? []),
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      verified: data['verified'] as bool? ?? false,
      status: data['status'] as String? ?? 'pending',
      addedBy: data['addedBy'] as String? ?? '',
      foodItems: data['foodItems'] as String? ?? '',
    );
  }

  /// EventModel -> Firestore document map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type,
      'description': description,
      'location': {'lat': lat, 'lng': lng},
      'city': city,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'photos': photos,
      'rating': rating,
      'verified': verified,
      'status': status,
      'addedBy': addedBy,
      'foodItems': foodItems,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Firestore Timestamp හෝ String -> DateTime
  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}
