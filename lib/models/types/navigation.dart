import 'package:flutter/material.dart';

class NavigationItemData {
  final int index;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  NavigationItemData({
    required this.index,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

