import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/job.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  JobListScreenState createState() => JobListScreenState();
}

class JobListScreenState extends State<JobListScreen> {
  List<Job> _jobs = [];
  List<Job> _filteredJobs = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  void _loadJobs() async {
    final jobs = await ApiService.getJobs();
    setState(() {
      _jobs = jobs;
      _filteredJobs = jobs;
      _isLoading = false;
    });
  }

  void _filterJobs(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredJobs = _jobs;
      } else {
        _filteredJobs = _jobs
            .where(
              (job) =>
                  job.title.toLowerCase().contains(query.toLowerCase()) ||
                  job.description.toLowerCase().contains(query.toLowerCase()) ||
                  job.requirements.any(
                    (req) => req.toLowerCase().contains(query.toLowerCase()),
                  ),
            )
            .toList();
      }
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
      appBar: AppBar(
        title: const Text('Jobs'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search jobs...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: _filterJobs,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredJobs.isEmpty
          ? Center(
              child: Text(
                _searchQuery.isEmpty
                    ? 'No jobs available'
                    : 'No jobs match your search',
                style: const TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: _filteredJobs.length,
              itemBuilder: (context, index) {
                final job = _filteredJobs[index];
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
                        Text(
                          job.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
