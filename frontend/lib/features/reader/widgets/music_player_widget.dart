import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class MusicPlayerWidget extends StatefulWidget {
  final String musicUrl;
  final String musicTitle;
  final VoidCallback onClose;

  const MusicPlayerWidget({super.key, required this.musicUrl, required this.musicTitle, required this.onClose});

  @override
  State<MusicPlayerWidget> createState() => _MusicPlayerWidgetState();
}

class _MusicPlayerWidgetState extends State<MusicPlayerWidget> with SingleTickerProviderStateMixin {
  late AudioPlayer _player;
  bool _isMuted = false;
  bool _hasError = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      debugPrint('🎵 Initializing music player...');
      debugPrint('🎵 Music URL: ${widget.musicUrl}');

      // Set audio source and load
      await _player.setAudioSource(AudioSource.uri(Uri.parse(widget.musicUrl)));

      // Configure player
      await _player.setVolume(0.5);
      await _player.setLoopMode(LoopMode.one);

      debugPrint('✅ Music loaded successfully');

      if (mounted) setState(() => _isLoading = false);

      // Auto-play
      debugPrint('▶️ Starting autoplay...');
      await _player.play();

      if (mounted) {
        debugPrint('✅ Music is now playing');
      }

      // Listen for processing state
      _player.processingStateStream.listen((state) {
        debugPrint('🎵 Processing state: $state');
        if (state == ProcessingState.completed) {
          // Loop back to start
          _player.seek(Duration.zero);
          _player.play();
        }
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Music player error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    debugPrint('🎵 Disposing music player');
    _player.dispose();
    super.dispose();
  }

  void _toggleMute() async {
    try {
      if (_isMuted) {
        debugPrint('🔊 Unmuting music');
        await _player.setVolume(0.5);
      } else {
        debugPrint('🔇 Muting music');
        await _player.setVolume(0.0);
      }
      setState(() => _isMuted = !_isMuted);
    } catch (e) {
      debugPrint('❌ Toggle mute error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: Colors.red.withAlpha(140), borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Failed to load music',
                style: TextStyle(color: Colors.white, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: widget.onClose,
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.black.withAlpha(140), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(Icons.music_note_rounded, color: Colors.white.withAlpha(200), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.musicTitle,
              style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 4),
          if (_isLoading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withAlpha(200)),
              ),
            )
          else
            GestureDetector(
              onTap: _toggleMute,
              child: Icon(_isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Colors.white, size: 20),
            ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () async {
              await _player.stop();
              widget.onClose();
            },
            child: Icon(Icons.close_rounded, color: Colors.white.withAlpha(180), size: 18),
          ),
        ],
      ),
    );
  }
}
