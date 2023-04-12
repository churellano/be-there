import 'dart:async';

import 'package:be_there/constants/strings.dart';
import 'package:be_there/models/friend.dart';
import 'package:be_there/models/meetup.dart';
import 'package:be_there/screens/ProgressIndicator/progress_indicator_page.dart';
import 'package:be_there/services/places.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:uuid/uuid.dart';

class CurrentMeetupMap extends StatefulWidget {
  const CurrentMeetupMap({required this.closestMeetupSnapshot});

  final QueryDocumentSnapshot<Map<String, dynamic>> closestMeetupSnapshot;

  @override
  State<CurrentMeetupMap> createState() => CurrentMeetupMapState();
}

class CurrentMeetupMapState extends State<CurrentMeetupMap> {
  final Location location = Location();
  late StreamSubscription<LocationData> _locationSubscription;
  late LocationData initialLocation;
  late PlaceApiProvider placeApiClient;
  late bool isLocationPermissionGranted;

  @override
  void initState() {
    super.initState();
    placeApiClient = PlaceApiProvider(Uuid().v4());

    _isLocationPermissionGranted().then((permissionGranted) {
      print("permissionGranted $permissionGranted");

      if (!permissionGranted) {
        return;
      }

      location.changeSettings(interval: 10000, accuracy: LocationAccuracy.balanced);
      location.enableBackgroundMode(enable: true);
    });

    String meetupStatus = widget.closestMeetupSnapshot.get("status");

    if (meetupStatus == "started") {
      _locationSubscription = location.onLocationChanged.listen((event) {
        // Update user's coordinates
        FirebaseFirestore.instance.collection(UsersCollection)
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
            "coordinates": GeoPoint(event.latitude!, event.longitude!)
          });
      });
      
    } else if (meetupStatus == "finished") {
      _locationSubscription.cancel();
    }
  }

  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: placeApiClient.getLatLngFromPlaceId(widget.closestMeetupSnapshot.get("placeId")),
      builder: (context, locationDataSnapshot) {
        if (!locationDataSnapshot.hasData) {
          return ProgressIndicatorPage();
        }

        CameraPosition cameraPosition = CameraPosition(
          target: LatLng(
            locationDataSnapshot.data!['lat']!,
            locationDataSnapshot.data!['lng']!
          ),
          zoom: 11
        );

        if (widget.closestMeetupSnapshot.get("status") != "started") {
          return Scaffold(
            body: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: cameraPosition,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                if (_controller.isCompleted) {
                  return;
                }

                _controller.complete(controller);
              },
            ),
          );
        }

        Meetup closestMeetup = Meetup.fromFirestore(widget.closestMeetupSnapshot, null);
        List<String> attendeeIds = closestMeetup.attendees!;
        attendeeIds.remove(FirebaseAuth.instance.currentUser!.uid);
        
        if (attendeeIds.isEmpty) {
          throw Exception("Error: No attendees besides the host are attending this event.");
        }

        var attendeesStream = FirebaseFirestore.instance.collection(UsersCollection)
          .where("uid", arrayContainsAny: attendeeIds)
          .snapshots();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: attendeesStream,
          builder: (context, attendeeSnapshots) {
            Set<Marker> markers = {};

            if (attendeeSnapshots.hasData && attendeeSnapshots.data!.docs.isNotEmpty) {
              for (QueryDocumentSnapshot<Map<String, dynamic>> attendeeSnapshot in attendeeSnapshots.data!.docs) {
                Friend attendee = Friend.fromFirestore(attendeeSnapshot, null);
                GeoPoint? coordinates = attendee.coordinates;

                print("help $coordinates");  

                if (coordinates != null) {
                  markers.add(
                    Marker(
                      markerId: MarkerId(attendee.uid!),
                      position: LatLng(coordinates.latitude, coordinates.longitude),
                      infoWindow: InfoWindow(
                        title: attendee.displayName,
                      )
                    )
                  );
                }
              }
            }

            return Scaffold(
              body: GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: cameraPosition,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onMapCreated: (GoogleMapController controller) {
                  if (_controller.isCompleted) {
                    return;
                  }

                  _controller.complete(controller);
                },
                markers: markers,
              ),
            );
          }
        );
      }
    );
  }

  Future<bool> _isLocationPermissionGranted() async {
    PermissionStatus permissionStatus = await location.hasPermission();
    if (permissionStatus == PermissionStatus.denied) {
      permissionStatus = await location.requestPermission();
    }

    return permissionStatus == PermissionStatus.granted;
  }
}