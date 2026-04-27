import 'package:flutter/material.dart';
import '../models/agent_full_access_model.dart';
import '../models/slogan_model.dart';
import '../models/video_generator_models.dart';
import '../models/video.dart';
import '../models/product_idea_model.dart';
import '../services/agent_full_access_service.dart';
import '../services/slogan_service.dart';
import '../services/video_generator_service.dart';
import '../services/product_idea_service.dart';

class AgentFullAccessViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool _isSlogansLoading = false;
  bool _isVideoLoading = false;
  bool _isProductLoading = false;
  String? _error;
  
  DecomposeResponse? _decomposeResponse;
  List<SloganModel>? _slogans;
  VideoIdea? _videoIdea;
  Video? _generatedVideo;
  ProductIdeaResult? _productIdea;

  bool get isLoading => _isLoading;
  bool get isSlogansLoading => _isSlogansLoading;
  bool get isVideoLoading => _isVideoLoading;
  bool get isProductLoading => _isProductLoading;
  String? get error => _error;
  DecomposeResponse? get decomposeResponse => _decomposeResponse;
  List<SloganModel>? get slogans => _slogans;
  VideoIdea? get videoIdea => _videoIdea;
  Video? get generatedVideo => _generatedVideo;
  ProductIdeaResult? get productIdea => _productIdea;

  Future<void> processFullAccess(String idea) async {
    _isLoading = true;
    _isSlogansLoading = false;
    _isVideoLoading = false;
    _isProductLoading = false;
    _error = null;
    _decomposeResponse = null;
    _slogans = null;
    _videoIdea = null;
    _generatedVideo = null;
    _productIdea = null;
    notifyListeners();

    try {
      // 1. Decompose the prompt
      print('🤖 Orchestrator: Decomposing prompt...');
      _decomposeResponse = await AgentFullAccessService.decomposePrompt(idea: idea);
      _isLoading = false;
      
      // Mark specific agents as loading
      _isSlogansLoading = true;
      _isVideoLoading = true;
      _isProductLoading = true;
      notifyListeners();

      final prompts = _decomposeResponse!.result;

      // 2. Run all agents in parallel but update independently
      print('🤖 Orchestrator: Running specific models...');
      
      await Future.wait([
        _runSloganAgent(prompts.sloganPrompt),
        _runVideoAgent(prompts.videoPrompt),
        _runProductAgent(prompts.productIdeaPrompt),
      ]);

      print('✅ Orchestrator: All models finished successfully');
    } catch (e) {
      print('❌ Orchestrator Error: $e');
      _error = e.toString();
      _isLoading = false;
      _isSlogansLoading = false;
      _isVideoLoading = false;
      _isProductLoading = false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _runSloganAgent(String prompt) async {
    try {
      _slogans = await SloganService.generateSlogansFromPrompt(prompt: prompt);
    } catch (e) {
      print('❌ Slogan Agent Error: $e');
    } finally {
      _isSlogansLoading = false;
      notifyListeners();
    }
  }

  Future<void> _runVideoAgent(String prompt) async {
    try {
      // 1. Generate Video Idea (Script)
      _videoIdea = await VideoGeneratorService.generateVideoIdeaFromPrompt(prompt: prompt);
      notifyListeners();

      // 2. Generate Real Video from the description/title
      if (_videoIdea != null) {
        _generatedVideo = await VideoGeneratorService.generateVideo(
          description: _videoIdea!.caption,
          category: 'lifestyle', // Default category
        );
      }
    } catch (e) {
      print('❌ Video Agent Error: $e');
    } finally {
      _isVideoLoading = false;
      notifyListeners();
    }
  }

  Future<void> _runProductAgent(String prompt) async {
    try {
      _productIdea = await ProductIdeaService.generateProductIdea(besoin: prompt);
    } catch (e) {
      print('❌ Product Agent Error: $e');
    } finally {
      _isProductLoading = false;
      notifyListeners();
    }
  }
}
