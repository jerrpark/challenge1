import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cross_file/cross_file.dart';
import '../services/post_service.dart';

class EditPostScreen extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> post;

  const EditPostScreen({
    super.key,
    required this.postId,
    required this.post,
  });

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final PostService _postService = PostService();
  final _contentController = TextEditingController();
  final List<String> _existingMediaUrls = [];
  final List<XFile> _newMediaFiles = [];
  final List<String> _deleteMediaUrls = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _contentController.text = widget.post['content'] ?? '';
    _existingMediaUrls.addAll(
      List<String>.from(widget.post['mediaUrls'] ?? []),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image == null) return;
      
      setState(() {
        _newMediaFiles.add(image);
      });
    } catch (e) {
      _showErrorSnackBar('이미지 선택 실패');
    }
  }

  Future<void> _updatePost() async {
    if (_contentController.text.trim().isEmpty) {
      _showErrorSnackBar('내용을 입력해주세요');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _postService.updatePost(
        widget.postId,
        _contentController.text.trim(),
        deleteMediaUrls: _deleteMediaUrls.isNotEmpty ? _deleteMediaUrls : null,
        newMediaFiles: _newMediaFiles.isNotEmpty ? _newMediaFiles : null,
      );
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시글이 수정되었습니다')),
        );
      }
    } catch (e) {
      _showErrorSnackBar('게시글 수정 실패');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removeExistingMedia(int index) {
    setState(() {
      _deleteMediaUrls.add(_existingMediaUrls[index]);
      _existingMediaUrls.removeAt(index);
    });
  }

  void _removeNewMedia(int index) {
    setState(() {
      _newMediaFiles.removeAt(index);
    });
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 수정'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _updatePost,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _contentController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: '내용을 입력하세요',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_existingMediaUrls.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '기존 이미지',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _existingMediaUrls.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Image.network(
                                      _existingMediaUrls[index],
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => _removeExistingMedia(index),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  if (_newMediaFiles.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '새 이미지',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _newMediaFiles.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Image.file(
                                      File(_newMediaFiles[index].path),
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => _removeNewMedia(index),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _existingMediaUrls.length + _newMediaFiles.length >= 5
                        ? null
                        : _pickMedia,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('이미지 추가'),
                  ),
                ],
              ),
            ),
    );
  }
} 