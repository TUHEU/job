import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/job.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  MatchesScreenState createState() => MatchesScreenState();
}

class MatchesScreenState extends State<MatchesScreen> {
  List<Job> _matches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  void _loadMatches() async {
    final matches = await ApiService.getMatches();
    setState(() {
      _matches = matches;
      _isLoading = false;
    });
  }

  void _apply(String jobId) async {
    final result = await ApiService.applyForJob(jobId);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result['message'])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Matches')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _matches.isEmpty
          ? const Center(
              child: Text(
                'No matches found. Update your skills to get better matches!',
              ),
            )
          : ListView.builder(
              itemCount: _matches.length,
              itemBuilder: (context, index) {
                final job = _matches[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.thumb_up, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              job.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(job.description),
                        const SizedBox(height: 8),
                        Text(
                          'Requirements: ${job.requirements.join(', ')}',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () => _apply(job.id),
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
