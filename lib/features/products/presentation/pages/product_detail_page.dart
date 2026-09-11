import 'package:flutter/material.dart';

class ProductDetailPage extends StatelessWidget {
  final String barcode;

  const ProductDetailPage({super.key, required this.barcode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Product detail page for $barcode - TODO')),
    );
  }
}
