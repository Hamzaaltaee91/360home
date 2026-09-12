import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../utils/error_handler.dart';
import '../../utils/validators.dart';

/// Allows the signed-in user to edit their profile details and avatar.
///
/// Pops with the updated [User] on success, or `null` if the user cancels.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  late Future<AppUser> _userFuture;
  AppUser? _user;

  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _userFuture = _loadUser();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<AppUser> _loadUser() async {
    final user = await SupabaseService().getCurrentUser();
    _user = user;
    _fullNameController.text = user.fullName;
    _phoneController.text = user.phone ?? '';
    _bioController.text = user.bio ?? '';
    return user;
  }

  void _reload() {
    setState(() {
      _userFuture = _loadUser();
    });
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedImageBytes = bytes;
        _pickedImageName = picked.name;
      });
    } catch (error) {
      if (!mounted) return;
      _showError(SupabaseErrorHandler.handle(error).message);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = _user;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      String? profilePictureUrl = user.profilePictureUrl;

      if (_pickedImageBytes != null && _pickedImageName != null) {
        profilePictureUrl = await SupabaseService().uploadProfilePicture(
          userId: user.id,
          fileName: _pickedImageName!,
          fileBytes: _pickedImageBytes!,
        );
      }

      final phone = _phoneController.text.trim();
      final bio = _bioController.text.trim();

      await SupabaseService().updateUserProfile(
        fullName: _fullNameController.text.trim(),
        phone: phone.isEmpty ? null : phone,
        bio: bio.isEmpty ? null : bio,
        profilePictureUrl: profilePictureUrl,
      );

      final updated = await SupabaseService().getCurrentUser();
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (error) {
      if (!mounted) return;
      _showError(SupabaseErrorHandler.handle(error).message);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل الملف الشخصي')),
      body: FutureBuilder<AppUser>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            final message = error is AppException
                ? error.message
                : 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى';
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _reload,
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('لا توجد بيانات'));
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _AvatarPicker(
                  imageBytes: _pickedImageBytes,
                  imageUrl: user.profilePictureUrl,
                  initials: _initials(user.fullName),
                  onTap: _isSaving ? null : _pickImage,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _fullNameController,
                  enabled: !_isSaving,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) =>
                      Validators.required(value, field: 'الاسم الكامل'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    return Validators.phone(value);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  enabled: !_isSaving,
                  maxLines: 4,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    labelText: 'نبذة',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'جارٍ الحفظ...' : 'حفظ التغييرات'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0];
    return '${parts.first[0]}${parts.last[0]}';
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.imageBytes,
    required this.imageUrl,
    required this.initials,
    required this.onTap,
  });

  final Uint8List? imageBytes;
  final String? imageUrl;
  final String initials;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ImageProvider? imageProvider;
    if (imageBytes != null) {
      imageProvider = MemoryImage(imageBytes!);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(imageUrl!);
    }

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Text(initials, style: theme.textTheme.headlineMedium)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Material(
              color: theme.colorScheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    size: 18,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
