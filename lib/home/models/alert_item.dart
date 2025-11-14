import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class AlertItem extends Equatable {
  final String id;
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color color;
  final String type;

  const AlertItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.color,
    required this.type,
  });

  @override
  List<Object> get props => [id, title, message, time, icon, color, type];
}
