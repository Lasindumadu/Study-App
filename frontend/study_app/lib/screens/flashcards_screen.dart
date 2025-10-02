import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/database_helper.dart';

class FlashcardsScreen extends StatefulWidget {
  final String documentId;

  const FlashcardsScreen({super.key, required this.documentId});

  @override
  _FlashcardsScreenState createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  List<dynamic> _flashcards = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchFlashcards();
  }

  void _fetchFlashcards() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    // First, try to fetch existing flashcards
    final fetchResponse = await http.get(
      Uri.parse('http://localhost:3000/api/flashcards/${widget.documentId}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (fetchResponse.statusCode == 200) {
      final fetched = json.decode(fetchResponse.body);
      if (fetched.isNotEmpty) {
        setState(() {
          _flashcards = fetched;
        });
        return;
      }
    }

    // If no existing, generate new ones
    final generateResponse = await http.post(
      Uri.parse('http://localhost:3000/api/flashcards/generate/${widget.documentId}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (generateResponse.statusCode == 200) {
      setState(() {
        _flashcards = json.decode(generateResponse.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
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
        child: _flashcards.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Card ${_currentIndex + 1} of ${_flashcards.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: FlipCard(
                        front: _buildCard(_flashcards[_currentIndex]['question'], 'Question'),
                        back: _buildCard(_flashcards[_currentIndex]['answer'], 'Answer'),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _currentIndex > 0 ? () => setState(() => _currentIndex--) : null,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Previous'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentIndex > 0 ? Colors.white : Colors.grey,
                            foregroundColor: const Color(0xFF6A1B9A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _currentIndex < _flashcards.length - 1 ? () => setState(() => _currentIndex++) : null,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Next'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentIndex < _flashcards.length - 1 ? Colors.white : Colors.grey,
                            foregroundColor: const Color(0xFF6A1B9A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCard(String text, String type) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: type == 'Question' ? [Colors.blue, Colors.purple] : [Colors.green, Colors.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
