import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cross_file/cross_file.dart';
import '../services/post_service.dart';
import '../screens/main_screen.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  File? _image;
  bool _isLoading = false;
  final PostService _postService = PostService();

  Future<void> _getImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _image = File(image.path);
        });
      }
    } catch (e) {
      print('이미지 선택 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지를 선택하는 중 오류가 발생했습니다')),
        );
      }
    }
  }

  Future<void> _uploadPost() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지를 선택해주세요')),
      );
      return;
    }

    if (_captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _postService.createPost(
        imageFile: _image!,
        caption: _captionController.text.trim(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시물이 업로드되었습니다')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('게시물 업로드 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시물 업로드에 실패했습니다')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 게시물'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _uploadPost,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  )
                : const Text('공유'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: GestureDetector(
                onTap: _isLoading ? null : _getImage,
                child: Container(
                  color: Colors.grey[200],
                  child: _image != null
                      ? Image.file(_image!, fit: BoxFit.cover)
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate,
                                  size: 60, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('사진을 선택하세요',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _captionController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  hintText: '문구 입력...',
                  border: InputBorder.none,
                ),
                maxLines: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 