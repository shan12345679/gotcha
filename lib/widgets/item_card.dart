import 'package:flutter/material.dart';

class ItemCard extends StatelessWidget {
  final String image;
  final String title;
  final String location;
  final String date;
  final VoidCallback onTap;

  const ItemCard({
    super.key,
    required this.image,
    required this.title,
    required this.location,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                image,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Tap for more details +',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}