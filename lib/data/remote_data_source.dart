import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Added for MediaType
import '../models/video_generator_models.dart';
import '../core/api_config.dart';
import '../services/auth_service.dart';

class VideoGeneratorRemoteDataSource {
  Future<List<VideoIdea>> generateIdeas(VideoRequest request) async {
    final url = Uri.parse(ApiConfig.generateVideoIdeasUrl);
    
    // If we have an image, we MUST use multipart/form-data
    if (request.productImagePath != null) {
      final multipartRequest = http.MultipartRequest('POST', url);
      
      // Add text fields
      multipartRequest.fields['platform'] = _mapPlatform(request.platform);
      multipartRequest.fields['duration'] = _durationToString(request.duration);
      multipartRequest.fields['goal'] = _mapGoal(request.goal);
      multipartRequest.fields['creatorType'] = _mapCreatorType(request.creatorType);
      multipartRequest.fields['tone'] = _mapTone(request.tone);
      multipartRequest.fields['language'] = _mapLanguage(request.language);
      multipartRequest.fields['productName'] = request.productName;
      multipartRequest.fields['productCategory'] = request.productCategory;
      multipartRequest.fields['targetAudience'] = request.targetAudience;
      multipartRequest.fields['batchSize'] = '1'; // Gemini 2.0 flow uses batchSize 1
      
      if (request.price != null) multipartRequest.fields['price'] = request.price!;
      if (request.offer != null) multipartRequest.fields['offer'] = request.offer!;
      if (request.painPoint != null) multipartRequest.fields['painPoint'] = request.painPoint!;
      
      // Add keyBenefits as a single string or multiple if backend supports array in multipart
      // Backend DTO expects keyBenefits: string[]
      // For multipart, usually we repeat fields or send comma-separated. 
      // NestJS FileInterceptor handles this. Let's send them individually.
      for (var benefit in request.keyBenefits) {
        multipartRequest.fields['keyBenefits[]'] = benefit;
      }

      // Add image
      final file = File(request.productImagePath!);
      if (await file.exists()) {
        multipartRequest.files.add(
          await http.MultipartFile.fromPath(
            'productImage',
            file.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final streamedResponse = await multipartRequest.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => VideoIdea.fromJson(json)).toList();
      } else {
        throw Exception('Failed to generate ideas: ${response.statusCode} ${response.body}');
      }
    }

    // Standard JSON request if no image
    final body = {
      'platform': _mapPlatform(request.platform),
      'duration': _durationToString(request.duration),
      'goal': _mapGoal(request.goal),
      'creatorType': _mapCreatorType(request.creatorType),
      'tone': _mapTone(request.tone),
      'language': _mapLanguage(request.language),
      'productName': request.productName,
      'productCategory': request.productCategory,
      'keyBenefits': request.keyBenefits,
      'targetAudience': request.targetAudience,
      'price': request.price,
      'offer': request.offer,
      'painPoint': request.painPoint,
      'batchSize': 1,
    };
    
    final authService = AuthService();
    await authService.isLoggedIn();
    final authToken = authService.accessToken;

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => VideoIdea.fromJson(json)).toList();
    } else {
      throw Exception('Failed to generate ideas: ${response.statusCode} ${response.body}');
    }
  }

  Future<Map<String, dynamic>> analyzeImage(String imagePath) async {
    final url = Uri.parse(ApiConfig.analyzeVideoImageUrl);
    final multipartRequest = http.MultipartRequest('POST', url);

    final file = File(imagePath);
    if (!await file.exists()) throw Exception('Image file not found');

    multipartRequest.files.add(
      await http.MultipartFile.fromPath(
        'productImage',
        file.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final streamedResponse = await multipartRequest.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Image analysis failed: ${response.statusCode}');
    }
  }

  Future<VideoIdea> refineIdea(String ideaId, String instruction) async {
    final url = Uri.parse(ApiConfig.refineVideoIdeaUrl);
    
    final authService = AuthService();
    await authService.isLoggedIn();
    final authToken = authService.accessToken;
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'ideaId': ideaId,
        'customInstruction': instruction,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return VideoIdea.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to refine idea: ${response.body}');
    }
  }

  Future<VideoIdea> approveVersion(String ideaId, int versionIndex) async {
    final url = Uri.parse(ApiConfig.approveVersionUrl);
    
    final authService = AuthService();
    await authService.isLoggedIn();
    final authToken = authService.accessToken;
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'ideaId': ideaId,
        'versionIndex': versionIndex,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return VideoIdea.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to approve version: ${response.body}');
    }
  }

  Future<VideoIdea> saveIdea(VideoIdea idea) async {
    final url = Uri.parse(ApiConfig.saveVideoIdeaUrl);
    
    final authService = AuthService();
    await authService.isLoggedIn();
    final authToken = authService.accessToken;
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(idea.currentVersion.toJson()), // Save current version structure
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return VideoIdea.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to save idea: ${response.body}');
    }
  }
  
  Future<List<VideoIdea>> getHistory() async {
    final authService = AuthService();
    await authService.isLoggedIn();
    final authToken = authService.accessToken;
    
    final url = Uri.parse(ApiConfig.getHistoryUrl);
    final response = await http.get(
      url,
      headers: {
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => VideoIdea.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch history: ${response.body}');
    }
  }
  
  Future<List<VideoIdea>> getFavorites() async {
    final authService = AuthService();
    await authService.isLoggedIn();
    final authToken = authService.accessToken;
    
    final url = Uri.parse(ApiConfig.getFavoritesUrl);
    final response = await http.get(
      url,
      headers: {
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => VideoIdea.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch favorites: ${response.body}');
    }
  }
  
  Future<VideoIdea> toggleFavorite(String id) async {
    final authService = AuthService();
    await authService.isLoggedIn();
    final authToken = authService.accessToken;
    
    final url = Uri.parse('${ApiConfig.toggleFavoriteUrl}/$id');
    final response = await http.post(
      url,
      headers: {
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return VideoIdea.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to toggle favorite: ${response.body}');
    }
  }
  
  Future<void> deleteIdea(String id) async {
    final authService = AuthService();
    await authService.isLoggedIn();
    final authToken = authService.accessToken;
    
    final url = Uri.parse('${ApiConfig.deleteVideoIdeaUrl}/$id');
    final response = await http.delete(
      url,
      headers: {
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
    );
    
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete idea: ${response.body}');
    }
  }

  // Helpers
  String _durationToString(DurationOption d) {
    switch (d) {
      case DurationOption.s15: return '15s';
      case DurationOption.s30: return '30s';
      case DurationOption.s60: return '60s';
      case DurationOption.s90: return '90s';
    }
  }
  
  String _mapPlatform(Platform p) {
    switch (p) {
      case Platform.tikTok: return 'TikTok';
      case Platform.instagramReels: return 'InstagramReels';
      case Platform.youTubeShorts: return 'YouTubeShorts';
      case Platform.youTubeLong: return 'YouTubeLong';
    }
  }

  String _mapGoal(VideoGoal g) {
    switch (g) {
      case VideoGoal.sellProduct: return 'SellProduct';
      case VideoGoal.brandAwareness: return 'BrandAwareness';
      case VideoGoal.ugcReview: return 'UGCReview';
      case VideoGoal.offerPromo: return 'OfferPromo';
      case VideoGoal.education: return 'Education';
      case VideoGoal.viralEngagement: return 'ViralEngagement';
    }
  }

  String _mapCreatorType(CreatorType c) {
    switch (c) {
      case CreatorType.ecommerceBrand: return 'EcommerceBrand';
      case CreatorType.influencer: return 'Influencer';
    }
  }

  String _mapTone(VideoTone t) {
    switch (t) {
      case VideoTone.trendy: return 'Trendy';
      case VideoTone.professional: return 'Professional';
      case VideoTone.emotional: return 'Emotional';
      case VideoTone.funny: return 'Funny';
      case VideoTone.luxury: return 'Luxury';
      case VideoTone.directResponse: return 'DirectResponse';
    }
  }

  String _mapLanguage(VideoLanguage l) {
    switch (l) {
      case VideoLanguage.french: return 'French';
      case VideoLanguage.english: return 'English';
      case VideoLanguage.arabic: return 'Arabic';
    }
  }
}
