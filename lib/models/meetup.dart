import 'package:cloud_firestore/cloud_firestore.dart';

class Meetup {
  final String? id;
  final String? name;
  final String? address;
  final Timestamp? date;
  final String? informalLocation;
  final List<String>? attendees;
  final String? status;
  final String? host;
  final String? placeId;

  Meetup({
    this.id,
    this.name,
    this.address,
    this.date,
    this.informalLocation,
    this.attendees,
    this.status,
    this.host,
    this.placeId,
  });

  factory Meetup.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Meetup(
      id: data?['id'],
      name: data?['name'],
      address: data?['address'],
      date: data?['date'],
      informalLocation: data?['informalLocation'],
      attendees: data?['attendees'] is Iterable ? List<String>.from(data?['attendees']) : null,
      status: data?['status'],
      host: data?['host'],
      placeId: data?['placeId'],
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      if (id != null) "id": id,
      if (name != null) "name": name,
      if (address != null) "address": address,
      if (date != null) "date": date,
      if (informalLocation != null) "informalLocation": informalLocation,
      if (attendees != null) "attendees": attendees,
      if (status != null) "hasStarted": status,
      if (host != null) "host": host,
      if (placeId != null) "placeId": placeId,
    };
  }
}