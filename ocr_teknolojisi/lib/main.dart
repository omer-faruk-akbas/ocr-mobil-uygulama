import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MaterialApp(home: OCRScreen(), debugShowCheckedModeBanner: false));
}

class OCRScreen extends StatefulWidget {
  const OCRScreen({super.key});

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  File? _imageFile;
  String _extractedText = '';

  Future<void> _pickCropAndRecognize() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      CroppedFile? croppedFile;

      try {
        croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Sorunun Kenarlarını Kırp',
              toolbarColor: Colors.deepPurple,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
          ],
        );
      } catch (e) {
        debugPrint('Kırpma hatası: $e');
        return;
      }

      if (croppedFile == null) return;

      final safeFile = File(croppedFile.path);

      setState(() {
        _imageFile = safeFile;
        _extractedText = 'Metin analiz ediliyor...';
      });

      await _performOCR(safeFile);
    } catch (e) {
      setState(() {
        _extractedText = 'Bir hata oluştu: $e';
      });
    }
  }

  Future<void> _performOCR(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognized = await recognizer.processImage(inputImage);

      setState(() {
        _extractedText = recognized.text;
      });

      recognizer.close();
    } catch (e) {
      setState(() {
        _extractedText = 'OCR Hatası: $e';
      });
    }
  }

  void _copyToClipboard() {
    if (_extractedText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _extractedText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Metin panoya kopyalandı')),
      );
    }
  }

  Widget buildGradientButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6A1B9A), Color(0xFF512DA8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('📷 Soru OCR Uygulaması'),
        backgroundColor: const Color(0xFF512DA8),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "1️⃣ SORUNUN FOTOĞRAFINI ÇEK",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _imageFile != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(_imageFile!, height: 250, fit: BoxFit.cover),
            )
                : Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey),
              ),
              child: const Center(
                child: Text(
                  "Hiç fotoğraf çekilmedi",
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ),
            const SizedBox(height: 20),
            buildGradientButton(
              text: "Fotoğraf Çek & Kırp",
              icon: Icons.camera_alt,
              onPressed: _pickCropAndRecognize,
            ),
            const SizedBox(height: 30),
            const Text(
              "2️⃣ ÇIKARILAN METİN",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                _extractedText.isEmpty
                    ? "Fotoğrafı çekip metni buraya alabilirsiniz."
                    : _extractedText,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            buildGradientButton(
              text: "Metni Kopyala",
              icon: Icons.copy,
              onPressed: _copyToClipboard,
            ),
          ],
        ),
      ),
    );
  }
}
