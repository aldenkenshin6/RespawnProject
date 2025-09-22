import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:projectrespawn/Account/Admin/pages/Dashboard.dart';
import 'package:projectrespawn/Account/Admin/pages/ManagePost.dart';
import 'package:projectrespawn/auth/auth_service.dart';
import 'package:projectrespawn/auth_layout.dart';

class Mainadmin extends StatefulWidget {
  const Mainadmin({super.key});

  @override
  State<Mainadmin> createState() => _MainadminState();
}

class _MainadminState extends State<Mainadmin> {
  int index = 0;

  final page = <Widget>[Dashboard(), Managepost()];

  String? displayname;

  Future<String?> getdisplayname(String uid) async {
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    if (documentSnapshot.exists) {
      return documentSnapshot["displayname"];
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    getName();
  }

  Future<void> getName() async {
    final uid = authService.value.currentUser?.uid;
    if (uid != null) {
      final name = await getdisplayname(uid);
      setState(() {
        displayname = name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    void PopPage() {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthLayout()),
        (route) => false,
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          displayname != null ? "Hi $displayname" : "Loading...",
          style: TextStyle(
            color: Color(0XFF149DE6),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await authService.value.signOut();
              PopPage();
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: page[index],
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: Color(0XFF149DE6),
        animationDuration: Duration(milliseconds: 300),
        onTap: (value) {
          setState(() {
            index = value;
          });
        },
        items: [
          Icon(Icons.dashboard, color: Colors.white),
          Icon(Icons.manage_accounts, color: Colors.white),
        ],
      ),
    );
  }
}
