// ignore_for_file: public_member_api_docs, sort_constructors_first, unnecessary_string_escapes
import 'package:chatter_box/pages/bottom_nav_page.dart';
import 'package:chatter_box/service/database.dart';
import 'package:chatter_box/service/shared_pref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:random_string/random_string.dart';
import 'package:share_plus/share_plus.dart';

// ignore: must_be_immutable
class ChatPage extends StatefulWidget {
  String name, profileurl, username;
  ChatPage({
    super.key,
    required this.username,
    required this.name,
    required this.profileurl,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController messagecontroller = new TextEditingController();
  String? myUserName, myProfilePic, myName, myEmail, messageId, chatRoomId;
  Stream? messageStream;

  getthesharedpref() async {
    myName = await SharedPreferenceHelperf().getDisplayName();
    myProfilePic = await SharedPreferenceHelperf().getUserPic();
    myEmail = await SharedPreferenceHelperf().getUserEmail();
    myUserName = await SharedPreferenceHelperf().getUserName();

    chatRoomId = getChatRoomIdbyUsername(widget.username, myUserName!);
    setState(() {});
  }

  ontheload() async {
    await getthesharedpref();
    await getAndSendMessage();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    ontheload();
  }

  getChatRoomIdbyUsername(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }

  Widget chatMessageTile(String message, bool sendByMe, String time,
      BuildContext context, DocumentSnapshot ds) {
    return GestureDetector(
      onLongPress: () => _showOptions(context, ds),
      child: Column(
        crossAxisAlignment:
            sendByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(25),
                      topRight: const Radius.circular(25),
                      bottomRight: sendByMe
                          ? const Radius.circular(0)
                          : const Radius.circular(25),
                      bottomLeft: sendByMe
                          ? const Radius.circular(25)
                          : const Radius.circular(0),
                    ),
                    color: sendByMe
                        ? const Color(0xFFE9EDEF)
                        : const Color(0xFF70A1FF),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(1, 3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: sendByMe ? Colors.black87 : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: sendByMe
                ? const EdgeInsets.only(right: 16.0, top: 2.0)
                : const EdgeInsets.only(left: 16.0, top: 2.0),
            child: Text(
              time,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context, DocumentSnapshot ds) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(40)), // More rounded corners
      ),
      backgroundColor:
          Colors.transparent, // Keep background transparent for gradient
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 450, // Adjusted height
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade800,
                Colors.blue.shade400
              ], // Bright gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 15,
                offset: Offset(0, 10), // Shadow effect
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select an Action',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _buildUniqueCard(context, Icons.edit, 'Edit', Colors.orange,
                        () {
                      Navigator.pop(context);
                      // Handle edit action
                    }),
                    _buildUniqueCard(
                        context, Icons.delete, 'Delete', Colors.red, () {
                      FirebaseFirestore.instance
                          .collection('messages')
                          .doc(ds.id)
                          .delete();
                      Navigator.pop(context);
                    }),
                    _buildUniqueCard(context, Icons.copy, 'Copy', Colors.green,
                        () {
                      Clipboard.setData(ClipboardData(text: ds['message']));
                      Navigator.pop(context);
                    }),
                    _buildUniqueCard(
                        context, Icons.share, 'Share', Colors.purple, () {
                      Share.share(ds['message']);
                      Navigator.pop(context);
                    }),
                    _buildUniqueCard(
                        context,
                        Icons.favorite,
                        'Mark as Favorite',
                        const Color.fromARGB(255, 187, 169, 0), () {
                      FirebaseFirestore.instance
                          .collection('favorites')
                          .add({'message': ds['message']});
                      Navigator.pop(context);
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUniqueCard(BuildContext context, IconData icon, String title,
      Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9), // Slightly opaque background
          borderRadius: BorderRadius.circular(55), // Rounded corners
          border: Border.all(color: iconColor, width: 2), // Colorful border
          boxShadow: [
            const BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: iconColor, // Colorful icon background
                child: Icon(icon, color: Colors.white, size: 25), // White icon
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget chatMessage() {
    return StreamBuilder(
      stream: messageStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          List<DocumentSnapshot> docs = snapshot.data.docs;
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100, top: 130),
            itemCount: docs.length,
            reverse: true,
            itemBuilder: (context, index) {
              DocumentSnapshot ds = docs[index];

              // Safely handle null time field
              Timestamp? timestamp = ds["time"];
              DateTime? currentMessageDate;
              if (timestamp != null) {
                currentMessageDate = timestamp.toDate();
              }

              // Set formatted time; use "Just Now" or a similar message if timestamp is null
              String formattedTime = currentMessageDate != null
                  ? formatTime(currentMessageDate)
                  : "Just Now"; // Default display for messages without a valid timestamp

              // Check if the message has a valid date
              if (currentMessageDate != null) {
                String formattedDate = formatDate(currentMessageDate);

                // Compare with the previous message's date (if exists)
                bool showDate = index == docs.length - 1 ||
                    (docs[index + 1]["time"] != null &&
                        currentMessageDate.day !=
                            (docs[index + 1]["time"] as Timestamp)
                                .toDate()
                                .day);

                return Column(
                  children: [
                    if (showDate)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          formattedDate,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    chatMessageTile(
                      ds["message"],
                      myUserName == ds["sendBy"],
                      formattedTime, // Display formatted time
                      context, // Pass context for options
                      ds, // Pass document snapshot for actions
                    ),
                  ],
                );
              } else {
                // Display message immediately even without a valid timestamp
                return chatMessageTile(
                  ds["message"],
                  myUserName == ds["sendBy"],
                  formattedTime, // Display the default time ("Just Now")
                  context, // Pass context for options
                  ds, // Pass document snapshot for actions
                );
              }
            },
          );
        } else {
          return const Center(
            child: CircularProgressIndicator.adaptive(),
          );
        }
      },
    );
  }

// Helper function to format time safely
  String formatTime(DateTime dateTime) {
    // Get hour in 12-hour format
    String hour = dateTime.hour > 12
        ? (dateTime.hour - 12).toString()
        : dateTime.hour.toString();

    // Determine AM or PM
    String amPm = dateTime.hour >= 12 ? 'PM' : 'AM';

    // Format minute with leading zero if necessary
    String formattedMinute = dateTime.minute.toString().padLeft(2, '0');

    return "$hour:$formattedMinute $amPm"; // Format as HH:mm AM/PM
  }

// Helper function to format date or day safely
  String formatDate(DateTime dateTime) {
    DateTime now = DateTime.now();
    DateTime startOfWeek =
        now.subtract(Duration(days: now.weekday - 1)); // Monday

    // If the message date is within the current week
    if (dateTime.isAfter(startOfWeek)) {
      // Show the day of the week
      return getDayOfWeek(dateTime.weekday);
    } else {
      // Otherwise, show the date in DD/MM/YYYY format
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    }
  }

// Helper function to get day of the week
  String getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return "Monday";
      case 2:
        return "Tuesday";
      case 3:
        return "Wednesday";
      case 4:
        return "Thursday";
      case 5:
        return "Friday";
      case 6:
        return "Saturday";
      case 7:
        return "Sunday";
      default:
        return "";
    }
  }

  addMessage(bool sendClick) {
    if (messagecontroller.text != "") {
      String message = messagecontroller.text;
      messagecontroller.text = "";

      DateTime now = DateTime.now();
      String formattedDate = DateFormat("h:mma").format(now);
      Map<String, dynamic> messageInfoMap = {
        "message": message,
        "sendBy": myUserName,
        "ts": formattedDate,
        "time": FieldValue.serverTimestamp(),
        "imgUrl": myProfilePic,
      };
      messageId ??= randomAlphaNumeric(10);

      DatabaseMethods()
          .addMessage(chatRoomId!, messageId!, messageInfoMap)
          .then((value) {
        Map<String, dynamic> lastMessageInfoMap = {
          "lastMessage": message,
          "LastMessageSendTs": formattedDate,
          "time": FieldValue.serverTimestamp(),
          "lastMessageSendBy": myUserName,
        };

        DatabaseMethods()
            .updateLastMessageSend(chatRoomId!, lastMessageInfoMap);
        if (sendClick) {
          messageId = null;
        }
      });
    }
  }

  getAndSendMessage() async {
    messageStream = await DatabaseMethods().getChatRoomMessages(chatRoomId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 26, 94, 242),
      // ignore: avoid_unnecessary_containers
      body: Container(
        child: Stack(
          children: [
            Container(
                margin: const EdgeInsets.only(top: 115),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 1.12,
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20))),
                child: chatMessage()),
            Padding(
              padding: const EdgeInsets.only(
                  left: 10, right: 20, top: 55, bottom: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const BottomNavBarPage(
                                    username: '',
                                    name: '',
                                    profileurl: '',
                                  )));
                    },
                    child: const Icon(
                      Icons.arrow_back_ios_new_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 20),
                  ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.network(
                        widget.profileurl,
                        height: 50,
                        width: 50,
                        fit: BoxFit.cover,
                      )),
                  const SizedBox(width: 10),
                  Text(
                    widget.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.bottomCenter,
              margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.grey[200]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: messagecontroller,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Say something...",
                            hintStyle: const TextStyle(
                                color: Colors.black38,
                                fontStyle: FontStyle.italic),
                            prefixIcon: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue[100],
                              ),
                              child: const Icon(Icons.keyboard,
                                  color: Colors.blueAccent),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 18, horizontal: 16),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Colors.blueAccent, Colors.lightBlueAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () {
                            addMessage(true);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
