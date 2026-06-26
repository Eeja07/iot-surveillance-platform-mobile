import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class ImageViewerScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String title;
  final String cameraName;

  const ImageViewerScreen({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
    required this.title,
    required this.cameraName,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _isProcessing = false;


  final TransformationController _transformationController = TransformationController();
  TapDownDetails? _doubleTapDetails;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;


    _transformationController.addListener(_onTransformationChange);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChange);
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformationChange() {

    final scale = _transformationController.value.getMaxScaleOnAxis();
    if (scale > 1.01 && !_isZoomed) {
      setState(() => _isZoomed = true);
    } else if (scale <= 1.01 && _isZoomed) {
      setState(() => _isZoomed = false);
    }
  }


  Future<String?> _downloadFile(String url, {String? customFileName}) async {
    try {
      final tempDir = await getTemporaryDirectory();

      final fileName = customFileName ?? 'temp_view_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savePath = '${tempDir.path}/$fileName';

      await Dio().download(url, savePath);
      return savePath;
    } catch (e) {
      print("Download error: $e");
      return null;
    }
  }

  void _shareImage() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final currentUrl = widget.imageUrls[_currentIndex];

      final path = await _downloadFile(currentUrl);
      if (path != null) {
        await Share.shareXFiles(
          [XFile(path)],
          text: 'Rekaman CCTV - ${widget.cameraName} (${widget.title})'
        );
      } else {
        await Share.share('Lihat rekaman CCTV ini: $currentUrl');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membagikan: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }


  void _saveImage() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      if (!await Gal.hasAccess()) await Gal.requestAccess();

      final currentUrl = widget.imageUrls[_currentIndex];



      String cleanCameraName = widget.cameraName.replaceAll(RegExp(r'[^\w\s\-]'), '').trim().replaceAll(' ', '_');


      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());


      String finalFileName = '${cleanCameraName}_$timestamp.jpg';


      final path = await _downloadFile(currentUrl, customFileName: finalFileName);

      if (path != null) {


        await Gal.putImage(path, album: 'MiotVision Cam');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tersimpan di Album "MiotVision Cam"\nNama: $finalFileName'),
              backgroundColor: Colors.green
            ),
          );
        }


        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }


  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();

    } else {
      final position = _doubleTapDetails!.localPosition;

      _transformationController.value = Matrix4.identity()
        ..translate(-position.dx, -position.dy)
        ..scale(2.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(widget.cameraName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              'Pukul ${widget.title} • ${_currentIndex + 1}/${widget.imageUrls.length}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareImage),
          IconButton(icon: const Icon(Icons.download), onPressed: _saveImage),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: PageView.builder(
        controller: _pageController,

        physics: _isZoomed ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;

            _transformationController.value = Matrix4.identity();
            _isZoomed = false;
          });
        },
        itemBuilder: (context, index) {
          return GestureDetector(
            onDoubleTapDown: (d) => _doubleTapDetails = d,
            onDoubleTap: _handleDoubleTap,
            child: InteractiveViewer(
              transformationController: _transformationController,
              panEnabled: true,
              minScale: 1.0,
              maxScale: 4.0,
              child: Center(
                child: Hero(
                  tag: widget.imageUrls[index],
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.contain,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return Center(child: CircularProgressIndicator(value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null, color: Colors.white));
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}