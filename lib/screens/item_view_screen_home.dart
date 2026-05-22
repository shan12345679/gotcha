// lib/screens/item_view_screen_home.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/header_nav.dart';

class ItemViewScreenHome extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> report;
  const ItemViewScreenHome({super.key, required this.report});

  bool get isLost => (report['type'] ?? 'lost') == 'lost';
  String get itemName => (report['itemName'] ?? 'Unknown Item').toString().toUpperCase();
  String get description => report['description'] ?? 'No description provided.';
  String get location => report['location'] ?? 'Location not specified.';
  String get contact => report['contact'] ?? 'No contact provided.';
  String get imageUrl => report['imageUrl'] ?? '';

  String get formattedDate {
    final ts = report['date'];
    if (ts == null) return 'Date not specified';
    final dt = (ts as Timestamp).toDate();
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const HeaderNav(),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Row(children: [Icon(Icons.arrow_back, color: AppTheme.gold), SizedBox(width: 6), Text('Back', style: TextStyle(color: AppTheme.gold))]),
              ),
              const SizedBox(height: 24),
              // ✅ Hero + white border + shadow on large image (220x220)
              Center(
                child: Hero(
                  tag: 'image_${report.id}',
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.9), width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 5)),
                        BoxShadow(color: Colors.white.withOpacity(0.15), blurRadius: 15, spreadRadius: 2),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                        imageUrl,
                        width: 220,
                        height: 220,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : Container(
                          width: 220,
                          height: 220,
                          color: AppTheme.navyLight,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.gold)),
                        ),
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                          : _imagePlaceholder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: Text(itemName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: isLost ? Colors.redAccent.withOpacity(0.2) : AppTheme.gold.withOpacity(0.2), borderRadius: BorderRadius.circular(30)),
                    child: Text(isLost ? 'LOST' : 'FOUND', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isLost ? Colors.redAccent : AppTheme.gold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _infoRow(icon: Icons.chat_bubble_outline, title: 'Description', value: description),
              const SizedBox(height: 12),
              _infoRow(icon: Icons.location_on_outlined, title: isLost ? 'Last seen location' : 'Found at', value: location),
              const SizedBox(height: 12),
              _infoRow(icon: Icons.calendar_month_outlined, title: isLost ? 'Date lost' : 'Date found', value: formattedDate),
              const SizedBox(height: 12),
              _infoRow(icon: Icons.call_outlined, title: 'Contact', value: contact),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppTheme.navyLight, borderRadius: BorderRadius.circular(20)),
                child: Row(children: const [Icon(Icons.info_outline, color: AppTheme.gold), SizedBox(width: 10), Expanded(child: Text('You can contact the owner using the information above', style: TextStyle(fontSize: 11, color: Colors.white70)))]),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    width: 220,
    height: 220,
    decoration: BoxDecoration(
      color: AppTheme.navyLight,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
    ),
    child: const Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.white38),
  );

  Widget _infoRow({required IconData icon, required String title, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.gold),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 11, color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }
}