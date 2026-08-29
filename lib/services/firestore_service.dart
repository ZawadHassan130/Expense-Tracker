import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin wrapper around a single Firestore collection that maps documents
/// to/from a typed model. Firestore's own offline persistence (enabled in
/// main.dart) already queues writes made while offline and replays them
/// once connectivity returns, so this service does not need to implement
/// its own retry/queue logic.
class FirestoreCollectionService<T> {
  FirestoreCollectionService({
    required this.collection,
    required this.fromMap,
    required this.toMap,
  });

  final CollectionReference<Map<String, dynamic>> collection;
  final T Function(String id, Map<String, dynamic> data) fromMap;
  final Map<String, dynamic> Function(T item) toMap;

  /// Generates a fresh document id without writing anything.
  String newId() => collection.doc().id;

  Stream<List<T>> streamAll() {
    return collection.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => fromMap(doc.id, doc.data())).toList(),
    );
  }

  Future<void> set(String id, T item) {
    return collection.doc(id).set(toMap(item));
  }

  Future<void> delete(String id) {
    return collection.doc(id).delete();
  }
}
