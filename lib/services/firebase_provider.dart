import 'package:chat_application/screens/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../screens/user_list_page.dart';

class FirebaseProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  String _concatenatedString = "";
  bool _isLightMode = true;

  String get currentUserEmail => _auth.currentUser?.email ?? "";
  String get concatenatedString => _concatenatedString;
  bool get isLightMode => _isLightMode;
  FirebaseFirestore get firestore => _firestore;

  void changeScreenMode() {
    _isLightMode = !_isLightMode;
    notifyListeners();
  }

  // Method for signing in with email and password
  Future<bool> signIn(
      String email, String password, BuildContext context) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Navigate to UserListPage if sign-in succeeds
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UserListPage()),
      );

      notifyListeners();
      return true; // Sign-in successful
    } catch (e) {
      print('Error signing in: $e');
      return false; // Sign-in failed
    }
  }

  // Method for registering a new user
  Future<bool> signUp(String email, String password, BuildContext context,
      String userName) async {
    try {
      // Attempt sign up
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      // Add user details to Firestore or another database (if applicable)
      await addUser(userName);

      // Navigate to another page after sign-up
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => UserListPage()));

      notifyListeners();

      return true; // Return true when sign-up is successful
    } catch (e) {
      // Handle any errors that occur during the sign-up process
      print("Error signing up: $e");
      return false; // Return false if sign-up fails
    }
  }

  // Method for logging out
  Future<void> logout() async {
    try {
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      throw Exception('Error signing out: $e');
    }
  }

  Future<String?> getUserName(String userEmail) async {
    try {
      // Fetch the document for the given email
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userEmail).get();

      // Check if the document exists
      if (userDoc.exists) {
        // Retrieve the 'userName' field
        return userDoc['userName'] as String?;
      } else {
        print('User does not exist.');
        return null;
      }
    } catch (e) {
      print('Error retrieving userName: $e');
      return null;
    }
  }

  Future<void> addUser(String userName) async {
    try {
      await _firestore.collection('users').doc(currentUserEmail).set({
        'email': currentUserEmail,
        'userName': userName,
        'imageUrl': "url",
        'created_at': FieldValue.serverTimestamp(),
        // Add more user fields as needed
      });
      notifyListeners(); // Notify listeners if needed
    } catch (e) {
      print('Error adding user: $e');
    }
  }

  // Method for storing an image message in Firebase Storage and Firestore
  Future<void> storeImageMessage(String chatId) async {
    final picker = ImagePicker();

    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);

        // Upload image to Firebase Storage
        final storageRef = _firebaseStorage
            .ref()
            .child('chats/$chatId/images/${DateTime.now()}.png');
        await storageRef.putFile(imageFile);

        // Get download URL
        final imageUrl = await storageRef.getDownloadURL();

        // Store image message in Firestore
        await _firestore.collection('chats/$chatId/messages').add({
          'imageUrl': imageUrl,
          'senderId': _auth.currentUser?.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Error storing image message: $e');
    }
  }

  Future<void> deleteConnectedUserByEmails(String concatenatedEmails) async {
    try {
      // Query the collection to find the document with the provided concatenated emails
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('connectedUsers')
          .where('users', isEqualTo: concatenatedEmails)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Get the document ID
        String documentId = querySnapshot.docs.first.id;

        // Delete the document
        await FirebaseFirestore.instance
            .collection('connectedUsers')
            .doc(documentId)
            .delete();

        print(
            "Document with concatenated emails $concatenatedEmails deleted successfully");
      } else {
        print("No document found with concatenated emails $concatenatedEmails");
      }
    } catch (e) {
      print("Error deleting document: $e");
    }
  }

  Future<bool> connectTwoUsers({
    required BuildContext context,
    required String receiverEmail,
    required String receiverName,
  }) async {
    QuerySnapshot userSnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: receiverEmail)
        .get();

    if (userSnapshot.docs.isEmpty) {
      // Receiver does not exist
      return false;
    }

    String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
    String currentUserName =
        FirebaseAuth.instance.currentUser!.displayName ?? '';

    CollectionReference connectedUsers =
        _firestore.collection('connectedUsers');

    // Sort emails to avoid duplicates
    List<String> emails = [currentUserEmail, receiverEmail]..sort();
    String documentName = "${emails[0]}-${emails[1]}";

    Map<String, Map<String, String>> users = {
      currentUserEmail: {
        'userName': currentUserName,
        'imageURL': '',
      },
      receiverEmail: {
        'userName': receiverName,
        'imageURL': '',
      },
    };

    try {
      await connectedUsers.doc(documentName).set({'users': users});
      print('ConnectedUsers document created successfully');
      return true;
    } catch (error) {
      print('Failed to create document: $error');
      return false;
    }
  }

  // Method to send a new message
  Future<void> sendNewMessage(
      {required String concatenatedEmail, required String message}) async {
    // Reference to the subcollection "messages" under the document
    CollectionReference messagesSubCollection = _firestore
        .collection('connectedUsers')
        .doc(concatenatedEmail)
        .collection('messages');

    // Add a message to the "messages" subcollection
    await messagesSubCollection.add({
      'sender': currentUserEmail,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    }).then((docRef) {
      print("Message added with ID: ${docRef.id}");
    }).catchError((error) {
      print("Failed to add message: $error");
    });
  }

  Future<String?> uploadImage(Uint8List fileBytes) async {
    try {
      String? email = _auth
          .currentUser?.email; // Replace `_auth` with your actual auth instance
      if (email == null) {
        throw Exception('User email is not available');
      }

      String sanitizedEmail =
          email.replaceAll('@', '_at_').replaceAll('.', '_dot_');
      String fileName = 'profile_picture.png';

      // Reference to the Firebase Storage location
      Reference storageRef = _firebaseStorage.ref().child('$email/$fileName');

      if (kIsWeb) {
        // For Web: Use Uint8List for uploading
        await storageRef.putData(fileBytes);
      } else {
        // For Mobile: Upload file (the Uint8List will need to be converted to a File object)
        await storageRef.putData(fileBytes);
      }

      // Get and return the download URL of the uploaded image
      return await storageRef.getDownloadURL();
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  Future<String?> getImageUrl(String email) async {
    try {
      String fileName = 'profile_picture.png';
      // Get reference to the storage location of the image
      final storageRef =
          FirebaseStorage.instance.ref().child('$email/$fileName');

      // Get the download URL of the file
      String downloadURL = await storageRef.getDownloadURL();

      // Return the download URL
      return downloadURL;
    } catch (e) {
      print('Error getting image URL: $e');
      return null;
    }
  }

  Future<void> setConcatenatedString(String receiverEmail) async {
    try {
      // Construct the concatenated strings
      String concatenatedString1 = "$currentUserEmail-$receiverEmail";
      String concatenatedString2 = "$receiverEmail-$currentUserEmail";

      // Check for the first concatenated string
      DocumentSnapshot documentSnapshot1 = await FirebaseFirestore.instance
          .collection('connectedUsers')
          .doc(concatenatedString1)
          .get();

      // Check for the second concatenated string
      DocumentSnapshot documentSnapshot2 = await FirebaseFirestore.instance
          .collection('connectedUsers')
          .doc(concatenatedString2)
          .get();

      // Return the concatenated string if the corresponding document exists
      if (documentSnapshot1.exists) {
        _concatenatedString = concatenatedString1;
      } else if (documentSnapshot2.exists) {
        _concatenatedString =
            concatenatedString2; // Return the second concatenated string
      }
    } catch (e) {
      print('Error checking documents: $e'); // Return empty on error
    }
  }
}
