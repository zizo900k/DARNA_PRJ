import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../theme/app_theme.dart';
import 'dart:async';

class AudioMessageBubble extends StatefulWidget {
  final String audioUrl;
  final int? durationMs;
  final bool isMine;
  final DateTime? createdAt;

  const AudioMessageBubble({
    super.key,
    required this.audioUrl,
    this.durationMs,
    required this.isMine,
    this.createdAt,
  });

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble> {
  late AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateSubscription;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    
    _durationSubscription = _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _playerState = PlayerState.stopped;
          _position = Duration.zero;
        });
      }
    });

    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });

    // If duration is provided from backend, use it as initial duration
    if (widget.durationMs != null) {
      _duration = Duration(milliseconds: widget.durationMs!);
    }
  }

  @override
  void didUpdateWidget(covariant AudioMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.audioUrl != oldWidget.audioUrl) {
      if (_playerState == PlayerState.playing) {
        _audioPlayer.stop();
      }
      setState(() {
         _hasError = false;
         _errorMessage = null;
      });
    }
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPause() async {
    try {
      if (_playerState == PlayerState.playing) {
        await _audioPlayer.pause();
      } else {
        if (mounted) setState(() => _hasError = false);
        await _audioPlayer.play(UrlSource(widget.audioUrl, mimeType: 'audio/webm'));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
      debugPrint("Audio playback error: $e");
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: widget.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _playPause,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.isMine ? Colors.white.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _hasError 
                      ? Icons.error_outline_rounded 
                      : (_playerState == PlayerState.playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  color: _hasError 
                      ? Colors.red 
                      : (widget.isMine ? Colors.white : AppColors.primary),
                  size: 24,
                ),
              ),
            ),
            if (_hasError)
               Padding(
                 padding: const EdgeInsets.only(left: 4),
                 child: Tooltip(
                   message: _errorMessage ?? "Error loading audio",
                   child: const Icon(Icons.info_outline, size: 14, color: Colors.red),
                 ),
               ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      activeTrackColor: widget.isMine ? Colors.white : AppColors.primary,
                      inactiveTrackColor: widget.isMine ? Colors.white.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.2),
                      thumbColor: widget.isMine ? Colors.white : AppColors.primary,
                    ),
                    child: Slider(
                      value: _position.inMilliseconds.toDouble(),
                      max: _duration.inMilliseconds.toDouble() > 0 
                          ? _duration.inMilliseconds.toDouble() 
                          : 1.0,
                      onChanged: (value) {
                        _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.isMine ? Colors.white.withValues(alpha: 0.7) : theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.isMine ? Colors.white.withValues(alpha: 0.7) : theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
