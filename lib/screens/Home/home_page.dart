import 'package:be_there/main.dart';
import 'package:be_there/screens/Friends/friend_requests.dart';
import 'package:be_there/screens/Friends/friends_page.dart';
import 'package:be_there/screens/CurrentMeetupPage/current_meetup_page.dart';
import 'package:be_there/screens/Meetups/invited_meetups_page.dart';
import 'package:be_there/screens/Meetups/upcoming_meetups_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = CurrentMeetupPage();
        break;
      case 1:
        page = UpcomingMeetupsPage();
        break;
      case 2:
        page = InvitedMeetupsPage();
        break;
      case 3:
        page = FriendsPage();
        break;
      case 4:
        page = FriendRequestsPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: false,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.event_available),
                    label: Text('Meetups'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.event),
                    label: Text('Meetup invites'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.group),
                    label: Text('Friends'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.group_add),
                    label: Text('Friend requests'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}
