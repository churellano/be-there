import 'dart:async';

import 'package:be_there/constants/strings.dart';
import 'package:be_there/models/friend.dart';
import 'package:be_there/models/meetup.dart';
import 'package:be_there/screens/CurrentMeetupPage/current_meetup_map_widget.dart';
import 'package:be_there/screens/ProgressIndicator/progress_indicator_page.dart';
import 'package:be_there/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class CurrentMeetupPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var meetupsStream = FirebaseFirestore.instance.collection(MeetupsCollection)
      .where("attendees", arrayContains: FirebaseAuth.instance.currentUser!.uid)
      .where("status", isNotEqualTo: "finished")
      .snapshots();

    return StreamBuilder(
      stream: meetupsStream,
      builder: (context, meetupsSnapshot) {

        if (!meetupsSnapshot.hasData) {
          return ProgressIndicatorPage();
        }

        // Show empty page
        if (meetupsSnapshot.data!.docs.isEmpty) {
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
                      NoMeetupsScheduledText,
                      style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 2.0)
                    ),
                  ],
                )
              ),
            ),
          );
        }

        QueryDocumentSnapshot<Map<String, dynamic>> closestMeetupSnapshot = meetupsSnapshot.data!.docs[0];
        for (QueryDocumentSnapshot<Map<String, dynamic>> meetupSnapshot in meetupsSnapshot.data!.docs) { 
          final Timestamp currentTimestamp = meetupSnapshot.get("date");
          final Timestamp closestTimestamp = closestMeetupSnapshot.get("date");
          if (currentTimestamp.compareTo(closestTimestamp) < 0) {
            closestMeetupSnapshot = meetupSnapshot;
          }
        }

        final Meetup meetup = Meetup.fromFirestore(closestMeetupSnapshot, null);
        final DateFormat dateFormatter = DateFormat("MMMM d, y").add_jm();
        final DateTime meetupDateTime = meetup.date!.toDate();
        final String formattedDateString = dateFormatter.format(meetupDateTime.toLocal());

        // Meetup can start up to 30 minutes before meetup time
        final bool isMeetupAbleToStart = DateTime.now().compareTo(meetupDateTime.subtract(const Duration(minutes: 30))) >= 0;

        return SafeArea(
          child: Scaffold(
            body: Center(
              child: Column(
                children: [
                  Text(
                    meetup.status == "started" ? CurrentMeetupPageHeading : NextMeetupPageHeading,
                    style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 2.0)
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: meetup.status != "started" ? Colors.black : null,
                      gradient: meetup.status == "started"
                      ? LinearGradient(
                        colors: [
                        Color.fromRGBO(100, 0, 255, 1),
                        Color.fromRGBO(255, 0, 100, 1)
                        ]
                      ) : null,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Text(
                                meetup.name!,
                                style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.5)
                              ),
                              Text(
                                formattedDateString,
                                style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.2)
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: meetup.status == "started",
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 16.0, right: 16.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(5), bottomRight: Radius.circular(5)),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                          Color.fromRGBO(100, 0, 255, 1),
                          Color.fromRGBO(255, 0, 100, 1)
                          ]
                        ),
                      ),
                      child: Text(
                        LiveIconText,
                        style: TextStyle(
                          color: Colors.white
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CurrentMeetupMap(closestMeetupSnapshot: closestMeetupSnapshot),
                    ),
                  ),
                  Visibility(
                    visible: meetup.host == FirebaseAuth.instance.currentUser!.uid,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: OutlinedButton.icon(
                        onPressed: meetup.status == "unstarted"
                        ? (
                          isMeetupAbleToStart 
                          ? () async {
                            // Start meetup
                            await closestMeetupSnapshot.reference.update({"status": "started"});
                                      
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(StartedMeetupSnackbarText)),
                              );
                            }
                          }
                          : null
                        )
                        : () async {
                          // Finish meetup
                          await closestMeetupSnapshot.reference.update({"status": "finished"});
                                      
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(FinishedMeetupSnackbarText)),
                            );
                          }
                        },
                        icon: meetup.status == "unstarted"
                          ? const Icon(Icons.celebration)
                          : const Icon(Icons.check),
                        label:  meetup.status == "unstarted"
                          ? const Text('Start Meetup')
                          : const Text('Finish Meetup'),
                      ),
                    ),
                  ),
                ]
              )
            ),
          )
        );
      }
    );
  }
}