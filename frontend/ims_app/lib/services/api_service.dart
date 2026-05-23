import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator uses a special alias to access host localhost.
      return 'http://10.0.2.2:8000';
    }

    // Desktop/iOS simulators typically reach backend on localhost.
    return 'http://127.0.0.1:8000';
  }

  static http.Client client = http.Client();

  static void _ensureSuccess(http.Response response, String action) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    // Convert non-2xx responses into a single readable exception format.
    String details = response.body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        details = (decoded['detail'] ?? decoded['message'] ?? response.body)
            .toString();
      }
    } catch (_) {
      // Keep raw body details when not JSON.
    }

    throw Exception('$action failed (${response.statusCode}): $details');
  }

  static Future<Map<String, dynamic>> checkDatabaseHealth() async {
    // The startup gate uses this response to decide whether to show the
    // dashboard or an offline retry screen.
    try {
      final response = await client.get(Uri.parse('$baseUrl/health/db'));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Fall through to offline status.
    }

    return {
      'status': 'offline',
      'message': 'Database offline. Check backend connection.',
    };
  }

  static Future<List<dynamic>> getProducts() async {
    // Product list is kept simple: fetch, decode, render, refresh.
    final response = await client.get(Uri.parse('$baseUrl/products'));
    _ensureSuccess(response, 'Load products');
    return jsonDecode(response.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await client.get(Uri.parse('$baseUrl/dashboard'));
    _ensureSuccess(response, 'Load dashboard');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getTransactions() async {
    final response = await client.get(Uri.parse('$baseUrl/transactions'));
    _ensureSuccess(response, 'Load transactions');
    return jsonDecode(response.body) as List<dynamic>;
  }

  static Future<List<dynamic>> getSuppliers() async {
    final response = await client.get(Uri.parse('$baseUrl/suppliers'));
    _ensureSuccess(response, 'Load suppliers');
    return jsonDecode(response.body) as List<dynamic>;
  }

  static Future<void> addProduct(Map<String, dynamic> data) async {
    // Product create/update/delete calls stay in the service layer so UI files
    // do not need to know HTTP details.
    final response = await client.post(
      Uri.parse('$baseUrl/products'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    _ensureSuccess(response, 'Add product');
  }

  static Future<void> updateProduct(int id, Map<String, dynamic> data) async {
    final response = await client.put(
      Uri.parse('$baseUrl/products/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    _ensureSuccess(response, 'Update product');
  }

  static Future<void> deleteProduct(int id) async {
    final response = await client.delete(Uri.parse('$baseUrl/products/$id'));
    _ensureSuccess(response, 'Delete product');
  }

  static Future<void> stockIn(int productId, int quantity) async {
    // Stock movement endpoints keep transaction history in sync.
    final response = await client.post(
      Uri.parse('$baseUrl/stock_in'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'product_id': productId, 'quantity': quantity}),
    );
    _ensureSuccess(response, 'Stock in');
  }

  static Future<void> stockOut(int productId, int quantity) async {
    final response = await client.post(
      Uri.parse('$baseUrl/stock_out'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'product_id': productId, 'quantity': quantity}),
    );
    _ensureSuccess(response, 'Stock out');
  }

  static Future<void> addSupplier(Map<String, dynamic> data) async {
    final response = await client.post(
      Uri.parse('$baseUrl/suppliers'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    _ensureSuccess(response, 'Add supplier');
  }

  static Future<void> updateSupplier(int id, Map<String, dynamic> data) async {
    final response = await client.put(
      Uri.parse('$baseUrl/suppliers/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    _ensureSuccess(response, 'Update supplier');
  }

  static Future<void> deleteSupplier(int id) async {
    final response = await client.delete(Uri.parse('$baseUrl/suppliers/$id'));
    _ensureSuccess(response, 'Delete supplier');
  }
}
