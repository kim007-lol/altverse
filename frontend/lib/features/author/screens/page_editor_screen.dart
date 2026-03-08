import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/image_service.dart';
import '../../../core/constants/api_endpoints.dart';

class PageEditorScreen extends StatefulWidget {
  final int episodeId;
  final String episodeTitle;

  const PageEditorScreen({
    super.key,
    required this.episodeId,
    required this.episodeTitle,
  });

  @override
  State<PageEditorScreen> createState() => _PageEditorScreenState();
}

class _PageEditorScreenState extends State<PageEditorScreen> {
  final List<_PageItem> _pages = [];
  bool _isLoading = true;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPages();
  }

  Future<void> _fetchPages() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get(
        ApiEndpoints.authorPages(widget.episodeId),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          setState(() {
            _pages.clear();
            for (var page in data) {
              _pages.add(
                _PageItem(
                  id: page['id'],
                  imagePath: page['image_path'] ?? '',
                  publicUrl: ApiService.getImageUrl(page['image_path']),
                  pageOrder: page['page_order'] ?? _pages.length + 1,
                  fileSize: page['file_size'] ?? 0,
                ),
              );
            }
          });
        }
      }
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat halaman: $e';
        _isLoading = false;
      });
    }
  }

  /// Upload images to R2 via presigned URL, then save metadata
  Future<void> _addPages() async {
    final remaining = 100 - _pages.length;
    if (remaining <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maksimal 100 halaman per episode'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final files = await ImageService.pickMultipleAndCompress(
      maxImages: remaining.clamp(0, 20), // pick max 20 at a time
    );
    if (files.isEmpty) return;

    setState(() => _isUploading = true);

    int successCount = 0;
    for (final file in files) {
      try {
        final fileName = file.path.split('/').last.split('\\').last;
        final ext = fileName.split('.').last.toLowerCase();
        final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';

        // 1. Request presigned URL from backend
        final signedResponse = await ApiService.post(
          ApiEndpoints.authorSignedUrl,
          {'filename': fileName, 'type': contentType},
        );

        if (signedResponse.statusCode != 200) continue;

        final signedData = jsonDecode(signedResponse.body);
        final uploadUrl = signedData['upload_url'] as String;
        final path = signedData['path'] as String;
        final publicUrl = signedData['public_url'] as String;

        // 2. Upload directly to R2
        final uploaded = await ApiService.uploadToR2(
          uploadUrl,
          file,
          contentType,
        );
        if (!uploaded) continue;

        // 3. Save page metadata to backend
        final pageResponse = await ApiService.post(
          ApiEndpoints.authorPages(widget.episodeId),
          {'image_path': path, 'file_size': file.lengthSync()},
        );

        if (pageResponse.statusCode == 201) {
          final pageData = jsonDecode(pageResponse.body);
          final page = pageData['page'];
          setState(() {
            _pages.add(
              _PageItem(
                id: page['id'],
                imagePath: path,
                publicUrl: publicUrl,
                pageOrder: page['page_order'] ?? _pages.length + 1,
                fileSize: file.lengthSync(),
              ),
            );
          });
          successCount++;
        }
      } catch (e) {
        debugPrint('Upload error: $e');
      }
    }

    setState(() => _isUploading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$successCount/${files.length} halaman berhasil diupload ke R2',
          ),
          backgroundColor: successCount > 0 ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _deletePage(int index) async {
    final page = _pages[index];
    if (page.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Halaman?'),
        content: const Text('Halaman ini akan dihapus permanen dari R2.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await ApiService.delete(
        ApiEndpoints.authorPageDelete(page.id!),
      );
      if (response.statusCode == 200) {
        setState(() => _pages.removeAt(index));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Page Editor',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            Text(
              widget.episodeTitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              onPressed: _addPages,
              tooltip: 'Tambah halaman',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchPages,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : _pages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Belum ada halaman'),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + untuk upload gambar langsung ke R2',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addPages,
                    icon: const Icon(Icons.add),
                    label: const Text('Upload Halaman'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pages.length,
              onReorder: _onReorder,
              itemBuilder: (context, i) {
                final page = _pages[i];
                return Card(
                  key: ValueKey('page_${page.id ?? i}'),
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        page.publicUrl,
                        width: 50,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, st) => Container(
                          width: 50,
                          height: 70,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 20),
                        ),
                      ),
                    ),
                    title: Text(
                      'Halaman ${page.pageOrder}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      ImageService.formatFileSize(page.fileSize),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.drag_handle,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red[400],
                          ),
                          onPressed: () => _deletePage(i),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text(
              'Selesai & Simpan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Halaman berhasil disimpan!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _pages.removeAt(oldIndex);
      _pages.insert(newIndex, item);

      // Update local page_order
      for (int i = 0; i < _pages.length; i++) {
        _pages[i].pageOrder = i + 1;
      }
    });

    // Sync reorder to backend
    _syncReorder();
  }

  Future<void> _syncReorder() async {
    try {
      await ApiService.patch(ApiEndpoints.authorPageReorder(widget.episodeId), {
        'pages': _pages.map((p) => {'id': p.id, 'order': p.pageOrder}).toList(),
      });
    } catch (e) {
      debugPrint('Reorder sync error: $e');
    }
  }
}

// ─── Data Model ───
class _PageItem {
  int? id;
  String imagePath;
  String publicUrl;
  int pageOrder;
  int fileSize;

  _PageItem({
    this.id,
    required this.imagePath,
    required this.publicUrl,
    required this.pageOrder,
    this.fileSize = 0,
  });
}

// ─── Preview Screen (horizontal swipe) ───
class PreviewScreen extends StatefulWidget {
  final String title;
  final List<String> pages;

  const PreviewScreen({super.key, required this.title, required this.pages});

  @override
  State<PreviewScreen> createState() => PreviewScreenState();
}

class PreviewScreenState extends State<PreviewScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Horizontal page reader
            PageView.builder(
              controller: _controller,
              itemCount: widget.pages.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (_, i) => InteractiveViewer(
                child: Center(
                  child: Image.network(
                    widget.pages[i],
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                              : null,
                          color: Colors.white54,
                        ),
                      );
                    },
                    errorBuilder: (_, e, st) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gagal memuat gambar',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // PREVIEW watermark
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(180),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PREVIEW MODE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),

            // Back button
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Page counter
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentPage + 1} / ${widget.pages.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
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
