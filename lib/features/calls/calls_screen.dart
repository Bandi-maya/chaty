import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../ui/core/theme/theme_config.dart';
import '../../../ui/core/theme/theme_controller.dart';
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
    _callsStream = Supabase.instance.client.from('call_sessions').stream(primaryKey: const <String>['id']).order('started_at', ascending: false);
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

  Conversation? _conversation(ChatyCallSession call) => widget.dataStore.conversations.where((c) => c.id == call.conversationId).firstOrNull;

  Future<void> _startFromConversation(Conversation conversation, UserProfile peer, bool video) async {
    final service = ChatyCallService();
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatyCallScreen(theme: locator<ThemeController>().globalTheme, callService: service, title: peer.displayName, conversationId: conversation.id, peerUserId: peer.id, isVideo: video)));
    service.dispose();
  }

  Future<void> _showNewCallSheet() async {
    final theme = locator<ThemeController>().globalTheme;
    final direct = widget.dataStore.conversations.where((c) => c.type == ConversationType.direct).toList(growable: false);
    if (direct.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Start a direct conversation before calling.')));
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
          itemCount: direct.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final conversation = direct[index];
            final peerId = conversation.participantIds.firstWhere((id) => id != widget.dataStore.currentUser.id, orElse: () => '');
            final peer = peerId.isEmpty ? null : widget.dataStore.getUser(peerId);
            if (peer == null) return const SizedBox.shrink();
            return ListTile(
              leading: AppAvatar(initials: peer.avatarInitials, colorHex: peer.avatarColorHex, size: 42),
              title: Text(peer.displayName, style: TextStyle(color: theme.primaryTextColor, fontWeight: FontWeight.w700)),
              subtitle: Text('@${peer.username}', style: TextStyle(color: theme.secondaryTextColor)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(tooltip: 'Voice call', icon: const Icon(Icons.call_rounded), onPressed: () { Navigator.pop(context); _startFromConversation(conversation, peer, false); }),
                IconButton(tooltip: 'Video call', icon: const Icon(Icons.videocam_rounded), onPressed: () { Navigator.pop(context); _startFromConversation(conversation, peer, true); }),
              ]),
            );
          },
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
            child: Row(children: [
              Expanded(child: Text('Calls', style: TextStyle(color: theme.primaryTextColor, fontSize: 24 * theme.fontScale, fontWeight: FontWeight.w800, letterSpacing: -.5))),
              IconButton(tooltip: 'New call', onPressed: _showNewCallSheet, icon: const Icon(Icons.add_call)),
            ]),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _callsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) return Center(child: CircularProgressIndicator(color: theme.accentColor));
                if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Unable to load call history: ${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: theme.dangerColor))));
                final calls = (snapshot.data ?? const <Map<String, dynamic>>[]).map((row) => ChatyCallSession.fromRow(Map<String, dynamic>.from(row))).toList(growable: false);
                if (calls.isEmpty) {
                  return Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.phone_in_talk_outlined, size: 56, color: theme.accentColor), const SizedBox(height: 18),
                    Text('No calls yet', style: TextStyle(color: theme.primaryTextColor, fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 8),
                    Text('Your real voice and video call history will appear here.', textAlign: TextAlign.center, style: TextStyle(color: theme.secondaryTextColor, height: 1.4)),
                  ])));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 92), itemCount: calls.length, separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final call = calls[index]; final peer = _peer(call); final conversation = _conversation(call); final mine = call.callerId == widget.dataStore.currentUser.id; final missed = call.status == 'declined' || (call.status == 'ended' && call.connectedAt == null);
                    return ListTile(
                      leading: AppAvatar(initials: peer?.avatarInitials ?? 'C', colorHex: peer?.avatarColorHex ?? '0xFF6366F1', size: 44),
                      title: Text(peer?.displayName ?? 'Chaty user', style: TextStyle(color: missed ? theme.dangerColor : theme.primaryTextColor, fontWeight: FontWeight.w700)),
                      subtitle: Row(children: [Icon(missed ? Icons.call_missed_rounded : mine ? Icons.call_made_rounded : Icons.call_received_rounded, size: 14, color: missed ? theme.dangerColor : theme.secondaryTextColor), const SizedBox(width: 5), Flexible(child: Text('${call.isVideo ? 'Video' : 'Voice'} • ${_formatTime(call.startedAt)} • ${call.status}', overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.secondaryTextColor, fontSize: 12)))]),
                      trailing: conversation == null || peer == null ? null : IconButton(tooltip: call.isVideo ? 'Video call again' : 'Voice call again', icon: Icon(call.isVideo ? Icons.videocam_rounded : Icons.call_rounded, color: theme.accentColor), onPressed: () => _startFromConversation(conversation, peer, call.isVideo)),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
      floatingActionButton: FloatingActionButton(backgroundColor: theme.accentColor, foregroundColor: theme.onAccentColor, onPressed: _showNewCallSheet, child: const Icon(Icons.add_call)),
    );
  }
}
