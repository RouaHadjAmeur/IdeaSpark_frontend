import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ideaspark/services/google_calendar_service.dart';
import 'package:ideaspark/models/google_calendar_tokens.dart';
import 'dart:convert';

// Generate mocks
@GenerateMocks([http.Client])
import 'google_calendar_service_test.mocks.dart';

void main() {
  group('GoogleCalendarService', () {
    late GoogleCalendarService service;
    late MockClient mockClient;
    const testAuthToken = 'test-auth-token';
    const testBaseUrl = 'http://10.0.2.2:3000';

    setUp(() {
      mockClient = MockClient();
      service = GoogleCalendarService(
        client: mockClient,
        baseUrl: testBaseUrl,
      );
    });

    tearDown(() {
      service.dispose();
    });

    group('getAuthUrl', () {
      test('should return auth URL on success', () async {
        // Arrange
        final responseBody = json.encode({
          'authUrl': 'https://accounts.google.com/o/oauth2/v2/auth?client_id=test',
        });

        when(mockClient.get(
          Uri.parse('$testBaseUrl/google-calendar/auth-url'),
          headers: {'Authorization': 'Bearer $testAuthToken'},
        )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await service.getAuthUrl(testAuthToken);

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, contains('https://accounts.google.com'));
        expect(result.error, null);
      });

      test('should return error on 401 unauthorized', () async {
        // Arrange
        when(mockClient.get(
          Uri.parse('$testBaseUrl/google-calendar/auth-url'),
          headers: {'Authorization': 'Bearer $testAuthToken'},
        )).thenAnswer((_) async => http.Response('Unauthorized', 401));

        // Act
        final result = await service.getAuthUrl(testAuthToken);

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Non authentifié'));
      });

      test('should return error on network failure', () async {
        // Arrange
        when(mockClient.get(
          Uri.parse('$testBaseUrl/google-calendar/auth-url'),
          headers: {'Authorization': 'Bearer $testAuthToken'},
        )).thenThrow(Exception('Network error'));

        // Act
        final result = await service.getAuthUrl(testAuthToken);

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Erreur de connexion'));
      });
    });

    group('syncEntry', () {
      test('should sync entry successfully', () async {
        // Arrange
        const entryId = 'entry-123';
        final tokens = GoogleCalendarTokens(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
        );

        when(mockClient.post(
          Uri.parse('$testBaseUrl/google-calendar/sync-entry'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{"success": true}', 200));

        // Act
        final result = await service.syncEntry(
          calendarEntryId: entryId,
          tokens: tokens,
          authToken: testAuthToken,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.error, null);
      });

      test('should return error on 403 forbidden', () async {
        // Arrange
        const entryId = 'entry-123';
        final tokens = GoogleCalendarTokens(
          accessToken: 'access-token',
        );

        when(mockClient.post(
          Uri.parse('$testBaseUrl/google-calendar/sync-entry'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('Forbidden', 403));

        // Act
        final result = await service.syncEntry(
          calendarEntryId: entryId,
          tokens: tokens,
          authToken: testAuthToken,
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.error, contains('Accès refusé'));
      });
    });

    group('syncPlan', () {
      test('should sync plan successfully', () async {
        // Arrange
        const planId = 'plan-123';
        final tokens = GoogleCalendarTokens(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
        );

        final responseBody = json.encode({
          'total': 10,
          'synced': 9,
          'failed': 1,
          'errors': ['Error syncing entry 5'],
        });

        when(mockClient.post(
          Uri.parse('$testBaseUrl/google-calendar/sync-plan'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await service.syncPlan(
          planId: planId,
          tokens: tokens,
          authToken: testAuthToken,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, isNotNull);
        expect(result.data!.total, 10);
        expect(result.data!.synced, 9);
        expect(result.data!.failed, 1);
        expect(result.data!.hasErrors, true);
        expect(result.data!.errors.length, 1);
      });

      test('should handle full success', () async {
        // Arrange
        const planId = 'plan-123';
        final tokens = GoogleCalendarTokens(
          accessToken: 'access-token',
        );

        final responseBody = json.encode({
          'total': 5,
          'synced': 5,
          'failed': 0,
          'errors': [],
        });

        when(mockClient.post(
          Uri.parse('$testBaseUrl/google-calendar/sync-plan'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(responseBody, 200));

        // Act
        final result = await service.syncPlan(
          planId: planId,
          tokens: tokens,
          authToken: testAuthToken,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.data!.isFullSuccess, true);
        expect(result.data!.hasErrors, false);
      });
    });
  });

  group('GoogleCalendarTokens', () {
    test('should create tokens from JSON', () {
      // Arrange
      final json = {
        'accessToken': 'access-123',
        'refreshToken': 'refresh-456',
        'expiresAt': '2026-02-28T12:00:00.000Z',
      };

      // Act
      final tokens = GoogleCalendarTokens.fromJson(json);

      // Assert
      expect(tokens.accessToken, 'access-123');
      expect(tokens.refreshToken, 'refresh-456');
      expect(tokens.expiresAt, isNotNull);
    });

    test('should convert tokens to JSON', () {
      // Arrange
      final tokens = GoogleCalendarTokens(
        accessToken: 'access-123',
        refreshToken: 'refresh-456',
        expiresAt: DateTime(2026, 2, 28, 12, 0, 0),
      );

      // Act
      final json = tokens.toJson();

      // Assert
      expect(json['accessToken'], 'access-123');
      expect(json['refreshToken'], 'refresh-456');
      expect(json['expiresAt'], isNotNull);
    });

    test('should detect expired tokens', () {
      // Arrange
      final expiredTokens = GoogleCalendarTokens(
        accessToken: 'access-123',
        expiresAt: DateTime.now().subtract(Duration(hours: 1)),
      );

      final validTokens = GoogleCalendarTokens(
        accessToken: 'access-123',
        expiresAt: DateTime.now().add(Duration(hours: 1)),
      );

      // Assert
      expect(expiredTokens.isExpired, true);
      expect(validTokens.isExpired, false);
    });

    test('should copy with updated fields', () {
      // Arrange
      final original = GoogleCalendarTokens(
        accessToken: 'old-token',
        refreshToken: 'refresh-token',
      );

      // Act
      final updated = original.copyWith(
        accessToken: 'new-token',
      );

      // Assert
      expect(updated.accessToken, 'new-token');
      expect(updated.refreshToken, 'refresh-token');
    });
  });

  group('SyncResult', () {
    test('should create from JSON', () {
      // Arrange
      final json = {
        'total': 10,
        'synced': 8,
        'failed': 2,
        'errors': ['Error 1', 'Error 2'],
      };

      // Act
      final result = SyncResult.fromJson(json);

      // Assert
      expect(result.total, 10);
      expect(result.synced, 8);
      expect(result.failed, 2);
      expect(result.errors.length, 2);
      expect(result.hasErrors, true);
      expect(result.isFullSuccess, false);
    });

    test('should detect full success', () {
      // Arrange
      final json = {
        'total': 5,
        'synced': 5,
        'failed': 0,
        'errors': [],
      };

      // Act
      final result = SyncResult.fromJson(json);

      // Assert
      expect(result.isFullSuccess, true);
      expect(result.hasErrors, false);
    });
  });
}
