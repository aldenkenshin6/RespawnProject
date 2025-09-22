import 'package:flutter/material.dart';

class NotificationUser extends StatefulWidget {
  const NotificationUser({super.key});

  @override
  State<NotificationUser> createState() => _NotificationUserState();
}

class _NotificationUserState extends State<NotificationUser> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text("Notification Nigga")],
        ),
      ),
    );
  }
}
