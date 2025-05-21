import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/problem_report_provider.dart';
import 'problem_detail.dart';

class ProblemsScreen extends StatefulWidget {
  const ProblemsScreen({Key? key}) : super(key: key);

  @override
  State<ProblemsScreen> createState() => _ProblemsScreenState();
}

class _ProblemsScreenState extends State<ProblemsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'all';
  String _sortBy = 'date';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    // Initialize the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProblemReportProvider>(context, listen: false).initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C2F41),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C2F41),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: Icon(Icons.account_balance, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/feed');
            },
          ),
        ),
        title: Consumer<ProblemReportProvider>(
          builder: (context, provider, child) {
            return Text(
              provider.isGovernment ? 'All Reported Problems' : 'My Reports',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                if (_sortBy == value) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortBy = value;
                  _sortAscending = true;
                }
              });
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'date',
                    child: Text('Sort by Date'),
                  ),
                  const PopupMenuItem(
                    value: 'status',
                    child: Text('Sort by Status'),
                  ),
                  const PopupMenuItem(
                    value: 'title',
                    child: Text('Sort by Title'),
                  ),
                ],
          ),
        ],
      ),
      body: Consumer<ProblemReportProvider>(
        builder: (context, provider, child) {
          if (provider.currentUserId == null) {
            return const Center(
              child: Text(
                'Please sign in to view problems',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          var problems = provider.problemReports;

          // Apply filters
          if (_selectedStatus != 'all') {
            problems =
                problems.where((p) => p.status == _selectedStatus).toList();
          }

          // Apply search
          if (_searchQuery.isNotEmpty) {
            problems =
                problems
                    .where(
                      (p) =>
                          p.title.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          p.description.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ),
                    )
                    .toList();
          }

          // Apply sorting
          problems.sort((a, b) {
            int comparison;
            switch (_sortBy) {
              case 'date':
                comparison = a.createdAt.compareTo(b.createdAt);
                break;
              case 'status':
                comparison = a.status.compareTo(b.status);
                break;
              case 'title':
                comparison = a.title.compareTo(b.title);
                break;
              default:
                comparison = 0;
            }
            return _sortAscending ? comparison : -comparison;
          });

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search problems...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white54,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF181B2C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('All', 'all'),
                          const SizedBox(width: 8),
                          _filterChip('Pending', 'pending'),
                          const SizedBox(width: 8),
                          _filterChip('In Progress', 'in_progress'),
                          const SizedBox(width: 8),
                          _filterChip('Completed', 'completed'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    problems.isEmpty
                        ? Center(
                          child: Text(
                            provider.isGovernment
                                ? 'No problems reported yet.'
                                : 'You haven\'t reported any problems yet.',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: problems.length,
                          itemBuilder: (context, index) {
                            final report = problems[index];
                            return Dismissible(
                              key: Key(report.id),
                              // Only allow dismissing if user is government or owns the report
                              direction:
                                  (provider.isGovernment ||
                                          report.userId ==
                                              provider.currentUserId)
                                      ? DismissDirection.endToStart
                                      : DismissDirection.none,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20.0),
                                color: Colors.red,
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: const Color(0xFF1C2F41),
                                      title: const Text(
                                        'Confirm Delete',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: const Text(
                                        'Are you sure you want to delete this report?',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(false),
                                          child: const Text(
                                            'CANCEL',
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('DELETE'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              onDismissed: (direction) {
                                provider.deleteProblemReport(report.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Problem report deleted'),
                                  ),
                                );
                              },
                              child: Card(
                                color: const Color(0xFF181B2C),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListTile(
                                  title: Text(
                                    report.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        report.description,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(report.createdAt),
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Chip(
                                        label: Text(
                                          report.status
                                              .replaceAll('_', ' ')
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                        backgroundColor: _getStatusColor(
                                          report.status,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => ProblemDetailScreen(
                                              report: report,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<ProblemReportProvider>(
        builder: (context, provider, child) {
          // Only show FAB for citizens
          if (provider.isGovernment) return const SizedBox.shrink();

          return FloatingActionButton(
            backgroundColor: const Color(0xFF1C2F41),
            onPressed: () {
              Navigator.pushNamed(context, '/reportProblem');
            },
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    return FilterChip(
      selected: _selectedStatus == value,
      label: Text(
        label,
        style: TextStyle(
          color: _selectedStatus == value ? Colors.white : Colors.white70,
        ),
      ),
      backgroundColor: const Color(0xFF181B2C),
      selectedColor: const Color(0xFF1C2F41),
      onSelected: (bool selected) {
        setState(() {
          _selectedStatus = selected ? value : 'all';
        });
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
