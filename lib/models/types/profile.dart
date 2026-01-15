import 'package:flutter/material.dart';

class Profile {
  final String name;
  final String role;
  final String nip;
  final String username;
  final String email;
  final String joinDate;

  Profile({
    required this.name,
    required this.role,
    required this.nip,
    required this.username,
    required this.email,
    required this.joinDate,
  });
}

class ProfileField {
  final String label;
  final IconData icon;
  final String key;

  ProfileField({
    required this.label,
    required this.icon,
    required this.key,
  });
}