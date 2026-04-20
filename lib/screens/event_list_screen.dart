import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/event_model.dart';
import '../services/firestore_service.dart';
import '../widgets/event_card.dart';
import '../widgets/wesak_app_bar.dart';

enum _SortMode { defaultSort, nearMe }

/// Category filtered event list screen with pagination (20 per page)
class EventListScreen extends StatefulWidget {
  final String eventType;
  final String displayName;

  const EventListScreen({
    super.key,
    required this.eventType,
    required this.displayName,
  });

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final _firestoreService = FirestoreService();
  final _scrollController = ScrollController();

  // Pagination state
  final List<EventModel> _events = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _initialLoading = true;
  String? _loadError;

  // Search
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Sort
  _SortMode _sortMode = _SortMode.defaultSort;
  Position? _userPosition;
  bool _loadingGps = false;
  String? _gpsError;

  static const _distCalc = Distance();

  static const _typeGradients = {
    'dansal': [Color(0xFFBF360C), Color(0xFFFF6D00)],
    'thorana': [Color(0xFF4A148C), Color(0xFF7B1FA2)],
    'kudu': [Color(0xFFF57F17), Color(0xFFFFD600)],
    'geetha': [Color(0xFF0D47A1), Color(0xFF1976D2)],
  };

  static const _typeIcons = {
    'dansal': Icons.restaurant,
    'thorana': Icons.account_balance,
    'kudu': Icons.light_mode,
    'geetha': Icons.music_note,
  };

  static const _typeDescriptions = {
    'dansal': 'Free food offerings for all',
    'thorana': 'Illuminated Wesak structures',
    'kudu': 'Traditional Wesak lanterns',
    'geetha': 'Buddhist devotional music',
  };

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Pagination ───────────────────────────────────────────────────────────────

  Future<void> _loadFirstPage() async {
    setState(() {
      _initialLoading = true;
      _events.clear();
      _lastDoc = null;
      _hasMore = true;
    });
    await _loadPage();
    if (mounted) setState(() => _initialLoading = false);
  }

  Future<void> _loadPage() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final result = await _firestoreService.fetchEventsByTypePage(
        widget.eventType,
        lastDoc: _lastDoc,
      );

      if (mounted) {
        setState(() {
          _loadError = null;
          _events.addAll(result.events);
          _lastDoc = result.lastDoc;
          // returned count == pageSize නම් more ිතිෙය් හෑකි
          _hasMore = result.events.length >= FirestoreService.pageSize;
          _isLoading = false;
        });

        // Page ිකෙකන් screen fill ිකෙනෙකෙරෙ ිනම් auto next page load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_hasMore &&
              _scrollController.hasClients &&
              _scrollController.position.maxScrollExtent == 0) {
            _loadPage();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = 'Failed to load events. Tap to retry.';
        });
      }
    }
  }

  void _onScroll() {
    // List bottom ිකෙදන් 300px ිකදී next page load
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadPage();
    }
  }

  // ── Sort / GPS ───────────────────────────────────────────────────────────────

  Future<void> _enableNearMe() async {
    setState(() {
      _loadingGps = true;
      _gpsError = null;
    });

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        setState(() {
          _gpsError = 'Location permission denied';
          _loadingGps = false;
          _sortMode = _SortMode.defaultSort;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      setState(() {
        _userPosition = pos;
        _loadingGps = false;
        _sortMode = _SortMode.nearMe;
      });
    } catch (_) {
      setState(() {
        _gpsError = 'Could not get location';
        _loadingGps = false;
        _sortMode = _SortMode.defaultSort;
      });
    }
  }

  double? _distanceTo(EventModel e) {
    if (_userPosition == null) return null;
    return _distCalc.as(
      LengthUnit.Kilometer,
      LatLng(_userPosition!.latitude, _userPosition!.longitude),
      LatLng(e.lat, e.lng),
    );
  }

  List<EventModel> get _sorted {
    List<EventModel> list;
    if (_sortMode == _SortMode.nearMe && _userPosition != null) {
      list = [..._events];
      list.sort((a, b) => (_distanceTo(a) ?? 0).compareTo(_distanceTo(b) ?? 0));
    } else {
      list = _events;
    }

    // City/location name search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((e) =>
              e.city.toLowerCase().contains(q) ||
              e.name.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gradients =
        _typeGradients[widget.eventType] ?? [Colors.grey, Colors.blueGrey];
    final icon = _typeIcons[widget.eventType] ?? Icons.event;
    final description = _typeDescriptions[widget.eventType] ?? '';

    if (_initialLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: WesakAppBar(title: widget.displayName, showBackButton: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Initial load ිකදීම error ිවෙලා ිනම්
    if (_loadError != null && _events.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: WesakAppBar(title: widget.displayName, showBackButton: true),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, size: 56, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Could not load events',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check your connection and try again',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _loadFirstPage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A0533),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final events = _sorted;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: WesakAppBar(title: widget.displayName, showBackButton: true),
      body: _events.isEmpty
          ? _buildEmptyState(gradients, icon)
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: _buildHeader(
                    gradients,
                    icon,
                    description,
                    events.length,
                  ),
                ),

                // Sort bar
                SliverToBoxAdapter(child: _buildSortBar(gradients)),

                // Search bar
                SliverToBoxAdapter(child: _buildSearchBar(gradients)),

                // GPS error
                if (_gpsError != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_off,
                              size: 16,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _gpsError!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Event cards or no-results state
                events.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No results for "$_searchQuery"',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((context, index) {
                            final event = events[index];
                            final dist = _sortMode == _SortMode.nearMe
                                ? _distanceTo(event)
                                : null;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: EventCard(event: event, distanceKm: dist),
                            );
                          }, childCount: events.length),
                        ),
                      ),

                // Bottom: loading / error / all-loaded indicator
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    child: _isLoading
                        ? _buildLoadMoreBanner(gradients, events.length)
                        : _loadError != null
                        ? GestureDetector(
                            onTap: _loadPage,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.refresh,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Failed to load more — tap to retry',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : !_hasMore
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'All ${events.length} events loaded',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(
    List<Color> gradients,
    IconData icon,
    String description,
    int count,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradients,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradients.last.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Loaded count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count${_hasMore ? '+' : ''}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortBar(List<Color> gradients) {
    final activeColor = gradients.first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          const Text(
            'Sort by',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 10),
          _sortChip(
            label: 'Default',
            icon: Icons.sort,
            selected: _sortMode == _SortMode.defaultSort,
            activeColor: activeColor,
            onTap: () => setState(() {
              _sortMode = _SortMode.defaultSort;
              _gpsError = null;
            }),
          ),
          const SizedBox(width: 8),
          _sortChip(
            label: 'Near Me',
            icon: _loadingGps ? Icons.gps_not_fixed : Icons.near_me,
            selected: _sortMode == _SortMode.nearMe,
            activeColor: const Color(0xFF2E7D32),
            loading: _loadingGps,
            onTap: _loadingGps
                ? null
                : () {
                    if (_sortMode == _SortMode.nearMe) {
                      setState(() => _sortMode = _SortMode.defaultSort);
                    } else if (_userPosition != null) {
                      setState(() => _sortMode = _SortMode.nearMe);
                    } else {
                      _enableNearMe();
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _sortChip({
    required String label,
    required IconData icon,
    required bool selected,
    required Color activeColor,
    VoidCallback? onTap,
    bool loading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? activeColor.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: selected ? 6 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: selected ? Colors.white : activeColor,
                ),
              )
            else
              Icon(
                icon,
                size: 13,
                color: selected ? Colors.white : Colors.grey[600],
              ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(List<Color> gradients) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search by city or event name...',
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
            prefixIcon: Icon(Icons.search, color: gradients.first, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreBanner(List<Color> gradients, int loadedCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradients.first.withValues(alpha: 0.08),
            gradients.last.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gradients.first.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(gradients.first),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Loading more events...',
            style: TextStyle(
              fontSize: 13,
              color: gradients.first,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: gradients.first.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$loadedCount loaded',
              style: TextStyle(
                fontSize: 11,
                color: gradients.first,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(List<Color> gradients, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gradients.first.withValues(alpha: 0.15),
                  gradients.last.withValues(alpha: 0.08),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40,
              color: gradients.first.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No ${widget.displayName} yet',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A0533),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to add one!',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }
}
