import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:projectrespawn/auth/auth_service.dart';
import 'package:intl/intl.dart';

class Messages extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const Messages({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<Messages> createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? photoUrl;

  void sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    await sendMessageToFirestore(widget.receiverId, _messageController.text);
    _messageController.clear();
    _scrollToBottom();
  }

  @override
  void initState() {
    super.initState();
    fetchPhoto();
  }

  Future<void> sendMessageToFirestore(String receiverId, String text) async {
    final currentUser = authService.value.currentUser;
    if (currentUser == null) return;
    String chatId = currentUser.uid.compareTo(receiverId) < 0
        ? "${currentUser.uid}_$receiverId"
        : "${receiverId}_${currentUser.uid}";
    await FirebaseFirestore.instance
        .collection("messages")
        .doc(chatId)
        .collection("messages")
        .add({
          "senderId": currentUser.uid,
          "receiverId": receiverId,
          "text": text,
          "timestamp": FieldValue.serverTimestamp(),
        });
  }

  Future<String?> getphotoUrl(String uid) async {
    DocumentSnapshot getUrl = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (getUrl.exists) {
      return getUrl.get("photoUrl");
    } else {
      return null;
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> fetchPhoto() async {
    final currentUser = authService.value.currentUser;
    if (currentUser != null) {
      final photo = await getphotoUrl(currentUser.uid);
      setState(() {
        photoUrl = photo;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = authService.value.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.receiverId)
              .get(),
          builder: (context, snapshot) {
            String? receiverPhotoUrl;
            if (snapshot.hasData && snapshot.data != null) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              if (data != null &&
                  data.containsKey("photoUrl") &&
                  data["photoUrl"] != null &&
                  data["photoUrl"].toString().isNotEmpty) {
                receiverPhotoUrl = data["photoUrl"];
              }
            }
            return Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: receiverPhotoUrl != null
                      ? NetworkImage(receiverPhotoUrl)
                      : null,
                  child: receiverPhotoUrl == null
                      ? const Icon(Icons.person, size: 20, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.receiverName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            );
          },
        ),
        backgroundColor: Color(0xFF830A0A),
        elevation: 2,
      ),
      body: Column(
        children: [
          // 🔹 Messages List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("messages")
                  .doc(
                    currentUser!.uid.compareTo(widget.receiverId) < 0
                        ? "${currentUser.uid}_${widget.receiverId}"
                        : "${widget.receiverId}_${currentUser.uid}",
                  )
                  .collection("messages")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var docs = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var msg = docs[index];
                    bool isMe = msg["senderId"] == currentUser.uid;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 10,
                      ),
                      child: Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Color(0xFF830A0A)
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isMe
                                      ? const Radius.circular(16)
                                      : const Radius.circular(0),
                                  bottomRight: isMe
                                      ? const Radius.circular(0)
                                      : const Radius.circular(16),
                                ),
                              ),
                              child: Text(
                                msg["text"],
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (msg["timestamp"] != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 2,
                                  left: 4,
                                  right: 4,
                                ),
                                child: Text(
                                  DateFormat('hh:mm a').format(
                                    (msg["timestamp"] as Timestamp).toDate(),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // 🔹 Message Input
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: "Type a message...",
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Color(0xFF830A0A),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
