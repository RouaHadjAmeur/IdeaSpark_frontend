import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoDownloadService {
  /// Download video from URL and save to temporary directory
  static Future<File?> downloadVideo(String videoUrl) async {
    try {
      print('📥 [VideoDownload] Starting download: $videoUrl');
      
      final response = await http.get(Uri.parse(videoUrl));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to download video: ${response.statusCode}');
      }
      
      final bytes = response.bodyBytes;
      final tempDir = await getTemporaryDirectory();
      final fileName = 'ideaspark_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final file = File('${tempDir.path}/$fileName');
      
      await file.writeAsBytes(bytes);
      
      print('✅ [VideoDownload] Video saved to: ${file.path}');
      return file;
    } catch (e) {
      print('❌ [VideoDownload] Error: $e');
      return null;
    }
  }

  /// Save video to gallery (requires permission)
  static Future<bool> saveToGallery(String videoUrl) async {
    try {
      print('💾 [VideoGallery] Requesting permission...');
      
      // Request storage permission
      final status = await Permission.photos.request();
      
      if (!status.isGranted) {
        print('❌ [VideoGallery] Permission denied');
        return false;
      }
      
      print('📥 [VideoGallery] Downloading video...');
      final response = await http.get(Uri.parse(videoUrl));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to download video');
      }
      
      final bytes = response.bodyBytes;
      
      // Save to temporary file first
      final tempDir = await getTemporaryDirectory();
      final fileName = 'ideaspark_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(bytes);
      
      print('💾 [VideoGallery] Saving to gallery...');
      // Use Gal to save to gallery
      await Gal.putVideo(tempFile.path, album: 'IdeaSpark');
      
      print('✅ [VideoGallery] Saved successfully');
      return true;
    } catch (e) {
      print('❌ [VideoGallery] Error: $e');
      return false;
    }
  }

  /// Share video using native share dialog
  static Future<void> shareVideo(String videoUrl, {String? caption}) async {
    try {
      print('📤 [VideoShare] Starting share process...');
      
      // Essayer d'abord de partager directement l'URL
      if (caption != null && caption.isNotEmpty) {
        await Share.share('$caption\n\n$videoUrl');
      } else {
        await Share.share(videoUrl);
      }
      
      print('✅ [VideoShare] URL shared successfully');
    } catch (e) {
      print('❌ [VideoShare] URL share failed, trying file download...');
      
      try {
        // Si le partage d'URL échoue, télécharger et partager le fichier
        final file = await downloadVideo(videoUrl);
        
        if (file == null) {
          throw Exception('Failed to download video');
        }
        
        print('📤 [VideoShare] Opening share dialog with file...');
        
        if (caption != null && caption.isNotEmpty) {
          await Share.shareXFiles(
            [XFile(file.path)],
            text: caption,
          );
        } else {
          await Share.shareXFiles([XFile(file.path)]);
        }
        
        print('✅ [VideoShare] File shared successfully');
      } catch (fileError) {
        print('❌ [VideoShare] File share also failed: $fileError');
        rethrow;
      }
    }
  }

  /// Copy caption to clipboard
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    print('📋 [VideoClipboard] Caption copied');
  }

  /// Open TikTok app
  static Future<bool> openTikTok() async {
    try {
      // Try to open TikTok app
      final tiktokUrl = Uri.parse('tiktok://');
      
      if (await canLaunchUrl(tiktokUrl)) {
        await launchUrl(tiktokUrl, mode: LaunchMode.externalApplication);
        print('✅ [TikTok] App opened');
        return true;
      } else {
        // Fallback to web
        final webUrl = Uri.parse('https://www.tiktok.com/');
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        print('✅ [TikTok] Web opened');
        return true;
      }
    } catch (e) {
      print('❌ [TikTok] Error: $e');
      return false;
    }
  }

  /// Open Instagram app
  static Future<bool> openInstagram() async {
    try {
      // Try to open Instagram app
      final instagramUrl = Uri.parse('instagram://');
      
      if (await canLaunchUrl(instagramUrl)) {
        await launchUrl(instagramUrl, mode: LaunchMode.externalApplication);
        print('✅ [Instagram] App opened');
        return true;
      } else {
        // Fallback to web
        final webUrl = Uri.parse('https://www.instagram.com/');
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        print('✅ [Instagram] Web opened');
        return true;
      }
    } catch (e) {
      print('❌ [Instagram] Error: $e');
      return false;
    }
  }

  /// Open Facebook app
  static Future<bool> openFacebook() async {
    try {
      // Try to open Facebook app
      final facebookUrl = Uri.parse('fb://');
      
      if (await canLaunchUrl(facebookUrl)) {
        await launchUrl(facebookUrl, mode: LaunchMode.externalApplication);
        print('✅ [Facebook] App opened');
        return true;
      } else {
        // Fallback to web
        final webUrl = Uri.parse('https://www.facebook.com/');
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        print('✅ [Facebook] Web opened');
        return true;
      }
    } catch (e) {
      print('❌ [Facebook] Error: $e');
      return false;
    }
  }

  /// Open Twitter app
  static Future<bool> openTwitter() async {
    try {
      // Try to open Twitter app
      final twitterUrl = Uri.parse('twitter://');
      
      if (await canLaunchUrl(twitterUrl)) {
        await launchUrl(twitterUrl, mode: LaunchMode.externalApplication);
        print('✅ [Twitter] App opened');
        return true;
      } else {
        // Fallback to web
        final webUrl = Uri.parse('https://twitter.com/');
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        print('✅ [Twitter] Web opened');
        return true;
      }
    } catch (e) {
      print('❌ [Twitter] Error: $e');
      return false;
    }
  }

  /// Open YouTube app
  static Future<bool> openYouTube() async {
    try {
      // Try to open YouTube app
      final youtubeUrl = Uri.parse('youtube://');
      
      if (await canLaunchUrl(youtubeUrl)) {
        await launchUrl(youtubeUrl, mode: LaunchMode.externalApplication);
        print('✅ [YouTube] App opened');
        return true;
      } else {
        // Fallback to web
        final webUrl = Uri.parse('https://www.youtube.com/');
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        print('✅ [YouTube] Web opened');
        return true;
      }
    } catch (e) {
      print('❌ [YouTube] Error: $e');
      return false;
    }
  }

  /// Complete workflow: Save to gallery + Copy caption + Open social media
  static Future<bool> shareToSocialMedia({
    required BuildContext context,
    required String videoUrl,
    required String caption,
    required VideoSocialPlatform platform,
  }) async {
    try {
      // 1. Save video to gallery
      print('📱 [VideoSocial] Step 1: Saving to gallery...');
      final saved = await saveToGallery(videoUrl);
      
      if (!saved) {
        throw Exception('Failed to save video to gallery');
      }
      
      // 2. Copy caption to clipboard
      print('📱 [VideoSocial] Step 2: Copying caption...');
      await copyToClipboard(caption);
      
      // 3. Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ Vidéo sauvegardée dans la galerie'),
                Text('📋 Caption copié (Ctrl+V pour coller)'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
      
      // 4. Wait a bit for user to see the message
      await Future.delayed(Duration(milliseconds: 1500));
      
      // 5. Open social media app
      print('📱 [VideoSocial] Step 3: Opening ${platform.name}...');
      bool opened = false;
      
      switch (platform) {
        case VideoSocialPlatform.tiktok:
          opened = await openTikTok();
          break;
        case VideoSocialPlatform.instagram:
          opened = await openInstagram();
          break;
        case VideoSocialPlatform.facebook:
          opened = await openFacebook();
          break;
        case VideoSocialPlatform.twitter:
          opened = await openTwitter();
          break;
        case VideoSocialPlatform.youtube:
          opened = await openYouTube();
          break;
      }
      
      if (!opened) {
        throw Exception('Failed to open ${platform.name}');
      }
      
      print('✅ [VideoSocial] Workflow completed successfully');
      return true;
    } catch (e) {
      print('❌ [VideoSocial] Error: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      return false;
    }
  }

  /// Show share options dialog
  static Future<void> showShareDialog({
    required BuildContext context,
    required String videoUrl,
    String? caption,
  }) async {
    final cs = Theme.of(context).colorScheme;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Partager la vidéo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              SizedBox(height: 16),
              
              // Save to gallery
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                leading: Icon(Icons.video_library, color: cs.primary, size: 24),
                title: Text('Sauvegarder', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text('Télécharger sur votre téléphone', style: TextStyle(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(context);
                  final saved = await saveToGallery(videoUrl);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(saved 
                          ? '✅ Vidéo sauvegardée' 
                          : '❌ Erreur'),
                        backgroundColor: saved ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
              ),
              
              Divider(height: 8),
              
              // Share via native dialog
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                leading: Icon(Icons.share, color: cs.primary, size: 24),
                title: Text('Partager', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text('Menu natif', style: TextStyle(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await shareVideo(videoUrl, caption: caption);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Partage ouvert'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Erreur partage: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              
              Divider(height: 8),
              
              // TikTok
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                leading: Icon(Icons.music_video, color: Colors.black, size: 24),
                title: Text('TikTok', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text('Galerie + Caption + Ouvre l\'app', style: TextStyle(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(context);
                  if (caption != null) {
                    await shareToSocialMedia(
                      context: context,
                      videoUrl: videoUrl,
                      caption: caption,
                      platform: VideoSocialPlatform.tiktok,
                    );
                  }
                },
              ),
              
              // Instagram
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                leading: Icon(Icons.camera_alt, color: Color(0xFFE4405F), size: 24),
                title: Text('Instagram', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text('Galerie + Caption + Ouvre l\'app', style: TextStyle(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(context);
                  if (caption != null) {
                    await shareToSocialMedia(
                      context: context,
                      videoUrl: videoUrl,
                      caption: caption,
                      platform: VideoSocialPlatform.instagram,
                    );
                  }
                },
              ),
              
              // Facebook
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                leading: Icon(Icons.facebook, color: Color(0xFF1877F2), size: 24),
                title: Text('Facebook', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text('Galerie + Caption + Ouvre l\'app', style: TextStyle(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(context);
                  if (caption != null) {
                    await shareToSocialMedia(
                      context: context,
                      videoUrl: videoUrl,
                      caption: caption,
                      platform: VideoSocialPlatform.facebook,
                    );
                  }
                },
              ),
              
              // Twitter
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                leading: Icon(Icons.alternate_email, color: Color(0xFF1DA1F2), size: 24),
                title: Text('Twitter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text('Galerie + Caption + Ouvre l\'app', style: TextStyle(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(context);
                  if (caption != null) {
                    await shareToSocialMedia(
                      context: context,
                      videoUrl: videoUrl,
                      caption: caption,
                      platform: VideoSocialPlatform.twitter,
                    );
                  }
                },
              ),
              
              // YouTube
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                leading: Icon(Icons.play_circle, color: Color(0xFFFF0000), size: 24),
                title: Text('YouTube', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text('Galerie + Caption + Ouvre l\'app', style: TextStyle(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(context);
                  if (caption != null) {
                    await shareToSocialMedia(
                      context: context,
                      videoUrl: videoUrl,
                      caption: caption,
                      platform: VideoSocialPlatform.youtube,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum VideoSocialPlatform {
  tiktok,
  instagram,
  facebook,
  twitter,
  youtube,
}
