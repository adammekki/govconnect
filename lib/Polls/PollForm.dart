import 'package:flutter/material.dart';

class PollForm extends StatelessWidget {
  final TextEditingController questionController;
  final List<TextEditingController> optionControllers;
  final VoidCallback onAddOption;
  final Function(int) onRemoveOption;

  const PollForm({
    Key? key,
    required this.questionController,
    required this.optionControllers,
    required this.onAddOption,
    required this.onRemoveOption,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Question field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF131E2F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: questionController,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                hintText: 'Question',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                filled: true,
                fillColor: Color(0xFF131E2F), // Match your container color
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Option fields
          ..._buildOptionFields(),
          
          // Add option button
          if (optionControllers.length < 4)
            GestureDetector(
              onTap: onAddOption,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF131E2F),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Add option',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildOptionFields() {
    return optionControllers.asMap().entries.map((entry) {
      int idx = entry.key;
      var controller = entry.value;
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF131E2F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: 'Option ${idx + 1}',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: const Color(0xFF131E2F), // Match your container color
                  ),
                ),
              ),
            ),
            if (optionControllers.length > 2)
              IconButton(
                icon: const Icon(
                  Icons.remove_circle,
                  color: Colors.red,
                ),
                onPressed: () => onRemoveOption(idx),
              ),
          ],
        ),
      );
    }).toList();
  }
}