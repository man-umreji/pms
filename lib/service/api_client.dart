import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'api_helper.dart';
import 'auth_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final AuthService _authService = AuthService();
  static const int maxRetries = 1;

  // Base URL
  static const String baseUrl = 'https://uatpms.sritindia.com:8443';

  /// Generic request method with interceptor
  Future<http.Response> request({
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    Object? body,
    Encoding? encoding,
    bool requiresAuth = true,
    bool isFormData = false, // ✅ NEW PARAMETER
  }) async {
    // Build URL with query parameters
    String url = endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint';
    if (queryParams != null && queryParams.isNotEmpty) {
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      url = uri.toString();
    }

    int retryCount = 0;

    while (retryCount <= maxRetries) {
      try {
        // Prepare headers
        Map<String, String> requestHeaders = {};

        if (requiresAuth) {
          requestHeaders = await ApiHeaders.get();
        } else {
          requestHeaders = ApiHeaders.getPublic();
        }

        // ✅ For FormData, let multipart set Content-Type with boundary (ApiHeaders forces JSON)
        if (isFormData) {
          requestHeaders.remove('Content-Type');
        } else {
          requestHeaders['Content-Type'] = 'application/json';
        }

        requestHeaders['Accept'] = 'application/json';

        // Merge additional headers
        if (headers != null) {
          requestHeaders.addAll(headers);
        }

        // Log request
        debugPrint('🌐 API Request: $method $url');
        debugPrint('📋 Headers: ${requestHeaders.keys}');
        debugPrint('📋 Content-Type: ${requestHeaders['Content-Type'] ?? 'multipart/form-data'}');

        if (body != null && !isFormData) {
          debugPrint('📦 Body: $body');
        } else if (isFormData) {
          debugPrint('📦 FormData: Sending multipart form data');
        }

        // Make request
        late http.Response response;
        final uri = Uri.parse(url);

        switch (method.toUpperCase()) {
          case 'GET':
            response = await http.get(uri, headers: requestHeaders);
            break;
          case 'POST':
            if (isFormData && body is Map<String, dynamic>) {
              // ✅ Handle FormData
              final request = http.MultipartRequest('POST', uri);
              request.headers.addAll(requestHeaders);

              // Add fields
              body.forEach((key, value) {
                if (value != null) {
                  if (value is http.MultipartFile) {
                    request.files.add(value);
                  } else if (value is List<http.MultipartFile>) {
                    request.files.addAll(value);
                  } else {
                    request.fields[key] = value.toString();
                  }
                }
              });

              final streamedResponse = await request.send();
              response = await http.Response.fromStream(streamedResponse);
            } else if (isFormData && body is http.MultipartRequest) {
              // If body is already a MultipartRequest
              final streamedResponse = await body.send();
              response = await http.Response.fromStream(streamedResponse);
            } else {
              response = await http.post(
                uri,
                headers: requestHeaders,
                body: body is Map ? jsonEncode(body) : body, // ✅ FIX
                encoding: encoding,
              );
            }
            break;
          case 'PUT':
            response = await http.put(
              uri,
              headers: requestHeaders,
              body: body,
              encoding: encoding,
            );
            break;
          case 'PATCH':
            response = await http.patch(
              uri,
              headers: requestHeaders,
              body: body,
              encoding: encoding,
            );
            break;
          case 'DELETE':
            response = await http.delete(uri, headers: requestHeaders);
            break;
          default:
            throw Exception('Unsupported HTTP method: $method');
        }

        // Log response
        debugPrint('✅ API Response: ${response.statusCode}');
        debugPrint('📦 Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

        // Handle 401 Unauthorized
        if (response.statusCode == 401 && requiresAuth && retryCount < maxRetries) {
          debugPrint('🔄 401 Unauthorized - Attempting token refresh (${retryCount + 1}/$maxRetries)');

          final refreshed = await _authService.refreshToken();

          if (refreshed) {
            debugPrint('✅ Token refreshed, retrying request...');
            retryCount++;
            continue;
          } else {
            debugPrint('❌ Token refresh failed');
            await _authService.clearAuthData();
            return response;
          }
        }

        return response;

      } catch (e) {
        debugPrint('❌ Request error: $e');
        rethrow;
      }
    }

    // Final attempt without refresh
    return _makeFinalRequest(method, url, headers, body, encoding, requiresAuth, isFormData);
  }

  /// Final request attempt
  Future<http.Response> _makeFinalRequest(
      String method,
      String url,
      Map<String, String>? headers,
      Object? body,
      Encoding? encoding,
      bool requiresAuth,
      bool isFormData,
      ) async {
    final uri = Uri.parse(url);
    final requestHeaders = <String, String>{};

    if (requiresAuth) {
      final token = await _authService.getToken();
      if (token != null) {
        if (!isFormData) {
          requestHeaders['Content-Type'] = 'application/json';
        }
        requestHeaders['Accept'] = 'application/json';
        requestHeaders['Authorization'] = 'Bearer $token';
      }
    } else {
      if (!isFormData) {
        requestHeaders['Content-Type'] = 'application/json';
      }
      requestHeaders['Accept'] = 'application/json';
    }

    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    switch (method.toUpperCase()) {
      case 'GET':
        return http.get(uri, headers: requestHeaders);
      case 'POST':
        if (isFormData && body is Map<String, dynamic>) {
          final request = http.MultipartRequest('POST', uri);
          request.headers.addAll(requestHeaders);

          body.forEach((key, value) {
            if (value != null) {
              if (value is http.MultipartFile) {
                request.files.add(value);
              } else if (value is List<http.MultipartFile>) {
                request.files.addAll(value);
              } else {
                request.fields[key] = value.toString();
              }
            }
          });

          final streamedResponse = await request.send();
          return await http.Response.fromStream(streamedResponse);
        }
        return http.post(
          uri,
          headers: requestHeaders,
          body: body,
          encoding: encoding,
        );
      case 'PUT':
        return http.put(
          uri,
          headers: requestHeaders,
          body: body,
          encoding: encoding,
        );
      case 'PATCH':
        return http.patch(
          uri,
          headers: requestHeaders,
          body: body,
          encoding: encoding,
        );
      case 'DELETE':
        return http.delete(uri, headers: requestHeaders);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  // Convenience methods with FormData support
  Future<http.Response> get(
      String endpoint, {
        Map<String, String>? headers,
        Map<String, dynamic>? queryParams,
        bool requiresAuth = true,
      }) {
    return request(
      method: 'GET',
      endpoint: endpoint,
      headers: headers,
      queryParams: queryParams,
      requiresAuth: requiresAuth,
    );
  }

  Future<http.Response> post(
      String endpoint, {
        Map<String, String>? headers,
        Map<String, dynamic>? queryParams,
        Object? body,
        Encoding? encoding,
        bool requiresAuth = true,
        bool isFormData = false, // ✅ NEW PARAMETER
      }) {
    return request(
      method: 'POST',
      endpoint: endpoint,
      headers: headers,
      queryParams: queryParams,
      body: body,
      encoding: encoding,
      requiresAuth: requiresAuth,
      isFormData: isFormData,
    );
  }

  Future<http.Response> put(
      String endpoint, {
        Map<String, String>? headers,
        Map<String, dynamic>? queryParams,
        Object? body,
        Encoding? encoding,
        bool requiresAuth = true,
        bool isFormData = false,
      }) {
    return request(
      method: 'PUT',
      endpoint: endpoint,
      headers: headers,
      queryParams: queryParams,
      body: body,
      encoding: encoding,
      requiresAuth: requiresAuth,
      isFormData: isFormData,
    );
  }

  Future<http.Response> patch(
      String endpoint, {
        Map<String, String>? headers,
        Map<String, dynamic>? queryParams,
        Object? body,
        Encoding? encoding,
        bool requiresAuth = true,
        bool isFormData = false,
      }) {
    return request(
      method: 'PATCH',
      endpoint: endpoint,
      headers: headers,
      queryParams: queryParams,
      body: body,
      encoding: encoding,
      requiresAuth: requiresAuth,
      isFormData: isFormData,
    );
  }

  Future<http.Response> delete(
      String endpoint, {
        Map<String, String>? headers,
        Map<String, dynamic>? queryParams,
        bool requiresAuth = true,
      }) {
    return request(
      method: 'DELETE',
      endpoint: endpoint,
      headers: headers,
      queryParams: queryParams,
      requiresAuth: requiresAuth,
    );
  }
}