import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminNotifications extends StatelessWidget {
  const AdminNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("notifications")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No notifications yet."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var notif = docs[index];
              return Card(
                child: ListTile(
                  title: Text(notif["title"]),
                  subtitle: Text(
                    "${notif["message"]}\n${DateFormat('hh:mm a').format((notif["timestamp"] as Timestamp).toDate())}",
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
