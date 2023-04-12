import 'package:be_there/constants/strings.dart';
import 'package:be_there/models/friend.dart';
import 'package:be_there/screens/Friends/add_friend_page.dart';
import 'package:be_there/screens/ProgressIndicator/progress_indicator_page.dart';
import 'package:be_there/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendRequestsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Database.getFriendStream(FirebaseAuth.instance.currentUser!.uid),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return ProgressIndicatorPage();
        }

        return FutureBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
          future: Future.wait([
            for (var friendRequesterUid in Friend.fromFirestore(userSnapshot.data!, null).friendRequests!)
              Database.getFriend(friendRequesterUid)
          ]),
          builder: (context, friendRequesterDocumentSnapshots) {
            if (!friendRequesterDocumentSnapshots.hasData) {
              return ProgressIndicatorPage(); 
            }

            if (friendRequesterDocumentSnapshots.data!.isEmpty) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 24.0,
                    left: 8.0
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          NoFriendRequestsTitle,
                          style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 2.0)
                        ),
                        Text(
                          NoFriendRequestsSubtitle,
                          style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.2)
                        ),
                      ],
                    )
                  ),
                ),
              );
            }
            
            return Scaffold(
              body: Center(
                child: ListView(
                  children: ListTile.divideTiles(
                    context: context,
                    tiles: [
                      Text(
                        FriendRequestsHeading,
                        style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 2.0)
                      ),
                      ...friendRequesterDocumentSnapshots.data!.map((DocumentSnapshot<Map<String, dynamic>> friendRequesterDocumentSnapshot) {
                        final Friend friend = Friend.fromFirestore(friendRequesterDocumentSnapshot, null);

                        return ListTile(
                          title: Text(friend.displayName!),
                          trailing: Wrap(
                            spacing: 12,
                            children: [
                              IconButton(
                                onPressed: () {
                                  Database.acceptFriendRequest(
                                    friendRequesterDocumentSnapshot,
                                    userSnapshot.data!,
                                  ).then((isSuccessful) {
                                    if (!isSuccessful) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(AcceptFriendRequestFailText)),
                                      );
                                    }
                                  });
                                },
                                icon: Icon(Icons.done)
                              ),
                              IconButton(
                                onPressed: () {
                                  Database.declineFriendRequest(friend.uid!)
                                    .then((isSuccessful) {
                                      if (!isSuccessful) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(DeclineFriendRequestFailText)),
                                        );
                                      }
                                    });
                                },
                                icon: Icon(Icons.close)
                              ),
                            ],
                          )
                        );
                      }),
                    ]
                  ).toList(),
                ),
              ),
            );
          },
        );
      }
    );
  }
}