import 'package:flutter/material.dart';

import '../../../ui/core/theme/theme_config.dart';
import '../../../ui/core/theme/theme_controller.dart';
import '../../data/repositories/mock_data_store.dart';
import '../../data/services/status_repository.dart';
import '../../domain/models/status_update.dart';
import '../../injection/locator.dart';
import '../../ui/core/controllers/chaty_preferences_controller.dart';
import '../../ui/core/widgets/app_avatar.dart';
import 'status_composer_sheet.dart';
import 'status_viewer_screen.dart';

class UpdatesScreen extends StatefulWidget {
  final ThemeConfig theme;
  final MockDataStore dataStore;
  final ChatyPreferencesController preferencesController;

  const UpdatesScreen({
    super.key,
    required this.theme,
    required this.dataStore,
    required this.preferencesController,
  });

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  late final StatusRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = StatusRepository()..addListener(_onRepositoryChanged);
    _repository.initialize();
  }

  void _onRepositoryChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _repository.removeListener(_onRepositoryChanged);
    _repository.dispose();
    super.dispose();
  }

  Future<void> _compose(ThemeConfig theme) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatusComposerSheet(
        theme: theme,
        repository: _repository,
      ),
    );
  }

  void _openStatus(StatusUpdate status, ThemeConfig theme) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StatusViewerScreen(
          status: status,
          theme: theme,
          dataStore: widget.dataStore,
          repository: _repository,
        ),
      ),
    );
  }

  String _relative(DateTime date) {
    final difference = DateTime.now().difference(date.toLocal());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    return '${difference.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = locator<ThemeController>().globalTheme;
    final currentUser = widget.dataStore.currentUser;
    final statuses = _repository.items;
    final own = statuses.where((status) => status.userId == currentUser.id).toList();
    final others = statuses.where((status) => status.userId != currentUser.id).toList();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _repository.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Updates',
                          style: TextStyle(
                            color: theme.primaryTextColor,
                            fontSize: 22 * theme.fontScale,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Add status',
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        color: theme.primaryTextColor,
                        onPressed: () => _compose(theme),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                  child: Material(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: own.isNotEmpty
                          ? () => _openStatus(own.first, theme)
                          : () => _compose(theme),
                      child: Padding(
                        padding: const EdgeInsets.all(13),
                        child: Row(
                          children: <Widget>[
                            Stack(
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.all(own.isNotEmpty ? 2 : 0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: own.isNotEmpty
                                        ? Border.all(color: theme.accentColor, width: 2)
                                        : null,
                                  ),
                                  child: AppAvatar(
                                    initials: currentUser.avatarInitials,
                                    colorHex: currentUser.avatarColorHex,
                                    size: 52,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: theme.accentColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.cardColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      own.isEmpty
                                          ? Icons.add_rounded
                                          : Icons.edit_rounded,
                                      color: theme.onAccentColor,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'My Status',
                                    style: TextStyle(
                                      color: theme.primaryTextColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    own.isEmpty
                                        ? 'Tap to share text, image, video, audio or a file'
                                        : '${own.length} active update${own.length == 1 ? '' : 's'} • ${_relative(own.first.createdAt)}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: theme.secondaryTextColor,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Create another status',
                              icon: const Icon(Icons.add_rounded),
                              color: theme.secondaryTextColor,
                              onPressed: () => _compose(theme),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: Text(
                    'RECENT UPDATES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.secondaryTextColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              if (_repository.loading && statuses.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_repository.error != null && statuses.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.cloud_off_rounded,
                            size: 52,
                            color: theme.secondaryTextColor,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Unable to load updates',
                            style: TextStyle(
                              color: theme.primaryTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check the connection and pull to retry.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: theme.secondaryTextColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (others.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.accentColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: 54,
                              color: theme.accentColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No recent updates',
                            style: TextStyle(
                              color: theme.primaryTextColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Active contact updates appear here for 24 hours.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.secondaryTextColor,
                              fontSize: 13.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList.separated(
                  itemCount: others.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    indent: 80,
                    color: theme.secondaryTextColor.withValues(alpha: 0.08),
                  ),
                  itemBuilder: (context, index) {
                    final status = others[index];
                    final user = widget.dataStore.getUser(status.userId);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.accentColor, width: 2.5),
                        ),
                        child: AppAvatar(
                          initials: user?.avatarInitials ?? 'CU',
                          colorHex: user?.avatarColorHex ?? '0xFF6366F1',
                          size: 44,
                        ),
                      ),
                      title: Text(
                        user?.displayName ?? 'Chaty user',
                        style: TextStyle(
                          color: theme.primaryTextColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${_relative(status.createdAt)} • ${status.mediaType}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.secondaryTextColor,
                          fontSize: 12.5,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: theme.secondaryTextColor,
                      ),
                      onTap: () => _openStatus(status, theme),
                    );
                  },
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}
