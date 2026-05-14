// lib/screens/post_internship_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/internship_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class PostInternshipScreen extends StatefulWidget {
  const PostInternshipScreen({super.key});

  @override
  State<PostInternshipScreen> createState() => _PostInternshipScreenState();
}

class _PostInternshipScreenState extends State<PostInternshipScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _fieldCtrl = TextEditingController();
  final _reqCtrl = TextEditingController();

  DateTime? _deadline;
  bool _posting = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _post() async {
    if (_titleCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      _showSnackbar('Title and description are required.', error: true);
      return;
    }
    if (_deadline == null) {
      _showSnackbar('Please select a deadline.', error: true);
      return;
    }

    setState(() => _posting = true);
    final reqs = _reqCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final provider = Provider.of<InternshipProvider>(context, listen: false);
    final success = await provider.postInternship({
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'location': _locationCtrl.text.trim(),
      'field': _fieldCtrl.text.trim(),
      'requirements': reqs,
      'deadline': _deadline!,
    });

    if (mounted) {
      setState(() => _posting = false);
      if (success) {
        _showSnackbar('Internship posted successfully!');
        Navigator.pop(context);
      } else {
        _showSnackbar(provider.error ?? 'Failed to post', error: true);
      }
    }
  }

  void _showSnackbar(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : AppColors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Post Internship')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const GradientBanner(
            title: 'Create a New Internship',
            subtitle:
                'Fill in the details so students can discover your opportunity.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              children: [
                GoTextField(
                  label: 'Job Title',
                  controller: _titleCtrl,
                  prefixIcon: Icons.work_outline,
                ),
                const SizedBox(height: 14),
                GoTextField(
                  label: 'Description',
                  controller: _descCtrl,
                  maxLines: 4,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GoTextField(
                        label: 'Location',
                        controller: _locationCtrl,
                        prefixIcon: Icons.location_on_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GoTextField(
                        label: 'Field',
                        controller: _fieldCtrl,
                        prefixIcon: Icons.category_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GoTextField(
                  label: 'Requirements (comma separated)',
                  controller: _reqCtrl,
                  hint: 'Python, Excel, Communication…',
                  prefixIcon: Icons.checklist_outlined,
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(14),
                      border: _deadline != null
                          ? Border.all(color: AppColors.green, width: 1.5)
                          : null,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.textGrey,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _deadline == null
                                ? 'Select Application Deadline'
                                : 'Deadline: ${_deadline!.toLocal().toString().split(' ')[0]}',
                            style: TextStyle(
                              color: _deadline == null
                                  ? AppColors.textGrey
                                  : AppColors.textDark,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: _deadline != null
                              ? AppColors.green
                              : AppColors.textGrey,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _posting
                    ? const LoadingOverlay()
                    : ElevatedButton.icon(
                        onPressed: _post,
                        icon: const Icon(Icons.publish_outlined),
                        label: const Text('Post Internship'),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
