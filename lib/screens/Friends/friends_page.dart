import 'package:be_there/constants/strings.dart';
import 'package:be_there/models/friend.dart';
import 'package:be_there/models/meetup.dart';
import 'package:be_there/screens/Friends/add_friend_page.dart';
import 'package:be_there/screens/ProgressIndicator/progress_indicator_page.dart';
import 'package:be_there/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _FriendsPageState();
  }
}

class _FriendsPageState extends State<FriendsPage> {
  List<DocumentSnapshot<Map<String, dynamic>>> friends = [];
  List<DocumentSnapshot<Map<String, dynamic>>> meetups = [];
  late QueryDocumentSnapshot<Map<String, dynamic>> user;

  @override
  Widget build(BuildContext context) {
    var friendRelationsStream = FirebaseFirestore.instance.collection("friendRelations")
      .where("userIds", arrayContains: FirebaseAuth.instance.currentUser!.uid)
      .snapshots();

    return StreamBuilder(
      stream: friendRelationsStream,
      builder: (context, friendRelationSnapshots) {
        if (!friendRelationSnapshots.hasData) {
          return ProgressIndicatorPage();
        }

        // Create list of all friends to fetch
        List<String> friendIds = [];
        for (var friendRelation in friendRelationSnapshots.data!.docs) {
          friendIds.add(
            friendRelation.data()["userIds"]
              .firstWhere((userId) => userId != FirebaseAuth.instance.currentUser!.uid)
          );
        }

        var friendFutures = Future.wait([
          for (String friendId in friendIds)
            FirebaseFirestore.instance.collection(UsersCollection).doc(friendId).get()
        ]);

        var meetupFutures = FirebaseFirestore.instance.collection(MeetupsCollection)
          .where("attendees", arrayContains: FirebaseAuth.instance.currentUser!.uid)
          .get();

        var userFuture = FirebaseFirestore.instance.collection(UsersCollection)
          .where("uid", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .get();

        return FutureBuilder<dynamic>(
          future: Future.wait([
            friendFutures.then((value) => friends = value),
            meetupFutures.then((value) => meetups = value.docs),
            userFuture.then((value) => user = value.docs[0])
          ]),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return ProgressIndicatorPage(); 
            }

            return Scaffold(  
              body: Center(
                child: ListView(
                  children: ListTile.divideTiles(
                    context: context,
                    tiles: [
                      Text(
                        FriendsHeading,
                        style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 2.0),
                      ),
                      ...friends.map((friendDocumentSnapshot) {
                        final Friend friend = Friend.fromFirestore(friendDocumentSnapshot, null);

                        return ListTile(
                          title: Text(friend.displayName!),
                          trailing: Wrap(
                            spacing: 12,
                            children: [
                              FutureBuilder(
                                future: Future.wait([
                                  for (
                                    final String meetupDocumentId in (
                                      friend.upcomingMeetups! +
                                      friend.invitedMeetups!
                                    )
                                  )
                                    Database.getMeetup(meetupDocumentId)
                                ]),
                                builder: (context, meetupsSnapshot) {
                                  Friend currentUser = Friend.fromFirestore(user, null);

                                  final Set<String> meetupsSet = Set<String>.from(currentUser.upcomingMeetups!);
                                  final Set<String> friendMeetupsSet = Set<String>.from(
                                    friend.upcomingMeetups! +
                                    friend.invitedMeetups!
                                  );
                                  final Set<String> meetupIdsFriendIsNotInvitedTo = meetupsSet.difference(friendMeetupsSet);

                                  final meetupsToDisplay = meetups.where((meetupDocumentSnapshot) => meetupIdsFriendIsNotInvitedTo
                                    .contains(meetupDocumentSnapshot.id))
                                    .toList();

                                  return PopupMenuButton(
                                    icon: Icon(Icons.add),
                                    itemBuilder: (context) =>
                                      meetupsToDisplay.map((meetupDocumentSnapshot) {
                                        final Meetup meetup = Meetup.fromFirestore(meetupDocumentSnapshot, null);
                                        return PopupMenuItem(
                                          child: Text(meetup.name!),
                                          onTap: () {
                                            // Invite friend to event
                                            Database.inviteToMeetup(friendDocumentSnapshot, meetupDocumentSnapshot.id).then((isSuccessful) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: isSuccessful ?
                                                    Text("Invited ${friend.displayName!} to ${meetup.name!}") :
                                                    Text(InviteFailText)
                                                ),
                                              );
                                            });
                                          },
                                        );
                                      }).toList()
                                  );
                                },
                              ),
                              PopupMenuButton(
                                itemBuilder: (context) => <PopupMenuEntry>[
                                  PopupMenuItem(
                                    child: Text(UnfriendMenuButton),
                                    onTap: () {
                                      Database.unfriend(user, friendDocumentSnapshot)
                                        .then((isSuccessful) {
                                          if (!isSuccessful) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(UnfriendFailText)),
                                            );
                                          }
                                        });
                                    },
                                  ),
                                ]
                              ),
                            ],
                          ),
                        );
                      }),
                    ]
                  ).toList(),
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddFriendPage())
                    );
                  }
                },
                child: const Icon(Icons.person_add)
              ),
            );
          }
        );
      }
    );

    // return StreamBuilder(
    //   stream: Database.getFriendStream(FirebaseAuth.instance.currentUser!.uid),
    //   builder: (context, userSnapshot) {
    //     if (!userSnapshot.hasData) {
    //       return ProgressIndicatorPage();
    //     }
    //     final Friend user = Friend.fromFirestore(userSnapshot.data!, null);

    //     return FutureBuilder<List<List<DocumentSnapshot<Map<String, dynamic>>>>>(
    //       future: Future.wait([
    //         Database.getAllFriends(user).then((value) => friends = value),
    //         Database.getAllMeetups(user).then((value) => meetups = value),
    //       ]),
    //       builder: (context, snapshot) {
            // if (!snapshot.hasData) {
            //   return ProgressIndicatorPage(); 
            // }

            // return Scaffold(  
            //   body: Center(
            //     child: ListView(
            //       children: ListTile.divideTiles(
            //         context: context,
            //         tiles: [
            //           Text(
            //             FriendsHeading,
            //             style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 2.0),
            //           ),
            //           ...friends.map((friendDocumentSnapshot) {
            //             final Friend friend = Friend.fromFirestore(friendDocumentSnapshot, null);

            //             return ListTile(
            //               title: Text(friend.displayName!),
            //               trailing: Wrap(
            //                 spacing: 12,
            //                 children: [
            //                   FutureBuilder(
            //                     future: Future.wait([
            //                       for (
            //                         final String meetupDocumentId in (
            //                           friend.upcomingMeetups! +
            //                           friend.invitedMeetups!
            //                         )
            //                       )
            //                         Database.getMeetup(meetupDocumentId)
            //                     ]),
            //                     builder: (context, meetupsSnapshot) {
            //                       final Set<String> meetupsSet = Set<String>.from(user.upcomingMeetups!);
            //                       final Set<String> friendMeetupsSet = Set<String>.from(
            //                         friend.upcomingMeetups! +
            //                         friend.invitedMeetups!
            //                       );
            //                       final Set<String> meetupIdsFriendIsNotInvitedTo = meetupsSet.difference(friendMeetupsSet);

            //                       final meetupsToDisplay = meetups.where((meetupDocumentSnapshot) => meetupIdsFriendIsNotInvitedTo
            //                         .contains(meetupDocumentSnapshot.id))
            //                         .toList();

            //                       return PopupMenuButton(
            //                         icon: Icon(Icons.add),
            //                         itemBuilder: (context) =>
            //                           meetupsToDisplay.map((meetupDocumentSnapshot) {
            //                             final Meetup meetup = Meetup.fromFirestore(meetupDocumentSnapshot, null);
            //                             return PopupMenuItem(
            //                               child: Text(meetup.name!),
            //                               onTap: () {
            //                                 // Invite friend to event
            //                                 Database.inviteToMeetup(friendDocumentSnapshot, meetupDocumentSnapshot.id).then((isSuccessful) {
            //                                   ScaffoldMessenger.of(context).showSnackBar(
            //                                     SnackBar(
            //                                       content: isSuccessful ?
            //                                         Text("Invited ${friend.displayName!} to ${meetup.name!}") :
            //                                         Text(InviteFailText)
            //                                     ),
            //                                   );
            //                                 });
            //                               },
            //                             );
            //                           }).toList()
            //                       );
            //                     },
            //                   ),
            //                   PopupMenuButton(
            //                     itemBuilder: (context) => <PopupMenuEntry>[
            //                       PopupMenuItem(
            //                         child: Text(UnfriendMenuButton),
            //                         onTap: () {
            //                           Database.unfriend(userSnapshot.data!, friendDocumentSnapshot)
            //                             .then((isSuccessful) {
            //                               if (!isSuccessful) {
            //                                 ScaffoldMessenger.of(context).showSnackBar(
            //                                   SnackBar(content: Text(UnfriendFailText)),
            //                                 );
            //                               }
            //                             });
            //                         },
            //                       ),
            //                     ]
            //                   ),
            //                 ],
            //               ),
            //             );
            //           }),
            //         ]
            //       ).toList(),
            //     ),
            //   ),
            //   floatingActionButton: FloatingActionButton(
            //     onPressed: () {
            //       if (context.mounted) {
            //         Navigator.push(
            //           context,
            //           MaterialPageRoute(builder: (context) => AddFriendPage())
            //         );
            //       }
            //     },
            //     child: const Icon(Icons.person_add)
            //   ),
            // );
    //       },
    //     );
    //   }
    // );
  }
}