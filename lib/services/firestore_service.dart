import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

/// Firestore database operations
/// Events collection: add, fetch, stream
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Firestore collection reference
  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('events');

  /// Public map/list ට - admin verified events only stream
  /// orderBy Dart side ෙකන් කරනවා - Firestore composite index ඕනේ නෑ
  Stream<List<EventModel>> getVerifiedEventsStream() {
    return _events
        .where('verified', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
      // startTime අනුව sort කරනවා
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
      return list;
    });
  }

  /// "My Submissions" screen ට - specific user ගේ events stream
  /// Pending + approved + rejected සියල්ලම show කරනවා
  Stream<List<EventModel>> getUserEventsStream(String uid) {
    return _events
        .where('addedBy', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
      // Newest first - createdAt descending
      list.sort((a, b) => b.startTime.compareTo(a.startTime));
      return list;
    });
  }

  /// Home screen category card ෙකන් - specific type events stream
  Stream<List<EventModel>> getEventsByTypeStream(String type) {
    return _events
        .where('verified', isEqualTo: true)
        .where('type', isEqualTo: type)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
      return list;
    });
  }

  /// Admin panel ට - pending approval events stream
  Stream<List<EventModel>> getPendingEventsStream() {
    return _events
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
      // Newest first
      list.sort((a, b) => b.startTime.compareTo(a.startTime));
      return list;
    });
  }

  /// User submit කළ event Firestore ට save කරනවා
  /// status: 'pending', verified: false — admin approval ට wait
  Future<void> addEvent(EventModel event) async {
    await _events.add(event.toFirestore());
  }

  /// Admin approve — event public map ේ show කරනවා
  Future<void> approveEvent(String eventId) async {
    await _events.doc(eventId).update({
      'status': 'approved',
      'verified': true,
    });
  }

  /// Admin reject — reason optional ලෙස save කරනවා
  Future<void> rejectEvent(String eventId, {String? reason}) async {
    await _events.doc(eventId).update({
      'status': 'rejected',
      'verified': false,
      'rejectionReason': reason,
    });
  }

  /// Admin හෝ owner ට event delete කරන්න
  Future<void> deleteEvent(String eventId) async {
    await _events.doc(eventId).delete();
  }
}
