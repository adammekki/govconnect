import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class AnnouncementForm extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final String selectedCategory;
  final Function(String) onCategoryChanged;
  final Function(String?)? onImageSelected;

  final List<String> _categories = [
    'General',
    'Update',
    'Emergency',
    'Event',
    'Other',
  ];

  AnnouncementForm({
    Key? key,
    required this.titleController,
    required this.descriptionController,
    required this.selectedCategory,
    required this.onCategoryChanged,
    this.onImageSelected,
  }) : super(key: key);

  @override
  State<AnnouncementForm> createState() => _AnnouncementFormState();
}

class _AnnouncementFormState extends State<AnnouncementForm> {
  File? _imageFile;
  String? _base64Image;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      final base64 = base64Encode(bytes);
      setState(() {
        _imageFile = file;
        _base64Image = base64;
      });
      if (widget.onImageSelected != null) {
        widget.onImageSelected!(base64);
      }
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _base64Image = null;
    });
    if (widget.onImageSelected != null) {
      widget.onImageSelected!(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The form itself
        Padding(
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF131E2F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: widget.titleController,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.blue,
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Color(0xFF131E2F),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Category dropdown
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF131E2F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: widget.selectedCategory,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF131E2F),
                    style: const TextStyle(color: Colors.white),
                    hint: const Text(
                      'Select Category',
                      style: TextStyle(color: Colors.white70),
                    ),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        widget.onCategoryChanged(newValue);
                      }
                    },
                    items:
                        widget._categories.map<DropdownMenuItem<String>>((
                          String value,
                        ) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Description field
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF131E2F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: widget.descriptionController,
                  maxLines: 6,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.blue,
                  decoration: const InputDecoration(
                    hintText: 'Write something...',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Color(0xFF131E2F),
                  ),
                ),
              ),
              // Only show image preview if image is picked
              if (_imageFile != null) ...[
                const SizedBox(height: 12),
                Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: _removeImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        // Floating image upload button (bottom right)
        Positioned(
          bottom: 0,
          right: 0,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: const Color(0xFF131E2F),
            foregroundColor: Colors.white,
            onPressed: _pickImage,
            heroTag: 'pick_announcement_image',
            child: const Icon(Icons.add_a_photo),
            tooltip: 'Add Image',
          ),
        ),
      ],
    );
  }
}
