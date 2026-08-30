import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Profil Mahasiswa')),
        body: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.school, size: 72),
            SizedBox(height: 16),
            Text('Excell Christian', style: TextStyle(fontSize: 24)),
            Text('NIM: 244107020227'),
            Text('Hobby: Bermain futsal dan game'),
            Text('Pemrograman Mobile - Minggu 1'),
          ]),
        ),
      ),
    );
  }
}