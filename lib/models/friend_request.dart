import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequest {
  final String? id;
  final List<String>? userIds;

  FriendRequest({
    this.id,
    this.userIds,
  });

  factory FriendRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return FriendRequest(
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