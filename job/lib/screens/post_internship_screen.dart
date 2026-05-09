// lib/screens/post_internship_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class PostInternshipScreen extends StatefulWidget {
  const PostInternshipScreen({super.key});
  @override
  State<PostInternshipScreen> createState() => _PostInternshipScreenState();
}

class _PostInternshipScreenState extends State<PostInternshipScreen> {
  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _fieldCtrl    = TextEditingController();
  final _reqCtrl      = TextEditingController();

  DateTime? _deadline;
  bool _loading = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.green,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _post() async {
    if (_titleCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      _snack('Title and description are required.', error: true);
      return;
    }
    if (_deadline == null) {
      _snack('Please select an application deadline.', error: true);
      return;
    }
    setState(() => _loading = true);
    final reqs = _reqCtrl.text
        .split(',').map((e) => e.trim())
        .where((e) => e.isNotEmpty).toList();

    final res = await ApiService.postInternship(
      _titleCtrl.text.trim(),
      _descCtrl.text.trim(),
      _locationCtrl.text.trim(),
      _fieldCtrl.text.trim(),
      reqs,
      _deadline!,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (res.containsKey('error')) {
      _snack(res['error'] as String, error: true);
    } else {
      _snack(res['message'] as String? ?? 'Internship posted!');
      Navigator.pop(context);
    }
  }

  void _snack(String msg, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : AppColors.green,
      ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Post Internship')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GradientBanner(
            title: 'Create a New Internship',
            subtitle: 'Fill in the details so students can discover your opportunity.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                  blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GoTextField(label: 'Job Title', controller: _titleCtrl,
                    prefixIcon: Icons.work_outline),
                const SizedBox(height: 14),
                GoTextField(label: 'Description', controller: _descCtrl,
                    maxLines: 4),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: GoTextField(
                    label: 'Location', controller: _locationCtrl,
                    prefixIcon: Icons.location_on_outlined,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: GoTextField(
                    label: 'Field', controller: _fieldCtrl,
                    prefixIcon: Icons.category_outlined,
                  )),
                ]),
                const SizedBox(height: 14),
                GoTextField(
                  label: 'Requirements (comma separated)',
                  controller: _reqCtrl,
                  hint: 'Python, Excel, Communication…',
                  prefixIcon: Icons.checklist_outlined,
                ),
                const SizedBox(height: 14),

                // ── Deadline picker ───────────────────────────────────
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(14),
                      border: _deadline != null
                          ? Border.all(color: AppColors.green, width: 1.5)
                          : null,
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AppColors.textGrey, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                        _deadline == null
                            ? 'Select Application Deadline'
                            : 'Deadline: ${_deadline!.toLocal().toString().split(' ')[0]}',
                        style: TextStyle(
                          color: _deadline == null
                              ? AppColors.textGrey : AppColors.textDark,
                          fontSize: 14,
                        ),
                      )),
                      Icon(Icons.arrow_drop_down,
                          color: _deadline != null
                              ? AppColors.green : AppColors.textGrey),
                    ]),
                  ),
                ),
                const SizedBox(height: 22),
                _loading
                    ? const LoadingOverlay()
                    : ElevatedButton.icon(
                        onPressed: _post,
                        icon: const Icon(Icons.publish_outlined),
                        label: const Text('Post Internship'),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
