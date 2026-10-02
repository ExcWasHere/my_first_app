import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pengumuman $id'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: Center(child: Text('Detail pengumuman dengan id: $id')),
    );
  }
}