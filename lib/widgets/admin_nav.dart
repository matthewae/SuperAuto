import 'package:flutter/material.dart';

class AdminNav extends StatelessWidget {
  final int selected;
  final Function(int) onSelect;

  const AdminNav({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem("Products", Icons.inventory_2_outlined),
      _NavItem("Orders", Icons.receipt_long),
      _NavItem("Booking", Icons.event_note),
      _NavItem("History", Icons.history),
      _NavItem("Profile", Icons.person),
    ];

    return Container(
      width: 220,
      color: const Color(0xFF1E1E1E),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            "Admin Panel",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 30),

          // Navigation items
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, index) {
                final isActive = index == selected;
                return InkWell(
                  onTap: () => onSelect(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: isActive
                        ? BoxDecoration(
                      color: Colors.blue.shade600.withValues(alpha: 0.2),
                      border: Border(
                        left: BorderSide(color: Colors.blue.shade400, width: 4),
                      ),
                    )
                        : null,
                    child: Row(
                      children: [
                        Icon(
                          items[index].icon,
                          color: isActive ? Colors.blue.shade300 : Colors.white70,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          items[index].label,
                          style: TextStyle(
                            fontSize: 16,
                            color: isActive ? Colors.blue.shade300 : Colors.white70,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Logout button placeholder
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text(
                "Logout",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  _NavItem(this.label, this.icon);
}
