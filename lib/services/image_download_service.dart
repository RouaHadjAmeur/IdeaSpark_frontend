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

class ImageDownloadService {
  /// Download image from URL and save to temporary directory
  static Future<File?> downloadImage(String imageUrl) async {
    try {
      debugPrint('📥 [Download] Starting download: $imageUrl');
      
      final response = await http.get(Uri.parse(imageUrl));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to download image: ${response.statusCode}');
      }
      
      final bytes = response.bodyBytes;
      final tempDir = await getTemporaryDirectory();
      final fileName = 'ideaspark_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${tempDir.path}/$fileName');
      
      await file.writeAsBytes(bytes);
      
      debugPrint('✅ [Download] Image saved to: ${file.path}');
      return file;
    } catch (e) {
      debugPrint('❌ [Download] Error: $e');
      return null;
    }
  }

  /// Save image to gallery (requires permission)
  static Future<bool> saveToGallery(String imageUrl) async {
    try {
      debugPrint('💾 [Gallery] Requesting permission...');
      
      // Request storage permission
      final status = await Permission.photos.request();
      
      if (!status.isGranted) {
        debugPrint('❌ [Gallery] Permission denied');
        return false;
      }
      
      debugPrint('📥 [Gallery] Downloading image...');
      final response = await http.get(Uri.parse(imageUrl));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }
      
      final bytes = response.bodyBytes;
      
      // Save to temporary file first
      final tempDir = await getTemporaryDirectory();
      final fileName = 'ideaspark_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(bytes);
      
      debugPrint('💾 [Gallery] Saving to gallery...');
      // Use Gal to save to gallery
      await Gal.putImage(tempFile.path);
      
      debugPrint('✅ [Gallery] Saved successfully');
      return true;
    } catch (e) {
      debugPrint('❌ [Gallery] Error: $e');
      return false;
    }
  }

  /// Share image using native share dialog
  static Future<void> shareImage(String imageUrl, {String? caption}) async {
    try {
      debugPrint('📤 [Share] Downloading image...');
      
      final file = await downloadImage(imageUrl);
      
      if (file == null) {
        throw Exception('Failed to download image');
      }
      
      debugPrint('📤 [Share] Opening share dialog...');
      
      if (caption != null && caption.isNotEmpty) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: caption,
        );
      } else {
        await Share.shareXFiles([XFile(file.path)]);
      }
      
      debugPrint('✅ [Share] Share dialog opened');
    } catch (e) {
      debugPrint('❌ [Share] Error: $e');
      rethrow;
    }
  }

  /// Copy caption to clipboard
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    debugPrint('📋 [Clipboard] Caption copied');
  }

  /// Open Instagram app
  static Future<bool> openInstagram() async {
    try {
      // Try to open Instagram app
      final instagramUrl = Uri.parse('instagram://');
      
      if (await canLaunchUrl(instagramUrl)) {
        await launchUrl(instagramUrl, mode: LaunchMode.externalApplication);
        debugPrint('✅ [Instagram] App opened');
        return true;
      } else {
        // Fallback to web
        final webUrl = Uri.parse('https://www.instagram.com/');
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        debugPrint('✅ [Instagram] Web opened');
        return true;
      }
    } catch (e) {
      debugPrint('❌ [Instagram] Error: $e');
      return false;
    }
  }

  /// Open TikTok app
  static Future<bool> openTikTok() async {
    try {
      // Try to open TikTok app
      final tiktokUrl = Uri.parse('tiktok://');
      
      if (await canLaunchUrl(tiktokUrl)) {
        await launchUrl(tiktokUrl, mode: LaunchMode.externalApplication);
        debugPrint('✅ [TikTok] App opened');
        return true;
      } else {
        // Fallback to web
        final webUrl = Uri.parse('https://www.tiktok.com/');
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        debugPrint('✅ [TikTok] Web opened');
        return true;
      }
    } catch (e) {
      debugPrint('❌ [TikTok] Error: $e');
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
        debugPrint('✅ [Facebook] App opened');
        return true;
      } else {
        // Fallback to web
        final webUrl = Uri.parse('https://www.facebook.com/');
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        debugPrint('✅ [Facebook] Web opened');
        return true;
      }
    } catch (e) {
      debugPrint('❌ [Facebook] Error: $e');
      return false;
    }
  }

  /// Complete workflow: Save to gallery + Copy caption + Open social media
  static Future<bool> shareToSocialMedia({
    required BuildContext context,
    required String imageUrl,
    required String caption,
    required SocialPlatform platform,
  }) async {
    try {
      // 1. Save image to gallery
      debugPrint('📱 [Social] Step 1: Saving to gallery...');
      final saved = await saveToGallery(imageUrl);
      
      if (!saved) {
        throw Exception('Failed to save image to gallery');
      }
      
      // 2. Copy caption to clipboard
      debugPrint('📱 [Social] Step 2: Copying caption...');
      await copyToClipboard(caption);
      
      // 3. Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ Image sauvegardée dans la galerie'),
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
      debugPrint('📱 [Social] Step 3: Opening ${platform.name}...');
      bool opened = false;
      
      switch (platform) {
        case SocialPlatform.instagram:
          opened = await openInstagram();
          break;
        case SocialPlatform.tiktok:
          opened = await openTikTok();
          break;
        case SocialPlatform.facebook:
          opened = await openFacebook();
          break;
      }
      
      if (!opened) {
        throw Exception('Failed to open ${platform.name}');
      }
      
      debugPrint('✅ [Social] Workflow completed successfully');
      return true;
    } catch (e) {
      debugPrint('❌ [Social] Error: $e');
      
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
    required String imageUrl,
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
                'Partager l\'image',
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
                leading: Icon(Icons.photo_library, color: cs.primary, size: 24),
                title: Text('Sauvegarder', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text('Télécharger sur votre téléphone', style: TextStyle(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(context);
                  final saved = await saveToGallery(imageUrl);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(saved 
                          ? '✅ Image sauvegardée' 
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
                  await shareImage(imageUrl, caption: caption);
                },
              ),
              
              Divider(height: 8),
              
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
                      imageUrl: imageUrl,
                      caption: caption,
                      platform: SocialPlatform.instagram,
                    );
                  }
                },
              ),
              
              // TikTok
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                leading: Icon(Icons.music_note, color: Colors.black, size: 24),
                title: Text('TikTok', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text('Galerie + Caption + Ouvre l\'app', style: TextStyle(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(context);
                  if (caption != null) {
                    await shareToSocialMedia(
                      context: context,
                      imageUrl: imageUrl,
                      caption: caption,
                      platform: SocialPlatform.tiktok,
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
                      imageUrl: imageUrl,
                      caption: caption,
                      platform: SocialPlatform.facebook,
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

enum SocialPlatform {
  instagram,
  tiktok,
  facebook,
}
