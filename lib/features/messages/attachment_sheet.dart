import 'package:flutter/material.dart';
import '../../../ui/core/theme/theme_config.dart';

class AttachmentSheet extends StatelessWidget {
  final ThemeConfig theme;
  final Function(String type, String name, String size) onAttachmentSelected;
  final VoidCallback onTaskOption;

  const AttachmentSheet({
    super.key,
    required this.theme,
    required this.onAttachmentSelected,
    required this.onTaskOption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.secondaryTextColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Share Media & Items',
              style: TextStyle(
                color: theme.primaryTextColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              children: [
                _buildItem(
                  context,
                  icon: Icons.image_rounded,
                  label: 'Gallery',
                  color: const Color(0xFF3B82F6),
                  onTap: () {
                    Navigator.pop(context);
                    onAttachmentSelected('image', 'mock_photo_preview.jpg', '2.8 MB');
                  },
                ),
                _buildItem(
                  context,
                  icon: Icons.videocam_rounded,
                  label: 'Video',
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.pop(context);
                    onAttachmentSelected('video', 'security_brief.mp4', '14.2 MB');
                  },
                ),
                _buildItem(
                  context,
                  icon: Icons.description_rounded,
                  label: 'Document',
                  color: const Color(0xFFEF4444),
                  onTap: () {
                    Navigator.pop(context);
                    onAttachmentSelected('document', 'E2EE_ASVS_Specification.pdf', '1.8 MB');
                  },
                ),
                _buildItem(
                  context,
                  icon: Icons.task_alt_rounded,
                  label: 'New Task',
                  color: const Color(0xFF10B981),
                  onTap: () {
                    Navigator.pop(context);
                    onTaskOption();
                  },
                ),
                _buildItem(
                  context,
                  icon: Icons.mic_rounded,
                  label: 'Audio Note',
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    Navigator.pop(context);
                    onAttachmentSelected('audio', 'voice_memo.aac', '512 KB');
                  },
                ),
                _buildItem(
                  context,
                  icon: Icons.location_on_rounded,
                  label: 'Location',
                  color: const Color(0xFF06B6D4),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mock Location card shared.')),
                    );
                  },
                ),
                _buildItem(
                  context,
                  icon: Icons.person_rounded,
                  label: 'Contact',
                  color: const Color(0xFFEC4899),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mock Contact card shared.')),
                    );
                  },
                ),
                _buildItem(
                  context,
                  icon: Icons.poll_rounded,
                  label: 'Poll',
                  color: const Color(0xFF6366F1),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mock Poll modal triggered.')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: theme.primaryTextColor,
              fontSize: 11.5 * theme.fontScale,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
