import 'dart:io' show File;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:projectrespawn/auth/auth_service.dart';
import 'package:video_player/video_player.dart';

class NewsFeeds extends StatefulWidget {
  const NewsFeeds({super.key});

  @override
  State<NewsFeeds> createState() => _NewsFeedsState();
}

class _NewsFeedsState extends State<NewsFeeds> {
  final TextEditingController _captionController = TextEditingController();
  final Map<String, TextEditingController> _commentControllers = {};
  String? displayname;
  String? photoUrl;
  TextEditingController _getCommentController(String postId) {
    return _commentControllers.putIfAbsent(
      postId,
      () => TextEditingController(),
    );
  }

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

  Future<String?> getUserPhotoUrl(String uid) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>?;
      return data?["photoUrl"];
    }
    return null;
  }

  //Step3: fetch the display in InitState kay ra nakog tarantado ani
  @override
  void initState() {
    super.initState();
    getname();
  }

  Future<void> getname() async {
    final uid = authService.value.currentUser?.uid;
    if (uid != null) {
      final name = await getUserDisplayname(uid);
      final a = await getUserPhotoUrl(uid);
      setState(() {
        displayname = name;
        photoUrl = a;
      });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    for (var c in _commentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  XFile? _pickedFile;
  Uint8List? _previewBytes;
  String? _mediaType;

  final String _cloudName = "ditzlkqag";
  final String _uploadPreset = "flutter_unsigned";

  Future<void> _pickMedia(bool isImage) async {
    final picker = ImagePicker();
    final picked = isImage
        ? await picker.pickImage(source: ImageSource.gallery)
        : await picker.pickVideo(source: ImageSource.gallery);

    if (picked != null) {
      if (kIsWeb && isImage) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedFile = picked;
          _previewBytes = bytes;
          _mediaType = "image";
        });
      } else {
        setState(() {
          _pickedFile = picked;
          _previewBytes = null;
          _mediaType = isImage ? "image" : "video";
        });
      }
    }
  }

  Future<String?> _uploadToCloudinary(XFile file, String type) async {
    final String resourcePath = type == "video" ? "video" : "image";
    final Uri uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/$_cloudName/$resourcePath/upload",
    );

    http.MultipartRequest request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = 'newsfeeds';

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: file.name),
      );
    } else {
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      return body['secure_url'] as String?;
    }
    throw Exception('Cloudinary upload failed: ${response.statusCode}');
  }

  bool _isPosting = false;

  Future<void> _createPost() async {
    final caption = _captionController.text.trim();
    if (caption.isEmpty && _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Write something or add media to post.")),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      final currentUser = authService.value.currentUser;
      String? mediaUrl;
      String? mediaType;

      if (_pickedFile != null && _mediaType != null) {
        mediaUrl = await _uploadToCloudinary(_pickedFile!, _mediaType!);
        mediaType = _mediaType;
      }

      await FirebaseFirestore.instance.collection("posts").add({
        "authorId": currentUser?.uid,
        "authorName": displayname ?? "Anonymous",
        "caption": caption,
        "mediaUrl": mediaUrl,
        "mediaType": mediaType,
        "timestamp": FieldValue.serverTimestamp(),
        "likes": [],
      });

      _captionController.clear();
      _pickedFile = null;
      _previewBytes = null;
      _mediaType = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Post created successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isPosting = false);
    }
  }

  Future<void> _toggleLike(DocumentSnapshot doc) async {
    final currentUser = authService.value.currentUser;
    if (currentUser == null) return;

    final postRef = doc.reference;
    final likes = List<String>.from(doc['likes'] ?? []);

    if (likes.contains(currentUser.uid)) {
      await postRef.update({
        "likes": FieldValue.arrayRemove([currentUser.uid]),
      });
    } else {
      await postRef.update({
        "likes": FieldValue.arrayUnion([currentUser.uid]),
      });

      // 🔔 Create notification for post author
      if (doc['authorId'] != currentUser.uid) {
        await FirebaseFirestore.instance
            .collection("notifications")
            .doc(doc['authorId'])
            .collection("items")
            .add({
              "type": "like",
              "fromUserId": currentUser.uid,
              "fromUserName": currentUser.email ?? "Someone",
              "postId": doc.id,
              "postCaption": doc['caption'],
              "timestamp": FieldValue.serverTimestamp(),
            });
      }
    }
  }

  Future<void> _addComment(String postId, String text) async {
    final currentUser = authService.value.currentUser;
    if (currentUser == null || text.trim().isEmpty) return;

    final postDoc = await FirebaseFirestore.instance
        .collection("posts")
        .doc(postId)
        .get();

    await FirebaseFirestore.instance
        .collection("posts")
        .doc(postId)
        .collection("comments")
        .add({
          "authorId": currentUser.uid,
          "authorName": currentUser.email ?? "Anonymous",
          "text": text.trim(),
          "timestamp": FieldValue.serverTimestamp(),
        });

    // 🔔 Create notification for post author
    if (postDoc.exists && postDoc['authorId'] != currentUser.uid) {
      await FirebaseFirestore.instance
          .collection("notifications")
          .doc(postDoc['authorId'])
          .collection("items")
          .add({
            "type": "comment",
            "fromUserId": currentUser.uid,
            "fromUserName": currentUser.email ?? "Someone",
            "postId": postDoc.id,
            "postCaption": postDoc['caption'],
            "commentText": text.trim(),
            "timestamp": FieldValue.serverTimestamp(),
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Image.asset('assets/LOGO 1.png', height: 140, width: 140),
          // 📝 Post composer
          Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _captionController,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: "What's on your mind?",
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_pickedFile != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _mediaType == "image"
                          ? (kIsWeb && _previewBytes != null
                                ? Image.memory(
                                    _previewBytes!,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(_pickedFile!.path),
                                    height: 150,
                                    fit: BoxFit.cover,
                                  ))
                          : const Icon(
                              Icons.videocam,
                              size: 80,
                              color: Colors.blueGrey,
                            ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _pickMedia(true),
                        icon: const Icon(Icons.image, color: Color(0xFF830A0A)),
                        label: const Text(
                          "Image",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _pickMedia(false),
                        icon: const Icon(
                          Icons.videocam,
                          color: Color(0xFF830A0A),
                        ),
                        label: const Text(
                          "Video",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF830A0A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isPosting ? null : _createPost,
                        child: _isPosting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Post",
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // 📱 Posts feed
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                    final doc = posts[index];
                    final post = doc.data() as Map<String, dynamic>;
                    final currentUser = authService.value.currentUser;
                    final likes = List<String>.from(post["likes"] ?? []);
                    final isLiked =
                        currentUser != null && likes.contains(currentUser.uid);
                    final commentController = _getCommentController(doc.id);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 👤 Author info
                            Row(
                              children: [
                                FutureBuilder<String?>(
                                  future: getUserPhotoUrl(post["authorId"]),
                                  builder: (context, snapshot) {
                                    final url = snapshot.data;
                                    return CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.grey[300],
                                      backgroundImage: url != null
                                          ? NetworkImage(url)
                                          : null,
                                      child: url == null
                                          ? const Icon(
                                              Icons.person,
                                              size: 20,
                                              color: Colors.white,
                                            )
                                          : null,
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  post["authorName"] ?? "Unknown",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if ((post["caption"] ?? "").toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Text(
                                  post["caption"],
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            // 📸 Media
                            if (post["mediaType"] == "image")
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  post["mediaUrl"],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            if (post["mediaType"] == "video")
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: PostVideoPlayer(url: post["mediaUrl"]),
                              ),
                            const SizedBox(height: 8),
                            // ❤️ Like button
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.favorite,
                                    color: isLiked ? Colors.red : Colors.grey,
                                  ),
                                  onPressed: () => _toggleLike(doc),
                                ),
                                Text("${likes.length} likes"),
                              ],
                            ),
                            const Divider(),
                            // 💬 Comments section
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection("posts")
                                  .doc(doc.id)
                                  .collection("comments")
                                  .orderBy("timestamp", descending: false)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox();
                                final comments = snapshot.data!.docs;
                                return Column(
                                  children: comments.map((c) {
                                    final data =
                                        c.data() as Map<String, dynamic>;
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: FutureBuilder<String?>(
                                        future: getUserPhotoUrl(
                                          data["authorId"],
                                        ),
                                        builder: (context, snapshot) {
                                          final url = snapshot.data;
                                          return CircleAvatar(
                                            radius: 14,
                                            backgroundColor: Colors.grey[300],
                                            backgroundImage: url != null
                                                ? NetworkImage(url)
                                                : null,
                                            child: url == null
                                                ? const Icon(
                                                    Icons.person,
                                                    size: 16,
                                                  )
                                                : null,
                                          );
                                        },
                                      ),
                                      title: Text(
                                        data["authorName"] ?? "Anon",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: Text(data["text"] ?? ""),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: commentController,
                                    decoration: const InputDecoration(
                                      hintText: "Write a comment...",
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.send,
                                    color: Color(0xFF830A0A),
                                  ),
                                  onPressed: () async {
                                    await _addComment(
                                      doc.id,
                                      commentController.text,
                                    );
                                    commentController.clear();
                                  },
                                ),
                              ],
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
        ],
      ),
    );
  }
}

class PostVideoPlayer extends StatefulWidget {
  final String url;
  const PostVideoPlayer({super.key, required this.url});

  @override
  State<PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends State<PostVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() => _isInitialized = true);
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(_controller, allowScrubbing: true),
          ),
          IconButton(
            icon: Icon(
              _controller.value.isPlaying
                  ? Icons.pause_circle
                  : Icons.play_circle,
              color: Colors.white,
              size: 48,
            ),
            onPressed: () {
              setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              });
            },
          ),
        ],
      ),
    );
  }
}
