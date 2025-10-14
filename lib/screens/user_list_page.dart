import 'package:chat_application/elements/custom_button.dart';
import 'package:chat_application/screens/chat_page.dart';
import 'package:chat_application/services/firebase_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../textfield.dart';

class UserListPage extends StatelessWidget {
  TextEditingController receiverEmailController = TextEditingController();
  TextEditingController receiverNameController = TextEditingController();
  static const String page = 'user_list';

  @override
  Widget build(BuildContext context) {
    final firebaseProvider = Provider.of<FirebaseProvider>(context);

    final backgroundColor =
        firebaseProvider.isLightMode ? Colors.white : Colors.black;
    final primaryColor =
        firebaseProvider.isLightMode ? Colors.green : Colors.teal;
    final textColor =
        firebaseProvider.isLightMode ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: primaryColor,
        title: Text(
          'Users',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              firebaseProvider.isLightMode ? Icons.dark_mode : Icons.light_mode,
              color: Colors.white,
            ),
            onPressed: () {
              firebaseProvider.changeScreenMode();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: firebaseProvider.firestore
                        .collection('connectedUsers')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: primaryColor,
                          ),
                        );
                      }

                      var documents = snapshot.data!.docs;

                      var filteredDocuments = documents.where((doc) {
                        String docId = doc.id;
                        return docId.toLowerCase().contains(
                            firebaseProvider.currentUserEmail.toLowerCase());
                      }).toList();

                      if (filteredDocuments.isEmpty) {
                        return Center(
                          child: Text(
                            'No connected users found.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: textColor,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredDocuments.length,
                        itemBuilder: (context, index) {
                          String connectionName = filteredDocuments[index].id;
                          String receiverEmail = connectionName
                              .replaceAll("-", "")
                              .replaceAll(
                                  firebaseProvider.currentUserEmail, "");

                          return FutureBuilder<String?>(
                            future: firebaseProvider.getUserName(receiverEmail),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return ListTile(
                                  title: Text(
                                    "Loading...",
                                    style: TextStyle(color: textColor),
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.grey[300],
                                    child: Icon(
                                      Icons.people,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                );
                              } else if (snapshot.hasError) {
                                return ListTile(
                                  title: Text(
                                    "Error loading name",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  leading: Icon(Icons.error, color: Colors.red),
                                );
                              } else if (!snapshot.hasData ||
                                  snapshot.data == null) {
                                return ListTile(
                                  title: Text(
                                    "Unknown user",
                                    style: TextStyle(color: textColor),
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.grey[300],
                                    child: Icon(
                                      Icons.person_outline,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                );
                              } else {
                                String receiverName = snapshot.data!;

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatPage(
                                          concatenatedEmail: connectionName,
                                          userEmail:
                                              firebaseProvider.currentUserEmail,
                                          receiverEmail: receiverName,
                                        ),
                                      ),
                                    );
                                  },
                                  child: ListTile(
                                    title: Text(
                                      receiverName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: textColor,
                                      ),
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: primaryColor,
                                      child: Icon(
                                        Icons.people,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: FloatingActionButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: firebaseProvider.isLightMode
                                  ? Colors.white
                                  : Colors.grey[900],
                              title: Center(
                                child: Text(
                                  'Create New Chat',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              actions: [
                                CustomTextfield(
                                  icon: Icons.people,
                                  text: 'Receiver Name',
                                  controller: receiverNameController,
                                ),
                                SizedBox(height: 10),
                                CustomTextfield(
                                  icon: Icons.mail,
                                  text: 'Receiver Email',
                                  controller: receiverEmailController,
                                ),
                                SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomButton(
                                        color: primaryColor,
                                        buttonText: "Save",
                                        onTap: () async {
                                          if (receiverEmailController
                                                  .text.isNotEmpty &&
                                              receiverNameController
                                                  .text.isNotEmpty) {
                                            bool isConnected =
                                                await firebaseProvider
                                                    .connectTwoUsers(
                                              context: context,
                                              receiverEmail:
                                                  receiverEmailController.text,
                                              receiverName:
                                                  receiverNameController.text,
                                            );

                                            if (!isConnected) {
                                              // Show alert dialog when user not found
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: Text('Error'),
                                                    content:
                                                        Text('User not found'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context), // Close the dialog
                                                        child: Text('OK'),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                              receiverEmailController.clear();
                                              receiverNameController.clear();
                                            } else {
                                              Navigator.pop(context);
                                              receiverEmailController.clear();
                                              receiverNameController
                                                  .clear(); // Close the current screen if connection successful
                                            }
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                backgroundColor: Colors.black,
                                                content: Text(
                                                  "Enter Username and Email",
                                                  style: TextStyle(
                                                    color: primaryColor,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: CustomButton(
                                        color: Colors.red,
                                        buttonText: "Cancel",
                                        onTap: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            );
                          },
                        );
                      },
                      backgroundColor: primaryColor,
                      child: Icon(Icons.add, size: 28),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
