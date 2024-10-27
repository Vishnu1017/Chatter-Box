import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chatter_box/service/database.dart';
import 'package:chatter_box/service/shared_pref.dart';
import 'package:intl/intl.dart';

class Status extends StatefulWidget {
  const Status({Key? key}) : super(key: key);

  @override
  State<Status> createState() => _StatusState();
}

class _StatusState extends State<Status> {
  String? myName, myProfilePic, myUserName, myEmail;
  Stream<QuerySnapshot<Object?>>? statusStream;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    onLoad();
  }

  // Fetch shared preferences
  getSharedPref() async {
    myName = await SharedPreferenceHelperf().getDisplayName();
    myProfilePic = await SharedPreferenceHelperf().getUserPic();
    myUserName = await SharedPreferenceHelperf().getUserName();
    myEmail = await SharedPreferenceHelperf().getUserEmail();
    setState(() {});
  }

  // Load initial data
  onLoad() async {
    await getSharedPref();
    statusStream = await DatabaseMethods().getStatuses();
    setState(() {});
  }

  // Show dialog to upload status
  void showStatusDialog() {
    final TextEditingController statusController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                const BoxShadow(
                  color: Colors.black54,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Upload Status",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: statusController,
                  decoration: InputDecoration(
                    hintText: "Enter your status",
                    hintStyle: const TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 15),
                _imageFile != null
                    ? Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                const BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _imageFile!,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _imageFile = null;
                              });
                            },
                            child: const Text(
                              "Remove Image",
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        "No image selected",
                        style: TextStyle(color: Colors.white),
                      ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final ImagePicker _picker = ImagePicker();
                        final XFile? pickedFile = await _picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                        );

                        if (pickedFile != null) {
                          setState(() {
                            _imageFile = File(pickedFile.path);
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("No image selected.")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        backgroundColor: Colors.white,
                      ),
                      child: const Text("Pick Image"),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        String statusText = statusController.text.trim();
                        if (statusText.isNotEmpty || _imageFile != null) {
                          String? imageUrl;

                          if (_imageFile != null) {
                            try {
                              final storageRef = FirebaseStorage.instance
                                  .ref()
                                  .child(
                                      'statuses/${DateTime.now().millisecondsSinceEpoch}.png');

                              await storageRef.putFile(_imageFile!);
                              imageUrl = await storageRef.getDownloadURL();
                            } catch (e) {
                              print("Error uploading image: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text("Failed to upload image: $e")),
                              );
                              return;
                            }
                          }

                          try {
                            await DatabaseMethods().uploadStatus(
                              myName!,
                              myUserName!,
                              myProfilePic!,
                              statusText,
                              imageUrl,
                              DateTime.now(), // Add timestamp here
                            );
                            Navigator.pop(context);
                            statusController.clear();
                            setState(() {
                              _imageFile = null;
                            });
                          } catch (e) {
                            print("Error uploading status: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text("Failed to upload status: $e")),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Please enter a status or pick an image.")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        backgroundColor: Colors.white,
                      ),
                      child: const Text("Upload"),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 64, 161, 246),
                Color.fromARGB(255, 8, 85, 163),
              ],
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
            ),
          ),
          child: AppBar(
            title: const Text(
              'Status',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Object?>>(
        stream: statusStream,
        builder: (context, AsyncSnapshot<QuerySnapshot<Object?>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No statuses available"));
          }

          final now = DateTime.now();
          final recentStatuses = snapshot.data!.docs.where((doc) {
            DateTime lastUpdated = (doc["lastUpdated"] as Timestamp).toDate();
            return now.difference(lastUpdated).inHours < 24;
          }).toList();

          if (recentStatuses.isEmpty) {
            return const Center(child: Text("No recent statuses"));
          }

          return ListView.builder(
            itemCount: recentStatuses.length,
            itemBuilder: (context, index) {
              DocumentSnapshot ds = recentStatuses[index];
              String statusId = ds.id;

              return Dismissible(
                key: Key(statusId),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                onDismissed: (direction) {
                  DatabaseMethods().deleteStatus(statusId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Status deleted")),
                  );
                },
                child: StatusListTile(
                  name: ds["Name"],
                  username: ds["username"],
                  profilePic: ds["Photo"],
                  status: ds["status"],
                  lastUpdated: ds["lastUpdated"],
                  imageUrl: ds["imageUrl"],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showStatusDialog,
        backgroundColor: Colors.blueAccent,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

// Widget to display each status
class StatusListTile extends StatelessWidget {
  final String name;
  final String username;
  final String profilePic;
  final String status;
  final Timestamp? lastUpdated; // Nullable Timestamp
  final String? imageUrl;

  const StatusListTile({
    Key? key,
    required this.name,
    required this.username,
    required this.profilePic,
    required this.status,
    this.lastUpdated,
    this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Format the lastUpdated time to 12-hour format
    String formattedTime = lastUpdated != null
        ? DateFormat('hh:mm a')
            .format(lastUpdated!.toDate()) // Format to 12-hour
        : "Unknown time";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Colors.blueAccent, Colors.purpleAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundImage: NetworkImage(profilePic),
            radius: 26,
          ),
          title: Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status,
                style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600),
              ),
              if (imageUrl != null && imageUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl!,
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                formattedTime, // Display the formatted time here
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StatusDetailPage(
                  name: name,
                  username: username,
                  profilePic: profilePic,
                  status: status,
                  imageUrl: imageUrl,
                  lastUpdated: lastUpdated,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class StatusDetailPage extends StatelessWidget {
  final String name;
  final String username;
  final String profilePic;
  final String status;
  final String? imageUrl;
  final Timestamp? lastUpdated;

  const StatusDetailPage({
    Key? key,
    required this.name,
    required this.username,
    required this.profilePic,
    required this.status,
    this.imageUrl,
    this.lastUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 64, 161, 246), // Light Blue
                Color.fromARGB(255, 8, 85, 163), // Darker Blue
              ],
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
            ),
          ),
          child: AppBar(
            title: Text(
              '$username\'s Status',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 240, 248, 255), // Light background
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section with a unique layout
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(profilePic),
                          radius: 45,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(
                                    255, 8, 85, 163), // Dark Blue
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              status,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Image Section
                if (imageUrl != null && imageUrl!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 200,
                        ),
                        // Overlay with a gradient
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.6),
                                Colors.transparent,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                        // Overlay Text
                        const Positioned(
                          bottom: 10,
                          left: 10,
                          child: Text(
                            'Status Image',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Last Updated Section
                if (lastUpdated != null)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Last updated: ${lastUpdated!.toDate().toLocal()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
