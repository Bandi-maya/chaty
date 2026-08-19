import 'package:flutter/material.dart';
import '../../../ui/core/theme/theme_config.dart';

class MockCallScreen extends StatefulWidget {
  final ThemeConfig theme;
  final String title;
  final bool isVideo;

  const MockCallScreen({
    super.key,
    required this.theme,
    required this.title,
    this.isVideo = false,
  });

  @override
  State<MockCallScreen> createState() => _MockCallScreenState();
}

class _MockCallScreenState extends State<MockCallScreen> {
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isVideoOn = true;
  int _secondsElapsed = 0;
  late final Stream<int> _timerStream;

  @override
  void initState() {
    super.initState();
    _isVideoOn = widget.isVideo;
    _timerStream = Stream.periodic(const Duration(seconds: 1), (i) => i + 1);
    _timerStream.listen((sec) {
      if (mounted) {
        setState(() => _secondsElapsed = sec);
      }
    });
  }

  String _formatDuration(int totalSec) {
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header Security Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, color: Color(0xFF10B981), size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Direct Peer-to-Peer Encrypted Call',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Caller Info
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDuration(_secondsElapsed),
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),

            const Spacer(),

            // Video Preview or Avatar
            if (_isVideoOn)
              Container(
                margin: const EdgeInsets.all(24),
                height: 280,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.accentColor.withValues(alpha: 0.4)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.videocam_rounded, size: 64, color: Colors.white38),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.title,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.accentColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    widget.title.isNotEmpty ? widget.title.substring(0, 2).toUpperCase() : 'CALL',
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            const Spacer(),

            // Call Controls Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute
                  _buildCallBtn(
                    icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    isActive: _isMuted,
                    onTap: () => setState(() => _isMuted = !_isMuted),
                  ),
                  // Video toggle
                  _buildCallBtn(
                    icon: _isVideoOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                    isActive: _isVideoOn,
                    onTap: () => setState(() => _isVideoOn = !_isVideoOn),
                  ),
                  // Speaker
                  _buildCallBtn(
                    icon: _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                    isActive: _isSpeakerOn,
                    onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                  ),
                  // End Call
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallBtn({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive ? Colors.white24 : Colors.white10,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
