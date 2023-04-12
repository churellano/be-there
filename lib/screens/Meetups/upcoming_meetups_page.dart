import 'package:be_there/constants/strings.dart';
import 'package:be_there/services/database.dart';
import 'package:be_there/models/friend.dart';
import 'package:be_there/models/meetup.dart';
import 'package:be_there/screens/CreateMeetup/create_meetup.dart';
import 'package:be_there/screens/ProgressIndicator/progress_indicator_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UpcomingMeetupsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var meetupsStream = FirebaseFirestore.instance.collection(MeetupsCollection)
      .where("attendees", arrayContains: FirebaseAuth.instance.currentUser!.uid)
      .where("status", isNotEqualTo: "finished")
      .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: meetupsStream,
      builder: (context, meetupsSnapshot) {
        if (!meetupsSnapshot.hasData) {
          return ProgressIndicatorPage();
        }

        final List<Meetup> meetupsSortedByAscendingDate = meetupsSnapshot.data!.docs.map(
          (meetupSnapshot) => Meetup.fromFirestore(meetupSnapshot, null)
        ).toList();
        meetupsSortedByAscendingDate.sort((a, b) => a.date!.compareTo(b.date!));

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: ListView(
                children: [
                  Text(
                    UpcomingMeetupsHeading,
                    style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 2.0),
                  ),
                  ...meetupsSortedByAscendingDate.map((meetup) {
                    final DateFormat dateFormatter = DateFormat("MMMM d | ").add_jm();
                    final String formattedDateString = dateFormatter.format(meetup.date!.toDate().toLocal());
          
                    return Card(
                      child: ListTile(
                        title: Text(
                          meetup.name!,
                          style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.5)
                        ),
                        subtitle: Text(formattedDateString),
                      )
                    );
                  }),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateMeetupPage())
              );
            },
            child: const Icon(Icons.add)
          ),
        );
      }
    );

    // return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    //   stream: Database.getFriendStream(FirebaseAuth.instance.currentUser!.uid),
    //   builder: (context, friendSnapshot) {
    //     if (friendSnapshot.hasData) {
    //       final Friend user = Friend.fromFirestore(friendSnapshot.data!, null);

    //       return FutureBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
    //         future: Future.wait([
    //           for (final String meetupDocumentId in user.upcomingMeetups!)
    //             Database.getMeetup(meetupDocumentId)
    //         ]),
    //         builder: (context, upcomingMeetupSnapshots) {
    //           if (!upcomingMeetupSnapshots.hasData) {
    //             return ProgressIndicatorPage(); 
    //           }

    //           final List<Meetup> meetupsSortedByAscendingDate = upcomingMeetupSnapshots.data!.map(
    //             (meetupSnapshot) => Meetup.fromFirestore(meetupSnapshot, null)
    //           ).toList();
    //           meetupsSortedByAscendingDate.sort((a, b) => a.date!.compareTo(b.date!));

    //           return Scaffold(
    //             body: Padding(
    //               padding: const EdgeInsets.only(right: 8.0),
    //               child: Center(
    //                 child: ListView(
    //                   children: [
    //                     Text(
    //                       UpcomingMeetupsHeading,
    //                       style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 2.0),
    //                     ),
    //                     ...meetupsSortedByAscendingDate.map((meetup) {
    //                       final DateFormat dateFormatter = DateFormat("MMMM d | ").add_jm();
    //                       final String formattedDateString = dateFormatter.format(meetup.date!.toDate().toLocal());
                
    //                       return Card(
    //                         child: ListTile(
    //                           title: Text(
    //                             meetup.name!,
    //                             style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.5)
    //                           ),
    //                           subtitle: Text(formattedDateString),
    //                         )
    //                       );
    //                     }),
    //                   ],
    //                 ),
    //               ),
    //             ),
    //             floatingActionButton: FloatingActionButton(
    //               onPressed: () {
    //                 Navigator.push(
    //                   context,
    //                   MaterialPageRoute(builder: (context) => CreateMeetupPage(user))
    //                 );
    //               },
    //               child: const Icon(Icons.add)
    //             ),
    //           );
    //         }
    //       );
    //     }
    //     return ProgressIndicatorPage();
    //   }
    // );
  }
}
