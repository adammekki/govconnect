import 'package:flutter/material.dart';

class AnnouncementForm extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final String selectedCategory;
  final Function(String) onCategoryChanged;
  
  final List<String> _categories = ['General', 'Update', 'Emergency', 'Event', 'Other'];

  AnnouncementForm({
    Key? key,
    required this.titleController,
    required this.descriptionController,
    required this.selectedCategory,
    required this.onCategoryChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                filled: true,
                fillColor: Color(0xFF131E2F),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Category dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF131E2F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCategory,
                isExpanded: true,
                dropdownColor: const Color(0xFF131E2F),
                style: const TextStyle(color: Colors.white),
                hint: const Text(
                  'Select Category',
                  style: TextStyle(color: Colors.grey),
                ),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    onCategoryChanged(newValue);
                  }
                },
                items: _categories
                    .map<DropdownMenuItem<String>>((String value) {
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
              controller: descriptionController,
              maxLines: 6,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                hintText: 'Write something...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                filled: true,
                fillColor: Color(0xFF131E2F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}