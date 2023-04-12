import 'package:be_there/constants/strings.dart';
import 'package:be_there/models/friend.dart';
import 'package:be_there/services/database.dart';
import 'package:be_there/services/places.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FriendSearch extends SearchDelegate<Friend> {
  final Friend user;

  FriendSearch(this.user);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        tooltip: 'Clear',
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, Friend());
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Text(Suggestion(query, "").toString());
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder(
      future: query == ""
          ? null
          : Database.getAllFriends(user),
      builder: (context, friendsSnapshot) {
        if (query == '') {
          return Container(
            padding: EdgeInsets.all(16.0),
            child: Text(MeetupFriendsText),
          );
        }
        
        if (!friendsSnapshot.hasData) {
          return Text('Loading...');
        }
        
        final List<Friend> friends = friendsSnapshot.data!.map((fs) => Friend.fromFirestore(fs, null)).toList();

        return ListView.separated(
          itemCount: friends.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text((friends[index]).displayName!),
              trailing: IconButton(
                onPressed: () {
                  close(context, friends[index]);
                },
                icon: Icon(Icons.add)
              ),
              onTap: () {
                close(context, friends[index]);
              },
            );
          },
          separatorBuilder:(context, index) => Divider(),
        );
      }
    );
  }
}