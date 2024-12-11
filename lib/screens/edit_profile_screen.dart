import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const EditProfileScreen({
    super.key,
    required this.userProfile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserService _userService = UserService();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  File? _selectedPhoto;
  bool _deletePhoto = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _displayNameController.text = widget.userProfile['displayName'] ?? '';
    _bioController.text = widget.userProfile['bio'] ?? '';
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image == null) return;
      
      setState(() {
        _selectedPhoto = File(image.path);
        _deletePhoto = false;
      });
    } catch (e) {
      _showErrorSnackBar('이미지 선택 실패');
    }
  }

  Future<void> _updateProfile() async {
    final displayName = _displayNameController.text.trim();
    if (displayName.isEmpty) {
      _showErrorSnackBar('이름을 입력해주세요');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _userService.updateProfile(
        displayName: displayName,
        bio: _bioController.text.trim(),
        photoFile: _selectedPhoto,
        deletePhoto: _deletePhoto,
      );
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필이 수정되었습니다')),
        );
      }
    } catch (e) {
      _showErrorSnackBar('프로필 수정 실패');
    } finally {
      setState(() => _isLoading = false);
    }
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
        title: const Text('프로필 수정'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _updateProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 64,
                          backgroundImage: _selectedPhoto != null
                              ? FileImage(File(_selectedPhoto!.path)) as ImageProvider
                              : widget.userProfile['photoURL'] != null && !_deletePhoto
                                  ? CachedNetworkImageProvider(
                                      widget.userProfile['photoURL'] as String,
                                    )
                                  : null,
                          child: _selectedPhoto == null &&
                                  (widget.userProfile['photoURL'] == null ||
                                      _deletePhoto)
                              ? const Icon(Icons.person, size: 64)
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt),
                              color: Colors.white,
                              onPressed: _pickPhoto,
                            ),
                          ),
                        ),
                        if (widget.userProfile['photoURL'] != null && !_deletePhoto)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: CircleAvatar(
                              backgroundColor: Colors.red,
                              child: IconButton(
                                icon: const Icon(Icons.close),
                                color: Colors.white,
                                onPressed: () {
                                  setState(() {
                                    _selectedPhoto = null;
                                    _deletePhoto = true;
                                  });
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: '이름',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '소개',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 