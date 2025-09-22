import 'package:flutter/material.dart';

class Newsfeeds extends StatefulWidget {
  const Newsfeeds({super.key});

  @override
  State<Newsfeeds> createState() => _NewsfeedsState();
}

class _NewsfeedsState extends State<Newsfeeds> {
  final List<_Post> _posts = <_Post>[
    _Post(
      authorName: 'Alex Johnson',
      authorHandle: '@alexj',
      timeAgo: '2h',
      content:
          'Exploring Flutter layouts today. Loving how flexible widgets are! 🚀',
      imageAsset: null,
      likeCount: 12,
      commentCount: 3,
      shareCount: 1,
    ),
    _Post(
      authorName: 'Taylor Lee',
      authorHandle: '@taylor',
      timeAgo: '5h',
      content: 'New coffee spot downtown. Highly recommend the cold brew.',
      imageAsset: 'assets/image 2.png',
      likeCount: 45,
      commentCount: 10,
      shareCount: 4,
    ),
    _Post(
      authorName: 'Morgan Yu',
      authorHandle: '@morgan',
      timeAgo: '1d',
      content:
          'Weekend hackathon wrap-up: built a small note app with offline sync.',
      imageAsset: 'assets/Login.png',
      likeCount: 88,
      commentCount: 14,
      shareCount: 6,
    ),
  ];

  bool _isRefreshing = false;

  Future<void> _onRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    setState(() {
      // Pretend we fetched updates by shuffling a bit
      _posts.shuffle();
      _isRefreshing = false;
    });
  }

  void _toggleLike(int index) {
    setState(() {
      final _Post post = _posts[index];
      if (post.isLiked) {
        post.isLiked = false;
        if (post.likeCount > 0) post.likeCount -= 1;
      } else {
        post.isLiked = true;
        post.likeCount += 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Newsfeeds'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(child: _Composer(onPost: _handleCreatePost)),
            SliverList(
              delegate: SliverChildBuilderDelegate((
                BuildContext context,
                int index,
              ) {
                final _Post post = _posts[index];
                return _PostCard(
                  post: post,
                  onLike: () => _toggleLike(index),
                  onComment: () {},
                  onShare: () {},
                );
              }, childCount: _posts.length),
            ),
            if (_isRefreshing)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24.0)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleCreatePost('What\'s on your mind?'),
        icon: const Icon(Icons.edit),
        label: const Text('Post'),
      ),
    );
  }

  void _handleCreatePost(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _posts.insert(
        0,
        _Post(
          authorName: 'You',
          authorHandle: '@you',
          timeAgo: 'now',
          content: text.trim(),
          imageAsset: null,
          likeCount: 0,
          commentCount: 0,
          shareCount: 0,
        ),
      );
    });
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.onPost});

  final void Function(String text) onPost;

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const CircleAvatar(child: Icon(Icons.person)),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "What's happening?",
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 12.0,
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      onPost(controller.text);
                    },
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Post'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  final _Post post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: <Widget>[
                  const CircleAvatar(child: Icon(Icons.person)),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          post.authorName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${post.authorHandle} · ${post.timeAgo}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            if (post.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(post.content),
              ),
            if (post.imageAsset != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset(
                    post.imageAsset!,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (
                          BuildContext context,
                          Object error,
                          StackTrace? stackTrace,
                        ) {
                          return Container(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image),
                          );
                        },
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: Row(
                children: <Widget>[
                  _Counter(
                    icon: Icons.favorite,
                    count: post.likeCount,
                    isActive: post.isLiked,
                  ),
                  const SizedBox(width: 12.0),
                  _Counter(
                    icon: Icons.mode_comment_outlined,
                    count: post.commentCount,
                  ),
                  const SizedBox(width: 12.0),
                  _Counter(icon: Icons.share_outlined, count: post.shareCount),
                ],
              ),
            ),
            const Divider(height: 1),
            Row(
              children: <Widget>[
                _ActionButton(
                  icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                  label: 'Like',
                  isActive: post.isLiked,
                  onPressed: onLike,
                ),
                _ActionButton(
                  icon: Icons.mode_comment_outlined,
                  label: 'Comment',
                  onPressed: onComment,
                ),
                _ActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onPressed: onShare,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final Color foreground = isActive
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87;
    return Expanded(
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: foreground),
        label: Text(label, style: TextStyle(color: foreground)),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.icon,
    required this.count,
    this.isActive = false,
  });

  final IconData icon;
  final int count;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final Color color = isActive
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).textTheme.bodySmall?.color ?? Colors.black54;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4.0),
        Text('$count', style: TextStyle(color: color)),
      ],
    );
  }
}

class _Post {
  _Post({
    required this.authorName,
    required this.authorHandle,
    required this.timeAgo,
    required this.content,
    required this.imageAsset,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
  });

  final String authorName;
  final String authorHandle;
  final String timeAgo;
  final String content;
  final String? imageAsset;
  int likeCount;
  final int commentCount;
  final int shareCount;
  bool isLiked = false;
}
