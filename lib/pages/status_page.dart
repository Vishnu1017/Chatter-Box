import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chatter_box/service/database.dart';
import 'package:chatter_box/service/shared_pref.dart';

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
            borderRadius: BorderRadius.circular(20), // Rounded corners
          ),
          backgroundColor: Colors
              .transparent, // Make the background transparent for gradient
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue[300]!,
                  Colors.blue[900]!
                ], // Gradient background
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  BorderRadius.circular(20), // Match the dialog border
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
                    color: Colors.white, // Title color
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: statusController,
                  decoration: InputDecoration(
                    hintText: "Enter your status",
                    hintStyle:
                        const TextStyle(color: Colors.white60), // Hint color
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                  ),
                  style:
                      const TextStyle(color: Colors.white), // Input text color
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
                                _imageFile = null; // Reset the image
                              });
                            },
                            child: const Text(
                              "Remove Image",
                              style: TextStyle(
                                  color:
                                      Colors.redAccent), // Remove button color
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        "No image selected",
                        style: TextStyle(
                            color: Colors.white), // No image text color
                      ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Button to pick an image
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
                            print("Picked image file: ${_imageFile!.path}");
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("No image selected.")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        backgroundColor: Colors.white, // Text color
                      ),
                      child: const Text("Pick Image"),
                    ),
                    // Button to upload status
                    ElevatedButton(
                      onPressed: () async {
                        String statusText = statusController.text.trim();
                        if (statusText.isNotEmpty || _imageFile != null) {
                          String? imageUrl; // Variable to hold the image URL

                          // Upload the image to Firebase Storage
                          if (_imageFile != null) {
                            try {
                              final storageRef = FirebaseStorage.instance
                                  .ref()
                                  .child(
                                      'statuses/${DateTime.now().millisecondsSinceEpoch}.png');

                              // Upload the file
                              await storageRef.putFile(_imageFile!);
                              // Get the download URL
                              imageUrl = await storageRef.getDownloadURL();
                              print("Image uploaded successfully: $imageUrl");
                            } catch (e) {
                              print("Error uploading image: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text("Failed to upload image: $e")),
                              );
                              return; // Exit if upload fails
                            }
                          }

                          // Upload status text and image URL to Firestore
                          try {
                            await DatabaseMethods().uploadStatus(
                              myName!,
                              myUserName!,
                              myProfilePic!,
                              statusText,
                              imageUrl, // Pass the image URL (as a string or null)
                            );
                            Navigator.pop(context); // Close the dialog
                            statusController.clear(); // Clear input field
                            setState(() {
                              _imageFile = null; // Reset the image
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
                        backgroundColor: Colors.white, // Text color
                      ),
                      child: const Text("Upload"),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Cancel Button
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white), // Cancel text color
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
                Color.fromARGB(255, 64, 161, 246), // Light Blue
                Color.fromARGB(255, 8, 85, 163), // Darker Blue
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

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot ds = snapshot.data!.docs[index];
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
    );
  }
}

// Widget to display each status
class StatusListTile extends StatelessWidget {
  final String name;
  final String username;
  final String profilePic;
  final String status;
  final Timestamp? lastUpdated;
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
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(profilePic),
        radius: 30,
      ),
      title: Text(name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(status),
          if (imageUrl != null && imageUrl!.isNotEmpty)
            Image.network(imageUrl!,
                height: 100, width: 100, fit: BoxFit.cover),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            lastUpdated != null
                ? "${lastUpdated!.toDate().hour}:${lastUpdated!.toDate().minute}"
                : "Unknown time",
            style: const TextStyle(fontSize: 12),
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
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: Text(
                            'Status Image',
                            style: const TextStyle(
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
