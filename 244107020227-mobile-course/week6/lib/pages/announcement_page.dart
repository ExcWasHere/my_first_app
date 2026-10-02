import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes.dart';

class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pengumuman $id'),
        leading: BackButton(onPressed: () => context.go(AppRoutes.home)),
      ),
      body: Center(child: Text('Detail pengumuman dengan id: $id')),
    );
  }
}