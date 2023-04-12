import 'package:be_there/constants/strings.dart';
import 'package:be_there/services/database.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddFriendPage extends StatelessWidget {
  AddFriendPage({super.key});

  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Add friend"),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(AddFriendByEmailText),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: EmailPlaceholderText
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      final trimmedEmail = _emailController.text.trim();

                      if (!EmailValidator.validate(trimmedEmail)){
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(EmailInvalidText)),
                        );

                        return;
                      }

                      // Check that requester != requestee
                      if (trimmedEmail == FirebaseAuth.instance.currentUser?.email) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(CannotAddYourselfText)),
                        );

                        return;
                      }

                      // Add friend request to database
                      Database.sendFriendRequest(FirebaseAuth.instance.currentUser!.uid, trimmedEmail)
                        .then((result) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result ? FriendRequestSuccessfulText : FriendRequestFailText)),
                          );
                        });
                    },
                    child: const Text(SendFriendRequestText),
                  ),
                )
              ]
            ),
          ),
        )
      ),
    );
  }

}