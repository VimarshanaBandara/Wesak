import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/app_locale.dart';
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
  final _foodItemsController = TextEditingController();

  String? _selectedType;
  LatLng? _selectedLocation;
  List<XFile> _selectedPhotos = [];
  bool _isSubmitting = false;
  String _submitStatus = '';

  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;

  static const _dark    = Color(0xFF1A0533);
  static const _purple  = Color(0xFF6A0080);
  static const _saffron = Color(0xFFE65100);

  static const _eventTypes = ['dansal', 'thorana', 'kudu', 'geetha'];

  static const _typeIcons = {
    'dansal':  Icons.restaurant,
    'thorana': Icons.account_balance,
    'kudu':    Icons.light_mode,
    'geetha':  Icons.music_note,
  };

  static const _typeGradients = {
    'dansal':  [Color(0xFFBF360C), Color(0xFFFF6D00)],
    'thorana': [Color(0xFF4A148C), Color(0xFF7B1FA2)],
    'kudu':    [Color(0xFFF57F17), Color(0xFFFFD600)],
    'geetha':  [Color(0xFF0D47A1), Color(0xFF1976D2)],
  };

  static const _typeColors = {
    'dansal':  Color(0xFFBF360C),
    'thorana': Color(0xFF4A148C),
    'kudu':    Color(0xFFF57F17),
    'geetha':  Color(0xFF0D47A1),
  };

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _contactController.dispose();
    _foodItemsController.dispose();
    super.dispose();
  }

  void _clearSchedule() {
    _startDate = null;
    _endDate   = null;
    _startTime = null;
  }

  Future<void> _pickDate({
    required String title,
    required void Function(DateTime) onPicked,
    DateTime? firstDate,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: firstDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime.now(),
      lastDate: DateTime(2027),
      helpText: title,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: _typeColors[_selectedType] ?? _purple,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => onPicked(picked));
  }

  Future<void> _pickTime({
    required String title,
    required void Function(TimeOfDay) onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      helpText: title,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: _typeColors[_selectedType] ?? _purple,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => onPicked(picked));
  }

  String _fmt(DateTime d)      => DateFormat('dd MMM yyyy').format(d);
  String _fmtTime(TimeOfDay t) => t.format(context);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF8EE),
        appBar: WesakAppBar(title: AppLocale.addTitle.getString(context)),
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
              Text(
                AppLocale.addSignInRequired.getString(context),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: _dark),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocale.addGoToProfile.getString(context),
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: WesakAppBar(title: AppLocale.addShareTitle.getString(context)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel(AppLocale.addChooseType.getString(context)),
                    const SizedBox(height: 12),
                    _buildTypeGrid(),
                    const SizedBox(height: 24),

                    if (_selectedType != null) ...[
                      _sectionLabel(AppLocale.addSchedule.getString(context)),
                      const SizedBox(height: 12),
                      _buildScheduleCard(),
                      const SizedBox(height: 24),
                    ],

                    _sectionLabel(AppLocale.addEventDetails.getString(context)),
                    const SizedBox(height: 12),
                    _buildDetailsCard(),
                    const SizedBox(height: 24),

                    _sectionLabel(AppLocale.addLocation.getString(context)),
                    const SizedBox(height: 12),
                    _buildLocationButton(),
                    const SizedBox(height: 24),

                    _sectionLabel(AppLocale.addPhotos.getString(context)),
                    const SizedBox(height: 12),
                    _buildPhotoGrid(),
                    const SizedBox(height: 30),

                    _buildSubmitButton(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 13, color: Colors.grey[400]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            AppLocale.addApprovalNote.getString(context),
                            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Type grid ───────────────────────────────────────────────────────────────

  Widget _buildTypeGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.0,
      children: _eventTypes.map((type) {
        final selected  = _selectedType == type;
        final gradients = _typeGradients[type]!;
        return GestureDetector(
          onTap: () => setState(() {
            _selectedType = type;
            _clearSchedule();
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      colors: gradients,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: selected ? null : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? Colors.transparent : Colors.grey.shade200,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? gradients.last.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: selected ? 10 : 4,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.22)
                        : gradients.first.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _typeIcons[type],
                    color: selected ? Colors.white : gradients.first,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  AppLocale.typeLabel(context, type),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : _dark,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Schedule card ───────────────────────────────────────────────────────────

  Widget _buildScheduleCard() {
    final typeColor = _typeColors[_selectedType] ?? _purple;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month, size: 16, color: typeColor),
                const SizedBox(width: 8),
                Text(
                  _scheduleTitle(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildScheduleFields(typeColor),
          ),
        ],
      ),
    );
  }

  String _scheduleTitle() => switch (_selectedType) {
    'dansal'  => AppLocale.scheduleDansal.getString(context),
    'thorana' => AppLocale.scheduleThorana.getString(context),
    'kudu'    => AppLocale.scheduleKudu.getString(context),
    'geetha'  => AppLocale.scheduleGeetha.getString(context),
    _         => AppLocale.addSchedule.getString(context),
  };

  Widget _buildScheduleFields(Color typeColor) {
    return switch (_selectedType) {
      'dansal'  => _buildDansalSchedule(typeColor),
      'thorana' => _buildDateRangeSchedule(typeColor),
      'kudu'    => _buildDateRangeSchedule(typeColor),
      'geetha'  => _buildGeethaSchedule(typeColor),
      _         => const SizedBox.shrink(),
    };
  }

  Widget _buildDansalSchedule(Color typeColor) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _dateTile(
                label: AppLocale.addDate.getString(context),
                value: _startDate != null ? _fmt(_startDate!) : null,
                icon: Icons.calendar_today,
                typeColor: typeColor,
                onTap: () => _pickDate(
                  title: AppLocale.addDate.getString(context),
                  onPicked: (d) => _startDate = d,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _dateTile(
                label: AppLocale.addStartTime.getString(context),
                value: _startTime != null ? _fmtTime(_startTime!) : null,
                icon: Icons.access_time,
                typeColor: typeColor,
                onTap: () => _pickTime(
                  title: AppLocale.addStartTime.getString(context),
                  onPicked: (t) => _startTime = t,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _foodItemsController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: AppLocale.addFoodLabel.getString(context),
            hintText: AppLocale.addFoodHint.getString(context),
            labelStyle: TextStyle(fontSize: 13, color: typeColor),
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
            prefixIcon: Icon(Icons.set_meal, size: 20, color: typeColor),
            filled: true,
            fillColor: typeColor.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              borderSide: BorderSide(color: typeColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeSchedule(Color typeColor) {
    return Row(
      children: [
        Expanded(
          child: _dateTile(
            label: AppLocale.addStartDate.getString(context),
            value: _startDate != null ? _fmt(_startDate!) : null,
            icon: Icons.calendar_today,
            typeColor: typeColor,
            onTap: () => _pickDate(
              title: AppLocale.addStartDate.getString(context),
              onPicked: (d) {
                _startDate = d;
                if (_endDate != null && _endDate!.isBefore(d)) _endDate = null;
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _dateTile(
            label: AppLocale.addEndDate.getString(context),
            value: _endDate != null ? _fmt(_endDate!) : null,
            icon: Icons.event_available,
            typeColor: typeColor,
            onTap: () => _pickDate(
              title: AppLocale.addEndDate.getString(context),
              firstDate: _startDate ?? DateTime.now(),
              onPicked: (d) => _endDate = d,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeethaSchedule(Color typeColor) {
    return Row(
      children: [
        Expanded(
          child: _dateTile(
            label: AppLocale.addConcertDate.getString(context),
            value: _startDate != null ? _fmt(_startDate!) : null,
            icon: Icons.calendar_today,
            typeColor: typeColor,
            onTap: () => _pickDate(
              title: AppLocale.addConcertDate.getString(context),
              onPicked: (d) => _startDate = d,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _dateTile(
            label: AppLocale.addStartTime.getString(context),
            value: _startTime != null ? _fmtTime(_startTime!) : null,
            icon: Icons.access_time,
            typeColor: typeColor,
            onTap: () => _pickTime(
              title: AppLocale.addStartTime.getString(context),
              onPicked: (t) => _startTime = t,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateTile({
    required String label,
    required String? value,
    required IconData icon,
    required Color typeColor,
    required VoidCallback onTap,
  }) {
    final filled = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: filled ? typeColor.withValues(alpha: 0.07) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: filled ? typeColor.withValues(alpha: 0.4) : Colors.grey.shade300,
            width: filled ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: filled ? typeColor : Colors.grey),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: filled ? typeColor : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              filled ? value : AppLocale.addTapToPick.getString(context),
              style: TextStyle(
                fontSize: 13,
                fontWeight: filled ? FontWeight.bold : FontWeight.normal,
                color: filled ? _dark : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Details card ────────────────────────────────────────────────────────────

  Widget _buildDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInlineField(
            controller: _nameController,
            label: AppLocale.addEventName.getString(context),
            hint: AppLocale.addEventNameHint.getString(context),
            icon: Icons.title,
            isFirst: true,
            validator: (v) => (v == null || v.isEmpty)
                ? AppLocale.addNameRequired.getString(context)
                : null,
          ),
          _divider(),
          _buildInlineField(
            controller: _cityController,
            label: AppLocale.addCity.getString(context),
            hint: AppLocale.addCityHint.getString(context),
            icon: Icons.location_city,
            validator: (v) => (v == null || v.isEmpty)
                ? AppLocale.addCityRequired.getString(context)
                : null,
          ),
          _divider(),
          _buildInlineField(
            controller: _contactController,
            label: AppLocale.addContact.getString(context),
            hint: AppLocale.addContactHint.getString(context),
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          _divider(),
          _buildInlineField(
            controller: _descriptionController,
            label: AppLocale.addDescription.getString(context),
            hint: AppLocale.addDescriptionHint.getString(context),
            icon: Icons.description,
            maxLines: 3,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, indent: 52, color: Colors.grey.shade100);

  Widget _buildInlineField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 14, right: 14, top: isFirst ? 20 : 16),
          child: Icon(icon, size: 20, color: _purple),
        ),
        Expanded(
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF6A0080)),
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey[350]),
              filled: false,
              contentPadding: EdgeInsets.only(
                right: 16,
                top: isFirst ? 16 : 12,
                bottom: isLast ? 16 : 12,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              errorStyle: const TextStyle(fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }

  // ── Location ────────────────────────────────────────────────────────────────

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: picked ? Colors.green.shade400 : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: picked
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : [const Color(0xFFE65100), const Color(0xFFBF360C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                picked ? Icons.location_on : Icons.add_location_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    picked
                        ? AppLocale.addLocationSelected.getString(context)
                        : AppLocale.addPickOnMap.getString(context),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: picked ? Colors.green.shade700 : _dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    picked
                        ? '${_selectedLocation!.latitude.toStringAsFixed(5)}, '
                            '${_selectedLocation!.longitude.toStringAsFixed(5)}'
                        : AppLocale.addTapMap.getString(context),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // ── Photo grid ──────────────────────────────────────────────────────────────

  Widget _buildPhotoGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ..._selectedPhotos.asMap().entries.map((entry) {
          final index = entry.key;
          final photo = entry.value;
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(photo.path),
                  width: 90, height: 90,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4, right: 4,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPhotos.removeAt(index)),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 12),
                  ),
                ),
              ),
            ],
          );
        }),
        if (_selectedPhotos.length < 5)
          GestureDetector(
            onTap: _pickFromGallery,
            child: _photoTile(
              Icons.add_photo_alternate,
              _purple,
              _selectedPhotos.isEmpty
                  ? AppLocale.addPhoto.getString(context)
                  : '${_selectedPhotos.length}/5',
            ),
          ),
        if (_selectedPhotos.length < 5)
          GestureDetector(
            onTap: _capturePhoto,
            child: _photoTile(
              Icons.camera_alt,
              _saffron,
              AppLocale.addCamera.getString(context),
            ),
          ),
      ],
    );
  }

  Widget _photoTile(IconData icon, Color color, String label) {
    return Container(
      width: 90, height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ── Submit ──────────────────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isSubmitting ? null : _submitForm,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: _isSubmitting
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF1A0533), Color(0xFF6A0080)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: _isSubmitting ? Colors.grey.shade300 : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isSubmitting
              ? []
              : [
                  BoxShadow(
                    color: _dark.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSubmitting)
              const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            else
              const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              _isSubmitting
                  ? _submitStatus
                  : AppLocale.addSubmit.getString(context),
              style: TextStyle(
                color: _isSubmitting ? Colors.grey[600] : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF6A0080),
        letterSpacing: 1.3,
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    try {
      final images = await _storageService.pickImages();
      final toAdd  = images.take(5 - _selectedPhotos.length).toList();
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

  // ── Validation & submit ─────────────────────────────────────────────────────

  bool _validateSchedule() {
    switch (_selectedType) {
      case 'dansal':
        if (_startDate == null) { _showSnack(AppLocale.validateDansalDate.getString(context)); return false; }
        if (_startTime == null) { _showSnack(AppLocale.validateDansalTime.getString(context)); return false; }
      case 'thorana':
        if (_startDate == null) { _showSnack(AppLocale.validateThoranaStart.getString(context)); return false; }
        if (_endDate == null)   { _showSnack(AppLocale.validateThoranaEnd.getString(context));   return false; }
      case 'kudu':
        if (_startDate == null) { _showSnack(AppLocale.validateKuduStart.getString(context)); return false; }
        if (_endDate == null)   { _showSnack(AppLocale.validateKuduEnd.getString(context));   return false; }
      case 'geetha':
        if (_startDate == null) { _showSnack(AppLocale.validateGeethaDate.getString(context)); return false; }
        if (_startTime == null) { _showSnack(AppLocale.validateGeethaTime.getString(context)); return false; }
    }
    return true;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  DateTime _buildStartDateTime() {
    final date = _startDate ?? DateTime.now();
    if (_startTime != null) {
      return DateTime(date.year, date.month, date.day, _startTime!.hour, _startTime!.minute);
    }
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _buildEndDateTime() {
    if (_endDate != null) {
      return DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59);
    }
    return _buildStartDateTime().add(const Duration(hours: 8));
  }

  Future<void> _submitForm() async {
    if (_selectedType == null) { _showSnack(AppLocale.addSelectType.getString(context)); return; }
    if (!_validateSchedule())    return;
    if (_selectedLocation == null) { _showSnack(AppLocale.addPickLocation.getString(context)); return; }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _submitStatus = AppLocale.addSubmitting.getString(context);
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;

      List<String> photoUrls = [];
      if (_selectedPhotos.isNotEmpty) {
        photoUrls = await _storageService.uploadEventPhotos(
          _selectedPhotos,
          onProgress: (uploaded, total) {
            if (mounted) {
              setState(() => _submitStatus =
                  context.formatString(AppLocale.addUploading, [uploaded, total]));
            }
          },
        );
      }

      final event = EventModel(
        id:          '',
        name:        _nameController.text.trim(),
        type:        _selectedType!,
        description: _descriptionController.text.trim(),
        lat:         _selectedLocation!.latitude,
        lng:         _selectedLocation!.longitude,
        city:        _cityController.text.trim(),
        startTime:   _buildStartDateTime(),
        endTime:     _buildEndDateTime(),
        photos:      photoUrls,
        addedBy:     user.uid,
        foodItems:   _foodItemsController.text.trim(),
      );

      setState(() => _submitStatus = AppLocale.addSaving.getString(context));
      await _firestoreService.addEvent(event);

      if (mounted) {
        _formKey.currentState!.reset();
        _nameController.clear();
        _descriptionController.clear();
        _cityController.clear();
        _contactController.clear();
        _foodItemsController.clear();
        setState(() {
          _selectedType     = null;
          _selectedLocation = null;
          _selectedPhotos   = [];
          _isSubmitting     = false;
          _submitStatus     = '';
          _clearSchedule();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocale.addSuccess.getString(context)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isSubmitting = false; _submitStatus = ''; });
        _showSnack('Failed to submit: $e');
      }
    }
  }
}
