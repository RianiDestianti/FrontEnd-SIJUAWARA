import 'package:flutter/material.dart';
import 'package:skoring/models/navigation.dart';

class WalikelasNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const WalikelasNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  
  State<WalikelasNavigation> createState
  () => _WalikelasNavigationState();
}

class _WalikelasNavigationState extends State<WalikelasNavigation> {
  final List<NavigationItemData> _items = [
    NavigationItemData(
      index: 0,
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Beranda',
    ),
    NavigationItemData(
      index: 1,
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups,
      label: 'Siswa',
    ),
    NavigationItemData(
      index: 2,
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment,
      label: 'Laporan',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            spreadRadius: 0,
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
          BoxShadow(
            color: Color(0x0D000000),
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: _items.map((item) => NavigationItem(
          item: item,
          currentIndex: widget.currentIndex,
          onTap: widget.onTap,
        )).toList(),
      ),
    );
  }
}

class NavigationItem extends StatelessWidget {
  final NavigationItemData item;
  final int currentIndex;
  final Function(int) onTap;

  const NavigationItem({
    Key? key,
    required this.item,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == item.index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(item.index),
        child: SizedBox(
          height: 70,
          child: Stack(
            children: [
              IndicatorBar(isActive: isActive),
              NavItemContent(
                isActive: isActive,
                icon: item.icon,
                activeIcon: item.activeIcon,
                label: item.label,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IndicatorBar extends StatelessWidget {
  final bool isActive;

  const IndicatorBar({Key? key, required this.isActive}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: 0,
      left: isActive ? 20 : 35,
      right: isActive ? 20 : 35,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: isActive ? 3 : 0,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class NavItemContent extends StatelessWidget {
  final bool isActive;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavItemContent({
    Key? key,
    required this.isActive,
    required this.icon,
    required this.activeIcon,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            AnimatedIcon(
              isActive: isActive,
              icon: icon,
              activeIcon: activeIcon,
            ),
            const SizedBox(height: 6),
            AnimatedLabel(
              isActive: isActive,
              label: label,
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedIcon extends StatelessWidget {
  final bool isActive;
  final IconData icon;
  final IconData activeIcon;

  const AnimatedIcon({
    Key? key,
    required this.isActive,
    required this.icon,
    required this.activeIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Icon(
        isActive ? activeIcon : icon,
        color: isActive ? Colors.blue : Colors.grey.shade600,
        size: 24,
      ),
    );
  }
}

class AnimatedLabel extends StatelessWidget {
  final bool isActive;
  final String label;

  const AnimatedLabel({
    Key? key,
    required this.isActive,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 300),
      style: TextStyle(
        color: isActive ? Colors.blue : Colors.grey.shade600,
        fontSize: 11,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
      ),
      child: Text(label),
    );
  }
}
