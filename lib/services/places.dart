import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';

// For storing our result
class Suggestion {
  final String placeId;
  final String description;

  Suggestion(this.placeId, this.description);

  @override
  String toString() {
    return 'Suggestion(description: $description, placeId: $placeId)';
  }
}

class PlaceApiProvider {
  final client = Client();

  PlaceApiProvider(this.sessionToken);

  final String sessionToken;

  // static final String androidKey = 'YOUR_API_KEY_HERE';
  // static final String iosKey = 'YOUR_API_KEY_HERE';
  // final apiKey = Platform.isAndroid ? androidKey : iosKey;
  final apiKey = 'AIzaSyCTDVfNQS7BKVU9hlfWmJkrrJYlboQwqBs';

  Future<List<Suggestion>> fetchSuggestions(String input, String lang) async {
    final request =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&types=establishment&language=$lang&components=country:ca&key=$apiKey&sessiontoken=$sessionToken';
    final response = await client.get(Uri.parse(request));

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        // compose suggestions in a list
        return result['predictions']
          .map<Suggestion>((p) => Suggestion(p['place_id'], p['description']))
          .toList();
      }

      if (result['status'] == 'ZERO_RESULTS') {
        return [];
      }

      throw Exception(result['error_message']);
    } else {
      throw Exception('Failed to fetch suggestion');
    }
  }

  Future<Map<String, dynamic>> getLatLngFromPlaceId(String placeId) async {
    final request =
      'https://maps.googleapis.com/maps/api/place/details/json?fields=geometry&place_id=$placeId&key=$apiKey&sessiontoken=$sessionToken';
    final response = await client.get(Uri.parse(request));

    if (response.statusCode == 200) {
      final result = json.decode(response.body);

      if (result['status'] == 'OK') {
        print(result);

        return result['result']['geometry']['location'];
      }

      throw Exception(result['error_message']);
    } else {
      throw Exception('Failed to fetch suggestion');
    }
  }
}