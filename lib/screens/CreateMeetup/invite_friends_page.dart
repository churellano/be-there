import 'package:be_there/constants/strings.dart';
import 'package:be_there/models/friend.dart';
import 'package:be_there/models/friend_relation.dart';
import 'package:be_there/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class InviteFriendsPage extends StatefulWidget {
  InviteFriendsPage();

  @override
  State<InviteFriendsPage> createState() => _InviteFriendsPageState();
}

class _InviteFriendsPageState extends State<InviteFriendsPage> {
  // final Map<String, bool> attendeeMap = {};
  final List<String> attendees = [];

  @override
  Widget build(BuildContext context) {
    var friendRelationsStream = FirebaseFirestore.instance.collection("friendRelations")
      .where("userIds", arrayContains: FirebaseAuth.instance.currentUser!.uid)
      .snapshots();

      return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(MeetupFriendsText),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: friendRelationsStream,
                  builder: (context, friendRelationsSnapshot) {
                    if (!friendRelationsSnapshot.hasData) {
                      return Text('Loading...');
                    }

                    if (friendRelationsSnapshot.data!.docs.isEmpty) {
                      return Text("No friends found.");
                    }

                    // Create list of all friends to fetch
                    List<String> friendIds = [];
                    for (var friendRelation in friendRelationsSnapshot.data!.docs) {
                      List<String> userIds = friendRelation.get("userIds") as List<String>;
                      friendIds.add(userIds.firstWhere((userId) => userId != FirebaseAuth.instance.currentUser!.uid));
                    }

                    var friends = friendIds.map(
                      (friendId) => FirebaseFirestore.instance.collection(UsersCollection).doc(friendId).get()
                    ).toList();
                          
                    return FutureBuilder(
                      future: Future.wait(friends),
                      builder: (context, friendsSnapshot) {
                        final List<Friend> friends = friendsSnapshot.data!.map((f) => Friend.fromFirestore(f, null)).toList();

                        return Expanded(
                          child: ListView.separated(
                            itemCount: friends.length,
                            itemBuilder: (context, index) {
                              return CheckboxListTile(
                                title: Text((friends[index]).displayName!),
                                // value: attendeeMap[friends[index].uid],
                                value: attendees.contains(friends[index].uid!),
                                onChanged: (bool? isChecked) {
                                  setState(() {
                                    // print("help $isChecked ${attendeeMap[friends[index].uid!]}");
                                    // print("help $isChecked ${attendees.contains([friends[index].uid!])}");
                                    // attendeeMap[friends[index].uid!] = isChecked!;
                                    isChecked! 
                                      ? attendees.add(friends[index].uid!)
                                      : attendees.remove(friends[index].uid!);
                                  });
                                },
                              );
                            },
                            separatorBuilder:(context, index) => Divider(),
                          ),
                        );
                      }
                    );
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    // attendeeMap.removeWhere((uid, isInvited) => !isInvited);
                    // Navigator.pop(context, attendeeMap.entries.toList());
                    Navigator.pop(context, attendees);
                  },
                  child: Text("Done"),
                )
              ],
            ),
          ),
        )
      )
    );

    // return SafeArea(
    //   child: Scaffold(
    //     appBar: AppBar(
    //       title: const Text(MeetupFriendsText),
    //     ),
    //     body: Center(
    //       child: Padding(
    //         padding: const EdgeInsets.all(8.0),
    //         child: Column(
    //           children: [
    //             FutureBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
    //               future: Database.getAllFriends(widget.user),
    //               builder: (context, friendsSnapshot) {
    //                 if (!friendsSnapshot.hasData) {
    //                   return Text('Loading...');
    //                 }

    //                 final List<Friend> friends = friendsSnapshot.data!.map((f) => Friend.fromFirestore(f, null)).toList();

    //                 return Expanded(
    //                   child: ListView.separated(
    //                     itemCount: friends.length,
    //                     itemBuilder: (context, index) {
    //                       return CheckboxListTile(
    //                         title: Text((friends[index]).displayName!),
    //                         // value: attendeeMap[friends[index].uid],
    //                         value: attendees.contains(friends[index].uid!),
    //                         onChanged: (bool? isChecked) {
    //                           setState(() {
    //                             // print("help $isChecked ${attendeeMap[friends[index].uid!]}");
    //                             print("help $isChecked ${attendees.contains([friends[index].uid!])}");
    //                             // attendeeMap[friends[index].uid!] = isChecked!;
    //                             isChecked! 
    //                               ? attendees.add(friends[index].uid!)
    //                               : attendees.remove(friends[index].uid!);
    //                           });
    //                         },
    //                       );
    //                     },
    //                     separatorBuilder:(context, index) => Divider(),
    //                   ),
    //                 );
    //               },
    //             ),
    //             ElevatedButton(
    //               onPressed: () {
    //                 // attendeeMap.removeWhere((uid, isInvited) => !isInvited);
    //                 // Navigator.pop(context, attendeeMap.entries.toList());
    //                 Navigator.pop(context, attendees);
    //               },
    //               child: Text("Done"),
    //             )
    //           ],
    //         ),
    //       ),
    //     )
    //   )
    // );
  }
}