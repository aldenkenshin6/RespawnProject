import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:projectrespawn/Account/Users/pages/NewsFeeds.dart';
import 'package:projectrespawn/Account/Users/pages/NotificationPage.dart';
import 'package:projectrespawn/Account/Users/pages/Profile.dart';
import 'package:projectrespawn/Account/Users/pages/UserListScreen.dart';
import 'package:projectrespawn/auth/auth_service.dart';
import 'package:projectrespawn/auth_layout.dart';

class MainUser extends StatefulWidget {
  const MainUser({super.key});

  @override
  State<MainUser> createState() => _MainUserState();
}

class _MainUserState extends State<MainUser> {
  int index = 0;

  final List<Widget> page = [
    NewsFeeds(),
    UsersListScreen(),
    NotificationPage(),
    Profile(),
  ];

  //Step2: declare ug naga accept ug null
  String? displayname;

  //Step1: Create function to fetch ang display name
  Future<String?> getUserDisplayname(String uid) async {
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();
    if (documentSnapshot.exists) {
      return documentSnapshot["displayname"];
    } else {
      return null;
    }
  }

  //Step3: fetch the display in InitState kay ra nakog tarantado ani
  @override
  void initState() {
    super.initState();
    getname();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> getname() async {
    final uid = authService.value.currentUser?.uid;
    if (uid != null) {
      final name = await getUserDisplayname(uid);
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
      extendBody: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        //Step 4: display na nimo
        title: Text(
          displayname != null ? "Hi, $displayname" : "Loading...",
          style: TextStyle(
            color: Color(0xFF830A0A),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Row(
            children: [
              IconButton(
                onPressed: () async {
                  await authService.value.signOut();
                  PopPage();
                },
                icon: Icon(Icons.logout),
              ),
            ],
          ),
        ],
      ),
      body: page[index],
      bottomNavigationBar: CurvedNavigationBar(
        color: Color(0xFF830A0A),
        animationDuration: Duration(milliseconds: 300),
        animationCurve: Curves.easeInOut,
        onTap: (value) {
          setState(() {
            index = value;
          });
        },
        backgroundColor: Colors.transparent,
        items: [
          Icon(Icons.home, color: Colors.white),
          Icon(Icons.message, color: Colors.white),
          Icon(Icons.notifications_none, color: Colors.white),
          Icon(Icons.person, color: Colors.white),
        ],
      ),
    );
  }
}
