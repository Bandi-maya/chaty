import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../ui/core/theme/theme_config.dart';
import '../../ui/core/theme/theme_controller.dart';
import '../../ui/core/ux/chaty_ux.dart';
import '../../data/repositories/mock_data_store.dart';
import '../../data/services/chaty_call_service.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/user_profile.dart';
import '../../injection/locator.dart';
import '../../ui/core/widgets/app_avatar.dart';
import 'chaty_call_screen.dart';

class CallsScreen extends StatefulWidget {
  final ThemeConfig theme;
  final MockDataStore dataStore;

  const CallsScreen({super.key, required this.theme, required this.dataStore});

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  late final Stream<List<Map<String, dynamic>>> _callsStream;

  @override
  void initState() {
    super.initState();
    _callsStream = Supabase.instance.client
        .from('call_sessions')
        .stream(primaryKey: const <String>['id'])
        .order('started_at', ascending: false);
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month} $h:$m';
  }

  UserProfile? _peer(ChatyCallSession call) {
    final me = widget.dataStore.currentUser.id;
    final id = call.callerId == me ? call.calleeId : call.callerId;
    return widget.dataStore.getUser(id);
  }

  Conversation? _conversation(ChatyCallSession call) =>
      widget.dataStore.conversations.where((c) => c.id == call.conversationId).firstOrNull;

  Future<void> _startFromConversation(Conversation conversation, UserProfile peer, bool video) async {
    final service = ChatyCallService();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatyCallScreen(
          theme: locator<ThemeController>().globalTheme,
          callService: service,
          title: peer.displayName,
          conversationId: conversation.id,
          peerUserId: peer.id,
          isVideo: video,
        ),
      ),
    );
    service.dispose();
  }

  Future<void> _showNewCallSheet() async {
    final theme = locator<ThemeController>().globalTheme;
    final direct = widget.dataStore.conversations
        .where((c) => c.type == ConversationType.direct)
        .toList(growable: false);
    if (direct.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start a direct conversation before calling.')),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .72),
          child: ChatyResponsiveContent(
            maxWidth: 640,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 18),
            child: ListView.separated(
              shrinkWrap: true,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: direct.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final conversation = direct[index];
                final peerId = conversation.participantIds.firstWhere(
                  (id) => id != widget.dataStore.currentUser.id,
                  orElse: () => '',
                );
                final peer = peerId.isEmpty ? null : widget.dataStore.getUser(peerId);
                if (peer == null) return const SizedBox.shrink();
                return MergeSemantics(
                  child: ListTile(
                    leading: AppAvatar(initials: peer.avatarInitials, colorHex: peer.avatarColorHex, size: 42),
                    title: Text(peer.displayName, style: TextStyle(color: theme.primaryTextColor, fontWeight: FontWeight.w700)),
                    subtitle: Text('@${peer.username}', style: TextStyle(color: theme.secondaryTextColor)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Voice call ${peer.displayName}',
                          icon: const Icon(Icons.call_rounded),
                          onPressed: () {
                            Navigator.pop(context);
                            _startFromConversation(conversation, peer, false);
                          },
                        ),
                        IconButton(
                          tooltip: 'Video call ${peer.displayName}',
                          icon: const Icon(Icons.videocam_rounded),
                          onPressed: () {
                            Navigator.pop(context);
                            _startFromConversation(conversation, peer, true);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = locator<ThemeController>().globalTheme;
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChatyResponsiveContent(
              maxWidth: ChatyUx.wideContentWidth,
              padding: EdgeInsets.fromLTRB(
                ChatyUx.horizontalPaddingFor(MediaQuery.sizeOf(context).width),
                8,
                8,
                8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Calls',
                        style: TextStyle(
                          color: theme.primaryTextColor,
                          fontSize: 24 * theme.fontScale,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.5,
                        ),
                      ),
                    ),
                  ),
                  IconButton(tooltip: 'Start a new call', onPressed: _showNewCallSheet, icon: const Icon(Icons.add_call)),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _callsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const ChatyStateView(
                      kind: ChatyStateKind.loading,
                      title: 'Loading calls',
                      message: 'Retrieving your call history.',
                    );
                  }
                  if (snapshot.hasError) {
                    return ChatyStateView(
                      kind: ChatyStateKind.error,
                      title: 'Unable to load calls',
                      message: 'Check your connection and try again. ${snapshot.error}',
                      actionLabel: 'Try again',
                      onAction: () => setState(() {}),
                    );
                  }
                  final calls = (snapshot.data ?? const <Map<String, dynamic>>[])
                      .map((row) => ChatyCallSession.fromRow(Map<String, dynamic>.from(row)))
                      .toList(growable: false);
                  if (calls.isEmpty) {
                    return ChatyStateView(
                      kind: ChatyStateKind.empty,
                      title: 'No calls yet',
                      message: 'Your voice and video call history will appear here after your first call.',
                      icon: Icons.phone_in_talk_outlined,
                      actionLabel: 'Start a call',
                      onAction: _showNewCallSheet,
                    );
                  }
                  return ChatyResponsiveContent(
                    maxWidth: ChatyUx.wideContentWidth,
                    padding: EdgeInsets.symmetric(horizontal: ChatyUx.horizontalPaddingFor(MediaQuery.sizeOf(context).width)),
                    child: ListView.separated(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.only(top: 4, bottom: 92),
                      itemCount: calls.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final call = calls[index];
                        final peer = _peer(call);
                        final conversation = _conversation(call);
                        final mine = call.callerId == widget.dataStore.currentUser.id;
                        final missed = call.status == 'declined' || (call.status == 'ended' && call.connectedAt == null);
                        final typeLabel = call.isVideo ? 'Video' : 'Voice';
                        final directionLabel = missed ? 'Missed' : mine ? 'Outgoing' : 'Incoming';
                        return Semantics(
                          container: true,
                          label: '${peer?.displayName ?? 'Chaty user'}, $directionLabel $typeLabel call, ${_formatTime(call.startedAt)}, ${call.status}',
                          child: ExcludeSemantics(
                            child: ListTile(
                              leading: AppAvatar(
                                initials: peer?.avatarInitials ?? 'C',
                                colorHex: peer?.avatarColorHex ?? '0xFF6366F1',
                                size: 44,
                              ),
                              title: Text(
                                peer?.displayName ?? 'Chaty user',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: missed ? theme.dangerColor : theme.primaryTextColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Icon(
                                    missed
                                        ? Icons.call_missed_rounded
                                        : mine
                                            ? Icons.call_made_rounded
                                            : Icons.call_received_rounded,
                                    size: 14,
                                    color: missed ? theme.dangerColor : theme.secondaryTextColor,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      '$typeLabel • ${_formatTime(call.startedAt)} • ${call.status}',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: theme.secondaryTextColor, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: conversation == null || peer == null
                                  ? null
                                  : IconButton(
                                      tooltip: call.isVideo ? 'Video call again' : 'Voice call again',
                                      icon: Icon(call.isVideo ? Icons.videocam_rounded : Icons.call_rounded, color: theme.accentColor),
                                      onPressed: () => _startFromConversation(conversation, peer, call.isVideo),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Start a new call',
        backgroundColor: theme.accentColor,
        foregroundColor: theme.onAccentColor,
        onPressed: _showNewCallSheet,
        child: const Icon(Icons.add_call),
      ),
    );
  }
}
