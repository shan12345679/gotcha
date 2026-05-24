import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/header_nav.dart';

class ItemViewScreenHome extends StatelessWidget {
  // Pass the full Firestore document snapshot
  final QueryDocumentSnapshot<Map<String, dynamic>> report;

  const ItemViewScreenHome({
    super.key,
    required this.report,
  });

  // ─── HELPERS ──────────────────────────────────────────────────────
  bool get isLost => (report['type'] ?? 'lost') == 'lost';

  String get itemName =>
      (report['itemName'] ?? 'Unknown Item').toString().toUpperCase();

  String get description =>
      report['description'] ?? 'No description provided.';

  String get location => report['location'] ?? 'Location not specified.';

  String get contact => report['contact'] ?? 'No contact provided.';

  String get imageUrl => report['imageUrl'] ?? '';

  String get formattedDate {
    final ts = report['date'];
    if (ts == null) return 'Date not specified';
    final dt = (ts as Timestamp).toDate();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9E7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // HEADER
              const HeaderNav(),

              const SizedBox(height: 10),

              // BACK BUTTON
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ITEM IMAGE
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
                    width: 220,
                    height: 150,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        width: 220,
                        height: 150,
                        color: Colors.white38,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                      : _imagePlaceholder(),
                ),
              ),

              const SizedBox(height: 20),

              // ITEM TITLE + TYPE BADGE
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      itemName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLost
                          ? Colors.redAccent.withOpacity(0.15)
                          : Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isLost ? 'LOST' : 'FOUND',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isLost ? Colors.redAccent : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // DESCRIPTION
              _infoRow(
                icon: Icons.chat_bubble_outline,
                title: 'Description',
                value: description,
              ),

              const SizedBox(height: 12),

              // LOCATION
              _infoRow(
                icon: Icons.location_on_outlined,
                title: isLost ? 'Last seen location' : 'Found at',
                value: location,
              ),

              const SizedBox(height: 12),

              // DATE
              _infoRow(
                icon: Icons.calendar_month_outlined,
                title: isLost ? 'Date lost' : 'Date found',
                value: formattedDate,
              ),

              const SizedBox(height: 12),

              // CONTACT
              _infoRow(
                icon: Icons.call_outlined,
                title: 'Contact',
                value: contact,
              ),

              const SizedBox(height: 22),

              // INFO NOTICE
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFBFD9F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You can contact the owner using the information above',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ─── IMAGE PLACEHOLDER ─────────────────────────────────────────────
  Widget _imagePlaceholder() {
    return Container(
      width: 220,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white38,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(Icons.image_not_supported_outlined,
          size: 40, color: Colors.black26),
    );
  }

  // ─── REUSABLE INFO ROW ─────────────────────────────────────────────
  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}