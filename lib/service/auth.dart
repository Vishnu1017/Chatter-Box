import 'package:firebase_auth/firebase_auth.dart';

class AuthMethods {
  final FirebaseAuth auth = FirebaseAuth.instance;

  getcurrentUser() async {
    return await auth.currentUser;
  }

  Future<void> SignOut() async {
    try {
      await auth.signOut();
    } catch (e) {
      throw Exception('Error signing out: $e');
    }
  }

  Future<void> deleteuser() async {
    try {
      User? user = auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }
}
