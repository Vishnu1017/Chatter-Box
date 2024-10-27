import 'package:chatter_box/service/shared_pref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: unused_import
import 'package:firebase_core/firebase_core.dart';

class DatabaseMethods {
  Future addUserDetails(Map<String, dynamic> userInfoMap, String id) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .set(userInfoMap);
  }

  Future<QuerySnapshot> getUserbyemail(String email) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .where("Email", isEqualTo: email)
        .get();
  }

  // ignore: non_constant_identifier_names
  Future<QuerySnapshot> Search(String username) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .where("SearchKey", isEqualTo: username.substring(0, 1).toUpperCase())
        .get();
  }

  createChatRoom(
      String chatRoomId, Map<String, dynamic> chatRoomInfoMap) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .get();
    if (snapshot.exists) {
      return true;
    } else {
      return FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(chatRoomId)
          .set(chatRoomInfoMap);
    }
  }

  Future addMessage(String chatRoomId, String messageId,
      Map<String, dynamic> messageInfoMap) async {
    await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .doc(messageId)
        .set(messageInfoMap);
  }

  updateLastMessageSend(
      String chatRoomId, Map<String, dynamic> lastMessageInfoMap) async {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .update(lastMessageInfoMap);
  }

  Future<Stream<QuerySnapshot>> getChatRoomMessages(chatRoomId) async {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .orderBy("time", descending: true)
        .snapshots();
  }

  Future<QuerySnapshot> getUserInfo(String username) async {
    return FirebaseFirestore.instance
        .collection("users")
        .where("username", isEqualTo: username)
        .get();
  }

  Future<Stream<QuerySnapshot>> getChatRooms() async {
    String? myUsername = await SharedPreferenceHelperf().getUserName();
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .orderBy("time", descending: true)
        .where("users", arrayContains: myUsername!.toUpperCase())
        .snapshots();
  }

  Future<void> deleteChatRoom(String chatRoomId) async {
    try {
      await FirebaseFirestore.instance
          .collection('chatrooms') // make sure this matches your collection
          .doc(chatRoomId)
          .delete();
    } catch (e) {
      print("Error deleting chat room: $e");
    }
  }

  Future<void> uploadStatus(String name, String username, String profilePic,
      String status, String? imageUrl) async {
    await FirebaseFirestore.instance.collection("statuses").add({
      "Name": name,
      "username": username,
      "Photo": profilePic,
      "status": status,
      "imageUrl": imageUrl, // Make sure this is correctly included
      "lastUpdated": FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Object?>> getStatuses() {
    return FirebaseFirestore.instance
        .collection("statuses")
        .orderBy("lastUpdated", descending: true)
        .snapshots();
  }

  Future<void> deleteStatus(String statusId) async {
    await FirebaseFirestore.instance
        .collection("statuses")
        .doc(statusId)
        .delete();
  }
}
