import 'package:flutter/material.dart';

class ProduitModel {
  final String? id;
  final String nomComplet;
  final String principesActifs;
  final double prixPrive;
  final String classeMedicamenteuse;
  final String format;
  final String dosage;
  final String laboratoire;
  final String conditionnement;
  final DateTime dateAjout;

  ProduitModel({
    this.id,
    required this.nomComplet,
    required this.principesActifs,
    required this.prixPrive,
    required this.classeMedicamenteuse,
    required this.format,
    required this.dosage,
    required this.laboratoire,
    required this.conditionnement,
    DateTime? dateAjout,
  }) : dateAjout = dateAjout ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'nomComplet': nomComplet,
      'principesActifs': principesActifs,
      'prixPrive': prixPrive,
      'classeMedicamenteuse': classeMedicamenteuse,
      'format': format,
      'dosage': dosage,
      'laboratoire': laboratoire,
      'conditionnement': conditionnement,
      'dateAjout': dateAjout.toIso8601String(),
    };
  }

  factory ProduitModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProduitModel(
      id: documentId,
      nomComplet: map['nomComplet'] ?? '',
      principesActifs: map['principesActifs'] ?? '',
      prixPrive: (map['prixPrive'] ?? 0.0).toDouble(),
      classeMedicamenteuse: map['classeMedicamenteuse'] ?? '',
      format: map['format'] ?? '',
      dosage: map['dosage'] ?? '',
      laboratoire: map['laboratoire'] ?? '',
      conditionnement: map['conditionnement'] ?? '',
      dateAjout: map['dateAjout'] != null
          ? DateTime.parse(map['dateAjout'])
          : DateTime.now(),
    );
  }
}
