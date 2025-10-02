import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  _ProgressScreenState createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<dynamic> _progress = [];

  @override
  void initState() {
    super.initState();
    _fetchProgress();
  }

  void _fetchProgress() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    final response = await http.get(
      Uri.parse('http://localhost:3000/api/progress'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        _progress = json.decode(response.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
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
        child: _progress.isEmpty
            ? const Center(
                child: Text(
                  'No progress data',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Your Quiz Scores',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          barGroups: _progress.asMap().entries.map((entry) {
                            int index = entry.key;
                            var prog = entry.value;
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: prog['score'].toDouble(),
                                  gradient: const LinearGradient(
                                    colors: [Colors.purple, Colors.blue],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  width: 20,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            );
                          }).toList(),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'Quiz ${value.toInt() + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 10,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.white.withOpacity(0.2),
                                strokeWidth: 1,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat('Total Quizzes', _progress.length.toString()),
                          _buildStat('Average Score', '${(_progress.map((p) => p['score']).reduce((a, b) => a + b) / _progress.length).toStringAsFixed(1)}'),
                          _buildStat('Highest Score', '${_progress.map((p) => p['score']).reduce((a, b) => a > b ? a : b)}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
