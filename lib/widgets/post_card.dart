import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/comment_service.dart';
import '../services/auth_service.dart';
import '../models/comment.dart';
import '../services/post_service.dart';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final TextEditingController _commentController = TextEditingController();
  final CommentService _commentService = CommentService();
  final AuthService _authService = AuthService();
  final PostService _postService = PostService();
  bool _isCommentSectionVisible = false;

  // 게시물 삭제 다이얼로그
  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('게시물 삭제'),
        content: Text('이 게시물을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _postService.deletePost(widget.post.id);
                Navigator.pop(context); // 다이얼로그 닫기
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('게시물이 삭제되었습니다')),
                );
              } catch (e) {
                Navigator.pop(context); // 다이얼로그 닫기
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('게시물 삭제 실패: $e')),
                );
              }
            },
            child: Text('삭제'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // 게시물 헤더
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // 프로필 이미지와 사용자 이름
                CircleAvatar(
                  backgroundImage: widget.post.userProfileImage != null
                      ? NetworkImage(widget.post.userProfileImage!)
                      : null,
                  child: widget.post.userProfileImage == null
                      ? Icon(Icons.person)
                      : null,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.post.userName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                // 더보기 메뉴 (작성자인 경우에만 표시)
                if (widget.post.userId == _authService.currentUser?.uid)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteDialog();
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('삭제', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // 게시물 이미지
          if (widget.post.imageUrl.isNotEmpty)
            Image.network(
              widget.post.imageUrl,
              fit: BoxFit.cover,
            ),
          // 댓글 섹션
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.comment_outlined),
                onPressed: () {
                  setState(() {
                    _isCommentSectionVisible = !_isCommentSectionVisible;
                  });
                },
              ),
              StreamBuilder<List<Comment>>(
                stream: _commentService.getComments(widget.post.id),
                builder: (context, snapshot) {
                  final commentCount = snapshot.data?.length ?? 0;
                  return Text('$commentCount');
                },
              ),
            ],
          ),

          if (_isCommentSectionVisible) _buildCommentSection(),
        ],
      ),
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: '댓글을 입력하세요...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: () async {
                  if (_commentController.text.trim().isNotEmpty) {
                    await _commentService.createComment(
                      widget.post.id,
                      _commentController.text.trim(),
                      _authService.currentUser!.uid,
                    );
                    _commentController.clear();
                  }
                },
              ),
            ],
          ),
        ),

        StreamBuilder<List<Comment>>(
          stream: _commentService.getComments(widget.post.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('오류가 발생했습니다'),
              );
            }
            
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final comments = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                return ListTile(
                  title: Text(comment.content),
                  subtitle: Text(
                    DateFormat('yyyy-MM-dd HH:mm').format(comment.createdAt),
                  ),
                  trailing: comment.userId == _authService.currentUser?.uid
                      ? PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              _showEditCommentDialog(comment);
                            } else if (value == 'delete') {
                              _showDeleteCommentDialog(comment);
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('수정'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20),
                                  SizedBox(width: 8),
                                  Text('삭제'),
                                ],
                              ),
                            ),
                          ],
                        )
                      : null,
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showEditCommentDialog(Comment comment) {
    final TextEditingController editController = TextEditingController(text: comment.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('댓글 수정'),
        content: TextField(
          controller: editController,
          decoration: InputDecoration(
            hintText: '수정할 내용을 입력하세요',
          ),
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              if (editController.text.trim().isNotEmpty) {
                await _commentService.updateComment(
                  postId: widget.post.id,
                  commentId: comment.id,
                  content: editController.text.trim(),
                );
                Navigator.pop(context);
              }
            },
            child: Text('수정'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCommentDialog(Comment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('댓글 삭제'),
        content: Text('이 댓글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              await _commentService.deleteComment(
                postId: widget.post.id,
                commentId: comment.id,
              );
              Navigator.pop(context);
            },
            child: Text('삭제'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
} 