import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';

class PublicityPage extends StatelessWidget {
  const PublicityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<AuthProvider>().api;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Publicités')),
      body: FutureBuilder<dynamic>(
        future: api.request('GET', '/advertisements'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data is! Map) {
            return const Center(child: Text('Impossible de charger les publicités.'));
          }
          final data = Map<String, dynamic>.from(snapshot.data as Map);
          final items = (data['advertisements'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          if (items.isEmpty) {
            return const Center(child: Text('Aucune publicité disponible pour le moment.'));
          }
          return RefreshIndicator(
            onRefresh: () async => (context as Element).markNeedsBuild(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, index) {
                final ad = items[index];
                final url = api.mediaUrl(ad['image_url']?.toString());
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (url != null && url.isNotEmpty)
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const ColoredBox(
                              color: Color(0xFFEAF2FF),
                              child: Center(child: Icon(Icons.broken_image_outlined, size: 60)),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text((ad['title'] ?? 'Publicité').toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            if ((ad['description'] ?? '').toString().trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(ad['description'].toString()),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
