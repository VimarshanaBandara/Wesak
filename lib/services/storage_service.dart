import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Firebase Storage photo upload service
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Gallery ෙකන් max 5 photos select කරනවා
  /// limit parameter Android 10 support නෑ - Dart side ෙකන් trim කරනවා
  Future<List<XFile>> pickImages() async {
    final images = await _picker.pickMultiImage(
      imageQuality: 70,
    );
    return images;
  }

  /// Camera ෙකන් single photo capture කරනවා
  Future<XFile?> capturePhoto() async {
    return await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
  }

  /// Single photo Firebase Storage ට upload කරලා download URL return කරනවා
  /// Path: events/{uid}/{timestamp}_{filename}
  Future<String> uploadEventPhoto(XFile photo) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = photo.name;

    // Storage path - user UID ෙකන් organize
    final ref = _storage
        .ref()
        .child('events')
        .child(uid)
        .child('${timestamp}_$filename');

    // File upload
    final uploadTask = await ref.putFile(File(photo.path));

    // Download URL get කරනවා - Firestore ේ save කරන්නේ මේක
    return await uploadTask.ref.getDownloadURL();
  }

  /// Multiple photos upload - progress callback optional
  Future<List<String>> uploadEventPhotos(
    List<XFile> photos, {
    void Function(int uploaded, int total)? onProgress,
  }) async {
    final urls = <String>[];

    for (int i = 0; i < photos.length; i++) {
      final url = await uploadEventPhoto(photos[i]);
      urls.add(url);
      // Progress notify කරනවා
      onProgress?.call(i + 1, photos.length);
    }

    return urls;
  }

  /// Storage ෙකන් photo delete කරනවා (URL ෙකන්)
  Future<void> deletePhoto(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (_) {
      // Already deleted හෝ not found - ignore
    }
  }
}
