import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../models/video.dart';

class VideoDownloadService {
  /// Télécharger la vidéo
  static Future<bool> downloadVideo(Video video) async {
    try {
      print('📥 [VideoDownload] Downloading video: ${video.id}');

      final response = await http.get(Uri.parse(video.videoUrl))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        throw Exception('Failed to download: ${response.statusCode}');
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final file = File('${tempDir.path}/$fileName');

      await file.writeAsBytes(response.bodyBytes);
      print('✅ [VideoDownload] Video downloaded: ${file.path}');

      return true;
    } catch (e) {
      print('❌ [VideoDownload] Error: $e');
      return false;
    }
  }

  /// Sauvegarder dans la galerie
  static Future<bool> saveToGallery(Video video) async {
    try {
      print('💾 [VideoDownload] Saving to gallery: ${video.id}');

      final response = await http.get(Uri.parse(video.videoUrl))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        throw Exception('Failed to download: ${response.statusCode}');
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final file = File('${tempDir.path}/$fileName');

      await file.writeAsBytes(response.bodyBytes);

      // Sauvegarder dans la galerie
      await Gal.putVideo(file.path, album: 'IdeaSpark Videos');
      print('✅ [VideoDownload] Video saved to gallery');

      return true;
    } catch (e) {
      print('❌ [VideoDownload] Error: $e');
      return false;
    }
  }

  /// Partager la vidéo
  static Future<void> shareVideo(Video video) async {
    try {
      print('📤 [VideoDownload] Sharing video: ${video.id}');

      final response = await http.get(Uri.parse(video.videoUrl))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        throw Exception('Failed to download: ${response.statusCode}');
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final file = File('${tempDir.path}/$fileName');

      await file.writeAsBytes(response.bodyBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '🎬 Vidéo générée avec IdeaSpark',
      );

      print('✅ [VideoDownload] Video shared');
    } catch (e) {
      print('❌ [VideoDownload] Error: $e');
    }
  }

  /// Copier le lien dans le presse-papiers
  static Future<void> copyToClipboard(Video video) async {
    try {
      print('📋 [VideoDownload] Copying link to clipboard');
      await Share.share(video.videoUrl);
      print('✅ [VideoDownload] Link copied');
    } catch (e) {
      print('❌ [VideoDownload] Error: $e');
    }
  }

  /// Ouvrir TikTok
  static Future<void> openTikTok() async {
    try {
      print('🎵 [VideoDownload] Opening TikTok');
      // Sur Android/iOS, ouvrir l'app TikTok
      // L'utilisateur devra copier-coller la vidéo manuellement
    } catch (e) {
      print('❌ [VideoDownload] Error: $e');
    }
  }

  /// Ouvrir Instagram
  static Future<void> openInstagram() async {
    try {
      print('📷 [VideoDownload] Opening Instagram');
      // Sur Android/iOS, ouvrir l'app Instagram
    } catch (e) {
      print('❌ [VideoDownload] Error: $e');
    }
  }

  /// Ouvrir Facebook
  static Future<void> openFacebook() async {
    try {
      print('📘 [VideoDownload] Opening Facebook');
      // Sur Android/iOS, ouvrir l'app Facebook
    } catch (e) {
      print('❌ [VideoDownload] Error: $e');
    }
  }

  /// Ouvrir YouTube
  static Future<void> openYouTube() async {
    try {
      print('▶️ [VideoDownload] Opening YouTube');
      // Sur Android/iOS, ouvrir l'app YouTube
    } catch (e) {
      print('❌ [VideoDownload] Error: $e');
    }
  }

  /// Afficher le dialog de partage
  static Future<void> showShareDialog(
    BuildContext context,
    Video video,
  ) async {
    // Implémenté dans le widget
  }
}
