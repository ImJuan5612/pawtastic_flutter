import 'package:flutter/material.dart';

class ServiceCatalogItem {
  final String name;
  final double basePrice;
  final String? description;
  final int? iconCodePoint;
  final String? iconFontFamily;
  final String? iconColorHex;

  ServiceCatalogItem({
    required this.name,
    required this.basePrice,
    this.description,
    this.iconCodePoint,
    this.iconFontFamily,
    this.iconColorHex,
  });

  factory ServiceCatalogItem.fromJson(Map<String, dynamic> json) {
    return ServiceCatalogItem(
      name: json['name'] as String,
      basePrice: (json['base_price'] as num).toDouble(),
      description: json['description'] as String?,
      iconCodePoint: json['icon_code_point'] as int?,
      iconFontFamily: json['icon_font_family'] as String?,
      iconColorHex: json['icon_color_hex'] as String?,
    );
  }

  IconData? get iconData {
    if (iconCodePoint != null && iconFontFamily != null) {
      return IconData(iconCodePoint!, fontFamily: iconFontFamily!);
    }
    return null;
  }

  Color? get iconColor {
    if (iconColorHex != null && iconColorHex!.length == 6) {
      try {
        return Color(int.parse('0xFF$iconColorHex'));
      } catch (e) {
        return null; // O un color por defecto
      }
    }
    return null;
  }
}
