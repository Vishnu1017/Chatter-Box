import 'dart:io';
import 'package:chatter_box/pages/signin.dart';
import 'package:chatter_box/service/auth.dart';
import 'package:flutter/material.dart';
import 'package:chatter_box/service/shared_pref.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? myName, myEmail, myImageUrl;
  File? myImageFile;

  @override
  void initState() {
    super.initState();
    getUserInfo();
  }

  Future<void> getUserInfo() async {
    myName = await SharedPreferenceHelperf().getDisplayName();
    myEmail = await SharedPreferenceHelperf().getUserEmail();
    myImageUrl = await SharedPreferenceHelperf().getUserPic();
    myImageFile = await _getImageFromPreferences();
    setState(() {});
  }

  Future<File?> _getImageFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final String? imagePath = prefs.getString('myImagePath');
    if (imagePath != null && imagePath.isNotEmpty) {
      File file = File(imagePath);
      if (await file.exists()) {
        return file;
      } else {
        print('File does not exist at path: $imagePath');
        await prefs.remove('myImagePath'); // Clear invalid image path
      }
    }
    return null;
  }

  Future<void> _saveImageToPreferences(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('myImagePath', path);
  }

  Future<void> logout(BuildContext context) async {
    try {
      await AuthMethods().SignOut(); // Corrected to match your AuthMethods
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Successfully logged out.", style: TextStyle(fontSize: 18)),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignIn()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error logging out: ${e.toString()}",
              style: const TextStyle(fontSize: 18)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> deleteUser(BuildContext context) async {
    try {
      await AuthMethods().deleteuser(); // Corrected to match your AuthMethods
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User account successfully deleted.",
              style: TextStyle(fontSize: 18)),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignIn()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error deleting user: ${e.toString()}",
              style: const TextStyle(fontSize: 18)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> pickImage() async {
    final ImagePicker _picker = ImagePicker();

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        setState(() {
          myImageFile = File(pickedFile.path);
          myImageUrl = null; // Reset URL since a new image is selected
        });
        await _saveImageToPreferences(pickedFile.path);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
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
              'Settings',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Profile Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        child: myImageFile != null
                            ? ClipOval(
                                child: Image.file(
                                  myImageFile!,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                ),
                              )
                            : myImageUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      myImageUrl!,
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
                                    ),
                                  )
                                : ClipOval(
                                    child: Container(
                                      color: Colors.grey,
                                      child: const Center(
                                        child: Icon(Icons.person,
                                            size: 50, color: Colors.white),
                                      ),
                                    ),
                                  ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      title: Text('Name: ${myName ?? 'Not set'}'),
                      trailing: const Icon(Icons.edit),
                      onTap: () {
                        // Implement edit name functionality
                      },
                    ),
                    ListTile(
                      title: Text('Email: ${myEmail ?? 'Not set'}'),
                      trailing: const Icon(Icons.edit),
                      onTap: () {
                        // Implement edit email functionality
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Settings Options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      // Implement change password functionality
                    },
                  ),
                  ListTile(
                    title: const Text('Privacy Settings'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      // Implement privacy settings functionality
                    },
                  ),
                  ListTile(
                    title: const Text('Log Out'),
                    trailing: const Icon(Icons.logout, color: Colors.red),
                    onTap: () => logout(context),
                  ),
                  ListTile(
                    title: const Text('Delete Account'),
                    trailing: const Icon(Icons.delete, color: Colors.red),
                    onTap: () => deleteUser(context),
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
