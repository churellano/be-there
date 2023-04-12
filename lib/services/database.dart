import 'package:be_there/constants/strings.dart';
import 'package:be_there/models/meetup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/friend.dart';

class Database {
  static var db = FirebaseFirestore.instance;

  /// Return a stream listening to changes to this Friend
  static Stream<DocumentSnapshot<Map<String, dynamic>>> getFriendStream(String uid) {
    return db.collection(UsersCollection).doc(uid).snapshots();
  }

  /// Return a stream listening to changes to this Meetup
  static Stream<DocumentSnapshot<Map<String, dynamic>>> getMeetupStream(String meetupId) {
    return db.collection(MeetupsCollection).doc(meetupId).snapshots();
  }

  /// Find a friend by uid
  static Future<DocumentSnapshot<Map<String, dynamic>>> getFriend(String uid) {
    return db.collection(UsersCollection).doc(uid).get();
  }

  /// Find all friends of a user
  static Future<List<DocumentSnapshot<Map<String, dynamic>>>> getAllFriends(Friend user) {
    return Future.wait([
      for (String friendDocumentId in user.friends!)
        db.collection(UsersCollection).doc(friendDocumentId).get()
    ]);
  }

  /// Find all upcoming meetups of a user
  static Future<List<DocumentSnapshot<Map<String, dynamic>>>> getAllMeetups(Friend user, [bool includeInvited = false]) {
    if (includeInvited) {
      return Future.wait([
        for (String meetupDocumentId in user.upcomingMeetups!)
          db.collection(MeetupsCollection).doc(meetupDocumentId).get(),
        for (String meetupDocumentId in user.invitedMeetups!)
          db.collection(MeetupsCollection).doc(meetupDocumentId).get()
      ]);
    }

    return Future.wait([
      for (String meetupDocumentId in user.upcomingMeetups!)
        db.collection(MeetupsCollection).doc(meetupDocumentId).get()
    ]);
  }

  /// Creates a new user in the database or return existing one
  static Future<Friend> createFriend(User user) async {
    var documentSnapshot = await db.collection(UsersCollection).doc(user.uid).get();

    if (documentSnapshot.exists) {
      return Friend.fromFirestore(documentSnapshot, null);
    }

    final newUserData = {
      "uid": user.uid,
      "email": user.email,
      "displayName": user.displayName,
      "friends": [],
      "friendRequests": [],
      "upcomingMeetups": [],
      "invitedMeetups": [],
    };

    await db.collection(UsersCollection).doc(user.uid).set(newUserData);
    documentSnapshot = await db.collection(UsersCollection).doc(user.uid).get();

    return Friend.fromFirestore(documentSnapshot, null);
  }

  /// Adds the requester to the specified person's requests list, and returns [True] if successful
  static Future<bool> sendFriendRequest(String requesterUid, String requesteeEmail) async {
    if (FirebaseAuth.instance.currentUser?.email == requesteeEmail) {
      return false;
    }

    final friendQuerySnapshot = await db.collection(UsersCollection).where("email", isEqualTo: requesteeEmail).get();

    if (friendQuerySnapshot.docs.isEmpty) {
      return false;
    }

    final friendSnapshot = friendQuerySnapshot.docs[0];

    if (!friendSnapshot.exists) {
      return false;
    }

    await friendSnapshot.reference.update({
      "friendRequests": FieldValue.arrayUnion([requesterUid])
    });
      
    return true;
  }

  /// Find meetup by id
  static Future<DocumentSnapshot<Map<String, dynamic>>> getMeetup(String documentId) async {
    print("getMeetup");
    final meetupSnapshot = await db.collection(MeetupsCollection).doc(documentId).get();

    if (!meetupSnapshot.exists) {
      throw Exception("Meetup does not exist!");
    }

    return meetupSnapshot;
  }

  /// Accept friend request from uid
  static Future<bool> acceptFriendRequest(
    DocumentSnapshot<Map<String, dynamic>> requester,
    DocumentSnapshot<Map<String, dynamic>> receiver
  ) async {
    if (!requester.exists || !receiver.exists) {
      return false;
    }

    await requester.reference.update({
      "friends": FieldValue.arrayUnion([receiver.id]),
    });

    await receiver.reference.update({
      "friendRequests": FieldValue.arrayRemove([requester.id]),
      "friends": FieldValue.arrayUnion([requester.id]),
    });

    return true;
  }

  /// Decline friend request from uid
  static Future<bool> declineFriendRequest(String requesterUid) async {
    final currentUserDocumentSnapshot = await db.collection(UsersCollection).doc(FirebaseAuth.instance.currentUser?.uid).get();

    if (!currentUserDocumentSnapshot.exists) {
      return false;
    }

    await currentUserDocumentSnapshot.reference.update({
      "friendRequests": FieldValue.arrayRemove([requesterUid])
    });

    return true;

  }

  /// Unfriend from uid
  static Future<bool> unfriend(
    DocumentSnapshot<Map<String, dynamic>> user,
    DocumentSnapshot<Map<String, dynamic>> exFriend
  ) async {
    if (!user.exists || !exFriend.exists) {
      return false;
    }

    await user.reference.update({
      "friends": FieldValue.arrayRemove([exFriend.id])
    });

    await exFriend.reference.update({
      "friends": FieldValue.arrayRemove([user.id])
    });

    return true;
  }

  /// Invite a friend to a meetup
  static Future<bool> inviteToMeetup(
    DocumentSnapshot<Map<String, dynamic>> friendDocumentSnapshot,
    String meetupId
  ) async {
    if (!friendDocumentSnapshot.exists) {
      return false;
    }

    await friendDocumentSnapshot.reference.update({
      "invitedMeetups": FieldValue.arrayUnion([meetupId])
    });

    return true;
  }

  /// Get my upcoming meetups
  static Future<List<String>> getUpcomingMeetups(String friendUid) async {
    final userDocumentSnapshot = await db.collection(UsersCollection).doc(friendUid).get();

    if (!userDocumentSnapshot.exists) {
      return [];
    }

    return userDocumentSnapshot.get("upcomingMeetups");
  }

  /// Create a new meetup
  static Future<bool> createMeetup(String userId, Meetup meetup) async {
    final DocumentSnapshot<Map<String, dynamic>> userDocumentSnapshot = await db.collection(UsersCollection).doc(userId).get();
    if (!userDocumentSnapshot.exists) {
      return false;
    }

    final newMeetup = await db.collection(MeetupsCollection)
      .withConverter(
        fromFirestore: Meetup.fromFirestore,
        toFirestore: (Meetup meetup, options) => meetup.toFirestore()
      )
      .add(meetup);
    
    await newMeetup.update({
      "id": newMeetup.id
    });

    for (String attendeeId in meetup.attendees!) {
      if (attendeeId != userDocumentSnapshot.id) {
        await db.collection(UsersCollection).doc(attendeeId).update({
          "invitedMeetups": FieldValue.arrayUnion([newMeetup.id])
        });
      }
    }

    // Add meetup to user's upcomingMeetups
    await userDocumentSnapshot.reference.update({
      "upcomingMeetups": FieldValue.arrayUnion([newMeetup.id])
    });

    return true;
  }

  /// Accept meetup invite
  static Future<bool> acceptMeetupInvite(
    DocumentSnapshot<Map<String, dynamic>> user,
    String meetupId
  ) async {
    if (!user.exists || meetupId.isEmpty) {
      return false;
    }

    await user.reference.update({
      "invitedMeetups": FieldValue.arrayRemove([meetupId]),
      "upcomingMeetups": FieldValue.arrayUnion([meetupId]),
    });

    return true;
  }

  /// Decline meetup invite
  static Future<bool> declineMeetupInvite(
    DocumentSnapshot<Map<String, dynamic>> user,
    String meetupId
  ) async {
    if (!user.exists || meetupId.isEmpty) {
      return false;
    }

    await user.reference.update({
      "invitedMeetups": FieldValue.arrayRemove([meetupId]),
    });

    return true;
  }

  // /// Find a stream of user's closest upcomingMeetup by 
  // static Stream<DocumentSnapshot<Map<String, dynamic>>> getClosestUpcomingMeetup(DocumentSnapshot<Map<String, dynamic>> userDocumentSnapshot) async {
  //   if (!userDocumentSnapshot.exists) {
  //     throw Exception("User (uid: ${userDocumentSnapshot.id}) does not exist!");
  //   }

  //   final Friend user = Friend.fromFirestore(userDocumentSnapshot, null);
  //   if (user.upcomingMeetups == null) {
  //     throw Exception("User (uid: ${userDocumentSnapshot.id}) upcomingMeetups array is null!");
  //   }

  //   if (user.upcomingMeetups!.isEmpty) {
  //     throw Exception("User (uid: ${userDocumentSnapshot.id}) upcomingMeetups array is empty!");
  //   }

  //   final List<DocumentSnapshot<Map<String, dynamic>>> meetupDocumentSnapshots = await Future.wait(
  //     user.upcomingMeetups!.map(
  //       (String meetupId) => 
  //       db.collection(MeetupsCollection)
  //         .doc(meetupId)
  //         .get()
  //     ).toList()
  //   );

  //   final List<Meetup> meetups = meetupDocumentSnapshots.map((meetupDocumentSnapshot) => Meetup.fromFirestore(meetupDocumentSnapshot, null)).toList();

  //   Meetup closestMeetup = meetups.reduce((currentUser, nextUser) => currentUser.date!.compareTo(nextUser.date!) < 0 ? currentUser : nextUser);

  //   final DocumentReference<Map<String, dynamic>> closestMeetupDocRef = db.collection(MeetupsCollection).doc(closestMeetup.id);
  //   final DocumentSnapshot<Map<String, dynamic>> meetupSnapshot = await closestMeetupDocRef.get();

  //   if (!meetupSnapshot.exists) {
  //     throw Exception("Meetup does not exist!");
  //   }

  //   return closestMeetupDocRef.snapshots();
  // }
}