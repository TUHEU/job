import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PostInternshipScreen extends StatefulWidget {
  const PostInternshipScreen({super.key});

  @override
  PostInternshipScreenState createState() => PostInternshipScreenState();
}

class PostInternshipScreenState extends State<PostInternshipScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _fieldController = TextEditingController();
  final _requirementsController = TextEditingController();
  DateTime? _deadline;
  bool _isLoading = false;

  void _postInternship() async {
    if (_deadline == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a deadline')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiService.postInternship(
        _titleController.text,
        _descriptionController.text,
        _locationController.text,
        _fieldController.text,
        _requirementsController.text.split(',').map((e) => e.trim()).toList(),
        _deadline!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Internship posted successfully')),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post internship')),
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _selectDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Internship')),
      body: Container(
        color: const Color(0xFFF7EFE5),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create a new internship',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Fill in the details below so students can discover your opportunity quickly.',
                    style: TextStyle(color: Colors.black54, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  _buildInputField('Title', _titleController),
                  const SizedBox(height: 16),
                  _buildInputField(
                    'Description',
                    _descriptionController,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  _buildInputField('Location', _locationController),
                  const SizedBox(height: 16),
                  _buildInputField(
                    'Field (e.g., Technology, Finance)',
                    _fieldController,
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    'Requirements (comma separated)',
                    _requirementsController,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _deadline == null
                              ? 'No deadline selected'
                              : 'Deadline: ${_deadline!.toLocal().toString().split(' ')[0]}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      TextButton(
                        onPressed: _selectDeadline,
                        child: const Text('Select Deadline'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _postInternship,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text('Post Internship'),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF5F2EE),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
