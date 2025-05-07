import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/problem_report.dart';

class ProblemDetailScreen extends StatelessWidget {
  final ProblemReport report;

  const ProblemDetailScreen({Key? key, required this.report}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (report.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  report.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Description',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(report.description, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            const Text(
              'Location',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF181B2C),
                border: Border.all(color: Colors.white12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(report.location.latitude, report.location.longitude),
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('problem_location'),
                    position: LatLng(report.location.latitude, report.location.longitude),
                  ),
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Status: ',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Chip(
                  label: Text(report.status, style: const TextStyle(color: Colors.white)),
                  backgroundColor: _getStatusColor(report.status),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Reported on: ${_formatDate(report.createdAt)}',
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  static Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}






