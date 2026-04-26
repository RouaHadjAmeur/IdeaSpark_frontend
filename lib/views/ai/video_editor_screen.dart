import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/video_edit.dart';
import '../../services/video_editor_service.dart';
import 'edited_videos_history_screen.dart';

class VideoEditorScreen extends StatefulWidget {
  final String videoPath;
  final String? videoId;

  const VideoEditorScreen({
    super.key,
    required this.videoPath,
    this.videoId,
  });

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  VideoPlayerController? _controller;
  AudioPlayer? _audioPlayer;
  VideoEdit? _videoEdit;
  bool _isProcessing = false;
  int _selectedTabIndex = 0;
  bool _isPreviewMode = false;
  bool _isMusicPlaying = false;
  String? _currentPlayingMusic;

  // Controllers pour le texte
  final _textController = TextEditingController();
  Duration _textStartTime = Duration.zero;
  Duration _textEndTime = const Duration(seconds: 5);

  // Musique sélectionnée
  VideoMusic? _selectedMusic;

  // Vidéos de test disponibles
  static const List<Map<String, String>> testVideos = [
    {
      'name': 'Vidéo Test Courte',
      'url': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
      'duration': '0:30',
    },
    {
      'name': 'Vidéo Test Nature',
      'url': 'https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4',
      'duration': '0:13',
    },
  ];

  // Musiques populaires comme dans les stories
  static const List<Map<String, String>> testMusic = [
    {
      'name': 'Chill Vibes',
      'artist': 'Lofi Hip Hop',
      'url': 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
      'genre': 'Chill',
      'duration': '0:30',
    },
    {
      'name': 'Summer Vibes',
      'artist': 'Tropical House',
      'url': 'https://commondatastorage.googleapis.com/codeskulptor-demos/DDR_assets/Kangaroo_MusiQue_-_The_Neverwritten_Role_Playing_Game.mp3',
      'genre': 'Electronic',
      'duration': '0:45',
    },
    {
      'name': 'Upbeat Energy',
      'artist': 'Pop Hits',
      'url': 'https://commondatastorage.googleapis.com/codeskulptor-assets/Epoq-Lepidoptera.ogg',
      'genre': 'Pop',
      'duration': '0:35',
    },
    {
      'name': 'Aesthetic Mood',
      'artist': 'Indie Pop',
      'url': 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
      'genre': 'Indie',
      'duration': '0:40',
    },
    {
      'name': 'Motivational Beat',
      'artist': 'Workout Mix',
      'url': 'https://commondatastorage.googleapis.com/codeskulptor-demos/DDR_assets/Kangaroo_MusiQue_-_The_Neverwritten_Role_Playing_Game.mp3',
      'genre': 'Energetic',
      'duration': '0:50',
    },
    {
      'name': 'Dreamy Nights',
      'artist': 'Ambient',
      'url': 'https://commondatastorage.googleapis.com/codeskulptor-assets/Epoq-Lepidoptera.ogg',
      'genre': 'Ambient',
      'duration': '0:55',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.videoPath.isNotEmpty) {
      _initializeVideo();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _audioPlayer?.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      VideoPlayerController controller;
      if (widget.videoPath.startsWith('http')) {
        controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
      } else {
        controller = VideoPlayerController.file(File(widget.videoPath));
      }
      
      _controller = controller;
      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _videoEdit = VideoEdit(
            id: widget.videoId ?? const Uuid().v4(),
            originalVideoPath: widget.videoPath,
            createdAt: DateTime.now(),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _createDemoMode() {
    setState(() {
      _videoEdit = VideoEdit(
        id: const Uuid().v4(),
        originalVideoPath: 'demo://video-editor-test',
        createdAt: DateTime.now(),
      );
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎬 Mode démo activé - Vous pouvez tester l\'édition!'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadTestVideo(String url) async {
    try {
      setState(() {
        _isProcessing = true;
      });
      
      await _controller?.dispose();
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      
      await _controller!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout lors du chargement de la vidéo');
        },
      );
      
      if (mounted) {
        setState(() {
          _videoEdit = VideoEdit(
            id: const Uuid().v4(),
            originalVideoPath: url,
            createdAt: DateTime.now(),
          );
          _isProcessing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Vidéo de test chargée!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur chargement vidéo: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _importFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
      
      if (video != null) {
        await _controller?.dispose();
        _controller = VideoPlayerController.file(File(video.path));
        await _controller!.initialize();
        
        if (mounted) {
          setState(() {
            _videoEdit = VideoEdit(
              id: const Uuid().v4(),
              originalVideoPath: video.path,
              createdAt: DateTime.now(),
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addTextOverlay() {
    if (_textController.text.trim().isEmpty) return;

    final textOverlay = VideoTextOverlay(
      text: _textController.text.trim(),
      startTime: _textStartTime,
      endTime: _textEndTime,
      x: 0.5,
      y: 0.5,
      fontSize: 24.0,
      color: Colors.white.value,
    );

    setState(() {
      if (_videoEdit != null) {
        final currentOverlays = List<VideoTextOverlay>.from(_videoEdit!.textOverlays);
        currentOverlays.add(textOverlay);
        _videoEdit = _videoEdit!.copyWith(textOverlays: currentOverlays);
      }
    });

    _textController.clear();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Texte ajouté!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _selectMusic(VideoMusic music) {
    setState(() {
      _selectedMusic = music;
      if (_videoEdit != null) {
        _videoEdit = _videoEdit!.copyWith(music: music);
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎵 ${music.name} sélectionnée'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _playMusic(String musicUrl, String musicName) async {
    try {
      if (_audioPlayer == null) {
        _audioPlayer = AudioPlayer();
      }

      // Arrêter la musique actuelle si elle joue
      if (_isMusicPlaying) {
        await _audioPlayer!.stop();
      }

      // Jouer la nouvelle musique
      await _audioPlayer!.play(UrlSource(musicUrl));
      
      setState(() {
        _isMusicPlaying = true;
        _currentPlayingMusic = musicName;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎵 Lecture de $musicName'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );

      // Écouter la fin de la musique
      _audioPlayer!.onPlayerComplete.listen((event) {
        setState(() {
          _isMusicPlaying = false;
          _currentPlayingMusic = null;
        });
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lecture musique: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopMusic() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
        setState(() {
          _isMusicPlaying = false;
          _currentPlayingMusic = null;
        });
      }
    } catch (e) {
      print('Erreur arrêt musique: $e');
    }
  }

  Future<void> _saveToHistory() async {
    if (_videoEdit == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingVideos = prefs.getStringList('edited_videos') ?? [];
      
      final videoToSave = {
        'id': _videoEdit!.id,
        'originalVideoPath': _videoEdit!.originalVideoPath,
        'createdAt': _videoEdit!.createdAt.toIso8601String(),
        'textOverlays': _videoEdit!.textOverlays.map((t) => {
          'text': t.text,
          'startTime': t.startTime.inMilliseconds,
          'endTime': t.endTime.inMilliseconds,
        }).toList(),
        'music': _selectedMusic != null ? {
          'name': _selectedMusic!.name,
          'path': _selectedMusic!.path,
        } : null,
      };
      
      existingVideos.add(jsonEncode(videoToSave));
      await prefs.setStringList('edited_videos', existingVideos);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Vidéo sauvegardée!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _finishEditing() async {
    await _saveToHistory();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        border: Border.all(color: cs.outlineVariant),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.chevron_left_rounded, size: 22, color: cs.onSurface),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Éditeur Vidéo',
                          style: GoogleFonts.syne(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          'Créez et éditez vos vidéos',
                          style: TextStyle(
                            fontSize: 11, 
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Bouton historique
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditedVideosHistoryScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        border: Border.all(color: cs.primary.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.history, size: 20, color: cs.primary),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section vidéo
                    if (_videoEdit == null && _controller == null)
                      _buildVideoSelectionSection(cs)
                    else
                      _buildVideoPreviewSection(cs),

                    const SizedBox(height: 24),

                    // Section édition si vidéo chargée
                    if (_videoEdit != null) ...[
                      _buildEditingSection(cs),
                      const SizedBox(height: 24),
                      _buildActionButtonsSection(cs),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildVideoSelectionSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisissez votre vidéo',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        
        // Mode démo
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _createDemoMode(),
            icon: const Icon(Icons.play_circle_outline, size: 20),
            label: const Text('Mode Démo (Sans Vidéo)'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Import depuis galerie
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _importFromGallery,
            icon: const Icon(Icons.video_library, size: 20),
            label: const Text('Importer depuis galerie'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Vidéos de test
        Text(
          'Vidéos de test en ligne',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        
        ...testVideos.map((video) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _loadTestVideo(video['url']!),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_download, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Text('${video['name']} (${video['duration']})'),
              ],
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildVideoPreviewSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aperçu vidéo',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        
        // Aperçu vidéo
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _buildVideoPreviewWidget(cs),
        ),
        
        // Contrôles vidéo si nécessaire
        if (_controller != null && _controller!.value.isInitialized) ...[
          const SizedBox(height: 12),
          _buildVideoControlsWidget(cs),
        ],
      ],
    );
  }

  Widget _buildVideoPreviewWidget(ColorScheme cs) {
    // Mode démo
    if (_videoEdit != null && _videoEdit!.originalVideoPath.startsWith('demo://')) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary.withOpacity(0.1),
              cs.secondary.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.primary.withOpacity(0.3)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Icône de lecture
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 30,
              ),
            ),
            
            // Indicateur mode démo
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '🎬 MODE DÉMO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            // Indicateur des modifications
            if (_videoEdit!.textOverlays.isNotEmpty || _videoEdit!.music != null)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_videoEdit!.textOverlays.isNotEmpty)
                        Text(
                          '📝 ${_videoEdit!.textOverlays.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      if (_videoEdit!.music != null)
                        Text(
                          '🎵 ${_videoEdit!.music!.name}',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Vidéo réelle
    if (_controller != null && _controller!.value.isInitialized) {
      return Container(
        width: double.infinity,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller!),
            
            // Bouton play/pause
            if (!_controller!.value.isPlaying)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _controller!.play();
                    });
                  },
                  icon: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            
            // Indicateur des modifications
            if (_videoEdit != null && (_videoEdit!.textOverlays.isNotEmpty || _videoEdit!.music != null))
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_videoEdit!.textOverlays.isNotEmpty)
                        Text(
                          '📝 ${_videoEdit!.textOverlays.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      if (_videoEdit!.music != null)
                        Text(
                          '🎵 ${_videoEdit!.music!.name}',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Chargement
    return Container(
      width: double.infinity,
      height: 200,
      color: cs.surfaceContainerHighest,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildVideoControlsWidget(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                if (_controller!.value.isPlaying) {
                  _controller!.pause();
                } else {
                  _controller!.play();
                }
              });
            },
            icon: Icon(
              _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: cs.primary,
            ),
          ),
          Expanded(
            child: VideoProgressIndicator(
              _controller!,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: cs.primary,
                backgroundColor: cs.surfaceContainerHigh,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildEditingSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Onglets d'édition
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTabIndex = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedTabIndex == 0 ? cs.primary : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedTabIndex == 0 ? cs.primary : cs.outlineVariant,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.text_fields,
                        size: 18,
                        color: _selectedTabIndex == 0 ? cs.onPrimary : cs.onSurface,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Texte',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _selectedTabIndex == 0 ? cs.onPrimary : cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTabIndex = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedTabIndex == 1 ? cs.primary : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedTabIndex == 1 ? cs.primary : cs.outlineVariant,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_note,
                        size: 18,
                        color: _selectedTabIndex == 1 ? cs.onPrimary : cs.onSurface,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Musique',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _selectedTabIndex == 1 ? cs.onPrimary : cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Contenu de l'onglet sélectionné
        if (_selectedTabIndex == 0)
          _buildTextEditingSection(cs)
        else
          _buildMusicEditingSection(cs),
      ],
    );
  }
  Widget _buildTextEditingSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ajouter du texte',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        
        TextField(
          controller: _textController,
          decoration: InputDecoration(
            hintText: 'Tapez votre texte...',
            hintStyle: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            filled: true,
            fillColor: cs.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(fontSize: 13),
        ),
        
        const SizedBox(height: 16),
        
        // Contrôles de timing
        Text(
          'Timing du texte',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Début: ${_formatDuration(_textStartTime)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(
                          height: 30,
                          child: Slider(
                            value: _textStartTime.inSeconds.toDouble(),
                            min: 0,
                            max: (_controller?.value.duration.inSeconds.toDouble() ?? 30),
                            onChanged: (value) => setState(() => _textStartTime = Duration(seconds: value.round())),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fin: ${_formatDuration(_textEndTime)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(
                          height: 30,
                          child: Slider(
                            value: _textEndTime.inSeconds.toDouble(),
                            min: 0,
                            max: (_controller?.value.duration.inSeconds.toDouble() ?? 30),
                            onChanged: (value) => setState(() => _textEndTime = Duration(seconds: value.round())),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Bouton ajouter texte
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _addTextOverlay,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Ajouter le texte'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        // Liste des textes ajoutés
        if (_videoEdit?.textOverlays.isNotEmpty ?? false) ...[
          const SizedBox(height: 16),
          Text(
            'Textes ajoutés (${_videoEdit!.textOverlays.length})',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(_videoEdit!.textOverlays.length, (index) {
            final overlay = _videoEdit!.textOverlays[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          overlay.text,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_formatDuration(overlay.startTime)} - ${_formatDuration(overlay.endTime)}',
                          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        final currentOverlays = List<VideoTextOverlay>.from(_videoEdit!.textOverlays);
                        currentOverlays.removeAt(index);
                        _videoEdit = _videoEdit!.copyWith(textOverlays: currentOverlays);
                      });
                    },
                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildMusicEditingSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisissez une musique',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.music_note, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Musiques populaires pour stories',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Contrôle global de musique
              if (_isMusicPlaying) ...[
                Text(
                  '♪ $_currentPlayingMusic',
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _stopMusic,
                  icon: Icon(Icons.stop_circle, color: Colors.red, size: 20),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Liste des musiques
        ...List.generate(testMusic.length, (index) {
          final track = testMusic[index];
          final isSelected = _selectedMusic?.name == track['name'];
          final isPlaying = _currentPlayingMusic == track['name'] && _isMusicPlaying;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? cs.primary : cs.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? cs.onPrimary : cs.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.music_note,
                      color: isSelected ? cs.primary : cs.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                track['name']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? cs.onPrimary : cs.onSurface,
                                ),
                              ),
                            ),
                            if (isPlaying)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '♪ En cours',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              track['artist']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? cs.onPrimary.withOpacity(0.8) : cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected ? cs.onPrimary.withOpacity(0.2) : cs.secondaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                track['genre']!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected ? cs.onPrimary : cs.onSecondaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              track['duration']!,
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? cs.onPrimary.withOpacity(0.8) : cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Bouton lecture/pause
                  IconButton(
                    onPressed: () {
                      if (isPlaying) {
                        _stopMusic();
                      } else {
                        _playMusic(track['url']!, track['name']!);
                      }
                    },
                    icon: Icon(
                      isPlaying ? Icons.pause_circle : Icons.play_circle,
                      color: isSelected ? cs.onPrimary : cs.primary,
                      size: 28,
                    ),
                  ),
                  // Bouton sélection
                  IconButton(
                    onPressed: () {
                      final music = VideoMusic(
                        name: track['name']!,
                        path: track['url']!,
                      );
                      _selectMusic(music);
                    },
                    icon: Icon(
                      isSelected ? Icons.check_circle : Icons.add_circle_outline,
                      color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        
        // Musique sélectionnée
        if (_selectedMusic != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primary.withOpacity(0.1),
                  cs.primaryContainer.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Musique sélectionnée',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _selectedMusic!.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '✓ Ajoutée',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtonsSection(ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Annuler'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _finishEditing,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Terminer'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}