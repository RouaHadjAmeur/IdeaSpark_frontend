import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class CameraService {
  CameraController? _controller;
  FaceDetector? _faceDetector;
  CameraDescription? _cameraDescription;

  CameraController? get controller => _controller;
  CameraDescription? get cameraDescription => _cameraDescription;

  Future<void> initialize({CameraLensDirection? lensDirection}) async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraDescription = cameras.firstWhere(
          (camera) =>
      camera.lensDirection == (lensDirection ?? CameraLensDirection.back),
      orElse: () => cameras.first,
    );

    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }

    _controller = CameraController(
      _cameraDescription!,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    _faceDetector ??= FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableClassification: false,
        minFaceSize: 0.1,
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    await _controller!.initialize();
  }

  Future<void> toggleCamera() async {
    final lensDirection =
    _cameraDescription?.lensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    await initialize(lensDirection: lensDirection);
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    await _faceDetector?.close();
    _controller = null;
    _faceDetector = null;
  }

  double analyzeLuminosity(CameraImage image) {
    final Uint8List bytes = image.planes[0].bytes;
    int total = 0;
    int count = 0;
    for (int i = 0; i < bytes.length; i += 10) {
      total += bytes[i];
      count++;
    }
    if (count == 0) return 0.5;
    return (total / count) / 255.0;
  }

  Future<List<Face>> detectFaces(CameraImage image) async {
    if (_faceDetector == null || _cameraDescription == null) return [];

    final sensorOrientation = _cameraDescription!.sensorOrientation;
    final bytes = image.planes[0].bytes;

    InputImageRotation imageRotation;
    switch (sensorOrientation) {
      case 90:
        imageRotation = InputImageRotation.rotation90deg;
        break;
      case 180:
        imageRotation = InputImageRotation.rotation180deg;
        break;
      case 270:
        imageRotation = InputImageRotation.rotation270deg;
        break;
      default:
        imageRotation = InputImageRotation.rotation0deg;
    }

    final inputImageData = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: imageRotation,
      format: InputImageFormat.nv21,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: inputImageData,
    );

    try {
      final faces = await _faceDetector!.processImage(inputImage);
      if (kDebugMode) {
        debugPrint('📸 [CameraService] Detection: ${faces.length} faces found');
      }
      return faces;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [CameraService] ML Kit Error: $e');
      }
      return [];
    }
  }
}