import 'dart:async';

import 'package:be_there/constants/strings.dart';
import 'package:be_there/models/friend.dart';
import 'package:be_there/models/meetup.dart';
import 'package:be_there/screens/CreateMeetup/address_search.dart';
import 'package:be_there/screens/CreateMeetup/invite_friends_page.dart';
import 'package:be_there/services/database.dart';
import 'package:be_there/services/places.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

enum CreateMeetupStatus {
  valid,
  noTitle,
  invalidDate,
  noAddress,
  noInvites,
}

class CreateMeetupPage extends StatefulWidget {
  CreateMeetupPage();

  @override
  State<StatefulWidget> createState() => _CreateMeetupPageState();
}

class _CreateMeetupPageState extends State<CreateMeetupPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  late DateTime? date; 
  final _dateController = TextEditingController();
  late TimeOfDay? time; 
  final _timeController = TextEditingController();
  final _addressController = TextEditingController();
  final _informalLocationController = TextEditingController();
  List<String> _attendeeIds = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(CreateMeetupHeading),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    contentPadding: EdgeInsets.only(left: 48.0),
                    border: UnderlineInputBorder(),
                    labelText: MeetupNameText,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return MeetupNameErrorText;
                    }
                    return null;
                  },
                ),
                TextField(
                  controller: _dateController,
                  onTap: () async {
                    showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365))
                    ).then((selectedDate){
                      // This will change the text displayed in the TextField
                      if (selectedDate != null) {
                        final DateFormat dateFormatter = DateFormat("MMMM d, y");
                        final String formattedDateString = dateFormatter.format(selectedDate.toLocal());

                        setState(() {
                          date = selectedDate;
                          _dateController.text = formattedDateString;
                        });
                      }
                    });
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.calendar_month),
                    border: UnderlineInputBorder(),
                    labelText: MeetupDateText,
                  ),
                ),
                TextField(
                  controller: _timeController,
                  onTap: () {
                    showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(DateTime.now().add(Duration(hours: 1)))
                    ).then((selectedTime) {
                      if (selectedTime != null) {
                        setState(() {
                          time = selectedTime;
                          _timeController.text = selectedTime.format(context);
                        });
                      }
                    });
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.schedule),
                    border: UnderlineInputBorder(),
                    labelText: MeetupTimeText,
                  ),
                ),
                TextField(
                  controller: _addressController,
                  onTap: () async {
                    // generate a new token here
                    final sessionToken = Uuid().v4();
                    final Suggestion? result = await showSearch(
                      context: context,
                      delegate: AddressSearch(sessionToken),
                    );
                    // This will change the text displayed in the TextField
                    if (result != null) {
                      setState(() {
                        _addressController.text = result.description;
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_on),
                    border: UnderlineInputBorder(),
                    labelText: MeetupAddressText,
                  ),
                ),
                TextFormField(
                  controller: _informalLocationController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.not_listed_location),
                    border: UnderlineInputBorder(),
                    labelText: MeetupInformalLocationText,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: OutlinedButton(
                    
                    onPressed: () async {
                      if (context.mounted) {
                        List<String>? result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => InviteFriendsPage())
                        );
                
                        if (result != null) {
                          _attendeeIds = result;
                        }
                      }
                    },
                    child: Text(MeetupFriendsText)
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton(
                    child: const Text("Save"),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {

                        final Meetup meetup = Meetup(
                          name: _nameController.text.trim(),
                          date: Timestamp.fromDate(
                            date!.add(
                              Duration(
                                hours: time!.hour,
                                minutes: time!.minute
                              )
                            )
                          ),
                          address: _addressController.text.trim(),
                          informalLocation: _informalLocationController.text.trim(),
                          attendees: _attendeeIds + [FirebaseAuth.instance.currentUser!.uid],
                          host: FirebaseAuth.instance.currentUser!.uid,
                        );

                        final CreateMeetupStatus meetupStatus = _validateMeetup(meetup);
                        final bool isMeetupValid = meetupStatus == CreateMeetupStatus.valid;
                        
                        if (!isMeetupValid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(CreateMeetupStatusStrings[meetupStatus.index]!)),
                          );
                        }

                        // Add to database
                        Database.createMeetup(FirebaseAuth.instance.currentUser!.uid, meetup).then((isSuccessful) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isSuccessful ? CreatedMeetupSnackbarText : CreatedMeetupFailSnackbarText)),
                          );

                          Navigator.pop(context);
                        });
                      }
                    },
                  )
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Return error code if invalid, or 0 if valid.
  CreateMeetupStatus _validateMeetup(Meetup meetup) {
    if (meetup.name!.isEmpty) {
      return CreateMeetupStatus.noTitle;
    }
    
    if (meetup.date == null) {
      return CreateMeetupStatus.invalidDate;
    }
    
    if (meetup.address!.isEmpty) {
      return CreateMeetupStatus.noAddress;
    }
    
    if (meetup.attendees!.length < 2) {
      return CreateMeetupStatus.noInvites;
    }

    return CreateMeetupStatus.valid;
  }
}