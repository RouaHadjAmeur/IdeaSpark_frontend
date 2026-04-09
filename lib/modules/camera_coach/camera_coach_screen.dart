
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:gal/gal.dart';
import 'services/camera_service.dart';
import 'services/tts_service.dart';
import 'services/stability_service.dart';
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
  final StabilityService _stabilityService = StabilityService();
  bool _isInitialized = false;
  double _luminosity = 0.5;
  List<Face> _faces = [];
  bool _isProcessing = false;
  DateTime _lastAnalysis = DateTime.now();
  DateTime _lastSpoken = DateTime.now();

  // TIMER FEATURE
  bool _autoTimerEnabled = false;
  int _countdown = 0;
  bool _isCountingDown = false;

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
    _stabilityService.initialize();
    _startImageStream();
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  void _startCountdown() async {
    if (_isCountingDown) return;
    _isCountingDown = true;
    
    for (int i = 3; i > 0; i--) {
      if (!mounted || !_isCountingDown || !_autoTimerEnabled) break;
      setState(() => _countdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }
    
    if (mounted && _isCountingDown && _autoTimerEnabled && _countdown == 1) {
      setState(() {
        _countdown = 0;
        _isCountingDown = false;
      });
      _takePhoto();
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
        final isFrontCamera = _cameraService.cameraDescription?.lensDirection == CameraLensDirection.front;
        final double lum = _cameraService.analyzeLuminosity(image);
        
        // FEATURE 3: Détection visage uniquement en mode selfie
        List<Face> detectedFaces = [];
        
        if (isFrontCamera) {
          detectedFaces = await _cameraService.detectFaces(image);
        }

        if (mounted) {
             setState(() {
               _luminosity = lum;
               _faces = detectedFaces;
             });

             // Logic for Auto Timer
             bool isFaceCentered = true;
             if (isFrontCamera) {
               if (detectedFaces.isEmpty) {
                 isFaceCentered = false;
               } else {
                 final face = detectedFaces.first;
                 final rect = face.boundingBox;
                 final sensorOrientation = _cameraService.controller?.description.sensorOrientation ?? 0;
                 final isPortrait = sensorOrientation == 90 || sensorOrientation == 270;
                 final previewSize = _cameraService.controller!.value.previewSize!;
                 final imageWidth = isPortrait ? previewSize.height : previewSize.width;
                 final imageHeight = isPortrait ? previewSize.width : previewSize.height;

                 double centerX = (rect.left + rect.width / 2) / imageWidth;
                 final double centerY = (rect.top + rect.height / 2) / imageHeight;
                 centerX = 1.0 - centerX; // Selfie mode

                 final isCenteredX = centerX > 1 / 3 && centerX < 2 / 3;
                 final isCenteredY = centerY > 1 / 3 && centerY < 2 / 3;
                 isFaceCentered = isCenteredX && isCenteredY;
               }
             }

             final bool everythingIsPerfect = _stabilityService.isStable &&
                 (_luminosity >= 0.3 && _luminosity <= 0.7) &&
                 (!isFrontCamera || isFaceCentered);

             if (_autoTimerEnabled && everythingIsPerfect) {
               if (!_isCountingDown && _countdown == 0) {
                 _startCountdown();
               }
             } else {
               if (_isCountingDown || _countdown != 0) {
                 setState(() {
                   _isCountingDown = false;
                   _countdown = 0;
                 });
               }
             }

             // Logic for TTS feedback every 3 seconds
          if (now.difference(_lastSpoken).inSeconds >= 3) {
            String message = "";

            // 1. Priorité à la Stabilité
            if (!_stabilityService.isStable) {
              message = "Stabilise ton téléphone";
            }
            // 2. Priorité à la Luminosité (Fonctionne pour les deux caméras)
            else if (_luminosity < 0.3) {
              message = "Trop sombre, trouve une meilleure lumière";
            } else if (_luminosity > 0.7) {
              message = "Trop de lumière, change d'angle";
            }
            // 3. Visage en dernier (Seulement si stabilité & luminosité OK ET en mode selfie)
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
    _stabilityService.dispose();
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
          // Face Feedback Overlay
          _buildFaceFeedback(),

          // Countdown Overlay
          if (_countdown > 0)
            Center(
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_countdown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 120,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

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

          // FEATURE: Stability Indicator
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 70,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.camera,
                    color: _stabilityService.isStable ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  if (!_stabilityService.isStable) ...[
                    const SizedBox(width: 5),
                    const Text(
                      "Stabilise ton téléphone",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ],
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

                // Auto Timer Toggle
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: Icon(
                      Icons.timer,
                      color: _autoTimerEnabled ? Colors.green : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _autoTimerEnabled = !_autoTimerEnabled;
                        if (!_autoTimerEnabled) {
                          _countdown = 0;
                          _isCountingDown = false;
                        }
                        _ttsService.speak(_autoTimerEnabled ? "Timer automatique activé" : "Timer automatique désactivé");
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
