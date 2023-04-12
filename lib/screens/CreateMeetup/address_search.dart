import 'package:be_there/services/places.dart';
import 'package:flutter/material.dart';

class AddressSearch extends SearchDelegate<Suggestion> {
  AddressSearch(this.sessionToken) {
    apiClient = PlaceApiProvider(sessionToken);
  }

  final String sessionToken;
  late PlaceApiProvider apiClient;

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
        close(context, Suggestion(query, ""));
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
          : apiClient.fetchSuggestions(
              query,
              Localizations.localeOf(context).languageCode
            ),
      builder: (context, snapshot) => query == ''
          ? Container(
              padding: EdgeInsets.all(16.0),
              child: Text('Choose a meetup location'),
            )
          : snapshot.hasData
              ? ListView.builder(
                  itemBuilder: (context, index) => ListTile(
                    title: Text((snapshot.data?[index])!.description),
                    onTap: () {
                      close(context, snapshot.data![index]);
                    },
                  ),
                  itemCount: snapshot.data?.length,
                )
              : Text('Loading...'),
    );
  }
}