import 'package:chatter_box/pages/home.dart';
import 'package:chatter_box/pages/settings_page.dart';
import 'package:chatter_box/pages/status_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BottomNavBarPage extends StatefulWidget {
  final String username;
  final String name;
  final String profileurl;

  const BottomNavBarPage({
    super.key,
    required this.username,
    required this.name,
    required this.profileurl,
  });

  @override
  _BottomNavBarPageState createState() => _BottomNavBarPageState();
}

class _BottomNavBarPageState extends State<BottomNavBarPage> {
  int _selectedIndex = 1; // Set initial index to Chats (1)

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const Status(),
      const Home(), // Chats page is now Home
      const SettingsPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Helper function to return the appropriate icon
  IconData _getIcon(int index) {
    switch (index) {
      case 0:
        return _selectedIndex == 0
            ? CupertinoIcons.photo_camera_solid // Filled icon for Status
            : CupertinoIcons.camera; // Outlined icon for Status
      case 1:
        return _selectedIndex == 1
            ? CupertinoIcons.chat_bubble_2_fill
            : CupertinoIcons.chat_bubble_2; // Chats icon
      case 2:
        return _selectedIndex == 2
            ? CupertinoIcons.settings
            : CupertinoIcons.settings_solid; // Settings icon
      default:
        return CupertinoIcons.exclamationmark; // Fallback icon
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.blue[800], // Darker blue background
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.grey,
              blurRadius: 10,
              spreadRadius: 1,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: List.generate(3, (index) {
            return BottomNavigationBarItem(
              icon: Icon(
                  _getIcon(index)), // Use the helper function to get the icon
              label: index == 0
                  ? 'Status'
                  : index == 1
                      ? 'Chats'
                      : 'Settings',
            );
          }),
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.white, // White for selected item
          unselectedItemColor:
              Colors.blue[100], // Lighter blue for unselected items
          showUnselectedLabels: true,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          iconSize: 30,
          selectedFontSize: 16,
          unselectedFontSize: 14,
          backgroundColor: Colors.blue[800], // Blue background
          selectedIconTheme:
              const IconThemeData(size: 35), // Increase icon size for selected
          unselectedIconTheme:
              const IconThemeData(size: 25), // Default size for unselected
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold, // Bold font for selected label
            color: Colors.white,
          ),
          unselectedLabelStyle: TextStyle(
            color: Colors.blue[100], // Lighter color for unselected labels
          ),
        ),
      ),
    );
  }
}
