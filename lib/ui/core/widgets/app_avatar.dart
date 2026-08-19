import 'package:flutter/material.dart';
import '../../../domain/models/user_profile.dart';

class AppAvatar extends StatelessWidget {
  final String initials;
  final String? colorHex;
  final double size;
  final bool showOnlineBadge;
  final PresenceState presence;

  const AppAvatar({
    super.key,
    required this.initials,
    this.colorHex,
    this.size = 44,
    this.showOnlineBadge = false,
    this.presence = PresenceState.offline,
  });

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF6366F1);
    try {
      final clean = hex.replaceAll('#', '').replaceAll('0x', '');
      return Color(int.parse(clean.length == 6 ? 'FF$clean' : clean, radix: 16));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  Color _getPresenceColor() {
    switch (presence) {
      case PresenceState.online:
        return const Color(0xFF10B981);
      case PresenceState.away:
        return const Color(0xFFF59E0B);
      case PresenceState.typing:
        return const Color(0xFF6366F1);
      case PresenceState.offline:
        return const Color(0xFF94A3B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _parseColor(colorHex);
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                bg,
                bg.withValues(alpha: 0.75),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: bg.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.4,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        if (showOnlineBadge)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.32,
              height: size * 0.32,
              decoration: BoxDecoration(
                color: _getPresenceColor(),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}