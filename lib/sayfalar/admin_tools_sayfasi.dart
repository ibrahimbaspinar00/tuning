import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/generate_reviews_script.dart';

class AdminToolsSayfasi extends StatefulWidget {
  const AdminToolsSayfasi({super.key});

  @override
  State<AdminToolsSayfasi> createState() => _AdminToolsSayfasiState();
}

class _AdminToolsSayfasiState extends State<AdminToolsSayfasi> {
  final GenerateReviewsScript _script = GenerateReviewsScript();
  bool _isRunning = false;
  String _status = '';
  bool _hasRunOnce = false;

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında otomatik çalıştır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasRunOnce) {
        _hasRunOnce = true;
        _generateReviews();
      }
    });
  }

  Future<void> _generateReviews() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _status = 'Yorumlar oluşturuluyor...';
    });

    try {
      await _script.generateAllReviews();
      
      if (mounted) {
        setState(() {
          _status = '✅ Tüm yorumlar başarıyla oluşturuldu!';
          _isRunning = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yorumlar başarıyla oluşturuldu!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = '❌ Hata: $e';
          _isRunning = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Araçları',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Text(
              'Yorum Oluşturma Aracı',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Her ürüne 50 yorum ekler (10 tanesi fotoğraflı)',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            
            // Bilgi kutusu
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Bilgi',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Önceki tüm yorumlar silinecek\n'
                    '• Her ürün için 50 yorum oluşturulacak\n'
                    '• 10 yorum fotoğraflı olacak\n'
                    '• Puanlar 1-5 arası farklı olacak\n'
                    '• Tüm yorumlar onaylı olacak\n'
                    '• Email adresleri gmail.com olacak',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.blue[800],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Durum
            if (_status.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _status.contains('✅') 
                      ? Colors.green[50] 
                      : _status.contains('❌')
                          ? Colors.red[50]
                          : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _status.contains('✅')
                        ? Colors.green[200]!
                        : _status.contains('❌')
                            ? Colors.red[200]!
                            : Colors.blue[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    if (_isRunning)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (_status.contains('✅'))
                      Icon(Icons.check_circle, color: Colors.green[700], size: 20)
                    else if (_status.contains('❌'))
                      Icon(Icons.error, color: Colors.red[700], size: 20)
                    else
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _status,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: _status.contains('✅')
                              ? Colors.green[800]
                              : _status.contains('❌')
                                  ? Colors.red[800]
                                  : Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Buton
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRunning ? null : _generateReviews,
                icon: _isRunning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  _isRunning ? 'Oluşturuluyor...' : 'Yorumları Oluştur',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

