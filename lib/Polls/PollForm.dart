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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create a Poll',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // Question field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF131E2F),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: questionController,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.blue,
              decoration: const InputDecoration(
                hintText: 'Enter your question',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                filled: true,
                fillColor: Color(0xFF131E2F),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          const Text(
            'Options',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Option fields
          ..._buildOptionFields(),
          
          // Add option button
          if (optionControllers.length < 4)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: GestureDetector(
                onTap: onAddOption,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue, width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_circle_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Add Option',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF131E2F),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.blue,
                  decoration: InputDecoration(
                    hintText: 'Option ${idx + 1}',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: const Color(0xFF131E2F),
                  ),
                ),
              ),
            ),
            if (optionControllers.length > 2)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                    size: 24,
                  ),
                  onPressed: () => onRemoveOption(idx),
                ),
              ),
          ],
        ),
      );
    }).toList();
  }
}