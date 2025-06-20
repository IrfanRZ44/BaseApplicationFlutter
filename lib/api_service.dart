// lib/api_service.dart

import 'dart:convert'; // For encoding/decoding JSON
import 'package:http/http.dart' as http; // For making HTTP requests

class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;

  ApiResponse({required this.success, required this.message, this.data});

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      // data: json['data'],
      data: json['data'] is Map<String, dynamic> ? json['data'] : {},
    );
  }
}

class ApiService {
  // Static function to perform login API call
  static Future<ApiResponse> login({
    required String username,
    required String password,
    required String estate,
    required String imei,
    required String apkVersion,
    required String clientId,
    required String clientSecret,
  }) async {
    // The endpoint URL for login
    final url = Uri.parse('https://epms.wilmar.co.id/API/ePMS/getLogin');

    // Headers to be included in the request
    final headers = {
      'Content-Type': 'application/json',
      'X-CPrint': '', // Custom header (still unused)
      'client_id': '18012016', // Static client ID
      'client_secret': '61646974636f79', // Static client secret
      'module': 'eBCC', // Module name
    };

    // Body data to send in the POST request
    final body = jsonEncode({
      "username": username,
      "password": password,
      "estateCode": estate,
      "apkVersion": "eBCC.3.8.5_PARTHENO",
      "Country": "ID",
      "imei": imei,
      "current_divisi": "0",
      "current_block": "0",
      "current_harvester": "0",
      "current_tph": "0",
      "current_employee": "0",
      "current_mandor": "0",
      "current_truck": "0",
      "current_supir": "0",
      "current_supervisor": "0",
      "current_auc": "0",
      "current_cost_center": "0",
      "current_customers": "0",
      "current_license": "0",
      "current_jobcode": "0",
      "current_pickup_driver": "0",
      "current_pickup_truck": "0",
      "current_material": "0"
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      print('Login success: $body');

      final decoded = jsonDecode(response.body);
      final result = decoded['result'];
      final data = decoded['data'];

      if (response.statusCode == 200) {
        if (result != null && result['status'] == "1") {
          return ApiResponse(
            success: true,
            message: result['message'] ?? 'Login successful',
            data: data, // 👈 Now correctly using the top-level "data"
          );
        } else {
          return ApiResponse(
            success: false,
            message: result?['message'] ?? 'Login failed',
            data: data,
          );
        }
      }
      else{
        return ApiResponse(
          success: false,
          message: 'Login gagal',
          data: data,
        );
      }
    } catch (e) {
      print('🔥 Error: $e');
      return ApiResponse(success: false, message: 'Failed to connect to server.');
    }
  }
}
