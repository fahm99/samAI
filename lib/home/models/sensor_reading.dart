import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SensorReading extends Equatable {
  final String name;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const SensorReading({
    required this.name,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  List<Object> get props => [name, value, unit, icon, color];
}
