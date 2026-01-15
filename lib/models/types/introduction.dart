import 'package:flutter/material.dart';

class PageData {
  final IconData? icon;
  final String? image;
  final String title;
  final String description;

  PageData({
    this.icon,
    this.image,
    required this.title,
    required this.description,
  });
}
