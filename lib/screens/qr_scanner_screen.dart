import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'add_device_manual_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  _QrScannerScreenState createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanCompleted = false;
  late AnimationController _animationController;

  bool _showSuccessIndicator = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_isScanCompleted) return;

    final String? code = capture.barcodes.first.rawValue;
    if (code != null && code.isNotEmpty) {
      setState(() {
        _isScanCompleted = true;
        _showSuccessIndicator = true;
      });
      _animationController.stop();

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddDeviceManualScreen(deviceIdFromQR: code),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pindai Kode QR'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleDetection,
          ),
          ScannerOverlay(animation: _animationController),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: Icons.flash_on,
                  onPressed: () => _scannerController.toggleTorch(),
                ),
                _buildControlButton(
                  icon: Icons.flip_camera_ios,
                  onPressed: () => _scannerController.switchCamera(),
                ),
              ],
            ),
          ),

          AnimatedOpacity(
            opacity: _showSuccessIndicator ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.greenAccent, size: 80),
                  SizedBox(height: 16),
                  Text(
                    'Berhasil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.black.withOpacity(0.4),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 30),
        onPressed: onPressed,
      ),
    );
  }
}

class ScannerOverlay extends StatelessWidget {
  final Animation<double> animation;

  const ScannerOverlay({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    final double scanAreaSize = MediaQuery.of(context).size.width * 0.7;
    const double cornerLength = 30.0;
    const double cornerThickness = 4.0;

    return Stack(
      children: [
        Center(
          child: SizedBox(
            width: scanAreaSize,
            height: scanAreaSize,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  child: _buildCorner(
                    cornerThickness,
                    cornerLength,
                    isTopLeft: true,
                  ),
                ),

                Positioned(
                  top: 0,
                  right: 0,
                  child: _buildCorner(
                    cornerThickness,
                    cornerLength,
                    isTopRight: true,
                  ),
                ),

                Positioned(
                  bottom: 0,
                  left: 0,
                  child: _buildCorner(
                    cornerThickness,
                    cornerLength,
                    isBottomLeft: true,
                  ),
                ),

                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _buildCorner(
                    cornerThickness,
                    cornerLength,
                    isBottomRight: true,
                  ),
                ),
              ],
            ),
          ),
        ),

        Center(
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return SizedBox(
                width: scanAreaSize,
                height: scanAreaSize,
                child: Stack(
                  children: [
                    Positioned(
                      top: scanAreaSize * animation.value,
                      left: 10,
                      right: 10,
                      child: Container(
                        height: 2.0,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.7),
                              blurRadius: 8.0,
                              spreadRadius: 2.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCorner(
    double thickness,
    double length, {
    bool isTopLeft = false,
    bool isTopRight = false,
    bool isBottomLeft = false,
    bool isBottomRight = false,
  }) {
    return SizedBox(
      width: length,
      height: length,
      child: CustomPaint(
        painter: _CornerPainter(
          thickness: thickness,
          isTopLeft: isTopLeft,
          isTopRight: isTopRight,
          isBottomLeft: isBottomLeft,
          isBottomRight: isBottomRight,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final double thickness;
  final bool isTopLeft, isTopRight, isBottomLeft, isBottomRight;

  _CornerPainter({
    this.thickness = 4.0,
    this.isTopLeft = false,
    this.isTopRight = false,
    this.isBottomLeft = false,
    this.isBottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    final path = Path();

    if (isTopLeft) {
      path.moveTo(size.width, 0);
      path.lineTo(0, 0);
      path.lineTo(0, size.height);
    } else if (isTopRight) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (isBottomLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else if (isBottomRight) {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
