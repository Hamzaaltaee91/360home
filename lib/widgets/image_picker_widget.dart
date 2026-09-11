import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// A reusable multi-image picker with thumbnail previews.
///
/// Wraps [ImagePicker] to allow selecting multiple images from the gallery
/// or camera, previewing them, and removing individual selections. The
/// current selection is reported through [onImagesChanged].
class ImagePickerWidget extends StatefulWidget {
  const ImagePickerWidget({
    super.key,
    this.maxImages = 5,
    this.onImagesChanged,
    this.initialImages = const [],
    this.enabled = true,
  });

  /// Maximum number of images that can be selected.
  final int maxImages;

  /// Called whenever the selection changes with the current list of images.
  final ValueChanged<List<XFile>>? onImagesChanged;

  /// Optional initial selection.
  final List<XFile> initialImages;

  /// Whether the widget is enabled.
  final bool enabled;

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImagePicker _picker = ImagePicker();
  late List<XFile> _images;

  @override
  void initState() {
    super.initState();
    _images = List<XFile>.from(widget.initialImages);
  }

  bool get _canAddMore => _images.length < widget.maxImages;

  Future<void> _pickImages(ImageSource source) async {
    if (!_canAddMore) return;

    try {
      if (source == ImageSource.gallery) {
        final picked = await _picker.pickMultiImage();
        if (picked.isEmpty) return;
        final remaining = widget.maxImages - _images.length;
        _updateImages([..._images, ...picked.take(remaining)]);
      } else {
        final picked = await _picker.pickImage(source: source);
        if (picked == null) return;
        _updateImages([..._images, picked]);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _updateImages(List<XFile> images) {
    setState(() => _images = images);
    widget.onImagesChanged?.call(List<XFile>.unmodifiable(_images));
  }

  void _removeImage(int index) {
    final updated = List<XFile>.from(_images)..removeAt(index);
    _updateImages(updated);
  }

  void _showSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImages(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImages(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _images.length; i++)
              _ImageThumbnail(
                file: _images[i],
                onRemove: widget.enabled ? () => _removeImage(i) : null,
              ),
            if (_canAddMore)
              _AddImageButton(
                enabled: widget.enabled,
                onTap: _showSourceSheet,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${_images.length}/${widget.maxImages} images',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({required this.file, this.onRemove});

  final XFile file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FutureBuilder<Uint8List>(
            future: file.readAsBytes(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container(
                  width: 80,
                  height: 80,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              return Image.memory(
                snapshot.data!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              );
            },
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: -8,
            right: -8,
            child: IconButton(
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.cancel),
              color: Theme.of(context).colorScheme.error,
              onPressed: onRemove,
            ),
          ),
      ],
    );
  }
}

class _AddImageButton extends StatelessWidget {
  const _AddImageButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Icon(
          Icons.add_a_photo,
          color: enabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).disabledColor,
        ),
      ),
    );
  }
}
