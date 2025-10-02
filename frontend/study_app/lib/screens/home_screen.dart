import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/feature_card.dart';
import 'upload_screen.dart';
import 'documents_screen.dart';
import 'progress_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Study Buddy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
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
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              FeatureCard(
                icon: Icons.upload_file,
                title: 'Upload Document',
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.blue],
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen()));
                },
              ),
              FeatureCard(
                icon: Icons.folder,
                title: 'My Documents',
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.teal],
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentsScreen()));
                },
              ),
              FeatureCard(
                icon: Icons.flip,
                title: 'Flashcards',
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.red],
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentsScreen()));
                },
              ),
              FeatureCard(
                icon: Icons.quiz,
                title: 'Quizzes',
                gradient: const LinearGradient(
                  colors: [Colors.pink, Colors.purple],
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentsScreen()));
                },
              ),
              FeatureCard(
                icon: Icons.bar_chart,
                title: 'Progress',
                gradient: const LinearGradient(
                  colors: [Colors.indigo, Colors.blue],
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
