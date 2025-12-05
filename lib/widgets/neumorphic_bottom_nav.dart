import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

class NeumorphicBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  const NeumorphicBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = const [
      _NavItem(Icons.home, 'Home'),
      _NavItem(Icons.history, 'Riwayat'),
      _NavItem(Icons.shopping_cart, 'Cart'),
      _NavItem(Icons.person, 'Profil'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Neumorphic(
        style: const NeumorphicStyle(
          depth: 4,
          intensity: 0.7,
          lightSource: LightSource.topLeft,
        ),
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavButton(
                  item: items[i],
                  selected: i == currentIndex,
                  onPressed: () => onTap(i),
                )
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onPressed;
  const _NavButton({required this.item, required this.selected, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return NeumorphicButton(
      onPressed: onPressed,
      style: NeumorphicStyle(
        depth: selected ? 8 : 4,
        intensity: 0.8,
        lightSource: LightSource.topLeft,
        color: NeumorphicColors.background,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: selected ? const Color(0xFF1E88E5) : null),
          const SizedBox(height: 4),
          Text(item.label, style: TextStyle(color: selected ? const Color(0xFF1E88E5) : null)),
        ],
      ),
    );
  }
}

