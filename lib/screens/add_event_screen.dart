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
  List<XFile> _selectedPhotos = [];
  bool _isSubmitting = false;
  String _submitStatus = '';

  // Wesak colors
  static const _dark = Color(0xFF1A0533);
  static const _purple = Color(0xFF6A0080);
  static const _saffron = Color(0xFFE65100);

  static const _eventTypes = ['dansal', 'thorana', 'kudu', 'geetha'];

  static const _typeLabels = {
    'dansal': 'Dansal',
    'thorana': 'Thorana',
    'kudu': 'Wesak Kudu',
    'geetha': 'Bhakthi Geetha',
  };

  static const _typeIcons = {
    'dansal': Icons.restaurant,
    'thorana': Icons.account_balance,
    'kudu': Icons.light_mode,
    'geetha': Icons.music_note,
  };

  static const _typeColors = {
    'dansal': Color(0xFFBF360C),
    'thorana': Color(0xFF4A148C),
    'kudu': Color(0xFFF57F17),
    'geetha': Color(0xFF0D47A1),
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
        backgroundColor: const Color(0xFFFFF8EE),
        appBar: const WesakAppBar(title: 'Add Event'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, size: 40, color: _purple),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sign in required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _dark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Go to Profile tab to sign in',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const WesakAppBar(title: 'Add Event'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Event type selector ──────────────────────────────────
              _sectionLabel('Event Type'),
              const SizedBox(height: 10),
              _buildTypeSelector(),
              const SizedBox(height: 20),

              // ── Event details ────────────────────────────────────────
              _sectionLabel('Event Details'),
              const SizedBox(height: 10),
              _buildCard(
                child: Column(
                  children: [
                    _buildField(
                      controller: _nameController,
                      label: 'Event Name',
                      icon: Icons.title,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _descriptionController,
                      label: 'Description (optional)',
                      icon: Icons.description,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _cityController,
                      label: 'City',
                      icon: Icons.location_city,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'City is required' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _contactController,
                      label: 'Contact Number (optional)',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Location ─────────────────────────────────────────────
              _sectionLabel('Location'),
              const SizedBox(height: 10),
              _buildLocationButton(),
              const SizedBox(height: 20),

              // ── Photos ───────────────────────────────────────────────
              _sectionLabel('Photos (optional)'),
              const SizedBox(height: 10),
              _buildPhotoSection(),
              const SizedBox(height: 28),

              // ── Submit button ────────────────────────────────────────
              GestureDetector(
                onTap: _isSubmitting ? null : _submitForm,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _isSubmitting ? Colors.grey : _dark,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _isSubmitting
                        ? []
                        : [
                            BoxShadow(
                              color: _dark.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSubmitting)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(Icons.send, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _isSubmitting ? _submitStatus : 'Submit for Review',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Info note
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Your event will be visible after admin approval.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Event type chips ────────────────────────────────────────────────────
  Widget _buildTypeSelector() {
    return Row(
      children: _eventTypes.map((type) {
        final selected = _selectedType == type;
        final color = _typeColors[type]!;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedType = type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(
                right: type != _eventTypes.last ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? color : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? color : Colors.grey.shade300,
                  width: selected ? 2 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Icon(
                    _typeIcons[type],
                    color: selected ? Colors.white : color,
                    size: 22,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _typeLabels[type]!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : _dark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Location button ─────────────────────────────────────────────────────
  Widget _buildLocationButton() {
    final picked = _selectedLocation != null;
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<LatLng>(
          context,
          MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
        );
        if (result != null) setState(() => _selectedLocation = result);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: picked ? Colors.green : Colors.grey.shade300,
            width: picked ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (picked ? Colors.green : _saffron)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.location_on,
                color: picked ? Colors.green : _saffron,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                picked
                    ? 'Location Selected ✓  (${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)})'
                    : 'Pick Location on Map',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: picked ? Colors.green : _dark,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── Photo section ───────────────────────────────────────────────────────
  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedPhotos.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedPhotos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(_selectedPhotos[index].path),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedPhotos.removeAt(index)),
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
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: _photoButton(
                icon: Icons.photo_library,
                label: _selectedPhotos.isEmpty
                    ? 'Gallery'
                    : '${_selectedPhotos.length}/5',
                color: _purple,
                onTap: _selectedPhotos.length >= 5 ? null : _pickFromGallery,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _photoButton(
                icon: Icons.camera_alt,
                label: 'Camera',
                color: _saffron,
                onTap: _selectedPhotos.length >= 5 ? null : _capturePhoto,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _photoButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: disabled
              ? Colors.grey.shade200
              : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: disabled ? Colors.grey.shade300 : color.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: disabled ? Colors.grey : color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: disabled ? Colors.grey : color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        prefixIcon: Icon(icon, size: 20, color: _purple),
        filled: true,
        fillColor: const Color(0xFFF8F4FF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _purple, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    try {
      final remaining = 5 - _selectedPhotos.length;
      final images = await _storageService.pickImages();
      final toAdd = images.take(remaining).toList();
      if (toAdd.isNotEmpty) setState(() => _selectedPhotos.addAll(toAdd));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _capturePhoto() async {
    try {
      final photo = await _storageService.capturePhoto();
      if (photo != null) setState(() => _selectedPhotos.add(photo));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
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

      List<String> photoUrls = [];
      if (_selectedPhotos.isNotEmpty) {
        photoUrls = await _storageService.uploadEventPhotos(
          _selectedPhotos,
          onProgress: (uploaded, total) {
            if (mounted) {
              setState(() => _submitStatus = 'Uploading $uploaded/$total...');
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
