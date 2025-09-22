import 'package:flutter/material.dart';

class Managepost extends StatefulWidget {
  const Managepost({super.key});

  @override
  State<Managepost> createState() => _ManagepostState();
}

class _ManagepostState extends State<Managepost> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text("This is the Dashboard")],
        ),
      ),
    );
  }
}
