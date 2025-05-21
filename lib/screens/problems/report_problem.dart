import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/problem_report_provider.dart';
import '../../utils/map_style.dart';
import 'dart:io';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';

class CreateReportDialog extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onReportCreated;

  const CreateReportDialog({
    Key? key,
    required this.onClose,
    required this.onReportCreated,
  }) : super(key: key);

  @override
  State<CreateReportDialog> createState() => _CreateReportDialogState();
}

class _CreateReportDialogState extends State<CreateReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _image;
  LatLng? _selectedLocation;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  GoogleMapController? _mapController;

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
      debugPrint("[CreateReportDialog] Submit report initiated. Setting isLoading = true.");
      setState(() => _isLoading = true);
      try {
        final provider = Provider.of<ProblemReportProvider>(context, listen: false);
        
        debugPrint("[CreateReportDialog] Calling provider.submitProblemReport...");


        await provider.submitProblemReport(
          title: _titleController.text,
          description: _descriptionController.text,
          image: _image,
          location: GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude),
        );
        debugPrint("[CreateReportDialog] provider.submitProblemReport completed successfully.");

        if (mounted) {
            debugPrint("[CreateReportDialog] Widget is mounted. Calling onReportCreated.");

          widget.onReportCreated();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Problem reported successfully')),
          );
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1621),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1C2F41),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: widget.onClose,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Report a Problem',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _titleController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Problem Title',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                filled: true,
                                fillColor: const Color(0xFF1C2F41),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Please enter a title' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descriptionController,
                              style: const TextStyle(color: Colors.white),
                              maxLines: 5,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                hintText: 'Problem Description',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                filled: true,
                                fillColor: const Color(0xFF1C2F41),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Please enter a description' : null,
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                height: 130,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C2F41),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: _image != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          _image!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_photo_alternate_outlined,
                                              size: 48,
                                              color: Colors.white38,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Tap to add image',
                                              style: TextStyle(color: Colors.white38),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: GoogleMap(
                                  initialCameraPosition: const CameraPosition(
                                    target: LatLng(30.0444, 31.2357),
                                    zoom: 11,
                                  ),
                                  onMapCreated: (GoogleMapController controller) {
                                    setState(() {
                                      _mapController = controller;
                                      controller.setMapStyle(MapStyle.darkMode);
                                    });
                                  },
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
                                  zoomControlsEnabled: true,
                                  mapToolbarEnabled: false,
                                  myLocationButtonEnabled: true,
                                  myLocationEnabled: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: GestureDetector(
                        onTap: _isLoading ? null : _submitReport,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Submit Report',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}