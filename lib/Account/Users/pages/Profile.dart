import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore
import 'package:projectrespawn/Account/Users/pages/profile_update_page.dart';
import 'package:projectrespawn/auth/auth_service.dart';
import 'package:video_player/video_player.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? displayname;
  User? _currentUser = authService.value.currentUser;
  int _postCount = 0;
  int _followersCount = 0;
  int _followingCount = 0;
  String? bio;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _fetchUserData() async {
    if (_currentUser == null) return;

    try {
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: _currentUser!.uid)
          .get();

      final uid = authService.value.currentUser?.uid;

      if (uid != null) {
        final name = await getUserDisplayname(uid);
        final bioDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .get();
        final a = await getUserPhotoUrl(uid);

        if (!mounted) return; // ✅ Prevent setState after dispose

        setState(() {
          _postCount = postsSnapshot.docs.length;
          displayname = name;
          _photoUrl = a;
        });
        setState(() {
          if (bioDoc.exists) {
            bio = bioDoc["bio"];
          } else {
            bio = "No bio available";
          }
        });
      }
    } catch (e) {
      if (!mounted) return; // ✅ Safe guard
      debugPrint("Error fetching user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(pinned: true, floating: false),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: _photoUrl != null
                              ? NetworkImage(_photoUrl!)
                              : null,
                          child: _photoUrl == null
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        _buildStatsColumn("Posts", _postCount.toString()),
                        _buildStatsColumn(
                          "Followers",
                          _followersCount.toString(),
                        ),
                        _buildStatsColumn(
                          "Following",
                          _followingCount.toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayname ?? "Unknown",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(bio ?? "No bio available"),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF830A0A),
                            ),
                            onPressed: () {
                              Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ProfileUpdatePage(),
                                    ),
                                  )
                                  .then((_) {
                                    if (mounted) {
                                      setState(() {
                                        _currentUser =
                                            FirebaseAuth.instance.currentUser;
                                      });
                                      _fetchUserData();
                                    }
                                  });
                            },
                            child: const Text(
                              "Edit Profile",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  indicatorColor: const Color(0xFF830A0A),
                  controller: _tabController,
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on, color: Color(0xFF830A0A))),
                    Tab(
                      icon: Icon(
                        Icons.person_pin_outlined,
                        color: Color(0xFF830A0A),
                      ),
                    ),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('authorId', isEqualTo: _currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No posts yet!'));
                }

                final posts = snapshot.data!.docs;
                return GridView.builder(
                  padding: const EdgeInsets.all(2),
                  itemCount: posts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemBuilder: (context, index) {
                    final post = posts[index].data() as Map<String, dynamic>;
                    final mediaUrl = post['mediaUrl'] as String?;
                    final mediaType = post['mediaType'] as String?;

                    if (mediaType == 'image' && mediaUrl != null) {
                      return GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Tapped on post: ${post['caption'] ?? 'No Caption'}',
                              ),
                            ),
                          );
                        },
                        child: Image.network(
                          mediaUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.error_outline,
                                color: Colors.red,
                              ),
                            );
                          },
                        ),
                      );
                    } else if (mediaType == 'video' && mediaUrl != null) {
                      return PostVideoPlayer(url: mediaUrl);
                    }
                    return Container(
                      color: Colors.blueGrey[100],
                      child: const Center(child: Icon(Icons.image)),
                    );
                  },
                );
              },
            ),
            const Center(child: Text("Tagged Posts (Coming Soon)")),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsColumn(String title, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(title),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
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
        if (!mounted) return; // ✅ Prevent setState after dispose
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
