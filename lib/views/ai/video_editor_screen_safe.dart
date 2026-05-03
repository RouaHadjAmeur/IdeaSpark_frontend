import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

// ⚡ MODÈLES IDENTIQUES À L'ÉDITEUR D'IMAGE

// Styles de background pour le texte
enum StyleTexteArrierePlan {
  aucun,           // Texte brut
  solide,          // Fond arrondi opaque
  semiTransparent, // Fond semi-transparent
  contour,         // Texte avec contour
}

class ElementTexteModifiable {
  String id;
  String texte;
  Offset position;
  double echelle;
  double rotation;
  Color couleur;
  Color couleurArrierePlan;
  StyleTexteArrierePlan styleArrierePlan;
  double tailleFonte;
  bool estGras;
  bool estItalique;
  Matrix4 transformation;

  ElementTexteModifiable({
    required this.id,
    required this.texte,
    required this.position,
    this.echelle = 1.0,
    this.rotation = 0.0,
    this.couleur = Colors.white,
    this.couleurArrierePlan = Colors.black,
    this.styleArrierePlan = StyleTexteArrierePlan.aucun,
    this.tailleFonte = 24.0,
    this.estGras = false,
    this.estItalique = false,
    Matrix4? transformation,
  }) : transformation = transformation ?? Matrix4.identity();

  ElementTexteModifiable copierAvec({
    String? id,
    String? texte,
    Offset? position,
    double? echelle,
    double? rotation,
    Color? couleur,
    Color? couleurArrierePlan,
    StyleTexteArrierePlan? styleArrierePlan,
    double? tailleFonte,
    bool? estGras,
    bool? estItalique,
    Matrix4? transformation,
  }) {
    return ElementTexteModifiable(
      id: id ?? this.id,
      texte: texte ?? this.texte,
      position: position ?? this.position,
      echelle: echelle ?? this.echelle,
      rotation: rotation ?? this.rotation,
      couleur: couleur ?? this.couleur,
      couleurArrierePlan: couleurArrierePlan ?? this.couleurArrierePlan,
      styleArrierePlan: styleArrierePlan ?? this.styleArrierePlan,
      tailleFonte: tailleFonte ?? this.tailleFonte,
      estGras: estGras ?? this.estGras,
      estItalique: estItalique ?? this.estItalique,
      transformation: transformation ?? this.transformation,
    );
  }
}

class TraitDessin {
  final List<Offset> points;
  final Color couleur;
  final double largeurTrait;

  TraitDessin({
    required this.points,
    required this.couleur,
    required this.largeurTrait,
  });
}

// Filtres professionnels avec matrices ColorFilter (identiques à l'éditeur d'image)
class FiltresProfessionnels {
  static const Map<String, List<double>> matricesFiltres = {
    'Aucun': [
      1, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, 1, 0,
    ],
    'Aesthetic': [ // Filtre chaud
      1.2, 0.1, 0.1, 0, 0,
      0.1, 1.0, 0.1, 0, 0,
      0.0, 0.0, 0.8, 0, 0,
      0, 0, 0, 1, 0,
    ],
    'N&B': [ // Noir et blanc contrasté
      0.393, 0.769, 0.189, 0, 0,
      0.349, 0.686, 0.168, 0, 0,
      0.272, 0.534, 0.131, 0, 0,
      0, 0, 0, 1, 0,
    ],
    'Bleu Froid': [ // Bleu froid
      0.8, 0.1, 0.1, 0, 0,
      0.1, 0.9, 0.1, 0, 0,
      0.2, 0.2, 1.3, 0, 0,
      0, 0, 0, 1, 0,
    ],
    'Sépia': [ // Sépia classique
      0.393, 0.769, 0.189, 0, 0,
      0.349, 0.686, 0.168, 0, 0,
      0.272, 0.534, 0.131, 0, 0,
      0, 0, 0, 1, 0,
    ],
    'Vivide': [ // Couleurs vives
      1.4, 0, 0, 0, 0,
      0, 1.4, 0, 0, 0,
      0, 0, 1.4, 0, 0,
      0, 0, 0, 1, 0,
    ],
  };

  static ColorFilter? obtenirFiltre(String nom) {
    final matrice = matricesFiltres[nom];
    if (matrice == null || nom == 'Aucun') return null;
    return ColorFilter.matrix(matrice);
  }
}

// ⚡ VERSION SÉCURISÉE DE L'ÉDITEUR DE VIDÉO
// Cette version élimine tous les bugs qui faisaient planter l'app

class VideoEditorScreen extends StatefulWidget {
  final String videoUrl;
  final String? videoId;

  const VideoEditorScreen({
    super.key,
    required this.videoUrl,
    this.videoId,
  });

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isProcessing = false;
  bool _isDisposed = false; // ⚡ FIX: Prévenir les setState après dispose

  // ⚡ TOUTES LES VARIABLES DE L'ÉDITEUR D'IMAGE
  final GlobalKey _stackKey = GlobalKey();
  final List<ElementTexteModifiable> _elementsTexte = [];
  ElementTexteModifiable? _elementTexteSelectionne;
  bool _modeDessin = false;
  final List<TraitDessin> _traitsDessin = [];
  TraitDessin? _traitActuel;
  Color _couleurDessin = Colors.red;
  double _taillePin = 5.0;
  bool _afficherZonePoubelle = false;
  ColorFilter? _filtreActuel;
  int _selectedTabIndex = 0; // 0: Filtres, 1: Texte, 2: Dessin, 3: Couleurs
  
  // Variables pour le texte
  double _fontSize = 24.0;
  Color _textColor = Colors.white;
  bool _textBold = false;
  bool _textItalic = false;
  StyleTexteArrierePlan _styleTexteArrierePlan = StyleTexteArrierePlan.aucun;

  @override
  void initState() {
    super.initState();
    _initialiserVideoSecurise();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _videoController?.pause();
    _videoController?.dispose();
    super.dispose();
  }

  // ⚡ FIX: setState sécurisé
  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  // ⚡ FIX: Initialisation ultra-sécurisée
  Future<void> _initialiserVideoSecurise() async {
    if (_isDisposed) return;
    
    try {
      // Validation de l'URL
      if (widget.videoUrl.isEmpty) {
        _retournerAvecErreur('URL de vidéo vide');
        return;
      }

      // Créer le contrôleur selon le type d'URL
      if (widget.videoUrl.startsWith('http')) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      } else {
        final file = File(widget.videoUrl);
        if (!await file.exists()) {
          _retournerAvecErreur('Fichier vidéo introuvable');
          return;
        }
        _videoController = VideoPlayerController.file(file);
      }
      
      // Initialisation avec timeout
      await _videoController!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout lors du chargement'),
      );
      
      if (_isDisposed) return;
      
      _safeSetState(() {
        _isVideoInitialized = true;
      });
      
      // Démarrer la lecture
      _videoController!.setLooping(true);
      _videoController!.play();
      
    } catch (e) {
      _retournerAvecErreur('Erreur lors du chargement: $e');
    }
  }

  // ⚡ FIX: Retour sécurisé en cas d'erreur
  void _retournerAvecErreur(String message) {
    if (!_isDisposed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $message'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  // ⚡ FIX: Toggle play/pause sécurisé
  void _togglePlayPause() {
    if (_isDisposed || _videoController == null) return;
    
    try {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
      _safeSetState(() {});
    } catch (e) {
      // Ignore les erreurs de lecture
    }
  }

  // ⚡ FIX: Import galerie sécurisé
  Future<void> _importerDepuisGalerie() async {
    if (_isDisposed) return;
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
      
      if (video != null && !_isDisposed) {
        final file = File(video.path);
        if (!await file.exists()) {
          _afficherMessage('Fichier sélectionné introuvable', Colors.red);
          return;
        }

        // Dispose sécurisé de l'ancien contrôleur
        await _videoController?.pause();
        _videoController?.dispose();
        
        // Nouveau contrôleur
        _videoController = VideoPlayerController.file(file);
        await _videoController!.initialize().timeout(
          const Duration(seconds: 10),
        );
        
        if (_isDisposed) return;
        
        _safeSetState(() {
          _isVideoInitialized = true;
        });
        
        _videoController!.setLooping(true);
        _videoController!.play();
        
        _afficherMessage('Vidéo importée avec succès!', Colors.green);
      }
    } catch (e) {
      _afficherMessage('Erreur lors de l\'importation: $e', Colors.red);
    }
  }

  // ⚡ FIX: Affichage de message sécurisé
  void _afficherMessage(String message, Color couleur) {
    if (!_isDisposed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: couleur,
        ),
      );
    }
  }

  // ⚡ FIX: Sauvegarde sécurisée dans l'historique des vidéos éditées (mise à jour)
  Future<void> _sauvegarderVideo() async {
    // Utiliser la nouvelle fonction de capture et sauvegarde
    await _capturerEtSauvegarder();
  }

  // ⚡ Créer une capture basique de la vidéo
  Future<String> _creerCaptureVideo() async {
    try {
      // Pour l'instant, créer une image placeholder
      // Dans une version future, on pourrait faire une vraie capture
      
      // Créer une image simple avec des informations sur la vidéo
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..color = Colors.blue.shade800;
      
      // Dessiner un rectangle de base
      canvas.drawRect(const Rect.fromLTWH(0, 0, 200, 150), paint);
      
      // Ajouter du texte
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Vidéo Éditée\n${DateTime.now().day}/${DateTime.now().month}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, const Offset(20, 50));
      
      // Convertir en image
      final picture = recorder.endRecording();
      final img = await picture.toImage(200, 150);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      
      // Encoder en Base64
      return base64Encode(bytes);
    } catch (e) {
      // En cas d'erreur, retourner une chaîne vide
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            // Interface principale
            Column(
              children: [
                // Header minimaliste (identique à l'éditeur d'image)
                _construireHeaderMinimaliste(),
                
                // Zone d'édition principale (Stack avec vidéo + éléments)
                Expanded(
                  child: _construireZoneEditionPrincipale(),
                ),
                
                // Filtres horizontaux en bas (si onglet filtres sélectionné)
                if (_selectedTabIndex == 0) _construireFiltresHorizontaux(),
                
                // Barre d'outils en bas
                _construireBarreOutilsBas(),
              ],
            ),
            
            // Zone de poubelle (apparaît seulement lors du déplacement)
            if (_afficherZonePoubelle) _construireZonePoubelle(),
          ],
        ),
      ),
    );
  }

  // ⚡ HEADER MINIMALISTE (identique à l'éditeur d'image)
  Widget _construireHeaderMinimaliste() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Bouton retour avec effet blur
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
          const Spacer(),
          // Bouton d'importation
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: _importerDepuisGalerie,
                  icon: const Icon(Icons.video_library_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Bouton historique
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: () => context.push('/edited-videos-history'),
                  icon: const Icon(Icons.history_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Bouton de sauvegarde
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: _capturerEtSauvegarder,
                  icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ⚡ ZONE D'ÉDITION PRINCIPALE (identique à l'éditeur d'image mais avec vidéo)
  Widget _construireZoneEditionPrincipale() {
    if (!_isVideoInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Chargement de la vidéo...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_videoController == null) {
      return const Center(
        child: Text(
          'Erreur de chargement',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: RepaintBoundary(
        key: _stackKey,
        child: Stack(
          children: [
            // Vidéo de fond avec filtre appliqué
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ColorFiltered(
                  colorFilter: _filtreActuel ?? const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                ),
              ),
            ),
            
            // Éléments de texte transformables
            ..._elementsTexte.map((element) => _construireTexteTransformable(element)),
            
            // Canvas de dessin
            if (_modeDessin)
              Positioned.fill(
                child: GestureDetector(
                  onPanStart: _commencerDessin,
                  onPanUpdate: _mettreAJourDessin,
                  onPanEnd: _terminerDessin,
                  child: CustomPaint(
                    painter: PeintreDessin(_traitsDessin, _traitActuel),
                  ),
                ),
              ),
            
            // Bouton d'effacement des dessins (apparaît quand il y a des dessins)
            if (_traitsDessin.isNotEmpty && !_modeDessin)
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: _effacerTousLesDessin,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.cleaning_services_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            
            // Contrôles de lecture flottants
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _construireControlesLecture(),
            ),
          ],
        ),
      ),
    );
  }

  // ⚡ CONTRÔLES DE LECTURE FLOTTANTS
  Widget _construireControlesLecture() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _togglePlayPause,
                icon: Icon(
                  _videoController?.value.isPlaying == true 
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                  color: Colors.white,
                  size: 32,
                ),
                tooltip: 'Lecture/Pause',
              ),
              Text(
                '${_elementsTexte.length} texte(s) • ${_traitsDessin.length} dessin(s)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ⚡ WIDGET TEXTE TRANSFORMABLE AVEC PINCH-TO-ZOOM (identique à l'éditeur d'image)
  Widget _construireTexteTransformable(ElementTexteModifiable element) {
    return Positioned(
      left: element.position.dx,
      top: element.position.dy,
      child: GestureDetector(
        onScaleStart: (details) {
          setState(() {
            _elementTexteSelectionne = element;
            _afficherZonePoubelle = true;
          });
          HapticFeedback.lightImpact();
        },
        onScaleUpdate: (details) {
          setState(() {
            // Gestion du déplacement (quand scale = 1.0, c'est un déplacement)
            if (details.scale == 1.0) {
              // Déplacement simple
              element.position += details.focalPointDelta;
            } else {
              // Transformation (échelle et rotation)
              element.echelle *= details.scale;
              element.rotation += details.rotation;
              
              // Limiter l'échelle entre 0.5 et 3.0
              element.echelle = element.echelle.clamp(0.5, 3.0);
              
              // Appliquer les transformations à la matrice
              element.transformation = Matrix4.identity()
                ..scale(element.echelle)
                ..rotateZ(element.rotation);
            }
          });
        },
        onScaleEnd: (details) {
          setState(() {
            _afficherZonePoubelle = false;
          });
          _verifierCollisionPoubelle(element);
        },
        onTap: () {
          setState(() {
            _elementTexteSelectionne = element;
          });
          HapticFeedback.selectionClick();
          
          // Afficher les options de personnalisation
          _afficherOptionsTexte(element);
        },
        child: Transform(
          transform: element.transformation,
          alignment: Alignment.center,
          child: Container(
            padding: _obtenirPaddingTexte(element.styleArrierePlan),
            decoration: _obtenirDecorationTexte(element),
            child: Text(
              element.texte,
              style: TextStyle(
                fontSize: element.tailleFonte,
                color: element.couleur,
                fontWeight: element.estGras ? FontWeight.bold : FontWeight.normal,
                fontStyle: element.estItalique ? FontStyle.italic : FontStyle.normal,
                shadows: element.styleArrierePlan == StyleTexteArrierePlan.contour
                    ? [
                        Shadow(
                          offset: const Offset(-1, -1),
                          color: element.couleurArrierePlan,
                          blurRadius: 1,
                        ),
                        Shadow(
                          offset: const Offset(1, -1),
                          color: element.couleurArrierePlan,
                          blurRadius: 1,
                        ),
                        Shadow(
                          offset: const Offset(1, 1),
                          color: element.couleurArrierePlan,
                          blurRadius: 1,
                        ),
                        Shadow(
                          offset: const Offset(-1, 1),
                          color: element.couleurArrierePlan,
                          blurRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ⚡ FILTRES HORIZONTAUX (identique à l'éditeur d'image)
  Widget _construireFiltresHorizontaux() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: FiltresProfessionnels.matricesFiltres.keys.length,
        itemBuilder: (context, index) {
          final nomFiltre = FiltresProfessionnels.matricesFiltres.keys.elementAt(index);
          final estSelectionne = _filtreActuel == FiltresProfessionnels.obtenirFiltre(nomFiltre);
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _filtreActuel = FiltresProfessionnels.obtenirFiltre(nomFiltre);
              });
              HapticFeedback.selectionClick();
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  // Aperçu du filtre avec la vidéo
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: estSelectionne ? Colors.white : Colors.white.withValues(alpha: 0.3),
                        width: estSelectionne ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: ColorFiltered(
                        colorFilter: FiltresProfessionnels.obtenirFiltre(nomFiltre) ?? 
                            const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                        child: _videoController != null 
                          ? AspectRatio(
                              aspectRatio: 1,
                              child: VideoPlayer(_videoController!),
                            )
                          : Container(
                              color: Colors.grey.shade800,
                              child: const Icon(Icons.video_library, color: Colors.white, size: 20),
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nomFiltre,
                    style: TextStyle(
                      color: estSelectionne ? Colors.white : Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: estSelectionne ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ⚡ BARRE D'OUTILS EN BAS (identique à l'éditeur d'image)
  Widget _construireBarreOutilsBas() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Filtres
          _construireBoutonOutil(
            icon: Icons.filter_vintage_rounded,
            isSelected: _selectedTabIndex == 0,
            onTap: () {
              setState(() {
                _selectedTabIndex = 0;
                _modeDessin = false;
                _elementTexteSelectionne = null;
              });
            },
          ),
          // Texte
          _construireBoutonOutil(
            icon: Icons.text_fields_rounded,
            isSelected: _selectedTabIndex == 1,
            onTap: () {
              setState(() {
                _selectedTabIndex = 1;
                _modeDessin = false;
              });
              _afficherDialogueTexte();
            },
          ),
          // Dessin
          _construireBoutonOutil(
            icon: Icons.brush_rounded,
            isSelected: _modeDessin,
            onTap: () {
              setState(() {
                _selectedTabIndex = 2;
                _modeDessin = !_modeDessin;
                _elementTexteSelectionne = null;
              });
            },
          ),
          // Couleurs
          _construireBoutonOutil(
            icon: Icons.palette_rounded,
            isSelected: _selectedTabIndex == 3,
            onTap: () {
              setState(() {
                _selectedTabIndex = 3;
                _modeDessin = false;
                _elementTexteSelectionne = null;
              });
              _afficherDialogueCouleurs();
            },
          ),
        ],
      ),
    );
  }

  Widget _construireBoutonOutil({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.white.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  // ⚡ ZONE DE POUBELLE (identique à l'éditeur d'image)
  Widget _construireZonePoubelle() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.delete_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ⚡ DIALOGUE POUR AJOUTER DU TEXTE (identique à l'éditeur d'image)
  void _afficherDialogueTexte() {
    final textController = TextEditingController();
    bool localTextBold = _textBold;
    bool localTextItalic = _textItalic;
    double localFontSize = _fontSize;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.black87,
              title: const Text('Ajouter du texte', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Tapez votre texte...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Taille: ', style: TextStyle(color: Colors.white)),
                      Expanded(
                        child: Slider(
                          value: localFontSize,
                          min: 12,
                          max: 48,
                          activeColor: Colors.white,
                          inactiveColor: Colors.white.withOpacity(0.3),
                          onChanged: (value) {
                            setDialogState(() {
                              localFontSize = value;
                            });
                          },
                        ),
                      ),
                      Text('${localFontSize.round()}', style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Gras', style: TextStyle(color: Colors.white, fontSize: 14)),
                          value: localTextBold,
                          activeColor: Colors.white,
                          checkColor: Colors.black,
                          side: const BorderSide(color: Colors.white),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) {
                            setDialogState(() {
                              localTextBold = value ?? false;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Italique', style: TextStyle(color: Colors.white, fontSize: 14)),
                          value: localTextItalic,
                          activeColor: Colors.white,
                          checkColor: Colors.black,
                          side: const BorderSide(color: Colors.white),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) {
                            setDialogState(() {
                              localTextItalic = value ?? false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (textController.text.trim().isNotEmpty) {
                      // Mettre à jour les variables globales
                      setState(() {
                        _fontSize = localFontSize;
                        _textBold = localTextBold;
                        _textItalic = localTextItalic;
                      });
                      
                      // Ajouter le texte avec les paramètres locaux
                      _ajouterElementTexteAvecParametres(
                        textController.text.trim(),
                        localFontSize,
                        localTextBold,
                        localTextItalic,
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  child: const Text('Ajouter', style: TextStyle(color: Colors.black)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ⚡ DIALOGUE COULEURS (identique à l'éditeur d'image)
  void _afficherDialogueCouleurs() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text('Choisir une couleur', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Couleur du texte:', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Colors.white,
                  Colors.black,
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.yellow,
                  Colors.purple,
                  Colors.orange,
                ].map((couleur) => GestureDetector(
                  onTap: () {
                    setState(() {
                      _textColor = couleur;
                      if (_elementTexteSelectionne != null) {
                        _elementTexteSelectionne!.couleur = couleur;
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: couleur,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _textColor == couleur ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Couleur du dessin:', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.yellow,
                  Colors.purple,
                  Colors.orange,
                  Colors.white,
                  Colors.black,
                ].map((couleur) => GestureDetector(
                  onTap: () {
                    setState(() {
                      _couleurDessin = couleur;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: couleur,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _couleurDessin == couleur ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ⚡ AJOUTER ÉLÉMENT TEXTE (identique à l'éditeur d'image)
  void _ajouterElementTexteAvecParametres(String texte, double taille, bool gras, bool italique) {
    final nouvelElement = ElementTexteModifiable(
      id: const Uuid().v4(),
      texte: texte,
      position: const Offset(100, 200), // Position fixe pour commencer
      tailleFonte: taille,
      couleur: _textColor,
      estGras: gras,
      estItalique: italique,
      styleArrierePlan: StyleTexteArrierePlan.aucun,
    );

    setState(() {
      _elementsTexte.add(nouvelElement);
      _elementTexteSelectionne = nouvelElement;
    });

    HapticFeedback.lightImpact();
    
    _afficherMessage('✅ Texte ajouté! Pincez pour zoomer, touchez pour éditer.', Colors.green);
  }

  // ⚡ OPTIONS TEXTE (identique à l'éditeur d'image)
  void _afficherOptionsTexte(ElementTexteModifiable element) {
    final textController = TextEditingController(text: element.texte);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.black87,
              title: const Text('Personnaliser le texte', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Champ pour modifier le texte
                    TextField(
                      controller: textController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Modifier le texte',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      onChanged: (nouveauTexte) {
                        setDialogState(() {
                          element.texte = nouveauTexte;
                        });
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    // Boutons d'emojis rapides
                    const Text('Emojis rapides:', style: TextStyle(color: Colors.white, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['😊', '❤️', '🔥', '✨', '👍', '🎉', '💯', '🌟'].map((emoji) => 
                        GestureDetector(
                          onTap: () {
                            final nouveauTexte = textController.text + emoji;
                            textController.text = nouveauTexte;
                            textController.selection = TextSelection.fromPosition(
                              TextPosition(offset: nouveauTexte.length),
                            );
                            setDialogState(() {
                              element.texte = nouveauTexte;
                            });
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(emoji, style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                      ).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Style du texte
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            title: const Text('Gras', style: TextStyle(color: Colors.white, fontSize: 12)),
                            value: element.estGras,
                            activeColor: Colors.white,
                            checkColor: Colors.black,
                            side: const BorderSide(color: Colors.white),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              setDialogState(() {
                                element.estGras = value ?? false;
                              });
                              setState(() {});
                            },
                          ),
                        ),
                        Expanded(
                          child: CheckboxListTile(
                            title: const Text('Italique', style: TextStyle(color: Colors.white, fontSize: 12)),
                            value: element.estItalique,
                            activeColor: Colors.white,
                            checkColor: Colors.black,
                            side: const BorderSide(color: Colors.white),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              setDialogState(() {
                                element.estItalique = value ?? false;
                              });
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Couleurs
                    const Text('Couleur du texte:', style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        Colors.white,
                        Colors.black,
                        Colors.red,
                        Colors.blue,
                        Colors.green,
                        Colors.yellow,
                        Colors.purple,
                        Colors.orange,
                      ].map((couleur) => GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            element.couleur = couleur;
                          });
                          setState(() {});
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: couleur,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: element.couleur == couleur ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Styles de background
                    const Text('Style de fond:', style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: StyleTexteArrierePlan.values.map((style) {
                        final estSelectionne = element.styleArrierePlan == style;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              element.styleArrierePlan = style;
                            });
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: estSelectionne ? Colors.white.withOpacity(0.3) : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.white.withOpacity(0.5)),
                            ),
                            child: Text(
                              _obtenirLabelStyleArrierePlan(style),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _elementsTexte.remove(element);
                      _elementTexteSelectionne = null;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ⚡ FONCTIONS UTILITAIRES (identiques à l'éditeur d'image)
  
  EdgeInsets _obtenirPaddingTexte(StyleTexteArrierePlan style) {
    switch (style) {
      case StyleTexteArrierePlan.solide:
      case StyleTexteArrierePlan.semiTransparent:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      default:
        return EdgeInsets.zero;
    }
  }

  BoxDecoration? _obtenirDecorationTexte(ElementTexteModifiable element) {
    switch (element.styleArrierePlan) {
      case StyleTexteArrierePlan.solide:
        return BoxDecoration(
          color: element.couleurArrierePlan,
          borderRadius: BorderRadius.circular(8),
        );
      case StyleTexteArrierePlan.semiTransparent:
        return BoxDecoration(
          color: element.couleurArrierePlan.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
        );
      default:
        return null;
    }
  }

  String _obtenirLabelStyleArrierePlan(StyleTexteArrierePlan style) {
    switch (style) {
      case StyleTexteArrierePlan.aucun:
        return 'Brut';
      case StyleTexteArrierePlan.solide:
        return 'Opaque';
      case StyleTexteArrierePlan.semiTransparent:
        return 'Semi';
      case StyleTexteArrierePlan.contour:
        return 'Contour';
    }
  }

  // ⚡ VÉRIFIER COLLISION AVEC LA POUBELLE (identique à l'éditeur d'image)
  void _verifierCollisionPoubelle(ElementTexteModifiable element) {
    final tailleEcran = MediaQuery.of(context).size;
    final centrePoubelle = Offset(tailleEcran.width / 2, tailleEcran.height - 130);
    final rayonPoubelle = 30.0;

    final distance = (element.position - centrePoubelle).distance;

    if (distance < rayonPoubelle) {
      setState(() {
        _elementsTexte.remove(element);
        _elementTexteSelectionne = null;
      });
      HapticFeedback.heavyImpact();
      _afficherMessage('🗑️ Texte supprimé', Colors.orange);
    }
  }

  // ⚡ FONCTIONS DE DESSIN (identiques à l'éditeur d'image)
  
  void _commencerDessin(DragStartDetails details) {
    setState(() {
      _traitActuel = TraitDessin(
        points: [details.localPosition],
        couleur: _couleurDessin,
        largeurTrait: _taillePin,
      );
    });
  }

  void _mettreAJourDessin(DragUpdateDetails details) {
    setState(() {
      _traitActuel?.points.add(details.localPosition);
    });
  }

  void _terminerDessin(DragEndDetails details) {
    if (_traitActuel != null) {
      setState(() {
        _traitsDessin.add(_traitActuel!);
        _traitActuel = null;
      });
    }
  }

  void _effacerTousLesDessin() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text('Effacer les dessins', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Voulez-vous effacer tous les dessins ?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _traitsDessin.clear();
                });
                Navigator.pop(context);
                _afficherMessage('✅ Tous les dessins ont été effacés!', Colors.green);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Effacer', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ⚡ CAPTURE ET SAUVEGARDE (adaptée pour vidéo)
  Future<void> _capturerEtSauvegarder() async {
    if (_isDisposed || _isProcessing) return;
    
    try {
      _safeSetState(() {
        _isProcessing = true;
      });

      // Pause la vidéo pour la capture
      await _videoController?.pause();
      
      // Attendre que la pause soit effective
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Capturer le Stack avec screenshot
      final RenderRepaintBoundary boundary = 
          _stackKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Sauvegarder dans l'historique des vidéos éditées
      await _sauvegarderDansHistoriqueVideo(pngBytes);
      
      // Reprendre la lecture
      _videoController?.play();
      
      _afficherMessage('✅ Vidéo sauvegardée avec succès!', Colors.green);
      
    } catch (e) {
      _afficherMessage('❌ Erreur lors de la sauvegarde: $e', Colors.red);
    } finally {
      _safeSetState(() {
        _isProcessing = false;
      });
    }
  }

  // ⚡ SAUVEGARDE DANS L'HISTORIQUE VIDÉO (mise à jour)
  Future<void> _sauvegarderDansHistoriqueVideo(Uint8List captureBytes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historiqueJson = prefs.getStringList('edited_videos_history') ?? [];
      
      final videoEditee = {
        'id': const Uuid().v4(),
        'originalUrl': widget.videoUrl,
        'editedDataBase64': base64Encode(captureBytes), // Image Base64 de la capture
        'createdAt': DateTime.now().toIso8601String(),
        'type': 'video_edit_complete',
        'textOverlays': _elementsTexte.length,
        'drawings': _traitsDessin.length,
        'filter': _filtreActuel != null ? 'Appliqué' : 'Aucun',
        'metadata': {
          'editor_version': 'complete_v2.0',
          'original_video_id': widget.videoId,
          'has_filters': _filtreActuel != null,
          'has_text': _elementsTexte.isNotEmpty,
          'has_drawings': _traitsDessin.isNotEmpty,
        },
      };
      
      historiqueJson.insert(0, jsonEncode(videoEditee));
      
      // Limiter à 50 vidéos pour éviter de surcharger
      if (historiqueJson.length > 50) {
        historiqueJson.removeRange(50, historiqueJson.length);
      }
      
      await prefs.setStringList('edited_videos_history', historiqueJson);
      
    } catch (e) {
      print('❌ Erreur sauvegarde historique vidéo: $e');
      rethrow;
    }
  }
}

// ⚡ CUSTOMPAINTER POUR LE DESSIN À MAIN LEVÉE (identique à l'éditeur d'image)
class PeintreDessin extends CustomPainter {
  final List<TraitDessin> traits;
  final TraitDessin? traitActuel;

  PeintreDessin(this.traits, this.traitActuel);

  @override
  void paint(Canvas canvas, Size size) {
    // Dessiner tous les traits terminés
    for (final trait in traits) {
      _dessinerTrait(canvas, trait);
    }
    
    // Dessiner le trait en cours
    if (traitActuel != null) {
      _dessinerTrait(canvas, traitActuel!);
    }
  }

  void _dessinerTrait(Canvas canvas, TraitDessin trait) {
    if (trait.points.isEmpty) return;
    
    final pinceau = Paint()
      ..color = trait.couleur
      ..strokeWidth = trait.largeurTrait
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final chemin = Path();
    chemin.moveTo(trait.points.first.dx, trait.points.first.dy);
    
    for (int i = 1; i < trait.points.length; i++) {
      chemin.lineTo(trait.points[i].dx, trait.points[i].dy);
    }
    
    canvas.drawPath(chemin, pinceau);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}