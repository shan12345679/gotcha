import 'package:flutter/material.dart';
import '../widgets/header_nav.dart';

class ItemViewScreenHome extends StatelessWidget {
  final bool isLost;

  const ItemViewScreenHome({
    super.key,
    required this.isLost,
  });

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

              // 🔹 HEADER (REUSED)
              const HeaderNav(),

              const SizedBox(height: 10),

// 🔙 BACK BUTTON (WIRE FRAME STYLE)
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  children: const [
                    Icon(
                      Icons.arrow_back,
                      size: 18,
                    ),
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

              // 🖼 ITEM IMAGE
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'images/wallet.jpg',
                    width: 220,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 🏷 ITEM TITLE
              const Text(
                'BROWN WALLET',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 16),

              // 📝 DESCRIPTION
              _infoRow(
                icon: Icons.chat_bubble_outline,
                title: 'Description',
                value: 'I lost my wallet. Last seen at SPCB Room 202.',
              ),

              const SizedBox(height: 12),

              // 📍 LAST SEEN LOCATION
              _infoRow(
                icon: Icons.location_on_outlined,
                title: 'Last seen location',
                value: 'SPCB Room 202',
              ),

              const SizedBox(height: 12),

              // 📅 DATE LOST / FOUND
              _infoRow(
                icon: Icons.calendar_month_outlined,
                title: isLost ? 'Date lost' : 'Date found',
                value: 'May 01, 2026',
              ),

              const SizedBox(height: 12),

              // 📞 CONTACT
              _infoRow(
                icon: Icons.call_outlined,
                title: 'Contact',
                value: '0912 345 6789',
              ),

              const SizedBox(height: 22),

              // ℹ INFO NOTICE
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFBFD9F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: const [
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

  // 🔹 REUSABLE INFO ROW
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