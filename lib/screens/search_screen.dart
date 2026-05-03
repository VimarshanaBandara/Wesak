import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import '../l10n/app_locale.dart';
import '../models/event_model.dart';
import '../services/firestore_service.dart';
import '../widgets/event_card.dart';
import '../widgets/wesak_app_bar.dart';

/// Global search screen — name, city, type filter
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _firestoreService = FirestoreService();
  List<EventModel> _events = [];
  bool _eventsLoading = true;

  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedType;

  static const _types = ['dansal', 'thorana', 'kudu', 'geetha'];

  static const _typeColors = {
    'dansal': Color(0xFFBF360C),
    'thorana': Color(0xFF4A148C),
    'kudu': Color(0xFFF57F17),
    'geetha': Color(0xFF0D47A1),
  };

  static const _typeIcons = {
    'dansal': Icons.restaurant,
    'thorana': Icons.account_balance,
    'kudu': Icons.light_mode,
    'geetha': Icons.music_note,
  };

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _eventsLoading = true);
    try {
      final events = await _firestoreService.getVerifiedEvents();
      if (mounted) setState(() { _events = events; _eventsLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _eventsLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EventModel> _filter(List<EventModel> all) {
    final q = _query.trim().toLowerCase();
    return all.where((e) {
      final matchType = _selectedType == null || e.type == _selectedType;
      final matchQuery = q.isEmpty ||
          e.name.toLowerCase().contains(q) ||
          e.city.toLowerCase().contains(q);
      return matchType && matchQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: WesakAppBar(
        title: AppLocale.searchTitle.getString(context),
        showBackButton: true,
      ),
      body: Column(
        children: [
          // ── Search bar ───────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: AppLocale.searchPlaceholder.getString(context),
                hintStyle:
                    const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon:
                    const Icon(Icons.search, color: Color(0xFF6A0080)),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF8F4FF),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── Type filter chips ────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(
                    label: AppLocale.searchFilterAll.getString(context),
                    icon: Icons.apps,
                    color: const Color(0xFF1A0533),
                    selected: _selectedType == null,
                    onTap: () =>
                        setState(() => _selectedType = null),
                  ),
                  const SizedBox(width: 8),
                  ..._types.map((type) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _filterChip(
                          label: AppLocale.typeLabel(context, type),
                          icon: _typeIcons[type]!,
                          color: _typeColors[type]!,
                          selected: _selectedType == type,
                          onTap: () =>
                              setState(() => _selectedType = type),
                        ),
                      )),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // ── Results ──────────────────────────────────────────────────
          Expanded(
            child: Builder(
              builder: (context) {
                if (_eventsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final all = _events;
                final filtered = _filter(all);

                if (_query.isEmpty && _selectedType == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          AppLocale.searchTypeHint.getString(context),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          AppLocale.searchNoEvents.getString(context),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 15,
                          ),
                        ),
                        if (_query.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            context.formatString(
                                AppLocale.searchTryDifferent, [_query]),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        filtered.length == 1
                            ? context.formatString(
                                AppLocale.searchResultSingle,
                                [filtered.length])
                            : context.formatString(
                                AppLocale.searchResultPlural,
                                [filtered.length]),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) =>
                            EventCard(event: filtered[i]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected ? Colors.white : Colors.grey),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
