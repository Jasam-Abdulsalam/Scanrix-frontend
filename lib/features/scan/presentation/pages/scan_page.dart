import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:scanrix_frontend/features/scan/presentation/widgets/category_mismatch.dart';
import 'package:scanrix_frontend/features/scan/presentation/widgets/scan_category_selection_overlay.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../bloc/scan_bloc.dart';
import '../bloc/scan_event.dart';
import '../bloc/scan_state.dart';
import '../widgets/barcode_popup_card.dart';

import '../widgets/scan_bottom_bar.dart';
import '../widgets/scan_category.dart';
import '../widgets/scan_status_bar.dart';
import '../widgets/scan_viewfinder_overlay.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Scanner phase state machine
// ─────────────────────────────────────────────────────────────────────────────
enum _ScannerPhase {
  /// Blur overlay shown, waiting for the user to pick a category.
  categorySelection,

  /// Live camera is running, scan line animating in viewfinder.
  scanning,

  /// Barcode detected — camera frozen, popup card animation playing.
  popupPlaying,

  /// Animation complete — result dispatched, navigating away.
  done,
}

// ─────────────────────────────────────────────────────────────────────────────
// ScanPage
// ─────────────────────────────────────────────────────────────────────────────
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final MobileScannerController _cameraCtrl;
  late final AnimationController _shakeCtrl;

  _ScannerPhase _phase = _ScannerPhase.categorySelection;
  ScanCategory? _selectedCategory;
  String? _detectedBarcode;
  String? _detectedFormat;
  bool _flashOn = false;

  // Guard against double-firing onDetect
  bool _processingDetection = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraCtrl = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      // Scanner logic stays frozen until a category is picked —
      // don't autoStart; we start it manually in _onCategorySelected.
      autoStart: false,
    );
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _setFullScreenOverlay();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _phase == _ScannerPhase.scanning) {
      _cameraCtrl.start();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cameraCtrl.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraCtrl.dispose();
    _shakeCtrl.dispose();
    _restoreOverlay();
    super.dispose();
  }

  // ── Full-screen immersive mode (no system status-bar tint on camera)
  void _setFullScreenOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _restoreOverlay() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Category selection → transition into scanning
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _onCategorySelected(ScanCategory category) async {
    setState(() => _selectedCategory = category);

    // Let the card's own press/glow animation play briefly before the
    // overlay fades and the camera starts (per the spec's transition motion).
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;

    setState(() => _phase = _ScannerPhase.scanning);

    // Camera was never started (autoStart: false) — start it now so the
    // BackdropFilter fade-out (300ms, handled by CategorySelectionOverlay's
    // AnimatedOpacity) reveals an already-live feed rather than a black gap.
    await _cameraCtrl.start();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Barcode detection callback
  // ─────────────────────────────────────────────────────────────────────────
  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_phase != _ScannerPhase.scanning) return;
    if (_processingDetection) return;
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final value = barcode.rawValue;
    if (value == null || value.isEmpty) return;

    _processingDetection = true;

    // 1. Freeze the camera
    _cameraCtrl.stop();

    // 2. Haptic feedback
    HapticFeedback.mediumImpact();

    // 3. Transition to popup phase
    setState(() {
      _phase = _ScannerPhase.popupPlaying;
      _detectedBarcode = value;
      _detectedFormat = barcode.format.name.toUpperCase();
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Called when the popup card animation finishes
  // ─────────────────────────────────────────────────────────────────────────
  void _onPopupComplete() {
    if (!mounted) return;
    setState(() => _phase = _ScannerPhase.done);

    // Dispatch to ScanBloc
    context.read<ScanBloc>().add(ScanBarcodeRequested(_detectedBarcode!));

    // NOTE: navigation is deferred to _handleScanBlocState below now,
    // so we can intercept a category mismatch before popping the page.
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Dismiss popup without result (user tapped outside card)
  // ─────────────────────────────────────────────────────────────────────────
  void _onPopupDismissed() {
    if (!mounted) return;
    setState(() {
      _phase = _ScannerPhase.scanning;
      _detectedBarcode = null;
      _detectedFormat = null;
      _processingDetection = false;
    });
    _cameraCtrl.start();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Flash toggle
  // ─────────────────────────────────────────────────────────────────────────
  void _toggleFlash() {
    setState(() => _flashOn = !_flashOn);
    _cameraCtrl.toggleTorch();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Category mismatch: switch and re-run without leaving the page
  // ─────────────────────────────────────────────────────────────────────────
  void _switchCategoryAndRetry(ScanCategory newCategory) {
    setState(() {
      _selectedCategory = newCategory;
      _phase = _ScannerPhase.scanning;
      _processingDetection = false;
    });
    // Re-fetch/display using the same barcode under the corrected category.
    if (_detectedBarcode != null) {
      context.read<ScanBloc>().add(ScanBarcodeRequested(_detectedBarcode!));
    }
  }

  Future<void> _playShake() async {
    await _shakeCtrl.forward(from: 0);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocListener<ScanBloc, ScanState>(
      listener: _handleScanBlocState,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // ── 1. Live camera feed (full-screen)
              _buildCamera(),

              // ── 2. Viewfinder overlay (vignette + brackets + scan line)
              ScanViewfinderOverlay(
                isScanning: _phase == _ScannerPhase.scanning,
              ),

              // ── 3. Top status bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ScanStatusBar(
                  isScanning: _phase == _ScannerPhase.scanning,
                  flashOn: _flashOn,
                  category: _phase == _ScannerPhase.categorySelection
                      ? null
                      : _selectedCategory,
                  onBack: () => Navigator.of(context).maybePop(),
                  onFlashToggle: _toggleFlash,
                ),
              ),

              // ── 4. Bottom action bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ScanBottomBar(
                  onCameraTap: _phase == _ScannerPhase.scanning
                      ? () => _cameraCtrl.switchCamera()
                      : null,
                ),
              ),

              // ── 5. Barcode pop-up card (shown when popupPlaying)
              if (_phase == _ScannerPhase.popupPlaying &&
                  _detectedBarcode != null)
                AnimatedBuilder(
                  animation: _shakeCtrl,
                  builder: (context, child) {
                    final t = _shakeCtrl.value;
                    // Simple decaying horizontal shake.
                    final offset =
                        (t == 0 || t == 1) ? 0.0 : (8 * (1 - t)) * ((t * 40).round().isEven ? 1 : -1);
                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: child,
                    );
                  },
                  child: BarcodePopupCard(
                    barcodeValue: _detectedBarcode!,
                    barcodeFormat: _detectedFormat,
                    onComplete: _onPopupComplete,
                    onDismiss: _onPopupDismissed,
                  ),
                ),

              // ── 6. Category selection blur overlay (topmost, initial state)
              CategorySelectionOverlay(
                visible: _phase == _ScannerPhase.categorySelection,
                onCategorySelected: _onCategorySelected,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCamera() {
    return MobileScanner(
      controller: _cameraCtrl,
      onDetect: _onBarcodeDetected,
      errorBuilder: (context, error) {
        return _CameraErrorWidget(error: error);
      },
    );
  }

  void _handleScanBlocState(BuildContext context, ScanState state) {
    if (state is ScanBarcodeSuccess) {
      // ── Category mismatch check ────────────────────────────────────────
      // TODO: confirm the actual field name on ScanResultEntity — adjust
      // `state.result.category` below to match (e.g. result.productCategory).
      final resultCategory =
          ScanCategoryX.fromBackendLabel(state.result.product.category);

      if (_selectedCategory != null &&
          resultCategory != null &&
          resultCategory != _selectedCategory) {
        _playShake();
        showCategoryMismatchSnackbar(
          context,
          detectedCategory: resultCategory,
          onSwitch: () => _switchCategoryAndRetry(resultCategory),
        );
        // Stay on the popup/frozen state until the user decides; don't
        // pop the page yet.
        return;
      }

      // No mismatch (or category unknown) — proceed as before.
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (state is ScanFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Scan failed: ${state.message}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      // Resume scanning on error
      if (_phase == _ScannerPhase.done) {
        setState(() {
          _phase = _ScannerPhase.scanning;
          _processingDetection = false;
        });
        _cameraCtrl.start();
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Camera permission / error widget
// ─────────────────────────────────────────────────────────────────────────────
class _CameraErrorWidget extends StatelessWidget {
  final MobileScannerException error;
  const _CameraErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final message = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'Camera permission denied.\nPlease enable it in Settings.',
      MobileScannerErrorCode.unsupported =>
        'Barcode scanning is not supported\non this device.',
      _ => 'Camera error: ${error.errorCode.name}',
    };

    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.no_photography_outlined,
                color: colors.secondaryText,
                size: 56,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.neonEmerald,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                ),
                child: const Text(
                  'Go Back',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}