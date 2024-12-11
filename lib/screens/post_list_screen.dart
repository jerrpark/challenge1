import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../services/like_service.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  final PostService _postService = PostService();
  final UserService _userService = UserService();
  final LikeService _likeService = LikeService();
  final ScrollController _scrollController = ScrollController();
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.95) {
      _loadMorePosts();
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);
    try {
      final snapshot = await _postService.getPostsStream(
        lastDocument: _lastDocument,
      ).first;

      if (snapshot.docs.isEmpty) {
        setState(() => _hasMore = false);
        return;
      }

      setState(() {
        _lastDocument = snapshot.docs.last;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글을 불러오는데 실패했습니다')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _getUserProfile(String uid) async {
    try {
      return await _userService.getCurrentUserProfile();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _postService.getPostsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('게시글을 불러오는데 실패했습니다'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data?.docs ?? [];
          
          if (posts.isEmpty) {
            return const Center(
              child: Text('게시글이 없습니다'),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            itemCount: posts.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == posts.length) {
                return _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : const SizedBox();
              }

              final post = posts[index].data() as Map<String, dynamic>;
              final authorId = post['authorId'] as String;

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getUserProfile(authorId),
                builder: (context, snapshot) {
                  final author = snapshot.data;
                  
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundImage: author?['photoURL'] != null
                                ? CachedNetworkImageProvider(author!['photoURL'])
                                : null,
                            child: author?['photoURL'] == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(author?['displayName'] ?? '사용자'),
                          subtitle: Text(
                            post['createdAt']?.toDate()?.toString() ?? '',
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(post['content'] ?? ''),
                        ),
                        if (post['mediaUrls']?.isNotEmpty ?? false)
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: post['mediaUrls'].length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: CachedNetworkImage(
                                    imageUrl: post['mediaUrls'][index],
                                    height: 200,
                                    width: 200,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              },
                            ),
                          ),
                        ButtonBar(
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.comment),
                              label: Text('${post['comments'] ?? 0}'),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/comments',
                                  arguments: {
                                    'postId': posts[index].id,
                                    'postAuthorId': post['authorId'],
                                  },
                                );
                              },
                            ),
                            TextButton.icon(
                              icon: StreamBuilder<bool>(
                                stream: _likeService.getLikeStatus(posts[index].id),
                                builder: (context, snapshot) {
                                  final isLiked = snapshot.data ?? false;
                                  return Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: isLiked ? Colors.red : null,
                                  );
                                },
                              ),
                              label: Text('${post['likes'] ?? 0}'),
                              onPressed: () async {
                                try {
                                  await _likeService.toggleLike(posts[index].id);
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('좋아요 처리에 실패했습니다'),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/create_post'),
        child: const Icon(Icons.add),
      ),
    );
  }
} 