import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../models/event_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../widgets/wesak_app_bar.dart';
import 'location_picker_screen.dart';

/// Add Event screen - user submit කරන form
/// Submit කළාම photos Storage ට upload කරලා Firestore ේ pending ලෙස save වෙනවා
class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _contactController = TextEditingController();

  String? _selectedType;
  LatLng? _selectedLocation;

  // Selected photos list - max 5
  List<XFile> _selectedPhotos = [];

  bool _isSubmitting = false;
  // Upload progress text - "Uploading 1/3..."
  String _submitStatus = '';

  static const List<String> _eventTypes = [
    'dansal',
    'thorana',
    'kudu',
    'geetha',
  ];

  static const Map<String, String> _typeLabels = {
    'dansal': 'Dansal',
    'thorana': 'Thorana',
    'kudu': 'Wesak Kudu',
    'geetha': 'Bhakthi Geetha',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: const WesakAppBar(title: 'Add Event', showBackButton: true),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Please sign in to add events'),
              SizedBox(height: 8),
              Text(
                'Go to Profile tab to sign in',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add Event'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Event Type',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              _buildTypeSelector(),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Event Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'City is required' : null,
              ),
              const SizedBox(height: 16),

              // Location picker
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push<LatLng>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LocationPickerScreen()),
                  );
                  if (result != null) {
                    setState(() => _selectedLocation = result);
                  }
                },
                icon: Icon(
                  Icons.location_on,
                  color: _selectedLocation != null ? Colors.green : null,
                ),
                label: Text(
                  _selectedLocation != null
                      ? 'Location Selected ✓  (${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)})'
                      : 'Pick Location on Map',
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: _selectedLocation != null
                      ? const BorderSide(color: Colors.green)
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // Photo picker section
              Text('Photos (optional)',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              _buildPhotoSection(),
              const SizedBox(height: 16),

              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              // Submit button
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitForm,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_isSubmitting
                    ? _submitStatus
                    : 'Submit for Review'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Your event will be visible after admin approval.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Photo picker + preview grid
  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected photos preview grid
        if (_selectedPhotos.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedPhotos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    // Local file preview - Image.file ෙකන් directly load
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_selectedPhotos[index].path),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Remove button
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(
                            () => _selectedPhotos.removeAt(index)),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Photo source buttons
        Row(
          children: [
            // Gallery button
            Expanded(
              child: OutlinedButton.icon(
                // Max 5 photos limit
                onPressed: _selectedPhotos.length >= 5
                    ? null
                    : _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: Text(
                  _selectedPhotos.isEmpty
                      ? 'Gallery'
                      : '${_selectedPhotos.length}/5',
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Camera button
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    _selectedPhotos.length >= 5 ? null : _capturePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Gallery ෙකන් photos select
  Future<void> _pickFromGallery() async {
    try {
      final remaining = 5 - _selectedPhotos.length;
      final images = await _storageService.pickImages();
      // Remaining limit ට trim
      final toAdd = images.take(remaining).toList();
      if (toAdd.isNotEmpty) {
        setState(() => _selectedPhotos.addAll(toAdd));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  /// Camera ෙකන් photo capture
  Future<void> _capturePhoto() async {
    try {
      final photo = await _storageService.capturePhoto();
      if (photo != null) {
        setState(() => _selectedPhotos.add(photo));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _eventTypes.map((type) {
        return FilterChip(
          label: Text(_typeLabels[type] ?? type),
          selected: _selectedType == type,
          onSelected: (_) => setState(() => _selectedType = type),
        );
      }).toList(),
    );
  }

  Future<void> _submitForm() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an event type')),
      );
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a location on the map')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _submitStatus = 'Submitting...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final now = DateTime.now();

      // Photos තිබ්බොත් Storage ට upload කරනවා
      List<String> photoUrls = [];
      if (_selectedPhotos.isNotEmpty) {
        photoUrls = await _storageService.uploadEventPhotos(
          _selectedPhotos,
          onProgress: (uploaded, total) {
            if (mounted) {
              setState(
                  () => _submitStatus = 'Uploading $uploaded/$total...');
            }
          },
        );
      }

      final event = EventModel(
        id: '',
        name: _nameController.text.trim(),
        type: _selectedType!,
        description: _descriptionController.text.trim(),
        lat: _selectedLocation!.latitude,
        lng: _selectedLocation!.longitude,
        city: _cityController.text.trim(),
        startTime: now,
        endTime: now.add(const Duration(days: 1)),
        photos: photoUrls,
        addedBy: user.uid,
      );

      setState(() => _submitStatus = 'Saving...');
      await _firestoreService.addEvent(event);

      if (mounted) {
        _formKey.currentState!.reset();
        _nameController.clear();
        _descriptionController.clear();
        _cityController.clear();
        _contactController.clear();
        setState(() {
          _selectedType = null;
          _selectedLocation = null;
          _selectedPhotos = [];
          _isSubmitting = false;
          _submitStatus = '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event submitted! Waiting for admin approval.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submitStatus = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    }
  }
}
