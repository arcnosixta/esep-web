import 'package:flutter/material.dart';

enum PropertyType {
  apartment('Квартира', 'apartment', Icons.apartment_rounded, Color(0xFF2563EB)),
  house('Дом', 'house', Icons.home_rounded, Color(0xFF0284C7)),
  land('Участок', 'land', Icons.landscape_rounded, Color(0xFF16A34A)),
  commercial('Коммерческая', 'commercial', Icons.business_rounded, Color(0xFFFBBF24));

  final String label;
  final String dbType;
  final IconData icon;
  final Color color;

  const PropertyType(this.label, this.dbType, this.icon, this.color);
}

const kApplicationFilters = ['Все', 'В работе', 'Завершённые'];

const kDocumentFileTypes = ['JPG', 'PNG', 'PDF'];
