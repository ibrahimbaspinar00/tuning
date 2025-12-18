import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:google_fonts/google_fonts.dart';

/// Profil fotoğrafı için image cropper widget
class ImageCropperWidget extends StatefulWidget {
  final Uint8List imageData;
  final Function(Uint8List croppedData) onCropComplete;

  const ImageCropperWidget({
    super.key,
    required this.imageData,
    required this.onCropComplete,
  });

  @override
  State<ImageCropperWidget> createState() => _ImageCropperWidgetState();
}

class _ImageCropperWidgetState extends State<ImageCropperWidget> {
  final CropController _cropController = CropController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Fotoğrafı Düzenle',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: () async {
                setState(() => _isProcessing = true);
                _cropController.crop();
              },
              child: Text(
                'Kaydet',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Crop(
                  image: widget.imageData,
                  controller: _cropController,
                  onCropped: (result) {
                    if (mounted) {
                      // CropResult yapısı: {data: Uint8List, rect: Rect}
                      widget.onCropComplete(result.data);
                      Navigator.pop(context);
                    }
                  },
                  radius: 200, // Yuvarlak crop için
                  aspectRatio: 1, // Kare crop
                  withCircleUi: true, // Yuvarlak UI
                  baseColor: Colors.blue.shade900,
                  maskColor: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
            // Alt bilgi
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black87,
              child: Text(
                'Fotoğrafı sürükleyerek konumlandırın ve yakınlaştırın',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
