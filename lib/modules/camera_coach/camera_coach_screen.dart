
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:gal/gal.dart';
import 'services/camera_service.dart';
import 'services/tts_service.dart';
import 'widgets/rule_of_thirds_overlay.dart';
import 'widgets/luminosity_indicator.dart';

class CameraCoachScreen extends StatefulWidget {
  const CameraCoachScreen({super.key});

  @override
  State<CameraCoachScreen> createState() => _CameraCoachScreenState();
}

class _CameraCoachScreenState extends State<CameraCoachScreen> with SingleTickerProviderStateMixin {
  final CameraService _cameraService = CameraService();
  final TtsService _ttsService = TtsService();
  bool _isInitialized = false;
  double _luminosity = 0.5;
  List<Face> _faces = [];
  bool _isProcessing = false;
  DateTime _lastAnalysis = DateTime.now();
  DateTime _lastSpoken = DateTime.now();

  // FEATURE 1 & 2
  bool _isVideoMode = false;
  bool _isRecording = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _initialize();
  }

  Future<void> _initialize() async {
    await _cameraService.initialize();
    await _ttsService.initialize();
    _startImageStream();
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  void _startImageStream() {
    if (_cameraService.controller == null) return;

    _cameraService.controller!.startImageStream((CameraImage image) async {
      if (_isProcessing) return;

      final now = DateTime.now();
      if (now.difference(_lastAnalysis).inMilliseconds < 500) return;

      _isProcessing = true;
      _lastAnalysis = now;

      try {
        final double lum = _cameraService.analyzeLuminosity(image);
        
        // FEATURE 3: Détection visage uniquement en mode selfie
        List<Face> detectedFaces = [];
        final isFrontCamera = _cameraService.cameraDescription?.lensDirection == CameraLensDirection.front;
        
        if (isFrontCamera) {
          detectedFaces = await _cameraService.detectFaces(image);
        }

        if (mounted) {
          setState(() {
            _luminosity = lum;
            _faces = detectedFaces;
          });

          // Logic for TTS feedback every 3 seconds
          if (now.difference(_lastSpoken).inSeconds >= 3) {
            String message = "";

            // 1. Priorité à la Luminosité (Fonctionne pour les deux caméras)
            if (_luminosity < 0.3) {
              message = "Trop sombre, trouve une meilleure lumière";
            } else if (_luminosity > 0.7) {
              message = "Trop de lumière, change d'angle";
            }
            // 2. Visage en second (Seulement si luminosité OK ET en mode selfie)
            else if (isFrontCamera) {
              if (detectedFaces.isEmpty) {
                message = "Aucun visage détecté";
              } else {
                final face = detectedFaces.first;
                final rect = face.boundingBox;
                final sensorOrientation =
                    _cameraService.controller?.description.sensorOrientation ??
                        0;
                final isPortrait =
                    sensorOrientation == 90 || sensorOrientation == 270;
                final previewSize =
                    _cameraService.controller!.value.previewSize!;
                final imageWidth =
                    isPortrait ? previewSize.height : previewSize.width;
                final imageHeight =
                    isPortrait ? previewSize.width : previewSize.height;

                double centerX = (rect.left + rect.width / 2) / imageWidth;
                final double centerY =
                    (rect.top + rect.height / 2) / imageHeight;

                centerX = 1.0 - centerX; // Selfie mode

                final isCenteredX = centerX > 1 / 3 && centerX < 2 / 3;
                final isCenteredY = centerY > 1 / 3 && centerY < 2 / 3;

                if (isCenteredX && isCenteredY) {
                  message = "Parfait";
                } else {
                  message = "Centre ton visage";
                }
              }
            }

            if (message.isNotEmpty) {
              _ttsService.speak(message);
              _lastSpoken = now;
            }
          }
        }
      } catch (e) {
        // ignore errors
      } finally {
        _isProcessing = false;
      }
    });
  }

  Future<void> _takePhoto() async {
    try {
      final XFile file = await _cameraService.controller!.takePicture();
      await Gal.putImage(file.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo sauvegardée ✅')),
        );
      }
    } catch (e) {
      print('Error taking photo: $e');
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      try {
        final XFile file = await _cameraService.controller!.stopVideoRecording();
        setState(() => _isRecording = false);
        await Gal.putVideo(file.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vidéo sauvegardée ✅')),
          );
        }
      } catch (e) {
        print('Error stopping video: $e');
      }
    } else {
      try {
        await _cameraService.controller!.startVideoRecording();
        setState(() => _isRecording = true);
      } catch (e) {
        print('Error starting video: $e');
      }
    }
  }

  Future<void> _toggleCamera() async {
    if (!_isInitialized) return;
    _isProcessing = false;

    if (_cameraService.controller?.value.isStreamingImages ?? false) {
      await _cameraService.controller?.stopImageStream();
    }

    await _cameraService.toggleCamera();
    
    // Annonce vocale du nouveau mode de caméra
    final isFront = _cameraService.cameraDescription?.lensDirection == CameraLensDirection.front;
    _ttsService.speak(isFront ? "Mode selfie" : "Mode normal");
    
    _startImageStream();

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _ttsService.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildFaceFeedback() {
    // FEATURE 3: Feedback uniquement en selfie
    final isFrontCamera = _cameraService.cameraDescription?.lensDirection == CameraLensDirection.front;
    if (!isFrontCamera) return const SizedBox.shrink();

    if (_faces.isEmpty) {
      return _buildFeedbackText("Aucun visage détecté", Colors.red);
    }

    final face = _faces.first;
    final rect = face.boundingBox;

    final sensorOrientation =
        _cameraService.controller?.description.sensorOrientation ?? 0;
    final isPortrait = sensorOrientation == 90 || sensorOrientation == 270;

    final previewSize = _cameraService.controller!.value.previewSize!;
    final imageWidth = isPortrait ? previewSize.height : previewSize.width;
    final imageHeight = isPortrait ? previewSize.width : previewSize.height;

    double centerX = (rect.left + rect.width / 2) / imageWidth;
    final double centerY = (rect.top + rect.height / 2) / imageHeight;

    centerX = 1.0 - centerX; // Selfie mode

    final isCenteredX = centerX > 1 / 3 && centerX < 2 / 3;
    final isCenteredY = centerY > 1 / 3 && centerY < 2 / 3;

    if (isCenteredX && isCenteredY) {
      return _buildFeedbackText("Parfait 👍", Colors.green);
    } else {
      return _buildFeedbackText("Centre ton visage", Colors.orange);
    }
  }

  Widget _buildFeedbackText(String text, Color color) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _cameraService.controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraService.controller!),
          const RuleOfThirdsOverlay(),
          _buildFaceFeedback(),
          LuminosityIndicator(luminosity: _luminosity),
          
          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => context.pop(),
            ),
          ),
          
          // Toggle Camera Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 15,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 28),
                onPressed: _toggleCamera,
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // FEATURE 1: Toggle Photo/Video
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: Icon(
                      _isVideoMode ? Icons.photo_camera : Icons.videocam,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isVideoMode = !_isVideoMode;
                        _ttsService.speak(_isVideoMode ? "Mode vidéo activé" : "Mode photo activé");
                      });
                    },
                  ),
                ),

                // FEATURE 2: Capture Button
                GestureDetector(
                  onTap: _isVideoMode ? _toggleRecording : _takePhoto,
                  child: ScaleTransition(
                    scale: _isRecording 
                        ? Tween(begin: 1.0, end: 1.1).animate(_pulseController)
                        : const AlwaysStoppedAnimation(1.0),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: _isVideoMode ? Colors.red : Colors.white,
                      ),
                      child: _isRecording 
                          ? const Center(child: Icon(Icons.stop, color: Colors.white, size: 40))
                          : null,
                    ),
                  ),
                ),

                // Placeholder for symmetry
                const SizedBox(width: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
