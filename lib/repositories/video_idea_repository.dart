import '../models/video_generator_models.dart';
import '../services/video_generator_service.dart';

/// Abstract repository for video idea generation
/// Defines the contract for generating video ideas
abstract class VideoIdeaRepository {
  /// Generate video ideas based on a request
  Future<List<VideoIdea>> generateIdeas(VideoRequest request, {bool useRemote = false});

  /// Regenerate ideas with the same request parameters
  Future<List<VideoIdea>> regenerateIdeas(VideoRequest request, {bool useRemote = false});
}

/// Implementation of VideoIdeaRepository using VideoIdeaGeneratorService
class VideoIdeaRepositoryImpl implements VideoIdeaRepository {
  final VideoIdeaGeneratorService service;

  VideoIdeaRepositoryImpl({
    required this.service,
  });

  @override
  Future<List<VideoIdea>> generateIdeas(VideoRequest request, {bool useRemote = false}) async {
    return await service.generateIdeas(request, useRemote: useRemote);
  }

  @override
  Future<List<VideoIdea>> regenerateIdeas(VideoRequest request, {bool useRemote = false}) async {
    // Regeneration is the same as generation in this implementation
    // Could add additional logic like caching or analytics here
    return await service.generateIdeas(request, useRemote: useRemote);
  }
}
