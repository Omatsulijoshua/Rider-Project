import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:rider/service/api_client.dart';
import 'package:rider/service/shared_pref.dart';
import 'dart:io' as io;

class BackendAuthService {
  final ApiClient _apiClient = ApiClient();
  final _deviceInfo = DeviceInfoPlugin();

  /// Get device information
  Future<Map<String, String>> _getDeviceInfo() async {
    try {
      // Check if running on web
      if (kIsWeb) {
        return {'deviceId': 'web-device', 'deviceName': 'Web Browser'};
      }

      if (io.Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return {
          'deviceId': info.id,
          'deviceName': info.model,
        };
      } else if (io.Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return {
          'deviceId': info.identifierForVendor ?? 'unknown',
          'deviceName': info.model,
        };
      }
    } catch (e) {
      debugPrint('❌ Error getting device info: $e');
    }
    return {
      'deviceId': 'unknown',
      'deviceName': 'Unknown Device',
    };
  }

  /// Sign up a new customer
  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final deviceInfo = await _getDeviceInfo();

      final response = await _apiClient.post(
        '/auth/signup',
        body: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone, // ✅ ADD THIS
          'role': 'CUSTOMER',
          'deviceInfo': {
            'deviceId': deviceInfo['deviceId'],
            'deviceName': deviceInfo['deviceName'],
          },
        },
        requireAuth: false,
      );

      if (response['accessToken'] != null && response['refreshToken'] != null) {
        // Save tokens
        await SharedpreferenceHelper().saveAccessToken(response['accessToken']);
        await SharedpreferenceHelper()
            .saveRefreshToken(response['refreshToken']);

        // Save user data
        if (response['user'] != null) {
          final user = response['user'];
          await SharedpreferenceHelper().saveUserID(user['id']);
          await SharedpreferenceHelper().saveUserName(user['name']);
          await SharedpreferenceHelper().saveUserEmail(user['email']);
        }

        return {
          'success': true,
          'message': 'Signup successful',
          'user': response['user'],
        };
      } else {
        throw Exception('Invalid response from server');
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Login with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final deviceInfo = await _getDeviceInfo();

      final response = await _apiClient.post(
        '/auth/login',
        body: {
          'email': email,
          'password': password,
          'deviceInfo': {
            'deviceId': deviceInfo['deviceId'],
            'deviceName': deviceInfo['deviceName'],
          },
        },
        requireAuth: false,
      );

      if (response['accessToken'] != null && response['refreshToken'] != null) {
        // Save tokens
        await SharedpreferenceHelper().saveAccessToken(response['accessToken']);
        await SharedpreferenceHelper()
            .saveRefreshToken(response['refreshToken']);

        // Save user data
        if (response['user'] != null) {
          final user = response['user'];
          await SharedpreferenceHelper().saveUserID(user['id']);
          await SharedpreferenceHelper().saveUserName(user['name']);
          await SharedpreferenceHelper().saveUserEmail(user['email']);
        }

        return {
          'success': true,
          'message': 'Login successful',
          'user': response['user'],
        };
      } else {
        throw Exception('Invalid response from server');
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Refresh access token
  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final refreshToken = await SharedpreferenceHelper().getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return {
          'success': false,
          'message': 'No refresh token available',
        };
      }

      final response = await _apiClient.post(
        '/auth/refresh',
        body: {'refreshToken': refreshToken},
        requireAuth: false,
      );

      if (response['accessToken'] != null) {
        await SharedpreferenceHelper().saveAccessToken(response['accessToken']);
        return {
          'success': true,
          'message': 'Token refreshed',
        };
      } else {
        throw Exception('Invalid response from server');
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Logout - clear all stored data
  Future<void> logout() async {
    try {
      await SharedpreferenceHelper().clearAllData();
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await SharedpreferenceHelper().getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Submit KYC verification documents
  Future<Map<String, dynamic>> submitKYC({
    required String idDocument,
    required String proofOfAddress,
    required String proofOfPhone,
  }) async {
    try {
      final userId = await SharedpreferenceHelper().getUserID();
      if (userId == null || userId.isEmpty) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      final response = await _apiClient.post(
        '/kyc/submit',
        body: {
          'userId': userId,
          'idDocument': idDocument,
          'proofOfAddress': proofOfAddress,
          'proofOfPhone': proofOfPhone,
          'submissionDate': DateTime.now().toIso8601String(),
        },
        requireAuth: true,
      );

      if (response['success'] == true || response['status'] == 'pending') {
        return {
          'success': true,
          'message': 'KYC submitted successfully',
          'data': response,
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to submit KYC',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error submitting KYC: ${e.toString()}',
      };
    }
  }

  /// Get KYC verification status
  Future<Map<String, dynamic>> getKYCStatus() async {
    try {
      final userId = await SharedpreferenceHelper().getUserID();
      if (userId == null || userId.isEmpty) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      final response = await _apiClient.get(
        '/kyc/status/$userId',
        requireAuth: true,
      );

      if (response['success'] == true || response['status'] != null) {
        return {
          'success': true,
          'status': response['status'] ?? 'pending',
          'data': response,
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to get status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error getting KYC status: ${e.toString()}',
      };
    }
  }
}
