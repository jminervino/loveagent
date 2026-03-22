import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class TagInputField extends StatefulWidget {
  const TagInputField({
    super.key,
    required this.tags,
    required this.onChanged,
    this.hintText = 'Adicionar...',
  });

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final String hintText;

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  void _addTag(String text) {
    final tag = text.trim();
    if (tag.isEmpty || widget.tags.contains(tag)) return;

    final updated = [...widget.tags, tag];
    widget.onChanged(updated);
    _controller.clear();
  }

  void _removeTag(String tag) {
    final updated = widget.tags.where((t) => t != tag).toList();
    widget.onChanged(updated);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: widget.tags.map((tag) {
              return Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeTag(tag),
                backgroundColor: AppColors.primary.withOpacity(0.08),
                side: BorderSide.none,
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: widget.hintText,
            isDense: true,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _addTag(_controller.text),
            ),
          ),
          onSubmitted: _addTag,
        ),
      ],
    );
  }
}
