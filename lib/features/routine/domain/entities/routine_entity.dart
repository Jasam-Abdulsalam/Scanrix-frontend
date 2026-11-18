import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// The two routine slots. [apiValue] is the backend path segment.
enum RoutineSlot {
  morning,
  evening;

  String get apiValue => name;
  String get label => this == morning ? 'Morning' : 'Evening';
  IconData get icon =>
      this == morning ? Icons.wb_sunny_rounded : Icons.nightlight_round;

  /// Morning before 3 pm, evening after: what the routine page opens on.
  static RoutineSlot forTime(DateTime now) => now.hour < 15 ? morning : evening;
}

/// The user's label for a product in their routine (one per product, shared by both slots).
/// [apiValue] is the backend value (`product_type`).
enum RoutineProductType {
  cleanser('Cleanser'),
  toner('Toner'),
  serum('Serum'),
  moisturizer('Moisturizer'),
  sunscreen('Sunscreen'),
  other('Other');

  final String label;
  const RoutineProductType(this.label);

  String get apiValue => name;

  static RoutineProductType? fromApi(Object? raw) {
    for (final t in values) {
      if (t.apiValue == raw) return t;
    }
    return null;
  }
}

/// One step of a routine (`GET /routine/` item, backend API_CONTRACT.md section 16).
/// [verdict]/[overallScore] are the product's stored values; the product screen re-evaluates.
class RoutineItemEntity extends Equatable {
  final String barcode;
  final String name;
  final String? brand;
  final String? imageUrl;
  final String? verdict;
  final int? overallScore;
  final RoutineProductType? productType;

  const RoutineItemEntity({
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    this.verdict,
    this.overallScore,
    this.productType,
  });

  /// The same product with [type] (null clears it).
  RoutineItemEntity withProductType(RoutineProductType? type) =>
      RoutineItemEntity(
        barcode: barcode,
        name: name,
        brand: brand,
        imageUrl: imageUrl,
        verdict: verdict,
        overallScore: overallScore,
        productType: type,
      );

  @override
  List<Object?> get props => [
    barcode,
    name,
    brand,
    imageUrl,
    verdict,
    overallScore,
    productType,
  ];
}

/// The whole routine: each slot's steps in order.
class RoutineEntity extends Equatable {
  final List<RoutineItemEntity> morning;
  final List<RoutineItemEntity> evening;

  const RoutineEntity({this.morning = const [], this.evening = const []});

  static const empty = RoutineEntity();

  List<RoutineItemEntity> slot(RoutineSlot s) =>
      s == RoutineSlot.morning ? morning : evening;

  /// Which slots hold this product (drives "In routine ✓" and the add sheet's ticks).
  Set<RoutineSlot> slotsOf(String barcode) => {
    for (final s in RoutineSlot.values)
      if (slot(s).any((i) => i.barcode == barcode)) s,
  };

  /// The product's type, from whichever slot holds it (both slots share one).
  RoutineProductType? productTypeOf(String barcode) {
    for (final s in RoutineSlot.values) {
      for (final i in slot(s)) {
        if (i.barcode == barcode) return i.productType;
      }
    }
    return null;
  }

  /// Every copy of the product (in either slot) gets [type].
  RoutineEntity withProductType(String barcode, RoutineProductType? type) {
    List<RoutineItemEntity> relabel(List<RoutineItemEntity> items) => [
      for (final i in items) i.barcode == barcode ? i.withProductType(type) : i,
    ];
    return RoutineEntity(morning: relabel(morning), evening: relabel(evening));
  }

  bool get isEmpty => morning.isEmpty && evening.isEmpty;

  RoutineEntity withSlot(RoutineSlot s, List<RoutineItemEntity> items) =>
      RoutineEntity(
        morning: s == RoutineSlot.morning ? items : morning,
        evening: s == RoutineSlot.evening ? items : evening,
      );

  @override
  List<Object?> get props => [morning, evening];
}
