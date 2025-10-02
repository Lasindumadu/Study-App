import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  bool get isAuthenticated => _token != null;

  String? get token => _token;

  Future<void> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _token = data['token'];
      await _saveToken(_token!);
      notifyListeners();
    } else {
      throw Exception('Login failed');
    }
  }

  Future<void> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name, 'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _token = data['token'];
      await _saveToken(_token!);
      notifyListeners();
    } else {
      throw Exception('Registration failed');
    }
  }

  Future<void> logout() async {
    _token = null;
    await _removeToken();
    notifyListeners();
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    notifyListeners();
  }
}
