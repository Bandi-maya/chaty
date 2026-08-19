import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatyCallSession {
  final String id;
  final String conversationId;
  final String callerId;
  final String calleeId;
  final bool isVideo;
  final String status;
  final String? offerSdp;
  final String? answerSdp;
  final DateTime startedAt;
  final DateTime? connectedAt;
  final DateTime? endedAt;

  const ChatyCallSession({
    required this.id,
    required this.conversationId,
    required this.callerId,
    required this.calleeId,
    required this.isVideo,
    required this.status,
    required this.startedAt,
    this.offerSdp,
    this.answerSdp,
    this.connectedAt,
    this.endedAt,
  });

  factory ChatyCallSession.fromRow(Map<String, dynamic> row) => ChatyCallSession(
        id: row['id']?.toString() ?? '',
        conversationId: row['conversation_id']?.toString() ?? '',
        callerId: row['caller_id']?.toString() ?? '',
        calleeId: row['callee_id']?.toString() ?? '',
        isVideo: row['kind']?.toString() == 'video',
        status: row['status']?.toString() ?? 'ringing',
        offerSdp: row['offer_sdp']?.toString(),
        answerSdp: row['answer_sdp']?.toString(),
        startedAt: DateTime.tryParse(row['started_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
        connectedAt: DateTime.tryParse(row['connected_at']?.toString() ?? '')?.toLocal(),
        endedAt: DateTime.tryParse(row['ended_at']?.toString() ?? '')?.toLocal(),
      );
}

enum ChatyCallState { preparing, ringing, connecting, connected, ended, declined, failed }

class ChatyCallService extends ChangeNotifier {
  final SupabaseClient _client;
  RTCPeerConnection? _peer;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  StreamSubscription<List<Map<String, dynamic>>>? _sessionSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _candidateSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _incomingSubscription;
  final Set<String> _appliedCandidateIds = <String>{};
  final StreamController<ChatyCallSession> _incomingController = StreamController<ChatyCallSession>.broadcast();

  ChatyCallSession? session;
  ChatyCallState state = ChatyCallState.preparing;
  bool microphoneEnabled = true;
  bool cameraEnabled = true;
  bool speakerEnabled = false;
  String? errorMessage;

  ChatyCallService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  Stream<ChatyCallSession> get incomingCalls => _incomingController.stream;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  Future<void> watchIncomingCalls() async {
    await _incomingSubscription?.cancel();
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    _incomingSubscription = _client
        .from('call_sessions')
        .stream(primaryKey: const <String>['id'])
        .eq('callee_id', userId)
        .listen((rows) {
      final ringing = rows
          .map((row) => ChatyCallSession.fromRow(Map<String, dynamic>.from(row)))
          .where((call) => call.status == 'ringing')
          .toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
      if (ringing.isNotEmpty) _incomingController.add(ringing.first);
    });
  }

  Future<ChatyCallSession> startOutgoing({
    required String conversationId,
    required String calleeId,
    required bool isVideo,
  }) async {
    await _preparePeer(isVideo: isVideo);
    final offer = await _peer!.createOffer();
    await _peer!.setLocalDescription(offer);
    final callerId = _requireUserId();
    final row = await _client
        .from('call_sessions')
        .insert(<String, dynamic>{
          'conversation_id': conversationId,
          'caller_id': callerId,
          'callee_id': calleeId,
          'kind': isVideo ? 'video' : 'audio',
          'status': 'ringing',
          'offer_sdp': offer.sdp,
        })
        .select()
        .single();
    session = ChatyCallSession.fromRow(Map<String, dynamic>.from(row));
    state = ChatyCallState.ringing;
    notifyListeners();
    await _bindSession(session!.id);
    return session!;
  }

  Future<void> acceptIncoming(ChatyCallSession incoming) async {
    if (incoming.offerSdp == null || incoming.offerSdp!.isEmpty) {
      throw Exception('The incoming call has no valid WebRTC offer.');
    }
    session = incoming;
    state = ChatyCallState.connecting;
    notifyListeners();
    await _preparePeer(isVideo: incoming.isVideo);
    await _peer!.setRemoteDescription(RTCSessionDescription(incoming.offerSdp, 'offer'));
    final answer = await _peer!.createAnswer();
    await _peer!.setLocalDescription(answer);
    await _client.from('call_sessions').update(<String, dynamic>{
      'status': 'accepted',
      'answer_sdp': answer.sdp,
      'connected_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', incoming.id);
    await _bindSession(incoming.id);
  }

  Future<void> declineIncoming(ChatyCallSession incoming) async {
    await _client.from('call_sessions').update(<String, dynamic>{
      'status': 'declined',
      'ended_at': DateTime.now().toUtc().toIso8601String(),
      'ended_by': _requireUserId(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', incoming.id);
  }

  Future<void> _preparePeer({required bool isVideo}) async {
    state = ChatyCallState.preparing;
    errorMessage = null;
    notifyListeners();
    _localStream = await navigator.mediaDevices.getUserMedia(<String, dynamic>{
      'audio': true,
      'video': isVideo
          ? <String, dynamic>{'facingMode': 'user', 'width': 1280, 'height': 720, 'frameRate': 30}
          : false,
    });
    cameraEnabled = isVideo;
    microphoneEnabled = true;
    _peer = await createPeerConnection(<String, dynamic>{
      'iceServers': <Map<String, dynamic>>[
        <String, dynamic>{'urls': 'stun:stun.l.google.com:19302'},
        <String, dynamic>{'urls': 'stun:stun1.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    });
    for (final track in _localStream!.getTracks()) {
      await _peer!.addTrack(track, _localStream!);
    }
    _peer!.onTrack = (event) {
      if (event.streams.isEmpty) return;
      _remoteStream = event.streams.first;
      notifyListeners();
    };
    _peer!.onConnectionState = (peerState) {
      if (peerState == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        state = ChatyCallState.connected;
      } else if (peerState == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        state = ChatyCallState.failed;
        errorMessage = 'The peer connection failed. Check network connectivity and try again.';
      } else if (peerState == RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
        state = ChatyCallState.connecting;
      }
      notifyListeners();
    };
    _peer!.onIceCandidate = (candidate) {
      if (candidate.candidate == null || candidate.candidate!.isEmpty || session == null) return;
      unawaited(_publishCandidate(candidate));
    };
  }

  Future<void> _bindSession(String callId) async {
    await _sessionSubscription?.cancel();
    await _candidateSubscription?.cancel();
    _sessionSubscription = _client
        .from('call_sessions')
        .stream(primaryKey: const <String>['id'])
        .eq('id', callId)
        .listen((rows) async {
      if (rows.isEmpty) return;
      final next = ChatyCallSession.fromRow(Map<String, dynamic>.from(rows.first));
      session = next;
      if (next.status == 'accepted' && next.answerSdp != null && _peer != null) {
        final remote = await _peer!.getRemoteDescription();
        if (remote == null) {
          state = ChatyCallState.connecting;
          notifyListeners();
          await _peer!.setRemoteDescription(RTCSessionDescription(next.answerSdp, 'answer'));
        }
      } else if (next.status == 'declined') {
        state = ChatyCallState.declined;
        await _closeMedia();
      } else if (next.status == 'ended') {
        state = ChatyCallState.ended;
        await _closeMedia();
      } else if (next.status == 'failed') {
        state = ChatyCallState.failed;
        await _closeMedia();
      }
      notifyListeners();
    });
    _candidateSubscription = _client
        .from('call_ice_candidates')
        .stream(primaryKey: const <String>['id'])
        .eq('call_id', callId)
        .listen((rows) async {
      final myId = _client.auth.currentUser?.id;
      for (final row in rows) {
        final id = row['id']?.toString() ?? '';
        if (id.isEmpty || _appliedCandidateIds.contains(id) || row['sender_id']?.toString() == myId) continue;
        _appliedCandidateIds.add(id);
        final candidate = RTCIceCandidate(
          row['candidate']?.toString(),
          row['sdp_mid']?.toString(),
          row['sdp_mline_index'] as int?,
        );
        try {
          await _peer?.addCandidate(candidate);
        } catch (_) {
          // Remote SDP can arrive a fraction later. Realtime reconciliation will
          // redeliver persisted candidates on the next stream emission.
          _appliedCandidateIds.remove(id);
        }
      }
    });
  }

  Future<void> _publishCandidate(RTCIceCandidate candidate) async {
    final active = session;
    if (active == null) return;
    await _client.from('call_ice_candidates').insert(<String, dynamic>{
      'call_id': active.id,
      'sender_id': _requireUserId(),
      'candidate': candidate.candidate,
      'sdp_mid': candidate.sdpMid,
      'sdp_mline_index': candidate.sdpMLineIndex,
    });
  }

  Future<void> setMicrophoneEnabled(bool enabled) async {
    microphoneEnabled = enabled;
    for (final track in _localStream?.getAudioTracks() ?? const <MediaStreamTrack>[]) {
      track.enabled = enabled;
    }
    notifyListeners();
  }

  Future<void> setCameraEnabled(bool enabled) async {
    cameraEnabled = enabled;
    for (final track in _localStream?.getVideoTracks() ?? const <MediaStreamTrack>[]) {
      track.enabled = enabled;
    }
    notifyListeners();
  }

  Future<void> switchCamera() async {
    final tracks = _localStream?.getVideoTracks() ?? const <MediaStreamTrack>[];
    if (tracks.isEmpty) return;
    await Helper.switchCamera(tracks.first);
  }

  Future<void> setSpeakerEnabled(bool enabled) async {
    speakerEnabled = enabled;
    await Helper.setSpeakerphoneOn(enabled);
    notifyListeners();
  }

  Future<void> endCall() async {
    final active = session;
    if (active != null && active.status != 'ended' && active.status != 'declined') {
      await _client.from('call_sessions').update(<String, dynamic>{
        'status': 'ended',
        'ended_at': DateTime.now().toUtc().toIso8601String(),
        'ended_by': _requireUserId(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', active.id);
    }
    state = ChatyCallState.ended;
    await _closeMedia();
    notifyListeners();
  }

  Future<void> _closeMedia() async {
    for (final track in _localStream?.getTracks() ?? const <MediaStreamTrack>[]) {
      await track.stop();
    }
    await _localStream?.dispose();
    await _remoteStream?.dispose();
    await _peer?.close();
    _localStream = null;
    _remoteStream = null;
    _peer = null;
  }

  String _requireUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('Authentication is required to start a call.');
    return id;
  }

  @override
  void dispose() {
    unawaited(_sessionSubscription?.cancel());
    unawaited(_candidateSubscription?.cancel());
    unawaited(_incomingSubscription?.cancel());
    unawaited(_incomingController.close());
    unawaited(_closeMedia());
    super.dispose();
  }
}
