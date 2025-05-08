import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/problem_report_provider.dart';
import 'dart:io';

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({Key? key}) : super(key: key);

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _image;
  LatLng? _selectedLocation;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  GoogleMapController? _mapController;

  // Initial camera position (can be set to your city's coordinates)
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(24.7136, 46.6753), // Riyadh coordinates
    zoom: 11,
  );

  @override
  void initState() {
    super.initState();
    // Check if user is authenticated and not a government official
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProblemReportProvider>(context, listen: false);
      if (provider.currentUserId == null) {
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }
      if (provider.isGovernment) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Government officials cannot report problems')),
        );
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _image = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate() && _selectedLocation != null) {
      setState(() => _isLoading = true);
      try {
        final provider = Provider.of<ProblemReportProvider>(context, listen: false);
        
        // Check authentication again before submitting
        if (provider.currentUserId == null) {
          throw Exception('You must be logged in to submit a report');
        }
        
        if (provider.isGovernment) {
          throw Exception('Government officials cannot submit problem reports');
        }

        await provider.submitProblemReport(
          title: _titleController.text,
          description: _descriptionController.text,
          image: _image,
          location: GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude),
        );

        if (mounted) {
          _resetForm();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Problem reported successfully')),
          );
          Navigator.pop(context); // Return to previous screen after successful submission
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error submitting report: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map')),
      );
    }
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _image = null;
      _selectedLocation = null;
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(_initialCameraPosition),
        );
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C2F41),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C2F41),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.account_balance, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Report a Problem',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<ProblemReportProvider>(
        builder: (context, provider, child) {
          if (provider.currentUserId == null) {
            return const Center(
              child: Text(
                'Please sign in to report a problem',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (provider.isGovernment) {
            return const Center(
              child: Text(
                'Government officials cannot report problems',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _roundedInput(
                    controller: _titleController,
                    label: 'Title',
                    validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
                  ),
                  const SizedBox(height: 16),
                  _roundedInput(
                    controller: _descriptionController,
                    label: 'Description',
                    maxLines: 3,
                    validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo),
                    label: const Text('Add Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF181B2C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  if (_image != null) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_image!, height: 180, fit: BoxFit.cover),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFF181B2C),
                      border: Border.all(color: Colors.white12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: _initialCameraPosition,
                            onMapCreated: (controller) => _mapController = controller,
                            onTap: (LatLng location) {
                              setState(() {
                                _selectedLocation = location;
                              });
                            },
                            markers: _selectedLocation == null
                                ? {}
                                : {
                                    Marker(
                                      markerId: const MarkerId('selected_location'),
                                      position: _selectedLocation!,
                                    ),
                                  },
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                            myLocationButtonEnabled: false,
                          ),
                          if (_selectedLocation == null)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Tap to select location',
                                  style: TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF181B2C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Submit Report'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _roundedInput({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF22304D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
