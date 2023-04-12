import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRelation {
  final String? id;
  final List<String>? userIds;

  FriendRelation({
    this.id,
    this.userIds,
  });

  factory FriendRelation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return FriendRelation(
      id: data?['id'],
      userIds: data?['userIds'] is Iterable ? List<String>.from(data?['userIds']) : null,
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      if (id != null) "id": id,
      if (userIds != null) "userIds": userIds,
    };
  }
}