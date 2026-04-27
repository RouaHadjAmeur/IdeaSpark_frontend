import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '../models/edited_image.dart';

class ImageEditorService {
  /// Appliquer un filtre à une image
  static Future<Uint8List> applyFilter(Uint8List imageData, ImageFilter filter) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) throw Exception('Impossible de décoder l\'image');

      img.Image filteredImage;

      switch (filter) {
        case ImageFilter.blackAndWhite:
          filteredImage = img.grayscale(image);
          break;
        case ImageFilter.sepia:
          filteredImage = img.sepia(image);
          break;
        case ImageFilter.vintage:
          // Effet vintage: sépia + contraste réduit + vignette
          filteredImage = img.sepia(image);
          filteredImage = img.contrast(filteredImage, contrast: 0.8);
          filteredImage = _applyVignette(filteredImage);
          break;
        case ImageFilter.cool:
          // Filtre froid: réduire les rouges, augmenter les bleus
          filteredImage = img.adjustColor(image, 
            saturation: 1.1,
            hue: 0.1,
          );
          break;
        case ImageFilter.warm:
          // Filtre chaud: augmenter les rouges/oranges
          filteredImage = img.adjustColor(image, 
            saturation: 1.2,
            hue: -0.1,
          );
          break;
        case ImageFilter.bright:
          // Plus lumineux
          filteredImage = img.adjustColor(image, brightness: 1.2);
          break;
        case ImageFilter.dark:
          // Plus sombre
          filteredImage = img.adjustColor(image, brightness: 0.8);
          break;
        case ImageFilter.none:
        default:
          filteredImage = image;
          break;
      }

      return Uint8List.fromList(img.encodePng(filteredImage));
    } catch (e) {
      print('❌ [ImageEditor] Filter error: $e');
      rethrow;
    }
  }

  /// Ajouter un cadre à une image
  static Future<Uint8List> addFrame(
    Uint8List imageData,
    ImageFrame frame,
    Color frameColor,
  ) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) throw Exception('Impossible de décoder l\'image');

      img.Image framedImage;

      switch (frame) {
        case ImageFrame.simple:
          framedImage = _addSimpleFrame(image, frameColor, 20);
          break;
        case ImageFrame.rounded:
          framedImage = _addRoundedFrame(image, frameColor, 20, 30);
          break;
        case ImageFrame.shadow:
          framedImage = _addShadowFrame(image, frameColor, 20);
          break;
        case ImageFrame.polaroid:
          framedImage = _addPolaroidFrame(image);
          break;
        case ImageFrame.film:
          framedImage = _addFilmFrame(image);
          break;
        case ImageFrame.none:
        default:
          framedImage = image;
          break;
      }

      return Uint8List.fromList(img.encodePng(framedImage));
    } catch (e) {
      print('❌ [ImageEditor] Frame error: $e');
      rethrow;
    }
  }

  /// Ajouter du texte sur une image
  static Future<Uint8List> addText(
    Uint8List imageData,
    List<TextOverlay> textOverlays,
  ) async {
    try {
      // Décoder l'image
      final codec = await ui.instantiateImageCodec(imageData);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Créer un canvas pour dessiner
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Dessiner l'image de base
      canvas.drawImage(image, Offset.zero, Paint());

      // Ajouter chaque texte
      for (final textOverlay in textOverlays) {
        await _drawTextOnCanvas(canvas, textOverlay, image.width, image.height);
      }

      // Convertir en image
      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(image.width, image.height);
      final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);

      return byteData!.buffer.asUint8List();
    } catch (e) {
      print('❌ [ImageEditor] Text error: $e');
      rethrow;
    }
  }

  /// Redimensionner une image
  static Future<Uint8List> resizeImage(
    Uint8List imageData,
    int targetWidth,
    int targetHeight,
  ) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) throw Exception('Impossible de décoder l\'image');

      final resizedImage = img.copyResize(
        image,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.cubic,
      );

      return Uint8List.fromList(img.encodePng(resizedImage));
    } catch (e) {
      print('❌ [ImageEditor] Resize error: $e');
      rethrow;
    }
  }

  /// Appliquer des effets à une image
  static Future<Uint8List> applyEffects(
    Uint8List imageData,
    List<ImageEffect> effects,
  ) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) throw Exception('Impossible de décoder l\'image');

      img.Image effectImage = image;

      for (final effect in effects) {
        switch (effect) {
          case ImageEffect.blur:
            effectImage = img.gaussianBlur(effectImage, radius: 2);
            break;
          case ImageEffect.shadow:
            effectImage = _addDropShadow(effectImage);
            break;
          case ImageEffect.glow:
            effectImage = _addGlow(effectImage);
            break;
          case ImageEffect.emboss:
            effectImage = img.emboss(effectImage);
            break;
          case ImageEffect.sharpen:
            // Utiliser un filtre de netteté simple
            effectImage = img.contrast(effectImage, contrast: 1.2);
            break;
          case ImageEffect.none:
          default:
            break;
        }
      }

      return Uint8List.fromList(img.encodePng(effectImage));
    } catch (e) {
      print('❌ [ImageEditor] Effects error: $e');
      rethrow;
    }
  }

  /// Traitement complet d'une image éditée
  static Future<Uint8List> processEditedImage(EditedImage editedImage) async {
    try {
      // Charger l'image originale
      final response = await NetworkAssetBundle(Uri.parse(editedImage.originalUrl)).load('');
      Uint8List imageData = response.buffer.asUint8List();

      // Appliquer le filtre
      if (editedImage.filter != ImageFilter.none) {
        imageData = await applyFilter(imageData, editedImage.filter);
      }

      // Appliquer les effets
      if (editedImage.effects.isNotEmpty) {
        imageData = await applyEffects(imageData, editedImage.effects);
      }

      // Redimensionner si nécessaire
      if (editedImage.resizedWidth != null && editedImage.resizedHeight != null) {
        imageData = await resizeImage(
          imageData,
          editedImage.resizedWidth!,
          editedImage.resizedHeight!,
        );
      }

      // Ajouter le cadre
      if (editedImage.frame != ImageFrame.none) {
        final frameColor = Color(editedImage.frameColor ?? 0xFF000000);
        imageData = await addFrame(imageData, editedImage.frame, frameColor);
      }

      // Ajouter le texte
      if (editedImage.textOverlays.isNotEmpty) {
        imageData = await addText(imageData, editedImage.textOverlays);
      }

      return imageData;
    } catch (e) {
      print('❌ [ImageEditor] Process error: $e');
      rethrow;
    }
  }

  // Méthodes privées pour les effets spéciaux

  static img.Image _applyVignette(img.Image image) {
    final centerX = image.width / 2;
    final centerY = image.height / 2;
    final maxDistance = math.sqrt(centerX * centerX + centerY * centerY);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final distance = math.sqrt((x - centerX) * (x - centerX) + (y - centerY) * (y - centerY));
        final vignette = 1.0 - (distance / maxDistance) * 0.5;
        
        final pixel = image.getPixel(x, y);
        final r = (pixel.r * vignette).round().clamp(0, 255);
        final g = (pixel.g * vignette).round().clamp(0, 255);
        final b = (pixel.b * vignette).round().clamp(0, 255);
        
        image.setPixel(x, y, img.ColorRgb8(r, g, b));
      }
    }
    return image;
  }

  static img.Image _addSimpleFrame(img.Image image, Color color, int thickness) {
    final frameColor = img.ColorRgb8(color.red, color.green, color.blue);
    return img.drawRect(
      image,
      x1: 0,
      y1: 0,
      x2: image.width - 1,
      y2: image.height - 1,
      color: frameColor,
      thickness: thickness,
    );
  }

  static img.Image _addRoundedFrame(img.Image image, Color color, int thickness, int radius) {
    // Implémentation simplifiée - dans une vraie app, utiliser une librairie plus avancée
    return _addSimpleFrame(image, color, thickness);
  }

  static img.Image _addShadowFrame(img.Image image, Color color, int thickness) {
    // Ajouter une ombre portée
    final shadowImage = img.copyCrop(image, x: 0, y: 0, width: image.width, height: image.height);
    final framedImage = _addSimpleFrame(image, color, thickness);
    
    // Combiner l'image avec l'ombre (implémentation simplifiée)
    return framedImage;
  }

  static img.Image _addPolaroidFrame(img.Image image) {
    // Cadre style Polaroid avec bordure blanche épaisse en bas
    final frameColor = img.ColorRgb8(255, 255, 255);
    final framedImage = img.copyExpandCanvas(
      image,
      newWidth: image.width + 40,
      newHeight: image.height + 80,
      position: img.ExpandCanvasPosition.topLeft,
      backgroundColor: frameColor,
    );
    return framedImage;
  }

  static img.Image _addFilmFrame(img.Image image) {
    // Cadre style pellicule photo avec perforations
    final frameColor = img.ColorRgb8(0, 0, 0);
    return img.drawRect(
      image,
      x1: 0,
      y1: 0,
      x2: image.width - 1,
      y2: image.height - 1,
      color: frameColor,
      thickness: 15,
    );
  }

  static img.Image _addDropShadow(img.Image image) {
    // Effet d'ombre portée (implémentation simplifiée)
    return image;
  }

  static img.Image _addGlow(img.Image image) {
    // Effet de lueur (implémentation simplifiée)
    return img.gaussianBlur(image, radius: 1);
  }

  static Future<void> _drawTextOnCanvas(
    Canvas canvas,
    TextOverlay textOverlay,
    int imageWidth,
    int imageHeight,
  ) async {
    final textStyle = TextStyle(
      fontSize: textOverlay.fontSize,
      fontFamily: textOverlay.fontFamily,
      color: Color(textOverlay.color),
      fontWeight: textOverlay.bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: textOverlay.italic ? FontStyle.italic : FontStyle.normal,
    );

    final textSpan = TextSpan(text: textOverlay.text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Calculer la position
    final x = textOverlay.x * imageWidth - (textPainter.width / 2);
    final y = textOverlay.y * imageHeight - (textPainter.height / 2);

    // Sauvegarder l'état du canvas
    canvas.save();

    // Appliquer la rotation si nécessaire
    if (textOverlay.rotation != 0) {
      canvas.translate(x + textPainter.width / 2, y + textPainter.height / 2);
      canvas.rotate(textOverlay.rotation * math.pi / 180);
      canvas.translate(-textPainter.width / 2, -textPainter.height / 2);
      textPainter.paint(canvas, Offset.zero);
    } else {
      textPainter.paint(canvas, Offset(x, y));
    }

    // Restaurer l'état du canvas
    canvas.restore();
  }
}