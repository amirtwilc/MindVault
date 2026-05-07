import 'package:flutter/material.dart';

const kCategoryColors = [
  '#EF5350', // Red
  '#FF7043', // Deep Orange
  '#FFCA28', // Amber
  '#66BB6A', // Green
  '#26A69A', // Teal
  '#00BCD4', // Cyan
  '#42A5F5', // Blue
  '#5C6BC0', // Indigo
  '#AB47BC', // Purple
  '#EC407A', // Pink
  '#8D6E63', // Brown
  '#CDDC39', // Lime
];

Color categoryColor(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF78909C); // default blue-grey
  final buffer = StringBuffer();
  if (hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

/// Returns white or black text color that is readable on [bg].
Color categoryTextColor(Color bg) =>
    bg.computeLuminance() > 0.45 ? Colors.black87 : Colors.white;
