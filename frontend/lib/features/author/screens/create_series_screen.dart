import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/image_service.dart';
import '../../../core/constants/api_endpoints.dart';
import 'episode_management_screen.dart';

class CreateSeriesScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const CreateSeriesScreen({super.key, this.onBack});

  @override
  State<CreateSeriesScreen> createState() => _CreateSeriesScreenState();
}

class _CreateSeriesScreenState extends State<CreateSeriesScreen> {
  final _titleCtrl = TextEditingController();
  final _synopsisCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  String _selectedGenre = '';
  String _selectedAgeRating = 'all';
  File? _coverFile;
  bool _isUploading = false;
  String? _errorMessage;

  final List<String> _ageRatings = ['all', '13+', '17+', '18+'];
  final List<String> _genres = [
    'Action',
    'Romance',
    'Fantasy',
    'Comedy',
    'Drama',
    'Horror',
    'Thriller',
    'Slice of Life',
    'Sci-Fi',
    'Mystery',
    'Adventure',
    'Isekai',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _synopsisCtrl.dispose();
    _sourceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final file = await ImageService.pickAndCompress();
    if (file != null) {
      setState(() => _coverFile = file);
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Judul Series wajib diisi');
      return;
    }
    if (_selectedGenre.isEmpty) {
      setState(() => _errorMessage = 'Genre wajib diisi');
      return;
    }
    if (_synopsisCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Sinopsis wajib diisi');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final fields = <String, String>{
        'title': _titleCtrl.text.trim(),
        'description': _synopsisCtrl.text.trim(),
        'genre': _selectedGenre,
        'age_rating': _selectedAgeRating,
      };
      if (_sourceCtrl.text.trim().isNotEmpty) {
        fields['source_url'] = _sourceCtrl.text.trim();
      }

      final files = <String, File>{};
      if (_coverFile != null) {
        files['cover'] = _coverFile!;
      }

      final response = await ApiService.multipart(
        ApiEndpoints.authorSeries,
        fields: fields,
        files: files,
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final seriesId = body['id'];
        final seriesTitle = _titleCtrl.text.trim();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Series berhasil dibuat! Lanjut tambah episode 🎉'),
              backgroundColor: Colors.green,
            ),
          );

          if (seriesId != null) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EpisodeManagementScreen(
                  seriesId: seriesId,
                  seriesTitle: seriesTitle,
                ),
              ),
            );

            if (mounted) {
              _titleCtrl.clear();
              _synopsisCtrl.clear();
              _sourceCtrl.clear();
              setState(() {
                _selectedGenre = '';
                _selectedAgeRating = 'all';
                _coverFile = null;
                _errorMessage = null;
              });

              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.pop(context);
              }
            }
          }
        }
      } else {
        setState(
          () => _errorMessage = body['message'] ?? 'Gagal membuat Series',
        );
      }
    } catch (e) {
      setState(
        () => _errorMessage =
            'Error: tidak dapat terhubung ke server. Periksa koneksi internet.',
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: widget.onBack ?? () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buat Series',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Share your story with the world',
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ─── Error Message ───
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[400],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ─── Cover Upload ───
              Center(
                child: GestureDetector(
                  onTap: _pickCover,
                  child: Container(
                    height: 200,
                    width: 140,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withAlpha(15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.primaryColor.withAlpha(40),
                        width: 2,
                      ),
                      image: _coverFile != null
                          ? DecorationImage(
                              image: FileImage(_coverFile!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _coverFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 40,
                                color: theme.primaryColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Upload Cover',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Auto-compressed',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          )
                        : Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              margin: const EdgeInsets.all(6),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                ImageService.formatFileSize(
                                  _coverFile!.lengthSync(),
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ─── Title ───
              _label('Judul Series *'),
              const SizedBox(height: 8),
              _inputField(
                controller: _titleCtrl,
                hint: 'Judul cerita series kamu',
              ),
              const SizedBox(height: 20),

              // ─── Genre ───
              _label('Genre *'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _genres.map((genre) {
                  final selected = _selectedGenre == genre.toLowerCase();
                  return ChoiceChip(
                    label: Text(
                      genre,
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? Colors.white : theme.primaryColor,
                      ),
                    ),
                    selected: selected,
                    selectedColor: theme.primaryColor,
                    backgroundColor: theme.primaryColor.withAlpha(15),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide.none,
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedGenre = genre.toLowerCase());
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ─── Age Rating ───
              _label('Age Rating *'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _ageRatings.map((rating) {
                  final selected = _selectedAgeRating == rating;
                  return ChoiceChip(
                    label: Text(
                      rating,
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? Colors.white : theme.primaryColor,
                      ),
                    ),
                    selected: selected,
                    selectedColor: theme.primaryColor,
                    backgroundColor: theme.primaryColor.withAlpha(15),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide.none,
                    onSelected: (val) {
                      if (val) setState(() => _selectedAgeRating = rating);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ─── Synopsis ───
              _label('Sinopsis *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _synopsisCtrl,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Tulis sinopsis cerita...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),

              // ─── Optional Source URL ───
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.link, color: Colors.grey[600], size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Optional Links',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _label('Link Novel Sumber'),
                    const SizedBox(height: 6),
                    _inputField(
                      controller: _sourceCtrl,
                      hint: 'Wattpad / Google Docs / Medium URL',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ─── Submit Button ───
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: theme.primaryColor.withAlpha(100),
                  ),
                  onPressed: _isUploading ? null : _submit,
                  child: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create Series',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
