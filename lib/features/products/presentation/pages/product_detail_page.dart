import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../widgets/analysis_result_view.dart';

/// Barcode-flow result screen. `initialProduct` is what the confirmation
/// screen already fetched via `POST /scan/` (so this page can render
/// instantly instead of flashing a loading state) — if its verdict is
/// still `"analyzing"`, this page polls `GET /products/{barcode}` (via the
/// app-wide `ProductBloc`, already provided in `app.dart`) every ~2.5s
/// until it flips to a terminal verdict.
class ProductDetailPage extends StatefulWidget {
  final String barcode;
  final ProductEntity? initialProduct;

  const ProductDetailPage({
    super.key,
    required this.barcode,
    this.initialProduct,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(ProductRequested(widget.barcode));
  }

  void _maybeStartPolling(ProductEntity product) {
    if (!product.isAnalyzing || _pollTimer != null) return;
    _pollTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      context.read<ProductBloc>().add(ProductRequested(widget.barcode));
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          widget.initialProduct?.name ?? 'Analysis',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: BlocConsumer<ProductBloc, ProductState>(
        // `ProductBloc` is a single app-wide instance (see app.dart) reused
        // across every scan — guard every state against this page's own
        // barcode so a leftover state from a *different* previous scan
        // never bleeds into this instance before the fresh dispatch resolves.
        listener: (context, state) {
          if (state is ProductLoaded && state.product.barcode == widget.barcode) {
            if (state.product.isAnalyzing) {
              _maybeStartPolling(state.product);
            } else {
              _stopPolling();
            }
          }
        },
        builder: (context, state) {
          final product = state is ProductLoaded && state.product.barcode == widget.barcode
              ? state.product
              : widget.initialProduct;

          if (product == null) {
            if (state is ProductFailure) {
              return _ErrorState(message: state.message);
            }
            return const Center(child: CircularProgressIndicator());
          }

          if (product.isAnalyzing) {
            return _AnalyzingState(product: product);
          }

          return AnalysisResultView(
            verdict: product.verdict,
            overallScore: product.overallScore,
            summary: product.summary,
            ingredients: product.ingredients,
          );
        },
      ),
    );
  }
}

class _AnalyzingState extends StatelessWidget {
  final ProductEntity product;
  const _AnalyzingState({required this.product});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colors.neonEmerald),
            SizedBox(height: 20.h),
            Text(
              'Analyzing ${product.name}…',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),
            Text(
              'Our AI is checking the ingredients — this usually takes a few seconds.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.secondaryText, fontSize: 13.sp, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.secondaryText, fontSize: 13.sp),
        ),
      ),
    );
  }
}
