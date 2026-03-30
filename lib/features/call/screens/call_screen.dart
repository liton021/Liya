import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CallScreen extends StatefulWidget {
  final String calleeId;
  final String calleeName;
  final bool isVideo;

  const CallScreen({
    super.key,
    required this.calleeId,
    required this.calleeName,
    required this.isVideo,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  bool _isMuted = false;
  bool _isVideoOff = false;
  String? _callId;

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _startCall();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> _startCall() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': widget.isVideo ? {'facingMode': 'user'} : false,
    });

    _localRenderer.srcObject = _localStream;
    setState(() {});

    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteRenderer.srcObject = event.streams[0];
        setState(() {});
      }
    };

    _peerConnection!.onIceCandidate = (candidate) {
      if (_callId != null) {
        FirebaseFirestore.instance
            .collection('calls')
            .doc(_callId)
            .collection('callerCandidates')
            .add(candidate.toMap());
      }
    };

    final callDoc = FirebaseFirestore.instance.collection('calls').doc();
    _callId = callDoc.id;

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    await callDoc.set({
      'callerId': currentUserId,
      'calleeId': widget.calleeId,
      'offer': offer.toMap(),
      'isVideo': widget.isVideo,
      'status': 'ringing',
      'timestamp': FieldValue.serverTimestamp(),
    });

    callDoc.snapshots().listen((snapshot) async {
      final data = snapshot.data();
      if (data != null && data['answer'] != null) {
        final answer = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );
        await _peerConnection!.setRemoteDescription(answer);
      }
      if (data != null && data['status'] == 'ended') {
        _endCall();
      }
    });

    FirebaseFirestore.instance
        .collection('calls')
        .doc(_callId)
        .collection('calleeCandidates')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data()!;
          _peerConnection!.addCandidate(RTCIceCandidate(
            data['candidate'],
            data['sdpMid'],
            data['sdpMLineIndex'],
          ));
        }
      }
    });
  }

  void _toggleMute() {
    if (_localStream != null) {
      final audioTrack = _localStream!.getAudioTracks()[0];
      audioTrack.enabled = !audioTrack.enabled;
      setState(() => _isMuted = !_isMuted);
    }
  }

  void _toggleVideo() {
    if (_localStream != null && widget.isVideo) {
      final videoTrack = _localStream!.getVideoTracks()[0];
      videoTrack.enabled = !videoTrack.enabled;
      setState(() => _isVideoOff = !_isVideoOff);
    }
  }

  void _endCall() async {
    if (_callId != null) {
      await FirebaseFirestore.instance
          .collection('calls')
          .doc(_callId)
          .update({'status': 'ended'});
    }

    _localStream?.dispose();
    _peerConnection?.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (widget.isVideo)
            SizedBox.expand(
              child: RTCVideoView(_remoteRenderer, mirror: false),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    child: Text(
                      widget.calleeName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.calleeName,
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Calling...',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
          if (widget.isVideo)
            Positioned(
              top: 50,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 120,
                  height: 160,
                  child: RTCVideoView(_localRenderer, mirror: true),
                ),
              ),
            ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CallButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  onPressed: _toggleMute,
                  color: _isMuted ? Colors.red : Colors.white,
                ),
                if (widget.isVideo)
                  _CallButton(
                    icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                    onPressed: _toggleVideo,
                    color: _isVideoOff ? Colors.red : Colors.white,
                  ),
                _CallButton(
                  icon: Icons.call_end,
                  onPressed: _endCall,
                  color: Colors.red,
                  isLarge: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _localStream?.dispose();
    _peerConnection?.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final bool isLarge;

  const _CallButton({
    required this.icon,
    required this.onPressed,
    required this.color,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isLarge ? 70 : 56,
      height: isLarge ? 70 : 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: isLarge ? 32 : 24),
        onPressed: onPressed,
      ),
    );
  }
}
