import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/database_helper.dart';

class QuizzesScreen extends StatefulWidget {
  final String documentId;

  const QuizzesScreen({super.key, required this.documentId});

  @override
  _QuizzesScreenState createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  List<dynamic> _quizzes = [];
  int _currentIndex = 0;
  int? _selectedOption;

  @override
  void initState() {
    super.initState();
    _fetchQuizzes();
  }

  void _fetchQuizzes() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    // First, try to fetch existing quizzes
    final fetchResponse = await http.get(
      Uri.parse('http://localhost:3000/api/quizzes/${widget.documentId}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (fetchResponse.statusCode == 200) {
      final fetched = json.decode(fetchResponse.body);
      if (fetched.isNotEmpty) {
        setState(() {
          _quizzes = fetched;
        });
        return;
      }
    }

    // If no existing, generate new ones
    final generateResponse = await http.post(
      Uri.parse('http://localhost:3000/api/quizzes/generate/${widget.documentId}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (generateResponse.statusCode == 200) {
      setState(() {
        _quizzes = json.decode(generateResponse.body);
      });
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _quizzes.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_quizzes.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF6A1B9A), Color(0xFF121212)],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    final quiz = _quizzes[_currentIndex];
    final options = List<String>.from(quiz['options']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzes'),
        backgroundColor: const Color(0xFF6A1B9A),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6A1B9A), Color(0xFF121212)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (_currentIndex + 1) / _quizzes.length,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                'Question ${_currentIndex + 1}/${_quizzes.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Colors.grey],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  quiz['question'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A1B9A),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: options.asMap().entries.map((entry) {
                    int idx = entry.key;
                    String option = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedOption == idx ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedOption == idx ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: RadioListTile<int>(
                          title: Text(
                            option,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          value: idx,
                          groupValue: _selectedOption,
                          onChanged: (value) {
                            setState(() {
                              _selectedOption = value;
                            });
                          },
                          activeColor: Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _selectedOption != null ? _nextQuestion : null,
                icon: const Icon(Icons.arrow_forward),
                label: Text(_currentIndex < _quizzes.length - 1 ? 'Next' : 'Finish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedOption != null ? Colors.white : Colors.grey,
                  foregroundColor: const Color(0xFF6A1B9A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
