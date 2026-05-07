import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  PostJobScreenState createState() => PostJobScreenState();
}

class PostJobScreenState extends State<PostJobScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  bool _isLoading = false;

  Future<void> _postJob() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _requirementsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final requirements = _requirementsController.text
          .split(',')
          .map((req) => req.trim())
          .where((req) => req.isNotEmpty)
          .toList();

      final result = await ApiService.postJob(
        _titleController.text,
        _descriptionController.text,
        requirements,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Job posted successfully')),
      );

      if (result['id'] != null) {
        _titleController.clear();
        _descriptionController.clear();
        _requirementsController.clear();
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to post job')));
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a Job')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Job Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Job Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _requirementsController,
              decoration: const InputDecoration(
                labelText: 'Requirements (comma separated)',
                border: OutlineInputBorder(),
                hintText: 'e.g., Flutter, Dart, Firebase',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _postJob,
                    child: const Text('Post Job'),
                  ),
          ],
        ),
      ),
    );
  }
}
