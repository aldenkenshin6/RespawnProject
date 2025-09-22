import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:projectrespawn/Account/Admin/MainAdmin.dart';
import 'package:projectrespawn/Account/Users/MainUser.dart';
import 'package:projectrespawn/apploadingpage.dart';
import 'package:projectrespawn/auth/auth_service.dart';
import 'package:projectrespawn/delay.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, this.thisInNotConnected});

  final Widget? thisInNotConnected;

  Future<String?> getUserRole(String uid) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    if (doc.exists) {
      return doc["role"];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: authService,
      builder: (context, authService, child) {
        return StreamBuilder(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Apploadingpage();
            }
            if (snapshot.hasData) {
              final uid = snapshot.data!.uid;
              return FutureBuilder<String?>(
                future: getUserRole(uid),
                builder: (context, rolesnapshot) {
                  if (rolesnapshot.connectionState == ConnectionState.waiting) {
                    return const Apploadingpage();
                  }
                  if (rolesnapshot.hasError || rolesnapshot.data == null) {
                    return Scaffold(
                      body: Center(child: Text("Error Loading user role")),
                    );
                  }
                  final userRole = rolesnapshot.data;
                  if (userRole == "admin") {
                    return const Mainadmin();
                  }
                  if (userRole == "user") {
                    return const MainUser();
                  } else {
                    return const Scaffold(
                      body: Center(child: Text("Unknown Role")),
                    );
                  }
                },
              );
            }
            return thisInNotConnected ?? const Delay();
          },
        );
      },
    );
  }
}
