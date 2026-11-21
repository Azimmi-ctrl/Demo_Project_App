import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  
static const String baseUrl = 'http://127.0.0.1:5000';


  // Test whether Flask and PostgreSQL are connected.
  static Future<Map<String, dynamic>> healthCheck() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/health'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Flask backend is unavailable.');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // Send a Firebase ID token to a protected API.
  static Future<Map<String, dynamic>> authenticatedRequest(
    String endpoint, {
    required bool post,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Please log in first.');
    }

    final token = await user.getIdToken();

    if (token == null || token.isEmpty) {
      throw Exception('Unable to get Firebase ID token.');
    }

    final url = Uri.parse('$baseUrl$endpoint');

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    late final http.Response response;

    if (post) {
      response = await http
          .post(url, headers: headers)
          .timeout(const Duration(seconds: 15));
    } else {
      response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['error'] ?? 'Request failed.');
    }

    return data;
  }

  // Create student + wallet in PostgreSQL.
  static Future<Map<String, dynamic>> syncStudent() {
    return authenticatedRequest('/api/students/sync', post: true);
  }

  // Retrieve logged-in student's data.
  static Future<Map<String, dynamic>> getMyProfile() {
    return authenticatedRequest('/api/students/me', post: false);
  }

  // Display connection results in the debug console.
  static Future<void> testConnection() async {
    final health = await healthCheck();
    debugPrint('Backend health: $health');

    final student = await syncStudent();
    debugPrint('Student synchronized: $student');

    final profile = await getMyProfile();
    debugPrint('Student profile retrieved: $profile');
  }

  static Future<Map<String, dynamic>> getWallet() {
    return authenticatedRequest('/api/wallet', post: false);
  }

  static Future<Map<String, dynamic>> topUpWallet({
    required int amountSen,
    required String idempotencyKey,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Please log in first.');
    }

    final token = await user.getIdToken();

    if (token == null || token.isEmpty) {
      throw Exception('Unable to get Firebase token.');
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/api/wallet/topup'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'amount_sen': amountSen,
            'idempotency_key': idempotencyKey,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['error'] ?? 'Top-up failed.');
    }

    return data;
  }

  static Future<Map<String, dynamic>> getTransactions() {
    return authenticatedRequest('/api/wallet/transactions', post: false);
  }

  static Future<Map<String, dynamic>> transferMoney({
    required String recipientEmail,
    required int amountSen,
    required String idempotencyKey,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Please log in first.');
    }

    final token = await user.getIdToken();

    if (token == null || token.isEmpty) {
      throw Exception('Unable to get Firebase ID token.');
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/api/wallet/transfer'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'recipient_email': recipientEmail.trim().toLowerCase(),
            'amount_sen': amountSen,
            'idempotency_key': idempotencyKey,
          }),
        )
        .timeout(const Duration(seconds: 20));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['error'] ?? 'Transfer failed.');
    }

    return data;
  }

  static Future<Map<String, dynamic>> getSavings() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Please log in first.');
    }

    final token = await user.getIdToken();

    if (token == null || token.isEmpty) {
      throw Exception('Unable to get Firebase ID token.');
    }

    final response = await http
        .get(
          Uri.parse('$baseUrl/api/savings'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 20));

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid savings API response.');
    }

    if (response.statusCode != 200) {
      throw Exception(decoded['error'] ?? 'Failed to load savings.');
    }

    return decoded;
  }

  // ======================================
  // CASHLY CAMPUS - SAVINGS HISTORY
  // ======================================

  static Future<Map<String, dynamic>> getSavingsTransactions() {
    return authenticatedRequest('/api/savings/transactions', post: false);
  }

  // ======================================
  // CASHLY CAMPUS - SAVINGS TRANSACTIONS
  // ======================================

  static Future<Map<String, dynamic>> depositSavings({
    required int amountSen,
    required String idempotencyKey,
  }) async {
    return _moveSavings(
      operation: 'deposit',
      amountSen: amountSen,
      idempotencyKey: idempotencyKey,
    );
  }

  static Future<Map<String, dynamic>> withdrawSavings({
    required int amountSen,
    required String idempotencyKey,
  }) async {
    return _moveSavings(
      operation: 'withdraw',
      amountSen: amountSen,
      idempotencyKey: idempotencyKey,
    );
  }

  static Future<Map<String, dynamic>> _moveSavings({
    required String operation,
    required int amountSen,
    required String idempotencyKey,
  }) async {
    if (operation != 'deposit' && operation != 'withdraw') {
      throw ArgumentError('Invalid savings operation.');
    }

    if (amountSen < 100 || amountSen > 100000) {
      throw Exception('Amount must be between RM1 and RM1000.');
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Please log in first.');
    }

    // Refresh the Firebase token before making the request.
    final token = await user.getIdToken(true);

    if (token == null || token.isEmpty) {
      throw Exception('Unable to get Firebase ID token.');
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/api/savings/$operation'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'amount_sen': amountSen,
            'idempotency_key': idempotencyKey,
          }),
        )
        .timeout(const Duration(seconds: 20));

    Map<String, dynamic> data;

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Unexpected response format.');
      }
      data = decoded;
    } on FormatException {
      throw Exception(
        'Savings API returned an invalid response '
        '(HTTP ${response.statusCode}).',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data['error']?.toString() ?? 'Savings transaction failed.',
      );
    }

    return data;
  }

  // ======================================
  // CASHLY CAMPUS - GET EXPENSES
  // ======================================

  static Future<Map<String, dynamic>> getExpenses({
    int? year,
    int? month,
  }) async {
    if ((year == null) != (month == null)) {
      throw ArgumentError('Provide both year and month.');
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Please log in first.');
    }

    final token = await user.getIdToken();

    if (token == null || token.isEmpty) {
      throw Exception('Unable to get Firebase token.');
    }

    final uri = Uri.parse('$baseUrl/api/expenses').replace(
      queryParameters: year == null
          ? null
          : {'year': year.toString(), 'month': month.toString()},
    );

    final response = await http
        .get(uri, headers: {'Authorization': 'Bearer $token'})
        .timeout(const Duration(seconds: 20));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Unable to load expenses.');
    }

    return data;
  }

  // ======================================
  // CASHLY CAMPUS - RECORD EXPENSE
  // ======================================

  static Future<Map<String, dynamic>> recordExpense({
    required int amountSen,
    required String category,
    required String description,
    required DateTime expenseDate,
  }) async {
    if (amountSen < 1 || amountSen > 10000000) {
      throw Exception('Expense must be between RM0.01 and RM100,000.');
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Please log in first.');
    }

    final token = await user.getIdToken();

    if (token == null || token.isEmpty) {
      throw Exception('Unable to get Firebase token.');
    }

    final dateText =
        '${expenseDate.year.toString().padLeft(4, '0')}-'
        '${expenseDate.month.toString().padLeft(2, '0')}-'
        '${expenseDate.day.toString().padLeft(2, '0')}';

    final response = await http
        .post(
          Uri.parse('$baseUrl/api/expenses'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'amount_sen': amountSen,
            'category': category,
            'description': description,
            'expense_date': dateText,
          }),
        )
        .timeout(const Duration(seconds: 20));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 201) {
      throw Exception(data['error'] ?? 'Unable to record expense.');
    }

    return data;
  }
}
