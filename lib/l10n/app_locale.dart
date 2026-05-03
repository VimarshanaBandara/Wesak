import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

/// App localization - English and Sinhala translations
///
/// Simple string:    AppLocale.someKey.getString(context)
/// With parameters:  context.formatString(AppLocale.someKey, ['param'])
/// Placeholder in value: %a  (replaced in order by formatString args)
class AppLocale {
  // ── Navigation ───────────────────────────────────────────────────────────
  static const String navHome = 'nav_home';
  static const String navMap = 'nav_map';
  static const String navAdd = 'nav_add';
  static const String navMyEvents = 'nav_my_events';
  static const String navProfile = 'nav_profile';

  // ── Splash ───────────────────────────────────────────────────────────────
  static const String splashBlessing = 'splash_blessing';

  // ── Home ─────────────────────────────────────────────────────────────────
  static const String homeTitle = 'home_title';
  static const String homeGreeting = 'home_greeting';
  static const String homeSubtitle = 'home_subtitle';
  static const String homeFindNearby = 'home_find_nearby';
  static const String homeVerified = 'home_verified';
  static const String homeBrowseCategory = 'home_browse_category';
  static const String homeTapExplore = 'home_tap_explore';
  static const String homeSeeAll = 'home_see_all';

  // ── Event types ───────────────────────────────────────────────────────────
  static const String typeDansal = 'type_dansal';
  static const String typeThorana = 'type_thorana';
  static const String typeKudu = 'type_kudu';
  static const String typeGeetha = 'type_geetha';

  // ── Event type descriptions ───────────────────────────────────────────────
  static const String descDansal = 'desc_dansal';
  static const String descThorana = 'desc_thorana';
  static const String descKudu = 'desc_kudu';
  static const String descGeetha = 'desc_geetha';

  // ── Profile ───────────────────────────────────────────────────────────────
  static const String profileTitle = 'profile_title';
  static const String profileGuest = 'profile_guest';
  static const String profileGuestSubtitle = 'profile_guest_subtitle';
  static const String profileSignIn = 'profile_sign_in';
  static const String profileLanguage = 'profile_language';
  static const String profileNotifications = 'profile_notifications';
  static const String profileManageAlerts = 'profile_manage_alerts';
  static const String profileAbout = 'profile_about';
  static const String profileAboutSubtitle = 'profile_about_subtitle';
  static const String profileAdminBadge = 'profile_admin_badge';
  static const String profileAdminPanel = 'profile_admin_panel';
  static const String profileAdminSubtitle = 'profile_admin_subtitle';
  static const String profileSignOut = 'profile_sign_out';
  static const String profileDeleteAccount = 'profile_delete_account';
  static const String profileDeleteConfirmTitle = 'profile_delete_confirm_title';
  static const String profileDeleteConfirmMsg = 'profile_delete_confirm_msg';
  static const String profileDeleteConfirmBtn = 'profile_delete_confirm_btn';
  static const String profileSettings = 'profile_settings';
  static const String profileAccount = 'profile_account';
  static const String profileAdmin = 'profile_admin';
  static const String profileLangEn = 'profile_lang_en';
  static const String profileLangSi = 'profile_lang_si';
  static const String profileSelectLang = 'profile_select_lang';

  // ── Search ────────────────────────────────────────────────────────────────
  static const String searchTitle = 'search_title';
  static const String searchPlaceholder = 'search_placeholder';
  static const String searchTypeHint = 'search_type_hint';
  static const String searchNoEvents = 'search_no_events';
  static const String searchFilterAll = 'search_filter_all';
  static const String searchResultSingle = 'search_result_single';
  static const String searchResultPlural = 'search_result_plural';
  static const String searchTryDifferent = 'search_try_different';

  // ── Event list ────────────────────────────────────────────────────────────
  static const String listSortBy = 'list_sort_by';
  static const String listSortDefault = 'list_sort_default';
  static const String listSortNearMe = 'list_sort_near_me';
  static const String listSearchPlaceholder = 'list_search_placeholder';
  static const String listNoResults = 'list_no_results';
  static const String listCouldNotLoad = 'list_could_not_load';
  static const String listCheckConnection = 'list_check_connection';
  static const String listRetry = 'list_retry';
  static const String listNoEvents = 'list_no_events';
  static const String listBeFirst = 'list_be_first';
  static const String listLoadingMore = 'list_loading_more';
  static const String listLoadedCount = 'list_loaded_count';
  static const String listFailedLoadMore = 'list_failed_load_more';
  static const String listAllLoaded = 'list_all_loaded';
  static const String listGpsDenied = 'list_gps_denied';
  static const String listGpsError = 'list_gps_error';

  // ── Map ───────────────────────────────────────────────────────────────────
  static const String mapTitle = 'map_title';
  static const String mapSearchPlaceholder = 'map_search_placeholder';
  static const String mapLocationNotFound = 'map_location_not_found';
  static const String mapSearchFailed = 'map_search_failed';
  static const String mapNoEvents = 'map_no_events';
  static const String mapFilterAll = 'map_filter_all';
  static const String mapViewDetails = 'map_view_details';
  static const String legendGeetha = 'legend_geetha';
  static const String mapNearestDansal = 'map_nearest_dansal';
  static const String mapNearestDansalTitle = 'map_nearest_dansal_title';
  static const String mapNoDansals = 'map_no_dansals';
  static const String mapShowOnMap = 'map_show_on_map';

  // ── Nearby ────────────────────────────────────────────────────────────────
  static const String nearbyTitle = 'nearby_title';
  static const String nearbyGettingLocation = 'nearby_getting_location';
  static const String nearbyAllowLocation = 'nearby_allow_location';
  static const String nearbyPermissionDenied = 'nearby_permission_denied';
  static const String nearbyLocationError = 'nearby_location_error';
  static const String nearbyTryAgain = 'nearby_try_again';
  static const String nearbyWithin = 'nearby_within';
  static const String nearbyNoEvents = 'nearby_no_events';
  static const String nearbyTryLarger = 'nearby_try_larger';
  static const String nearbyEventsCount = 'nearby_events_count';
  static const String nearbyEventsCountPlural = 'nearby_events_count_plural';

  // ── Add event ─────────────────────────────────────────────────────────────
  static const String addTitle = 'add_title';
  static const String addShareTitle = 'add_share_title';
  static const String addSignInRequired = 'add_sign_in_required';
  static const String addGoToProfile = 'add_go_to_profile';
  static const String addChooseType = 'add_choose_type';
  static const String addSchedule = 'add_schedule';
  static const String addEventDetails = 'add_event_details';
  static const String addLocation = 'add_location';
  static const String addPhotos = 'add_photos';
  static const String addEventName = 'add_event_name';
  static const String addEventNameHint = 'add_event_name_hint';
  static const String addCity = 'add_city';
  static const String addCityHint = 'add_city_hint';
  static const String addContact = 'add_contact';
  static const String addContactHint = 'add_contact_hint';
  static const String addDescription = 'add_description';
  static const String addDescriptionHint = 'add_description_hint';
  static const String addFoodLabel = 'add_food_label';
  static const String addFoodHint = 'add_food_hint';
  static const String addDate = 'add_date';
  static const String addStartTime = 'add_start_time';
  static const String addStartDate = 'add_start_date';
  static const String addEndDate = 'add_end_date';
  static const String addConcertDate = 'add_concert_date';
  static const String addTapToPick = 'add_tap_to_pick';
  static const String addPickOnMap = 'add_pick_on_map';
  static const String addLocationSelected = 'add_location_selected';
  static const String addTapMap = 'add_tap_map';
  static const String addPhoto = 'add_photo';
  static const String addCamera = 'add_camera';
  static const String addSubmit = 'add_submit';
  static const String addSubmitting = 'add_submitting';
  static const String addUploading = 'add_uploading';
  static const String addSaving = 'add_saving';
  static const String addApprovalNote = 'add_approval_note';
  static const String addSuccess = 'add_success';
  static const String addSelectType = 'add_select_type';
  static const String addPickLocation = 'add_pick_location';
  static const String addNameRequired = 'add_name_required';
  static const String addCityRequired = 'add_city_required';

  // ── Schedule titles ───────────────────────────────────────────────────────
  static const String scheduleDansal = 'schedule_dansal';
  static const String scheduleThorana = 'schedule_thorana';
  static const String scheduleKudu = 'schedule_kudu';
  static const String scheduleGeetha = 'schedule_geetha';

  // ── Schedule validation ───────────────────────────────────────────────────
  static const String validateDansalDate = 'validate_dansal_date';
  static const String validateDansalTime = 'validate_dansal_time';
  static const String validateThoranaStart = 'validate_thorana_start';
  static const String validateThoranaEnd = 'validate_thorana_end';
  static const String validateKuduStart = 'validate_kudu_start';
  static const String validateKuduEnd = 'validate_kudu_end';
  static const String validateGeethaDate = 'validate_geetha_date';
  static const String validateGeethaTime = 'validate_geetha_time';

  // ── My submissions ────────────────────────────────────────────────────────
  static const String submissionsTitle = 'submissions_title';
  static const String submissionsYour = 'submissions_your';
  static const String submissionsCountSingle = 'submissions_count_single';
  static const String submissionsCountPlural = 'submissions_count_plural';
  static const String submissionsPending = 'submissions_pending';
  static const String submissionsLive = 'submissions_live';
  static const String submissionsRejected = 'submissions_rejected';
  static const String submissionsNoEvents = 'submissions_no_events';
  static const String submissionsAddHint = 'submissions_add_hint';

  // ── Admin ─────────────────────────────────────────────────────────────────
  static const String adminTitle = 'admin_title';
  static const String adminNoPending = 'admin_no_pending';
  static const String adminApprove = 'admin_approve';
  static const String adminReject = 'admin_reject';
  static const String adminRejectTitle = 'admin_reject_title';
  static const String adminRejectReason = 'admin_reject_reason';
  static const String adminCancel = 'admin_cancel';
  static const String adminApprovedMsg = 'admin_approved_msg';
  static const String adminRejectedMsg = 'admin_rejected_msg';

  // ── Location picker ───────────────────────────────────────────────────────
  static const String locationTitle = 'location_title';
  static const String locationConfirm = 'location_confirm';
  static const String locationTapHint = 'location_tap_hint';
  static const String locationSelectedHint = 'location_selected_hint';
  static const String locationGetting = 'location_getting';
  static const String locationMyLocation = 'location_my_location';

  // ── Event detail ──────────────────────────────────────────────────────────
  static const String detailGetDirections = 'detail_get_directions';
  static const String detailShare = 'detail_share';
  static const String detailPhotos = 'detail_photos';
  static const String detailAbout = 'detail_about';
  static const String detailOpenNow = 'detail_open_now';
  static const String detailUpcoming = 'detail_upcoming';
  static const String detailEnded = 'detail_ended';
  static const String detailRating = 'detail_rating';

  // ── Common ────────────────────────────────────────────────────────────────
  static const String commonSignInFailed = 'common_sign_in_failed';
  static const String commonMaway = 'common_m_away';
  static const String commonKmaway = 'common_km_away';

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String typeLabel(BuildContext context, String type) {
    return switch (type) {
      'dansal' => typeDansal.getString(context),
      'thorana' => typeThorana.getString(context),
      'kudu' => typeKudu.getString(context),
      'geetha' => typeGeetha.getString(context),
      _ => type,
    };
  }

  static String typeDesc(BuildContext context, String type) {
    return switch (type) {
      'dansal' => descDansal.getString(context),
      'thorana' => descThorana.getString(context),
      'kudu' => descKudu.getString(context),
      'geetha' => descGeetha.getString(context),
      _ => '',
    };
  }

  static String statusLabel(BuildContext context, String status) {
    return switch (status) {
      'pending' => submissionsPending.getString(context),
      'approved' => submissionsLive.getString(context),
      'rejected' => submissionsRejected.getString(context),
      _ => status,
    };
  }

  // ────────────────────────────────────────────────────────────────────────────
  // ENGLISH TRANSLATIONS  (placeholder: %a)
  // ────────────────────────────────────────────────────────────────────────────
  static const Map<String, dynamic> EN = {
    navHome: 'Home',
    navMap: 'Map',
    navAdd: 'Add',
    navMyEvents: 'My Events',
    navProfile: 'Profile',

    splashBlessing: 'May you be blessed with a noble Wesak!',

    homeTitle: 'Wesak 2026',
    homeGreeting: 'Happy Wesak!',
    homeSubtitle: 'Explore Dansal, Thorana & more near you',
    homeFindNearby: 'Find Nearby',
    homeVerified: 'Verified',
    homeBrowseCategory: 'Browse by Category',
    homeTapExplore: 'Tap to explore',
    homeSeeAll: 'See all →',

    typeDansal: 'Dansal',
    typeThorana: 'Thorana',
    typeKudu: 'Wesak Kudu',
    typeGeetha: 'Bhakthi Geetha',

    descDansal: 'Free food offerings for all',
    descThorana: 'Illuminated Wesak structures',
    descKudu: 'Traditional Wesak lanterns',
    descGeetha: 'Buddhist devotional music',

    profileTitle: 'Profile',
    profileGuest: 'Guest User',
    profileGuestSubtitle: 'Sign in to add events & track submissions',
    profileSignIn: 'Sign in with Google',
    profileLanguage: 'Language',
    profileNotifications: 'Notifications',
    profileManageAlerts: 'Manage alerts',
    profileAbout: 'About',
    profileAboutSubtitle: 'Wesak 2026 · v1.0.0',
    profileAdminBadge: 'Administrator',
    profileAdminPanel: 'Admin Panel',
    profileAdminSubtitle: 'Review pending submissions',
    profileSignOut: 'Sign Out',
    profileDeleteAccount: 'Delete Account',
    profileDeleteConfirmTitle: 'Delete Account?',
    profileDeleteConfirmMsg: 'This will permanently delete your account and all your data. This action cannot be undone.',
    profileDeleteConfirmBtn: 'Delete',
    profileSettings: 'Settings',
    profileAccount: 'Account',
    profileAdmin: 'Admin',
    profileLangEn: 'English',
    profileLangSi: 'Sinhala',
    profileSelectLang: 'Select Language',

    searchTitle: 'Search',
    searchPlaceholder: 'Search by name or city...',
    searchTypeHint: 'Type to search events',
    searchNoEvents: 'No events found',
    searchFilterAll: 'All',
    searchResultSingle: '%a result',
    searchResultPlural: '%a results',
    searchTryDifferent: '"%a" — try a different search',

    listSortBy: 'Sort by',
    listSortDefault: 'Default',
    listSortNearMe: 'Near Me',
    listSearchPlaceholder: 'Search by city or event name...',
    listNoResults: 'No results for "%a"',
    listCouldNotLoad: 'Could not load events',
    listCheckConnection: 'Check your connection and try again',
    listRetry: 'Retry',
    listNoEvents: 'No %a yet',
    listBeFirst: 'Be the first to add one!',
    listLoadingMore: 'Loading more events...',
    listLoadedCount: '%a loaded',
    listFailedLoadMore: 'Failed to load more — tap to retry',
    listAllLoaded: 'All %a events loaded',
    listGpsDenied: 'Location permission denied',
    listGpsError: 'Could not get location',

    mapTitle: 'Map',
    mapSearchPlaceholder: 'Search location...',
    mapLocationNotFound: 'Location not found',
    mapSearchFailed: 'Search failed. Check connection.',
    mapNoEvents: 'No approved events yet',
    mapFilterAll: 'All',
    mapViewDetails: 'View Details',
    legendGeetha: 'Geetha',
    mapNearestDansal: 'Nearest Dansal',
    mapNearestDansalTitle: 'Nearest Dansals',
    mapNoDansals: 'No dansals found near you',
    mapShowOnMap: 'Show on map',

    nearbyTitle: 'Nearby Events',
    nearbyGettingLocation: 'Getting your location...',
    nearbyAllowLocation: 'Please allow location access',
    nearbyPermissionDenied:
        'Location permission denied.\nPlease enable in Settings.',
    nearbyLocationError: 'Could not get location. Please try again.',
    nearbyTryAgain: 'Try Again',
    nearbyWithin: 'Within',
    nearbyNoEvents: 'No events within %a km',
    nearbyTryLarger: 'Try a larger radius',
    nearbyEventsCount: '%a event within %a km',
    nearbyEventsCountPlural: '%a events within %a km',

    addTitle: 'Add Event',
    addShareTitle: 'Share Your Event',
    addSignInRequired: 'Sign in required',
    addGoToProfile: 'Go to Profile tab to sign in',
    addChooseType: 'Choose Event Type',
    addSchedule: 'Schedule',
    addEventDetails: 'Event Details',
    addLocation: 'Location',
    addPhotos: 'Photos  (optional, up to 5)',
    addEventName: 'Event Name',
    addEventNameHint: 'e.g. Wijaya Dansal, Kadawatha',
    addCity: 'City',
    addCityHint: 'e.g. Colombo',
    addContact: 'Contact',
    addContactHint: 'Phone number (optional)',
    addDescription: 'Description',
    addDescriptionHint: 'Brief description (optional)',
    addFoodLabel: 'What food will be served?',
    addFoodHint: 'e.g. Rice, Curry, Kiribath, Tea',
    addDate: 'Date',
    addStartTime: 'Start Time',
    addStartDate: 'Start Date',
    addEndDate: 'End Date',
    addConcertDate: 'Concert Date',
    addTapToPick: 'Tap to pick',
    addPickOnMap: 'Pick on Map',
    addLocationSelected: 'Location Selected',
    addTapMap: 'Tap to open map and drop a pin',
    addPhoto: 'Add Photo',
    addCamera: 'Camera',
    addSubmit: 'Submit for Review',
    addSubmitting: 'Submitting...',
    addUploading: 'Uploading %a/%a...',
    addSaving: 'Saving...',
    addApprovalNote: 'Your event will be visible after admin approval.',
    addSuccess: 'Event submitted! Waiting for admin approval.',
    addSelectType: 'Please select an event type',
    addPickLocation: 'Please pick a location on the map',
    addNameRequired: 'Name is required',
    addCityRequired: 'City is required',

    scheduleDansal: 'Dansal Date, Time & Food',
    scheduleThorana: 'Thorana Duration',
    scheduleKudu: 'Display Duration',
    scheduleGeetha: 'Concert Date & Time',

    validateDansalDate: 'Please select the Dansal date',
    validateDansalTime: 'Please select the Dansal start time',
    validateThoranaStart: 'Please select the Thorana start date',
    validateThoranaEnd: 'Please select the Thorana end date',
    validateKuduStart: 'Please select the display start date',
    validateKuduEnd: 'Please select the display end date',
    validateGeethaDate: 'Please select the concert date',
    validateGeethaTime: 'Please select the concert start time',

    submissionsTitle: 'My Submissions',
    submissionsYour: 'Your Submissions',
    submissionsCountSingle: '%a event submitted',
    submissionsCountPlural: '%a events submitted',
    submissionsPending: 'Pending',
    submissionsLive: 'Live',
    submissionsRejected: 'Rejected',
    submissionsNoEvents: 'No submissions yet',
    submissionsAddHint: 'Add an event from the Add tab',

    adminTitle: 'Admin Panel',
    adminNoPending: 'No pending approvals',
    adminApprove: 'Approve',
    adminReject: 'Reject',
    adminRejectTitle: 'Reject Event',
    adminRejectReason: 'Reason (optional)',
    adminCancel: 'Cancel',
    adminApprovedMsg: '"%a" approved and live on map!',
    adminRejectedMsg: '"%a" rejected.',

    locationTitle: 'Pick Location',
    locationConfirm: 'Confirm',
    locationTapHint: 'Tap on the map to select location',
    locationSelectedHint: 'Location selected — tap Confirm to save',
    locationGetting: 'Getting your location...',
    locationMyLocation: 'My Location',

    detailGetDirections: 'Get Directions',
    detailShare: 'Share',
    detailPhotos: 'PHOTOS',
    detailAbout: 'ABOUT',
    detailOpenNow: 'Open Now',
    detailUpcoming: 'Upcoming',
    detailEnded: 'Ended',
    detailRating: 'Rating',

    commonSignInFailed: 'Sign in failed: %a',
    commonMaway: '%a m away',
    commonKmaway: '%a km away',
  };

  // ────────────────────────────────────────────────────────────────────────────
  // SINHALA TRANSLATIONS  (placeholder: %a)
  // ────────────────────────────────────────────────────────────────────────────
  static const Map<String, dynamic> SI = {
    navHome: 'මුල් පිටුව',
    navMap: 'සිතියම',
    navAdd: 'එකතු',
    navMyEvents: 'මගේ ඉසව්',
    navProfile: 'පැතිකඩ',

    splashBlessing: 'උතුම් වෙසක් මංගල්‍යයක් වේවා',

    homeTitle: 'වෙසක් 2026',
    homeGreeting: 'සුභ වෙසක් !',
    homeSubtitle: 'ළඟම ඇති දන්සල්,තෝරන්,වෙසක් කූඩු සහ වෙසක් කලාප සොයා ගන්න.',
    homeFindNearby: 'ළඟම ඇති ඉසව්',
    homeVerified: 'සනාථ',
    homeBrowseCategory: 'වර්ගය අනුව සොයන්න',
    homeTapExplore: 'ස්පර්ශ කරන්න',
    homeSeeAll: 'සියලුම →',

    typeDansal: 'දන්සල්',
    typeThorana: 'තොරණ',
    typeKudu: 'වෙසක් කූඩු',
    typeGeetha: 'භක්ති ගීත',

    descDansal: 'තහවුරු කරන ලද දන්සල්',
    descThorana: 'ආලෝකිත වෙසක් ව්‍යූහ',
    descKudu: 'ආලෝකිත වෙසක් කූඩු',
    descGeetha: 'බෞද්ධ භක්ති ගීත',

    profileTitle: 'පැතිකඩ',
    profileGuest: 'ආගන්තුක',
    profileGuestSubtitle: 'ඉසව් එකතු කිරීමට හා නිරීක්ෂණය කිරීමට ඇතුළු වන්න',
    profileSignIn: 'Google ෙකන් ඇතුළු වන්න',
    profileLanguage: 'භාෂාව',
    profileNotifications: 'දැනුම්දීම්',
    profileManageAlerts: 'ඇඟවීම් කළමනාකරණය',
    profileAbout: 'යෙදුම පිළිබඳව',
    profileAboutSubtitle: 'වෙසක් 2026 · v1.0.0',
    profileAdminBadge: 'පරිපාලක',
    profileAdminPanel: 'පරිපාලන කොටස',
    profileAdminSubtitle: 'ලැබෙන ඉදිරිපත් කිරීම් සමාලෝචනය',
    profileSignOut: 'ඉවත් වන්න',
    profileDeleteAccount: 'ගිණුම මකන්න',
    profileDeleteConfirmTitle: 'ගිණුම මකන්නද?',
    profileDeleteConfirmMsg: 'ඔබේ ගිණුම සහ සියලු දත්ත සදහටම මකා දමනු ලැබේ. මෙය undo කළ නොහැක.',
    profileDeleteConfirmBtn: 'මකන්න',
    profileSettings: 'සැකසීම්',
    profileAccount: 'ගිණුම',
    profileAdmin: 'පරිපාලක',
    profileLangEn: 'ඉංග්‍රීසි',
    profileLangSi: 'සිංහල',
    profileSelectLang: 'භාෂාව තෝරන්න',

    searchTitle: 'සොයන්න',
    searchPlaceholder: 'නාමය හෝ නගරය සොයන්න...',
    searchTypeHint: 'ඉසව් සොයන ලෙස ලියන්න',
    searchNoEvents: 'ඉසව් හමු නොවීය',
    searchFilterAll: 'සියල්ල',
    searchResultSingle: '%a ප්‍රතිඵලය',
    searchResultPlural: '%a ප්‍රතිඵල',
    searchTryDifferent: '"%a" — වෙනත් වචනයකින් සොයන්න',

    listSortBy: 'ක්‍රමය',
    listSortDefault: 'පෙරනිමි',
    listSortNearMe: 'ළඟ',
    listSearchPlaceholder: 'නගරය හෝ ඉසව් නාමය සොයන්න...',
    listNoResults: '"%a" සඳහා ප්‍රතිඵල නෑ',
    listCouldNotLoad: 'ඉසව් load කළ නොහැකි විය',
    listCheckConnection: 'සම්බන්ධතාවය පරීක්ෂා කර නැවත උත්සාහ කරන්න',
    listRetry: 'නැවත',
    listNoEvents: '%a ඉසව් නෑ',
    listBeFirst: 'ප්‍රථමයා වන්න!',
    listLoadingMore: 'තවත් ඉසව් load වෙමින්...',
    listLoadedCount: '%a load වුණා',
    listFailedLoadMore: 'Load නොවීය — ස්පර්ශ කරා නැවත',
    listAllLoaded: 'ඉසව් %a ක් load වුණා',
    listGpsDenied: 'ස්ථාන අවසරය ප්‍රතික්ෂේප විය',
    listGpsError: 'ස්ථානය ලබා ගැනීමට නොහැකි විය',

    mapTitle: 'සිතියම',
    mapSearchPlaceholder: 'ස්ථානය සොයන්න...',
    mapLocationNotFound: 'ස්ථානය හමු නොවීය',
    mapSearchFailed: 'සෙවීම අසාර්ථකයි. සම්බන්ධතාවය පරීක්ෂා කරන්න.',
    mapNoEvents: 'තාමත් අනු​මත ඉසව් නෑ',
    mapFilterAll: 'සියල්ල',
    mapViewDetails: 'සම්පූර්ණ විස්තරය',
    legendGeetha: 'ගීත',
    mapNearestDansal: 'ළඟම දන්සල',
    mapNearestDansalTitle: 'ළඟම දන්සල්',
    mapNoDansals: 'ළඟ දන්සල් හමු නොවීය',
    mapShowOnMap: 'සිතියමේ',

    nearbyTitle: 'ළඟා ඉසව්',
    nearbyGettingLocation: 'ස්ථානය ලබාගනිමින්...',
    nearbyAllowLocation: 'ස්ථාන ප්‍රවේශය අනු​මත කරන්න',
    nearbyPermissionDenied:
        'ස්ථාන අවසරය ප්‍රතික්ෂේප විය.\nසැකසීම් තුළ සක්‍රිය කරන්න.',
    nearbyLocationError: 'ස්ථානය ලබා ගැනීමට නොහැකි විය. නැවත උත්සාහ කරන්න.',
    nearbyTryAgain: 'නැවත උත්සාහ',
    nearbyWithin: 'ඇතුළේ',
    nearbyNoEvents: 'km %a ඇතුළේ ඉසව් නෑ',
    nearbyTryLarger: 'විශාල ශ්‍රේණියක් උත්සාහ කරන්න',
    nearbyEventsCount: 'km %a ඇතුළේ ඉසව් %a ක්',
    nearbyEventsCountPlural: 'km %a ඇතුළේ ඉසව් %a ක්',

    addTitle: 'ඉසව් එකතු',
    addShareTitle: 'ඔබේ ඉසව් බෙදාගන්න',
    addSignInRequired: 'ඇතුළු වීම අවශ්‍යයි',
    addGoToProfile: 'ඇතුළු වීමට Profile ටැබ් ෙකට යන්න',
    addChooseType: 'ඉසව් වර්ගය තෝරන්න',
    addSchedule: 'කාලසටහන',
    addEventDetails: 'ඉසව් විස්තර',
    addLocation: 'ස්ථානය',
    addPhotos: 'ඡායාරූප  (විකල්ප, 5 දක්වා)',
    addEventName: 'ඉසව් නාමය',
    addEventNameHint: 'උදා: විජය දානශාල, කඩවත',
    addCity: 'නගරය',
    addCityHint: 'උදා: කොළඹ',
    addContact: 'සම්බන්ධ වීමට',
    addContactHint: 'දූරකථන අංකය',
    addDescription: 'විස්තරය',
    addDescriptionHint: 'කෙටි විස්තරය (විකල්ප)',
    addFoodLabel: 'කුමන ආහාර සේවය කෙරේද?',
    addFoodHint: 'උදා: බත්, කෑම, කිරිබත්, තේ',
    addDate: 'දිනය',
    addStartTime: 'ආරම්භ කාලය',
    addStartDate: 'ආරම්භ දිනය',
    addEndDate: 'අවසාන දිනය',
    addConcertDate: 'ප්‍රසංගයේ දිනය',
    addTapToPick: 'ස්පර්ශ කරා තෝරන්න',
    addPickOnMap: 'සිතියමෙන් තෝරන්න',
    addLocationSelected: 'ස්ථානය තෝරා ගත්තා',
    addTapMap: 'සිතියම ස්පර්ශ කරා pin තබන්න',
    addPhoto: 'ඡායාරූප',
    addCamera: 'කැමරාව',
    addSubmit: 'සමාලෝචනය සඳහා ඉදිරිපත් කරන්න',
    addSubmitting: 'ඉදිරිපත් කෙරෙමින්...',
    addUploading: '%a/%a upload වෙමින්...',
    addSaving: 'සුරකිමින්...',
    addApprovalNote: 'ඔබේ ඉසව් පරිපාලකගේ අනු​මතයෙන් පසු දිස් වේ.',
    addSuccess: 'ඉසව් ඉදිරිපත් කළා! පරිපාලකගේ අනු​මතය බලාගෙන ඉන්නා.',
    addSelectType: 'ඉසව් වර්ගයක් තෝරන්න',
    addPickLocation: 'සිතියමෙන් ස්ථානයක් තෝරන්න',
    addNameRequired: 'නාමය අවශ්‍යයි',
    addCityRequired: 'නගරය අවශ්‍යයි',

    scheduleDansal: 'දානශාල දිනය, කාලය හා ආහාර',
    scheduleThorana: 'තොරණ කාලය',
    scheduleKudu: 'ප්‍රදර්ශන කාලය',
    scheduleGeetha: 'ප්‍රසංගයේ දිනය හා කාලය',

    validateDansalDate: 'දානශාල දිනය තෝරන්න',
    validateDansalTime: 'දානශාල ආරම්භ කාලය තෝරන්න',
    validateThoranaStart: 'තොරණ ආරම්භ දිනය තෝරන්න',
    validateThoranaEnd: 'තොරණ අවසාන දිනය තෝරන්න',
    validateKuduStart: 'ප්‍රදර්ශන ආරම්භ දිනය තෝරන්න',
    validateKuduEnd: 'ප්‍රදර්ශන අවසාන දිනය තෝරන්න',
    validateGeethaDate: 'ප්‍රසංගයේ දිනය තෝරන්න',
    validateGeethaTime: 'ප්‍රසංගයේ ආරම්භ කාලය තෝරන්න',

    submissionsTitle: 'මගේ ඉදිරිපත් කිරීම්',
    submissionsYour: 'ඔබේ ඉදිරිපත් කිරීම්',
    submissionsCountSingle: 'ඉසව් %a ක් ඉදිරිපත් කළා',
    submissionsCountPlural: 'ඉසව් %a ක් ඉදිරිපත් කළා',
    submissionsPending: 'බලාගෙන',
    submissionsLive: 'සජීවී',
    submissionsRejected: 'ප්‍රතික්ෂේප',
    submissionsNoEvents: 'ඉදිරිපත් කිරීම් නෑ',
    submissionsAddHint: 'Add ටැබ් ෙකන් ඉසව් එකතු කරන්න',

    adminTitle: 'පරිපාලන කොටස',
    adminNoPending: 'බලාගෙන ඉන්නා අනු​මත කිරීම් නෑ',
    adminApprove: 'අනු​මත කරන්න',
    adminReject: 'ප්‍රතික්ෂේප',
    adminRejectTitle: 'ඉසව් ප්‍රතික්ෂේප කරන්න',
    adminRejectReason: 'හේතුව (විකල්ප)',
    adminCancel: 'අවලංගු',
    adminApprovedMsg: '"%a" අනු​මත කර සිතියමේ දිස් වේ!',
    adminRejectedMsg: '"%a" ප්‍රතික්ෂේප කළා.',

    locationTitle: 'ස්ථානය තෝරන්න',
    locationConfirm: 'තහවුරු කරන්න',
    locationTapHint: 'ස්ථානය තෝරන්න සිතියම ස්පර්ශ කරන්න',
    locationSelectedHint: 'ස්ථානය තෝරා ගත්තා — Confirm ස්පර්ශ කරා සුරකින්න',
    locationGetting: 'ස්ථානය ලබාගනිමින්...',
    locationMyLocation: 'මගේ ස්ථානය',

    detailGetDirections: 'දිශාව ලබාගන්න',
    detailShare: 'බෙදාගන්න',
    detailPhotos: 'ඡායාරූප',
    detailAbout: 'ගැන',
    detailOpenNow: 'දැන් විවෘතයි',
    detailUpcoming: 'ඉදිරියේදී',
    detailEnded: 'අවසන් වුණා',
    detailRating: 'ශ්‍රේණිය',

    commonSignInFailed: 'ඇතුළු වීමේ දෝෂය: %a',
    commonMaway: '%a m ළඟ',
    commonKmaway: '%a km ළඟ',
  };
}
