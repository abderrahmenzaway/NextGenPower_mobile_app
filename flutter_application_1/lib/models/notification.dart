import 'package:flutter/material.dart';

class Notification {
  final String id;
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final DateTime timestamp;

  Notification({
    required this.id,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.timestamp,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day ago';
    } else {
      return '${(difference.inDays / 7).floor()} week ago';
    }
  }
}
