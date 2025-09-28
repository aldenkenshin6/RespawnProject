import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:projectrespawn/auth/auth_service.dart';
import 'package:projectrespawn/Account/Users/pages/Messages.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  String searchQuery = "";
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    fetchPhoto();
  }

  Future<String?> getphotoUrl(String uid) async {
    DocumentSnapshot getUrl = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (getUrl.exists) {
      return getUrl.get('photoUrl');
    } else {
      return null;
    }
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
        title: const Text(
          "Chats",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF830A0A),
        elevation: 3,
      ),
      body: Column(
        children: [
          // 🔹 Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search users...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // 🔹 User List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var users = snapshot.data!.docs;

                // Exclude current user
                var filteredUsers = users
                    .where((u) => u.id != currentUser!.uid)
                    .where(
                      (u) =>
                          u["displayname"].toString().toLowerCase().contains(
                            searchQuery,
                          ) ||
                          u["username"].toString().toLowerCase().contains(
                            searchQuery,
                          ),
                    )
                    .toList();

                if (filteredUsers.isEmpty) {
                  return const Center(
                    child: Text(
                      "No users found",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    var user = filteredUsers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[300],
                          backgroundImage:
                              (user.data() as Map<String, dynamic>).containsKey(
                                    "photoUrl",
                                  ) &&
                                  user["photoUrl"] != null &&
                                  user["photoUrl"].toString().isNotEmpty
                              ? NetworkImage(user["photoUrl"])
                              : null,
                          child:
                              (!(user.data() as Map<String, dynamic>)
                                      .containsKey("photoUrl") ||
                                  user["photoUrl"] == null ||
                                  user["photoUrl"].toString().isEmpty)
                              ? const Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Colors.white,
                                )
                              : null,
                        ),

                        title: Text(
                          user["displayname"],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          user["username"],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chat_bubble_outline,
                          color: Color(0xFF830A0A),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Messages(
                                receiverId: user.id,
                                receiverName: user["displayname"],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
