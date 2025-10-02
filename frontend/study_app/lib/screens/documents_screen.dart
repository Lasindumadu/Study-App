import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'flashcards_screen.dart';
import 'quizzes_screen.dart';
import 'package:flutter_tts/flutter_tts.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  _DocumentsScreenState createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<dynamic> _documents = [];

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  void _fetchDocuments() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    final response = await http.get(
      Uri.parse('http://localhost:3000/api/documents'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        _documents = json.decode(response.body);
      });
    }
  }

  void _summarize(String docId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    final response = await http.post(
      Uri.parse('http://localhost:3000/api/summarize'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: json.encode({'documentId': docId}),
    );

    if (response.statusCode == 200) {
      final summary = json.decode(response.body)['summary'];
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Summary'),
          content: Text(summary),
          actions: [
            TextButton(
              onPressed: () async {
                FlutterTts flutterTts = FlutterTts();
                await flutterTts.speak(summary);
              },
              child: const Text('Speak'),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Documents')),
      body: ListView.builder(
        itemCount: _documents.length,
        itemBuilder: (context, index) {
          final doc = _documents[index];
          return ListTile(
            title: Text(doc['filename']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _summarize(doc['_id']),
                      child: const Text('Summarize'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => FlashcardsScreen(documentId: doc['_id'])));
                      },
                      child: const Text('Flashcards'),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => QuizzesScreen(documentId: doc['_id'])));
                  },
                  child: const Text('Quizzes'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
