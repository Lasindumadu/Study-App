import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  String? _fileName;
  Uint8List? _fileBytes;
  bool _isLoadingFile = false;
  TextEditingController _textController = TextEditingController();
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  void _pickFile() async {
    setState(() {
      _isLoadingFile = true;
    });

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withReadStream: !kIsWeb, // Only allow readStream on non-web
    );

    if (result != null) {
      PlatformFile file = result.files.single;

      setState(() {
        _fileName = file.name;
      });

      if (kIsWeb) {
        // Web → use bytes directly
        setState(() {
          _fileBytes = file.bytes;
          _isLoadingFile = false;
        });
      } else {
        // Mobile/Desktop → use readStream if available
        if (file.readStream != null) {
          List<int> bytes = [];
          await for (var data in file.readStream!) {
            bytes.addAll(data);
          }
          setState(() {
            _fileBytes = Uint8List.fromList(bytes);
            _isLoadingFile = false;
          });
        } else {
          // Fallback
          setState(() {
            _fileBytes = file.bytes;
            _isLoadingFile = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoadingFile = false;
      });
    }
  }

  void _uploadFile() async {
    if (_fileName == null || _fileBytes == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://localhost:3000/api/documents/upload'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(http.MultipartFile.fromBytes('file', _fileBytes!, filename: _fileName));

    var response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload successful')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed')));
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) => setState(() {
          _textController.text = val.recognizedWords;
        }));
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _uploadText() async {
    if (_textController.text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    final response = await http.post(
      Uri.parse('http://localhost:3000/api/documents/upload-text'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: json.encode({'text': _textController.text}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Text upload successful')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Text upload failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Document')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // PDF Upload Section
            const Text('Upload PDF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: _isLoadingFile ? null : _pickFile,
              child: _isLoadingFile ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator()) : Text('Pick PDF File'),
            ),
            if (_fileName != null) Text(_isLoadingFile ? 'Loading file...' : 'Selected: $_fileName'),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: (_fileName != null && _fileBytes != null && !_isLoadingFile) ? _uploadFile : null,
              child: const Text('Upload PDF'),
            ),
            const Divider(height: 40),
            // Text Input Section
            const Text('Or Input Text', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Enter text here',
                suffixIcon: IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  onPressed: _listen,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadText,
              child: const Text('Upload Text'),
            ),
          ],
        ),
      ),
    );
  }
}
