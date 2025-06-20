import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanPage extends StatefulWidget {
  final Function(String) onScanned;

  const QrScanPage({super.key, required this.onScanned});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanned = false;

  late AnimationController _animationController;
  late Animation<Color?> _borderColor;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _borderColor = ColorTween(
      begin: Colors.green,
      end: Colors.transparent,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_isScanned || capture.barcodes.isEmpty) return;

              final barcode = capture.barcodes.first;
              final String? code = barcode.rawValue;

              if (code != null && code.isNotEmpty) {
                _isScanned = true;
                Fluttertoast.showToast(msg: "Scanned: $code");
                _controller.stop();

                Future.delayed(const Duration(milliseconds: 300), () {
                  Navigator.pop(context);
                  widget.onScanned(code);
                });
              }
            },
          ),
          Center(
            child: AnimatedBuilder(
              animation: _borderColor,
              builder: (context, child) {
                return Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _borderColor.value ?? Colors.green,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
