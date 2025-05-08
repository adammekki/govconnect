import 'package:flutter/material.dart';
import '../../models/problem_report.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/problem_report_provider.dart';

class ProblemDetailScreen extends StatelessWidget {
  final ProblemReport report;

  const ProblemDetailScreen({Key? key, required this.report}) : super(key: key);

  void _showStatusUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C2F41),
          title: const Text(
            'Update Status',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusOption(context, 'Pending'),
              _buildStatusOption(context, 'In Progress'),
              _buildStatusOption(context, 'Completed'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusOption(BuildContext context, String status) {
    final String statusValue = status.toLowerCase().replaceAll(' ', '_');
    return ListTile(
      tileColor: const Color(0xFF181B2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Text(
        status,
        style: const TextStyle(color: Colors.white),
      ),
      trailing: Icon(
        Icons.circle,
        color: _getStatusColor(statusValue),
      ),
      onTap: () async {
        try {
          final provider = Provider.of<ProblemReportProvider>(context, listen: false);
          
          // Check if user is government official
          if (!provider.isGovernment) {
            throw Exception('Only government officials can update problem status');
          }
          
          await provider.updateProblemStatus(report.id, statusValue);
          Navigator.pop(context); // Close dialog
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Status updated successfully')),
            );
          }
        } catch (e) {
          Navigator.pop(context); // Close dialog
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating status: $e')),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProblemReportProvider>(
      builder: (context, provider, child) {
        final bool canManageReport = provider.isGovernment || report.userId == provider.currentUserId;

        return Scaffold(
          backgroundColor: const Color(0xFF1C2F41),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1C2F41),
            elevation: 0,
            title: Text(
              report.title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (provider.isGovernment)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showStatusUpdateDialog(context),
                  tooltip: 'Update Status',
                ),
              if (canManageReport)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: const Color(0xFF1C2F41),
                          title: const Text(
                            'Confirm Delete',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text(
                                'CANCEL',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
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

                    if (confirmed == true && context.mounted) {
                      try {
                        await provider.deleteProblemReport(report.id);
                        Navigator.pop(context); // Return to previous screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Report deleted successfully')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error deleting report: $e')),
                        );
                      }
                    }
                  },
                  tooltip: 'Delete Report',
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (report.imageUrl != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: NetworkImage(report.imageUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Card(
                  color: const Color(0xFF181B2C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Status',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Chip(
                              label: Text(
                                report.status.replaceAll('_', ' ').toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: _getStatusColor(report.status),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Description',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          report.description,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey[900],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                  report.location.latitude,
                                  report.location.longitude,
                                ),
                                zoom: 15,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('problem_location'),
                                  position: LatLng(
                                    report.location.latitude,
                                    report.location.longitude,
                                  ),
                                ),
                              },
                              zoomControlsEnabled: false,
                              mapToolbarEnabled: false,
                              myLocationButtonEnabled: false,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Report Information',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Reported on: ${_formatDate(report.createdAt)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}


