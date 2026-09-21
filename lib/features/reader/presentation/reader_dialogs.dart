import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class JumpToPageDialog extends StatelessWidget {
  const JumpToPageDialog({
    super.key,
    required this.controller,
    required this.totalPages,
  });

  final TextEditingController controller;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Go to page'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          hintText: '1 – $totalPages',
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(context),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: () => _submit(context), child: const Text('Go')),
      ],
    );
  }

  void _submit(BuildContext context) {
    final value = int.tryParse(controller.text);
    if (value != null && value >= 1 && value <= totalPages) {
      Navigator.pop(context, value);
    }
  }
}

class BookmarkLabelDialog extends StatefulWidget {
  const BookmarkLabelDialog({super.key, required this.defaultLabel});

  final String defaultLabel;

  @override
  State<BookmarkLabelDialog> createState() => _BookmarkLabelDialogState();
}

class _BookmarkLabelDialogState extends State<BookmarkLabelDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add bookmark'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: widget.defaultLabel,
          helperText: 'Leave blank to use default name',
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => Navigator.pop(context, _controller.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
