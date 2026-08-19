import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../ui/core/theme/theme_config.dart';
import '../../../ui/core/theme/theme_controller.dart';
import '../../data/repositories/mock_data_store.dart';
import '../../data/services/chat_media_service.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/user_profile.dart';
import '../../ui/core/commands/chat_command_parser.dart';
import '../../ui/core/controllers/chaty_preferences_controller.dart';
import '../../ui/core/design_system/chaty_settings_primitives.dart';
import '../../ui/core/widgets/app_avatar.dart';
import '../../ui/core/widgets/security_chip.dart';
import '../calls/mock_call_screen.dart';
import '../messages/attachment_sheet.dart';
import '../messages/media_viewer_screen.dart';
import '../messages/message_action_sheet.dart';
import '../messages/message_bubble.dart';
import '../tasks/task_create_edit_modal.dart';
import '../tasks/task_detail_screen.dart';
import 'group_info_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final ThemeConfig theme;
  final MockDataStore dataStore;
  final String conversationId;
  final ChatyPreferencesController preferencesController;
  final ThemeController? themeController;

  const ChatDetailScreen({
    super.key,
    required this.theme,
    required this.dataStore,
    required this.conversationId,
    required this.preferencesController,
    this.themeController,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatMediaService _mediaService = ChatMediaService();
  final AudioRecorder _recorder = AudioRecorder();
  final Uuid _uuid = const Uuid();
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  ChatMessage? _replyTarget;
  bool _showQuickReplyOverlay = false;
  bool _recordingVoice = false;
  bool _sendingVoice = false;
  DateTime? _recordingStartedAt;

  ThemeConfig get _liveTheme => widget.themeController?.globalTheme ?? widget.theme;

  @override
  void initState() {
    super.initState();
    unawaited(widget.dataStore.ensureConversationLoaded(widget.conversationId));
    final conversation = widget.dataStore.conversations
        .where((item) => item.id == widget.conversationId)
        .firstOrNull;
    if (conversation != null && conversation.draftText.isNotEmpty) {
      _textCtrl.text = conversation.draftText;
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    unawaited(_recorder.dispose());
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    final parsedCommand = ChatCommandParser.parse(text);
    if (parsedCommand.type == ChatCommandType.task) {
      _textCtrl.clear();
      widget.dataStore.setDraft(widget.conversationId, '');
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => TaskCreateEditModal(
          theme: _liveTheme,
          dataStore: widget.dataStore,
          sourceConversationId: widget.conversationId,
          initialTitle:
              parsedCommand.argument.isNotEmpty ? parsedCommand.argument : null,
        ),
      );
      return;
    }

    final reply = _replyTarget;
    _textCtrl.clear();
    widget.dataStore.setDraft(widget.conversationId, '');
    setState(() {
      _replyTarget = null;
      _showQuickReplyOverlay = false;
    });

    try {
      await widget.dataStore.sendMessage(
        conversationId: widget.conversationId,
        text: text,
        replyToMessageId: reply?.id,
        replyToSenderName:
            reply != null ? _getSenderName(reply.senderId) : null,
        replyToPreviewText: reply?.text,
      );
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Message failed: ${error.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getSenderName(String senderId) {
    if (senderId == widget.dataStore.currentUser.id) return 'You';
    return widget.dataStore.getUser(senderId)?.displayName ?? 'Chaty user';
  }

  String _presenceLabel(UserProfile? user) {
    if (user == null) return 'Last seen unavailable';
    if (user.presence == PresenceState.online) return 'Online';
    final local = user.lastSeenAt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(local.year, local.month, local.day);
    final days = today.difference(date).inDays;
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    if (days == 0) return 'Last seen today at $time';
    if (days == 1) return 'Last seen yesterday at $time';
    return 'Last seen ${local.day}/${local.month}/${local.year} at $time';
  }

  void _onMessageLongPress(ChatMessage message) {
    final isMe = message.senderId == widget.dataStore.currentUser.id;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => MessageActionSheet(
        message: message,
        isMe: isMe,
        theme: _liveTheme,
        onReact: (emoji) {
          widget.dataStore.toggleReaction(widget.conversationId, message.id, emoji);
          Navigator.of(sheetContext).pop();
        },
        onReply: () {
          setState(() => _replyTarget = message);
          Navigator.of(sheetContext).pop();
        },
        onPin: () {
          widget.dataStore.togglePinMessage(widget.conversationId, message.id);
          Navigator.of(sheetContext).pop();
        },
        onStar: () {
          widget.dataStore.toggleStarMessage(widget.conversationId, message.id);
          Navigator.of(sheetContext).pop();
        },
        onCopy: () {
          Navigator.of(sheetContext).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message copied to clipboard')),
          );
        },
        onDeleteForMe: () {
          widget.dataStore.deleteMessage(
            widget.conversationId,
            message.id,
            forEveryone: false,
          );
          Navigator.of(sheetContext).pop();
        },
        onDeleteForEveryone: isMe
            ? () {
                widget.dataStore.deleteMessage(
                  widget.conversationId,
                  message.id,
                  forEveryone: true,
                );
                Navigator.of(sheetContext).pop();
              }
            : null,
        onReport: () {
          Navigator.of(sheetContext).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message reported')),
          );
        },
        onCreateTask: () {
          Navigator.of(sheetContext).pop();
          _openCreateTaskModal(
            initialTitle: message.text,
            sourceMessageId: message.id,
          );
        },
      ),
    );
  }

  Future<void> _openCreateTaskModal({
    String? initialTitle,
    String? sourceMessageId,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TaskCreateEditModal(
        theme: _liveTheme,
        dataStore: widget.dataStore,
        sourceConversationId: widget.conversationId,
        initialTitle: initialTitle,
        sourceMessageId: sourceMessageId,
      ),
    );
  }

  void _openLinkedTask(ChatMessage message) {
    final taskId = message.linkedTaskId;
    if (taskId == null || taskId.isEmpty) {
      _openCreateTaskModal(sourceMessageId: message.id);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskDetailScreen(
          taskId: taskId,
          theme: _liveTheme,
          dataStore: widget.dataStore,
        ),
      ),
    );
  }

  void _openAttachmentSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AttachmentSheet(
        theme: _liveTheme,
        onMediaRequested: _shareMedia,
        onLocationRequested: _shareLocation,
        onContactRequested: _shareContact,
        onPollRequested: _createPoll,
        onTaskOption: () => _openCreateTaskModal(),
      ),
    );
  }

  Future<void> _shareMedia(String type) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final attachment = await _mediaService.pickAndUpload(
        conversationId: widget.conversationId,
        type: type,
      );
      if (attachment == null) return;
      final messageType = switch (type) {
        'image' => MessageType.image,
        'video' => MessageType.video,
        'audio' => MessageType.audio,
        _ => MessageType.document,
      };
      await widget.dataStore.sendMessage(
        conversationId: widget.conversationId,
        text: attachment.name,
        type: messageType,
        attachment: attachment,
      );
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Unable to share file: ${error.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  Future<void> _shareLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Turn on location services to share your location.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required.');
      }
      final position = await Geolocator.getCurrentPosition();
      final latitude = position.latitude.toStringAsFixed(6);
      final longitude = position.longitude.toStringAsFixed(6);
      await widget.dataStore.sendMessage(
        conversationId: widget.conversationId,
        type: MessageType.location,
        text: '📍 Location\nhttps://maps.google.com/?q=$latitude,$longitude',
      );
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _shareContact() async {
    try {
      var allowed = await FlutterContacts.permissions.has(PermissionType.read);
      if (!allowed) {
        await FlutterContacts.permissions.request(PermissionType.read);
        allowed = await FlutterContacts.permissions.has(PermissionType.read);
      }
      if (!allowed) throw Exception('Contacts permission is required.');
      final contacts = await FlutterContacts.getAll(limit: 200);
      if (!mounted || contacts.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No contacts are available to share.')),
          );
        }
        return;
      }
      final selected = await showModalBottomSheet<Contact>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.72,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                  child: Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Share contact',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (_, index) {
                      final contact = contacts[index];
                      final displayName = (contact.displayName ?? '').trim();
                      final name = displayName.isEmpty
                          ? 'Unnamed contact'
                          : displayName;
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person_outline_rounded),
                        ),
                        title: Text(name),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.pop(sheetContext, contact),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (selected == null) return;
      final selectedDisplayName = (selected.displayName ?? '').trim();
      final name = selectedDisplayName.isEmpty
          ? 'Unnamed contact'
          : selectedDisplayName;
      await widget.dataStore.sendMessage(
        conversationId: widget.conversationId,
        type: MessageType.contact,
        text: '👤 Contact: $name',
      );
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _createPoll() async {
    final questionCtrl = TextEditingController();
    final option1Ctrl = TextEditingController();
    final option2Ctrl = TextEditingController();
    try {
      final submitted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Create poll'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: questionCtrl,
                  maxLength: 300,
                  decoration: const InputDecoration(labelText: 'Question'),
                ),
                TextField(
                  controller: option1Ctrl,
                  maxLength: 160,
                  decoration: const InputDecoration(labelText: 'Option 1'),
                ),
                TextField(
                  controller: option2Ctrl,
                  maxLength: 160,
                  decoration: const InputDecoration(labelText: 'Option 2'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Create'),
            ),
          ],
        ),
      );
      if (submitted != true) return;
      final question = questionCtrl.text.trim();
      final options = <String>[option1Ctrl.text.trim(), option2Ctrl.text.trim()]
          .where((option) => option.isNotEmpty)
          .toList();
      if (question.isEmpty || options.length < 2) {
        throw Exception('A poll requires a question and at least two options.');
      }
      await Supabase.instance.client.rpc(
        'create_poll',
        params: <String, dynamic>{
          'p_conversation_id': widget.conversationId,
          'p_client_message_id': _uuid.v4(),
          'p_question': question,
          'p_options': options,
          'p_allow_multiple': false,
        },
      );
      await widget.dataStore.ensureConversationLoaded(widget.conversationId);
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      questionCtrl.dispose();
      option1Ctrl.dispose();
      option2Ctrl.dispose();
    }
  }

  Future<void> _toggleVoiceRecording() async {
    if (_sendingVoice) return;
    if (_recordingVoice) {
      await _finishVoiceRecording();
    } else {
      await _startVoiceRecording();
    }
  }

  Future<void> _startVoiceRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        throw Exception('Microphone permission is required for voice notes.');
      }
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/chaty_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 44100,
          numChannels: 1,
          noiseSuppress: true,
        ),
        path: path,
      );
      if (!mounted) return;
      setState(() {
        _recordingVoice = true;
        _recordingStartedAt = DateTime.now();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _finishVoiceRecording() async {
    setState(() {
      _recordingVoice = false;
      _sendingVoice = true;
    });
    try {
      final path = await _recorder.stop();
      if (path == null || path.isEmpty) throw Exception('Voice recording was empty.');
      final seconds = DateTime.now()
          .difference(_recordingStartedAt ?? DateTime.now())
          .inSeconds
          .clamp(1, 3600)
          .toInt();
      final attachment = await _mediaService.uploadFile(
        conversationId: widget.conversationId,
        type: 'audio',
        sourcePath: path,
        displayName: 'Voice note.m4a',
        durationSeconds: seconds,
      );
      await widget.dataStore.sendMessage(
        conversationId: widget.conversationId,
        text: 'Voice note',
        type: MessageType.audio,
        attachment: attachment,
      );
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sendingVoice = false;
          _recordingStartedAt = null;
        });
      }
    }
  }

  void _startCallSession(bool isVideo) {
    final conversation = widget.dataStore.conversations
        .where((item) => item.id == widget.conversationId)
        .firstOrNull;
    if (conversation == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MockCallScreen(
          theme: _liveTheme,
          title: conversation.title,
          isVideo: isVideo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listenables = <Listenable>[
      widget.dataStore,
      widget.preferencesController,
      if (widget.themeController != null) widget.themeController!,
    ];
    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, _) => _buildReactiveChat(context),
    );
  }

  Widget _buildReactiveChat(BuildContext context) {
    final theme = _liveTheme;
    final dataStore = widget.dataStore;
    final convPrefs = widget.preferencesController.conversation;
    final autoPrefs = widget.preferencesController.automation;
    final visual = widget.preferencesController.visual;
    final conversation = dataStore.conversations
        .where((item) => item.id == widget.conversationId)
        .firstOrNull;

    if (conversation == null) {
      return Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text('Chat'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final otherParticipant = conversation.participantIds.firstWhere(
      (id) => id != dataStore.currentUser.id,
      orElse: () => '',
    );
    final otherUser =
        otherParticipant.isNotEmpty ? dataStore.getUser(otherParticipant) : null;
    final messages = dataStore.getMessages(widget.conversationId);
    final isTyping = dataStore.isUserTyping(widget.conversationId);

    Widget chatContent = Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.chevron_left_rounded),
          color: theme.primaryTextColor,
          onPressed: () => Navigator.maybePop(context),
        ),
        titleSpacing: 0,
        title: InkWell(
          onTap: () {
            if (conversation.type == ConversationType.group) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => GroupInfoScreen(
                    theme: theme,
                    dataStore: dataStore,
                    conversationId: widget.conversationId,
                  ),
                ),
              );
            }
          },
          child: Row(
            children: <Widget>[
              AppAvatar(
                initials: conversation.avatarInitials ??
                    conversation.title.characters.take(2).toString().toUpperCase(),
                colorHex: conversation.avatarColorHex ?? '0xFF6366F1',
                size: 38,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      conversation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.primaryTextColor,
                        fontSize: 15.5 * theme.fontScale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isTyping
                          ? 'typing…'
                          : conversation.type == ConversationType.group
                              ? '${conversation.participantIds.length} members'
                              : _presenceLabel(otherUser),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isTyping || otherUser?.presence == PresenceState.online
                            ? theme.successColor
                            : theme.secondaryTextColor,
                        fontSize: 10.8 * theme.fontScale,
                        fontStyle: isTyping ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Voice call',
            icon: const Icon(Icons.call_rounded),
            onPressed: () => _startCallSession(false),
          ),
          IconButton(
            tooltip: 'Video call',
            icon: const Icon(Icons.videocam_rounded),
            onPressed: () => _startCallSession(true),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: SecurityChip(status: conversation.encryptionStatus),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Text(
                        'No messages yet',
                        style: TextStyle(color: theme.secondaryTextColor),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == dataStore.currentUser.id;
                        final senderName = conversation.type == ConversationType.group && !isMe
                            ? _getSenderName(message.senderId)
                            : null;
                        return MessageBubble(
                          message: message,
                          isMe: isMe,
                          theme: theme,
                          bubbleVariant: visual.bubbleStyle,
                          senderName: senderName,
                          onLongPress: () => _onMessageLongPress(message),
                          onReactionTap: (emoji) => dataStore.toggleReaction(
                            conversation.id,
                            message.id,
                            emoji,
                          ),
                          onTaskTap: message.type == MessageType.taskCard
                              ? () => _openLinkedTask(message)
                              : null,
                          onMediaTap: message.attachment != null
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => MediaViewerScreen(
                                        title: message.attachment!.name,
                                        type: message.attachment!.type,
                                        size: message.attachment!.size,
                                        storagePath: message.attachment!.url,
                                        theme: theme,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                        );
                      },
                    ),
            ),
            if (_showQuickReplyOverlay && autoPrefs.quickReplies.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 190),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.accentColor.withValues(alpha: 0.3),
                  ),
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: autoPrefs.quickReplies.map((reply) {
                    return ListTile(
                      dense: true,
                      title: Text(
                        '${reply.shortcut} — ${reply.title}',
                        style: TextStyle(
                          color: theme.primaryTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        reply.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: theme.secondaryTextColor),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        _textCtrl.text = reply.content;
                        _textCtrl.selection = TextSelection.collapsed(
                          offset: _textCtrl.text.length,
                        );
                        setState(() => _showQuickReplyOverlay = false);
                      },
                    );
                  }).toList(),
                ),
              ),
            if (_replyTarget != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: theme.cardColor,
                child: Row(
                  children: <Widget>[
                    Icon(Icons.reply_rounded, color: theme.accentColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Replying to ${_getSenderName(_replyTarget!.senderId)}',
                            style: TextStyle(
                              color: theme.accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _replyTarget!.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(() => _replyTarget = null),
                    ),
                  ],
                ),
              ),
            _buildComposer(theme),
          ],
        ),
      ),
    );

    if (convPrefs.enableQuickContactSidebar && dataStore.contacts.isNotEmpty) {
      return Row(
        children: <Widget>[
          if (convPrefs.sidebarPosition == 'Left')
            _quickContactSidebar(theme, dataStore),
          Expanded(child: chatContent),
          if (convPrefs.sidebarPosition == 'Right')
            _quickContactSidebar(theme, dataStore),
        ],
      );
    }
    return chatContent;
  }

  Widget _buildComposer(ThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        border: Border(
          top: BorderSide(
            color: theme.secondaryTextColor.withValues(alpha: 0.10),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              color: theme.accentColor,
              tooltip: 'Attach',
              onPressed: _openAttachmentSheet,
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.secondaryTextColor.withValues(alpha: 0.10),
                  ),
                ),
                child: TextField(
                  controller: _textCtrl,
                  maxLines: 5,
                  minLines: 1,
                  style: TextStyle(
                    color: theme.primaryTextColor,
                    fontSize: 14.5 * theme.fontScale,
                  ),
                  onChanged: (value) {
                    widget.dataStore.setDraft(widget.conversationId, value);
                    setState(() {
                      _showQuickReplyOverlay = value.contains('#');
                    });
                  },
                  decoration: InputDecoration(
                    hintText: _recordingVoice
                        ? 'Recording voice note… tap mic to send'
                        : 'Type a message… (/task or #)',
                    hintStyle: TextStyle(
                      color: theme.secondaryTextColor.withValues(alpha: 0.75),
                      fontSize: 13.5 * theme.fontScale,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 7),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: _textCtrl.text.trim().isNotEmpty
                  ? IconButton.filled(
                      key: const ValueKey<String>('send'),
                      tooltip: 'Send',
                      icon: const Icon(Icons.send_rounded, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.accentColor,
                        foregroundColor: theme.onAccentColor,
                      ),
                      onPressed: _sendMessage,
                    )
                  : IconButton.filledTonal(
                      key: ValueKey<String>(
                        _recordingVoice ? 'recording' : 'mic',
                      ),
                      tooltip: _recordingVoice
                          ? 'Stop and send voice note'
                          : 'Record voice note',
                      icon: _sendingVoice
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _recordingVoice
                                  ? Icons.stop_rounded
                                  : Icons.mic_rounded,
                              size: 20,
                            ),
                      style: IconButton.styleFrom(
                        backgroundColor: _recordingVoice
                            ? theme.dangerColor.withValues(alpha: 0.18)
                            : theme.accentColor.withValues(alpha: 0.13),
                        foregroundColor:
                            _recordingVoice ? theme.dangerColor : theme.accentColor,
                      ),
                      onPressed: _sendingVoice ? null : _toggleVoiceRecording,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickContactSidebar(ThemeConfig theme, MockDataStore dataStore) {
    return SizedBox(
      width: 54,
      child: ColoredBox(
        color: theme.surfaceColor.withValues(
          alpha: widget.preferencesController.conversation.sidebarOpacity,
        ),
        child: ListView.builder(
          itemCount: dataStore.contacts.length,
          itemBuilder: (context, index) {
            final contact = dataStore.contacts[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: GestureDetector(
                onTap: () async {
                  final next = await dataStore.getOrCreateDirectConversation(contact);
                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => ChatDetailScreen(
                        conversationId: next.id,
                        theme: theme,
                        dataStore: dataStore,
                        preferencesController: widget.preferencesController,
                        themeController: widget.themeController,
                      ),
                    ),
                  );
                },
                child: Center(
                  child: ChatyAvatar(
                    initials: contact.avatarInitials,
                    color: Color(int.parse(contact.avatarColorHex)),
                    size: 36,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
