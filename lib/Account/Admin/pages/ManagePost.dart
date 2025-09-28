import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManagePostsPage extends StatelessWidget {
  const ManagePostsPage({super.key});

  Future<void> deletePost(String postId) async {
    await FirebaseFirestore.instance.collection("posts").doc(postId).delete();
  }

  Future<void> editCaption(
    String postId,
    String oldCaption,
    BuildContext context,
  ) async {
    TextEditingController captionController = TextEditingController(
      text: oldCaption,
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Caption"),
        content: TextField(
          controller: captionController,
          decoration: const InputDecoration(labelText: "New Caption"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("posts")
                  .doc(postId)
                  .update({"caption": captionController.text});
              Navigator.pop(ctx);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Posts")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("posts")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              var post = posts[index];
              String postId = post.id;
              String caption = post["caption"] ?? "";
              String author = post["authorName"] ?? "Unknown";
              List likes = post["likes"] ?? [];
              String mediaUrl = post["mediaUrl"] ?? "";
              String mediaType = post["mediaType"] ?? "image";

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: mediaUrl.isNotEmpty
                      ? (mediaType == "image"
                            ? Image.network(
                                mediaUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.videocam, size: 40))
                      : const Icon(Icons.image, size: 40),
                  title: Text(
                    caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text("By $author • Likes: ${likes.length}"),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == "edit") {
                        editCaption(postId, caption, context);
                      } else if (value == "delete") {
                        deletePost(postId);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: "edit", child: Text("Edit")),
                      const PopupMenuItem(
                        value: "delete",
                        child: Text("Delete"),
                      ),
                    ],
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
