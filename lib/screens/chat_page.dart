import 'package:chat_application/services/firebase_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class MyTextProvider with ChangeNotifier {
  TextEditingController _textController = TextEditingController();

  MyTextProvider() {
    // Add listener to detect text changes
    _textController.addListener(_onTextChanged);
  }

  TextEditingController get textController => _textController;

  bool _isEmpty = true;

  bool get isEmpty => _isEmpty;

  void _onTextChanged() {
    if (_textController.text.isNotEmpty) {
      // Perform action when text is not empty
      _isEmpty = false;
    } else {
      // Perform action when text is empty
      _isEmpty = true;
    }
    // Notify listeners if UI needs to update
    notifyListeners();
  }

  // Make sure to clean up the controller when the provider is disposed
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

class ChatPage extends StatelessWidget {
  ChatPage(
      {super.key,
      required this.concatenatedEmail,
      required this.userEmail,
      required this.receiverEmail});
  static const String page = "chat_page";
  final String concatenatedEmail;
  final String userEmail;
  final String receiverEmail;

  @override
  Widget build(BuildContext context) {
    final textProvider = Provider.of<MyTextProvider>(context, listen: false);
    final firebaseProvider =
        Provider.of<FirebaseProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          receiverEmail,
          style: TextStyle(
              color:
                  firebaseProvider.isLightMode ? Colors.white : Colors.black),
        ),
      ),
      backgroundColor:
          firebaseProvider.isLightMode ? Colors.white : Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('connectedUsers')
                    .doc(
                        concatenatedEmail) // e.g. 'abc@gmail.com-xyz@gmail.com'
                    .collection('messages')
                    .orderBy('timestamp',
                        descending: true) // Order messages by timestamp
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No messages yet'));
                  }

                  final messages = snapshot.data!.docs;

                  return ListView.builder(
                    reverse: true, // Show latest message at the bottom
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var messageData = messages[index];
                      var sender = messageData['sender'];
                      var message = messageData['message'];
                      var timestamp = messageData['timestamp'];

                      // Check if the timestamp is not null before converting it
                      String time = ''; // Default message if timestamp is null
                      if (timestamp != null) {
                        DateTime dateTime = timestamp.toDate();
                        time =
                            DateFormat.jm().format(dateTime); // Format to AM/PM
                      }

                      return Padding(
                        padding: sender == userEmail
                            ? EdgeInsets.only(bottom: 10, left: 70)
                            : EdgeInsets.only(bottom: 10, right: 70),
                        child: Wrap(
                          alignment: sender == userEmail
                              ? WrapAlignment.end
                              : WrapAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: sender == userEmail
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              child: Column(
                                crossAxisAlignment: sender == userEmail
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        message,
                                        style: TextStyle(
                                            color: firebaseProvider.isLightMode
                                                ? Colors.white
                                                : Colors.black,
                                            fontSize: 16,
                                            fontFamily: "Roboto",
                                            fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        time,
                                        style: TextStyle(
                                            color: firebaseProvider.isLightMode
                                                ? Colors.white54
                                                : Colors.black54,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            //Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              color: firebaseProvider.isLightMode ? Colors.white : Colors.black,
              child:
                  Consumer<MyTextProvider>(builder: (context, provider, child) {
                return Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          color: firebaseProvider.isLightMode
                              ? Colors.white
                              : Colors.black,
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.face,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                style: TextStyle(
                                  color: firebaseProvider.isLightMode
                                      ? Colors.black
                                      : Colors.white,
                                ),
                                controller: textProvider.textController,
                                decoration: InputDecoration(
                                  hintText: 'Type a message',
                                  hintStyle: TextStyle(
                                      color: firebaseProvider.isLightMode
                                          ? Colors.black
                                          : Colors.white),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.attach_file,
                              color: Colors.green,
                            ),
                            if (provider.isEmpty)
                              Row(
                                children: const [
                                  SizedBox(width: 10),
                                  Icon(
                                    Icons.currency_rupee,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 10),
                                  Icon(
                                    Icons.photo_camera,
                                    color: Colors.green,
                                  ),
                                ],
                              ),
                            // Use Consumer to rebuild only when `isEmpty` changes
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () async {
                        if (textProvider.textController.text.isNotEmpty) {
                          await firebaseProvider.sendNewMessage(
                              concatenatedEmail: concatenatedEmail,
                              message: textProvider.textController.text);
                          textProvider.textController.clear();
                        }
                        print(firebaseProvider.currentUserEmail);
                        // firebaseProvider.getCurrentUserEmailFieldValues(
                        //     context: context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: Colors.green,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            provider.isEmpty ? Icons.mic : Icons.send,
                            color: firebaseProvider.isLightMode
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    )
                  ],
                );
              }),
            )
          ],
        ),
      ),
    );
  }
}
