import 'package:be_there/constants/strings.dart';
import 'package:be_there/models/friend.dart';
import 'package:be_there/models/meetup.dart';
import 'package:be_there/screens/ProgressIndicator/progress_indicator_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/database.dart';

class InvitedMeetupsPage extends StatelessWidget {
  @override
  Widget build(Object context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: Database.getFriendStream(FirebaseAuth.instance.currentUser!.uid),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return ProgressIndicatorPage();
        }

        return FutureBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
          future: Future.wait([
            for (final String meetupDocumentId in Friend.fromFirestore(userSnapshot.data!, null).invitedMeetups!)
              Database.getMeetup(meetupDocumentId)
          ]),
          builder: (context, invitedMeetupsSnapshot) {
            if (!invitedMeetupsSnapshot.hasData) {
              return ProgressIndicatorPage(); 
            }

            if (invitedMeetupsSnapshot.data!.isEmpty) {
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
                          NoInvitesTitle,
                          style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 2.0)
                        ),
                        Text(
                          NoInvitesSubtitle,
                          style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.2)
                        ),
                      ],
                    )
                  ),
                ),
              );
            }

            final List<Meetup> meetupsSortedByAscendingDate = invitedMeetupsSnapshot.data!.map((meetupSnapshot) => Meetup.fromFirestore(meetupSnapshot, null)).toList();
            // final List<DocumentSnapshot<Map<String, dynamic>>> meetupDocumentSnapshotsSortedByAscendingDate = invitedMeetupsSnapshot.data!;
            // meetupDocumentSnapshotsSortedByAscendingDate.sort((a, b) => a["date"]!.compareTo(b["date"]!));
            meetupsSortedByAscendingDate.sort((a, b) => a.date!.compareTo(b.date!));

            return Scaffold(
              body: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Center(
                  child: ListView(
                    children: [
                      Text(
                        InvitedMeetupsHeading,
                        style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 2.0),
                      ),
                      ...meetupsSortedByAscendingDate.map((meetup) {

                        // final Meetup meetup = Meetup.fromFirestore(meetupDocumentSnapshot, null);
                        final DateFormat dateFormatter = DateFormat("MMMM d | ").add_jm();
                        final String formattedDateString = dateFormatter.format(meetup.date!.toDate().toLocal());
              
                        return Card(
                          child: ListTile(
                            title: Text(
                              meetup.name!,
                              style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.5)
                            ),
                            subtitle: Text(formattedDateString),
                            trailing: Wrap(
                              spacing: 12,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.done),
                                  onPressed: () {
                                    Database.acceptMeetupInvite(
                                      userSnapshot.data!,
                                      meetup.id!
                                    ).then((isSuccessful) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isSuccessful
                                              ? AcceptMeetupInviteText + meetup.name!
                                              : AcceptMeetupInviteFailText
                                          )
                                        ),
                                      );
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () {
                                    Database.declineMeetupInvite(userSnapshot.data!, meetup.id!)
                                      .then((isSuccessful) {
                                        if (!isSuccessful) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(DeclineMeetupInviteFailText)),
                                          );
                                        }
                                      });
                                  },
                                ),
                              ],
                            ),
                          )
                        );
                      }),
                    ],
                  ),
                ),
              )
            );
          }
        );
      }
    );
  }

}