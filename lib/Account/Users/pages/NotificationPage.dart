import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projectrespawn/auth/auth_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = authService.value.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to see notifications")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("notifications")
            .doc(currentUser.uid)
            .collection("items")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                "No notifications yet",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;

              String message = "";
              IconData icon = Icons.notifications;
              Color iconColor = Colors.grey;

              if (data["type"] == "like") {
                message =
                    "${data['fromUserName']} liked your post: \"${data['postCaption'] ?? ''}\"";
                icon = Icons.favorite;
                iconColor = Colors.red;
              } else if (data["type"] == "comment") {
                message =
                    "${data['fromUserName']} commented: \"${data['commentText']}\" on your post: \"${data['postCaption'] ?? ''}\"";
                icon = Icons.comment;
                iconColor = Colors.blue;
              }

              // Format timestamp
              String timeAgo = "";
              if (data["timestamp"] != null) {
                final dateTime = (data["timestamp"] as Timestamp).toDate();
                timeAgo = timeago.format(dateTime);
              }

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    child: Icon(icon, color: iconColor),
                  ),
                  title: Text(message, style: const TextStyle(fontSize: 14)),
                  subtitle: timeAgo.isNotEmpty
                      ? Text(
                          timeAgo,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
