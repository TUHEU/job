import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/internship.dart';

class InternshipListScreen extends StatefulWidget {
  const InternshipListScreen({super.key});

  @override
  InternshipListScreenState createState() => InternshipListScreenState();
}

class InternshipListScreenState extends State<InternshipListScreen> {
  List<Internship> _internships = [];
  List<Internship> _filteredInternships = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _locationFilter = '';
  String _fieldFilter = '';

  @override
  void initState() {
    super.initState();
    _loadInternships();
  }

  void _loadInternships() async {
    final internships = await ApiService.getInternships();
    setState(() {
      _internships = internships;
      _filteredInternships = internships;
      _isLoading = false;
    });
  }

  void _filterInternships() {
    setState(() {
      _filteredInternships = _internships.where((internship) {
        final matchesSearch =
            _searchQuery.isEmpty ||
            internship.title.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            internship.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            internship.requirements.any(
              (req) => req.toLowerCase().contains(_searchQuery.toLowerCase()),
            );
        final matchesLocation =
            _locationFilter.isEmpty ||
            internship.location.toLowerCase().contains(
              _locationFilter.toLowerCase(),
            );
        final matchesField =
            _fieldFilter.isEmpty ||
            internship.field.toLowerCase().contains(_fieldFilter.toLowerCase());
        return matchesSearch && matchesLocation && matchesField;
      }).toList();
    });
  }

  void _apply(String internshipId) async {
    final result = await ApiService.applyForInternship(internshipId);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result['message'])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Internships')),
      body: Container(
        color: const Color(0xFFF7EFE5),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF14563A), Color(0xFF7B1023)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 18,
                      offset: Offset.zero,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Find your next internship',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Browse active internships from local employers. Filter by field, location, and keyword to find opportunities that suit your goals.',
                      style: TextStyle(color: Colors.white70, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSearchField(
                        context,
                        hintText: 'Search internships...',
                        icon: Icons.search,
                        onChanged: (value) {
                          _searchQuery = value;
                          _filterInternships();
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSearchField(
                              context,
                              hintText: 'Location',
                              icon: Icons.location_on,
                              onChanged: (value) {
                                _locationFilter = value;
                                _filterInternships();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildSearchField(
                              context,
                              hintText: 'Field',
                              icon: Icons.business,
                              onChanged: (value) {
                                _fieldFilter = value;
                                _filterInternships();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredInternships.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 28,
                      ),
                      child: Text(
                        'No internships match your criteria. Try changing the filters or keyword search.',
                        style: TextStyle(fontSize: 16, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: _filteredInternships.length,
                      itemBuilder: (context, index) {
                        final internship = _filteredInternships[index];
                        final daysLeft = internship.deadline
                            .difference(DateTime.now())
                            .inDays;
                        return _buildInternshipCard(internship, daysLeft);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(
    BuildContext context, {
    required String hintText,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF5F2EE),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildInternshipCard(Internship internship, int daysLeft) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      internship.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14563A).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${daysLeft >= 0 ? '$daysLeft days' : 'Closed'}',
                      style: TextStyle(
                        color: daysLeft >= 0
                            ? Colors.green[700]
                            : Colors.red[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                internship.companyName,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Text(
                internship.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _buildInfoChip(internship.location, const Color(0xFFE9F6F0)),
                  _buildInfoChip(internship.field, const Color(0xFFF5E7E9)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Requirements: ${internship.requirements.join(', ')}',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _apply(internship.id),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Chip(label: Text(label), backgroundColor: color);
  }
}
