import 'package:cloud_firestore/cloud_firestore.dart';

class Friend {
  final String? uid;
  final String? email;
  final String? displayName;
  final List<String>? friends;
  final List<String>? friendRequests;
  final List<String>? upcomingMeetups;
  final List<String>? invitedMeetups;
  final GeoPoint? coordinates;

  Friend({
    this.uid,
    this.email,
    this.displayName,
    this.friends,
    this.friendRequests,
    this.upcomingMeetups,
    this.invitedMeetups,
    this.coordinates,
  });

  factory Friend.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Friend(
      uid: data?['uid'],
      email: data?['email'],
      displayName: data?['displayName'],
      friends: data?['friends'] is Iterable ? List<String>.from(data?['friends']) : null,
      friendRequests: data?['friendRequests'] is Iterable ? List<String>.from(data?['friendRequests']) : null,
      upcomingMeetups: data?['upcomingMeetups'] is Iterable ? List<String>.from(data?['upcomingMeetups']) : null,
      invitedMeetups: data?['invitedMeetups'] is Iterable ? List<String>.from(data?['invitedMeetups']) : null,
      coordinates: data?['coordinates'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (uid != null) "uid": uid,
      if (email != null) "email": email,
      if (displayName != null) "displayName": displayName,
      if (friends != null) "friends": friends,
      if (friendRequests != null) "friendRequests": friendRequests,
      if (upcomingMeetups != null) "upcomingMeetups": upcomingMeetups,
      if (invitedMeetups != null) "invitedMeetups": invitedMeetups,
      if (coordinates != null) "coordinates": coordinates,
    };
  }

}