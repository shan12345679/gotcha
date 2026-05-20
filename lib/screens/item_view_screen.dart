import 'package:flutter/material.dart';
import '../widgets/header_nav.dart';

class ItemViewScreen extends StatefulWidget {
  final bool isLost;

  const ItemViewScreen({
    super.key,
    required this.isLost,
  });

  @override
  State<ItemViewScreen> createState() => _ItemViewScreenState();
}

class _ItemViewScreenState extends State<ItemViewScreen> {
  bool isEditing = false;
  bool isResolved = false;

  // SAMPLE DATA (replace later with real data / controllers)
  String title = 'CELLPHONE';
  String description = 'I lost my wallet. Last seen at SPCB Room 202.';
  String location = 'SPCB Room 202';
  String date = 'May 01, 2026';
  String contact = '0912 345 6789';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9E7FB),
      body: SafeArea(
        child: Column(
          children: [
            // ===== HEADER NAV WITH PADDING =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: const HeaderNav(),
            ),

            const SizedBox(height: 8),

            // 🔙 BACK BUTTON (WIRE FRAME STYLE)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  children: const [
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
            ),


            // ===== SCROLLABLE CONTENT =====
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // IMAGE
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          widget.isLost
                              ? 'images/wallet.jpg'
                              : 'images/phone.jpg',
                          width: 220,
                          height: 220,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // TITLE
                    isEditing
                        ? _editField(title, (v) => title = v)
                        : Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 18),

                    _detail(
                      Icons.chat_bubble_outline,
                      'Description',
                      description,
                      isEditing,
                          (v) => description = v,
                    ),

                    _detail(
                      Icons.location_on_outlined,
                      widget.isLost ? 'Last seen location' : 'Found at',
                      location,
                      isEditing,
                          (v) => location = v,
                    ),

                    _detail(
                      Icons.calendar_month_outlined,
                      widget.isLost ? 'Date lost' : 'Date found',
                      date,
                      false,
                      null,
                    ),

                    _detail(
                      Icons.phone_in_talk_outlined,
                      'Contact',
                      contact,
                      isEditing,
                          (v) => contact = v,
                    ),

                    const SizedBox(height: 40),

                    // ===== RESOLVED STATUS =====
                    if (isResolved)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9ED6B8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.isLost
                                ? 'Item has been found'
                                : 'Item has been claimed',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // ===== FIXED BOTTOM ACTION BAR =====
            if (!isResolved)
              Container(
                padding: const EdgeInsets.fromLTRB(26, 12, 26, 22),
                decoration: const BoxDecoration(
                  color: Color(0xFFD9E7FB),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _actionButton(
                            isEditing ? 'Save' : 'Edit',
                            Icons.edit,
                            const Color(0xFF9EC1F7),
                                () {
                              setState(() {
                                isEditing = !isEditing;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _actionButton(
                            isEditing ? 'Cancel' : 'Delete',
                            isEditing ? Icons.close : Icons.delete,
                            const Color(0xFFE59A9A),
                            isEditing ? _cancelEdit : _confirmDelete,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (!isEditing)
                      _actionButton(
                        widget.isLost
                            ? 'Mark as found'
                            : 'Mark as claimed',
                        Icons.check_circle,
                        const Color(0xFF9ED6B8),
                        _confirmMark,
                        fullWidth: true,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===== UI HELPERS =====

  Widget _detail(
      IconData icon,
      String label,
      String value,
      bool editable,
      Function(String)? onChanged,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                editable
                    ? _editField(value, onChanged!)
                    : Text(value, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editField(String initial, Function(String) onChanged) {
    return TextFormField(
      initialValue: initial,
      style: const TextStyle(fontSize: 12),
      onChanged: onChanged,
      decoration: const InputDecoration(
        isDense: true,
        border: UnderlineInputBorder(),
      ),
    );
  }

  Widget _actionButton(
      String text,
      IconData icon,
      Color color,
      VoidCallback onTap, {
        bool fullWidth = false,
      }) {
    return SizedBox(
      height: 44,
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // ===== DIALOGS =====

  void _confirmDelete() {
    _showDialog(
      'Delete item?',
      'Are you sure you want to delete this item?',
          () => Navigator.pop(context),
    );
  }

  void _confirmMark() {
    _showDialog(
      'Confirm action',
      'Clicking yes would mark this item as '
          '${widget.isLost ? 'found' : 'claimed'} '
          'and would no longer show on the main feed.',
          () {
        setState(() {
          isResolved = true;
        });
        Navigator.pop(context);
      },
    );
  }

  void _cancelEdit() {
    setState(() {
      isEditing = false;
    });
  }

  void _showDialog(
      String title,
      String message,
      VoidCallback onConfirm,
      ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: onConfirm,
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}