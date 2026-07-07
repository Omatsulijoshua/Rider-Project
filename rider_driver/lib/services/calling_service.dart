import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:rider_driver/services/shared_pref.dart';
import 'package:rider_driver/services/api_client.dart';

enum CallState { idle, calling, ringing, connected, disconnected, failed }

class CallInfo {
  final String callId;
  final String callerId;
  final String callerName;
  final String receiverId;
  final CallState state;
  final DateTime startTime;

  CallInfo({
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.receiverId,
    required this.state,
    required this.startTime,
  });
}

class CallingService {
  late io.Socket _socket;
  late RTCPeerConnection _peerConnection;
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;

  final String baseUrl = ApiClient.baseUrl.replaceAll('/api', '');
  CallInfo? _currentCall;

  Function(CallInfo)? onIncomingCall;
  Function(CallInfo)? onCallStateChanged;
  Function(RTCVideoRenderer)? onLocalStream;
  Function(RTCVideoRenderer)? onRemoteStream;
  Function(dynamic)? onError;

  Future<void> initialize() async {
    try {
      final userId = await SharedpreferenceHelper().getUserID();

      _socket = io.io(
        baseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      _socket.onConnect((_) {
        debugPrint('✅ Calling service connected');
        _socket.emit('joinCall', {'userId': userId});
      });

      _socket.on('incomingCall', (data) {
        _handleIncomingCall(data);
      });

      _socket.on('callAccepted', (data) {
        _handleCallAccepted(data);
      });

      _socket.on('callRejected', (_) {
        _handleCallRejected();
      });

      _socket.on('offer', (data) {
        _handleOffer(data);
      });

      _socket.on('answer', (data) {
        _handleAnswer(data);
      });

      _socket.on('iceCandidate', (data) {
        _handleIceCandidate(data);
      });

      _socket.on('callEnded', (_) {
        _handleCallEnded();
      });

      _socket.onError((error) {
        debugPrint('❌ Calling error: $error');
        onError?.call(error);
      });

      _socket.connect();
    } catch (e) {
      debugPrint('❌ Failed to initialize calling: $e');
      onError?.call(e);
    }
  }

  Future<void> initializeRenderers() async {
    try {
      _localRenderer = RTCVideoRenderer();
      await _localRenderer!.initialize();

      _remoteRenderer = RTCVideoRenderer();
      await _remoteRenderer!.initialize();
    } catch (e) {
      debugPrint('❌ Failed to initialize renderers: $e');
      onError?.call(e);
    }
  }

  Future<void> startCall(String recipientId, String recipientName) async {
    try {
      await initializeRenderers();

      final userId = await SharedpreferenceHelper().getUserID();
      final userName = await SharedpreferenceHelper().getUserName();

      final callId = DateTime.now().millisecondsSinceEpoch.toString();
      _currentCall = CallInfo(
        callId: callId,
        callerId: userId ?? '',
        callerName: userName ?? 'Driver',
        receiverId: recipientId,
        state: CallState.calling,
        startTime: DateTime.now(),
      );

      _socket.emit('initiateCall', {
        'callId': callId,
        'callerId': userId,
        'callerName': userName ?? 'Driver',
        'receiverId': recipientId,
        'receiverName': recipientName,
      });

      await _setupPeerConnection();
      await _getUserMedia();

      onCallStateChanged?.call(_currentCall!);
    } catch (e) {
      debugPrint('❌ Failed to start call: $e');
      onError?.call(e);
    }
  }

  Future<void> acceptCall() async {
    try {
      if (_currentCall == null) return;

      _currentCall = CallInfo(
        callId: _currentCall!.callId,
        callerId: _currentCall!.callerId,
        callerName: _currentCall!.callerName,
        receiverId: _currentCall!.receiverId,
        state: CallState.connected,
        startTime: _currentCall!.startTime,
      );

      _socket.emit('acceptCall', {'callId': _currentCall!.callId});

      await _setupPeerConnection();
      await _getUserMedia();

      onCallStateChanged?.call(_currentCall!);
    } catch (e) {
      debugPrint('❌ Failed to accept call: $e');
      onError?.call(e);
    }
  }

  Future<void> rejectCall() async {
    try {
      if (_currentCall == null) return;
      _socket.emit('rejectCall', {'callId': _currentCall!.callId});
      await endCall();
    } catch (e) {
      debugPrint('❌ Failed to reject call: $e');
      onError?.call(e);
    }
  }

  Future<void> endCall() async {
    try {
      if (_currentCall == null) return;

      _socket.emit('endCall', {'callId': _currentCall!.callId});

      await _peerConnection.close();
      await _localRenderer?.dispose();
      await _remoteRenderer?.dispose();

      _currentCall = null;
    } catch (e) {
      debugPrint('❌ Failed to end call: $e');
      onError?.call(e);
    }
  }

  Future<void> _setupPeerConnection() async {
    try {
      final config = {
        'iceServers': [
          {
            'urls': ['stun:stun1.l.google.com:19302'],
          },
          {
            'urls': ['stun:stun2.l.google.com:19302'],
          },
        ],
      };

      _peerConnection = await createPeerConnection(config, {
        'mandatory': {},
        'optional': [],
      });

      _peerConnection.onAddStream = (MediaStream stream) {
        debugPrint('✅ Remote stream received');
        _remoteRenderer?.srcObject = stream;
        onRemoteStream?.call(_remoteRenderer!);
      };

      _peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
        _socket.emit('iceCandidate', {
          'callId': _currentCall!.callId,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMLineIndex': candidate.sdpMLineIndex,
            'sdpMid': candidate.sdpMid,
          },
        });
      };

      _peerConnection.onConnectionState = (RTCPeerConnectionState state) {
        debugPrint('✅ Connection state: $state');
      };
    } catch (e) {
      debugPrint('❌ Failed to setup peer connection: $e');
      onError?.call(e);
    }
  }

  Future<void> _getUserMedia() async {
    try {
      final stream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {'facingMode': 'user'},
      });

      _localRenderer?.srcObject = stream;
      onLocalStream?.call(_localRenderer!);

      stream.getTracks().forEach((track) {
        _peerConnection.addTrack(track, stream);
      });

      // Create and send offer
      final offer = await _peerConnection.createOffer();
      await _peerConnection.setLocalDescription(offer);

      _socket.emit('offer', {
        'callId': _currentCall!.callId,
        'offer': offer.toMap(),
      });
    } catch (e) {
      debugPrint('❌ Failed to get user media: $e');
      onError?.call(e);
    }
  }

  Future<void> _handleIncomingCall(dynamic data) async {
    try {
      final callId = data['callId'];
      final callerId = data['callerId'];
      final callerName = data['callerName'];

      _currentCall = CallInfo(
        callId: callId,
        callerId: callerId,
        callerName: callerName,
        receiverId: callerId,
        state: CallState.ringing,
        startTime: DateTime.now(),
      );

      onIncomingCall?.call(_currentCall!);
    } catch (e) {
      debugPrint('❌ Error handling incoming call: $e');
    }
  }

  Future<void> _handleCallAccepted(dynamic data) async {
    try {
      if (_currentCall == null) return;
      _currentCall = CallInfo(
        callId: _currentCall!.callId,
        callerId: _currentCall!.callerId,
        callerName: _currentCall!.callerName,
        receiverId: _currentCall!.receiverId,
        state: CallState.connected,
        startTime: _currentCall!.startTime,
      );
      onCallStateChanged?.call(_currentCall!);
    } catch (e) {
      debugPrint('❌ Error handling call accepted: $e');
    }
  }

  Future<void> _handleCallRejected() async {
    try {
      if (_currentCall == null) return;
      _currentCall = CallInfo(
        callId: _currentCall!.callId,
        callerId: _currentCall!.callerId,
        callerName: _currentCall!.callerName,
        receiverId: _currentCall!.receiverId,
        state: CallState.disconnected,
        startTime: _currentCall!.startTime,
      );
      onCallStateChanged?.call(_currentCall!);
      await Future.delayed(Duration(seconds: 2));
      _currentCall = null;
    } catch (e) {
      debugPrint('❌ Error handling call rejected: $e');
    }
  }

  Future<void> _handleOffer(dynamic data) async {
    try {
      final offer = RTCSessionDescription(
        data['offer']['sdp'],
        data['offer']['type'],
      );

      await _peerConnection.setRemoteDescription(offer);
      final answer = await _peerConnection.createAnswer();
      await _peerConnection.setLocalDescription(answer);

      _socket.emit('answer', {
        'callId': _currentCall!.callId,
        'answer': answer.toMap(),
      });
    } catch (e) {
      debugPrint('❌ Error handling offer: $e');
    }
  }

  Future<void> _handleAnswer(dynamic data) async {
    try {
      final answer = RTCSessionDescription(
        data['answer']['sdp'],
        data['answer']['type'],
      );
      await _peerConnection.setRemoteDescription(answer);
    } catch (e) {
      debugPrint('❌ Error handling answer: $e');
    }
  }

  Future<void> _handleIceCandidate(dynamic data) async {
    try {
      final candidate = RTCIceCandidate(
        data['candidate']['candidate'],
        data['candidate']['sdpMid'],
        data['candidate']['sdpMLineIndex'],
      );
      await _peerConnection.addCandidate(candidate);
    } catch (e) {
      debugPrint('❌ Error adding ice candidate: $e');
    }
  }

  void _handleCallEnded() {
    endCall();
  }

  CallInfo? get currentCall => _currentCall;
  RTCVideoRenderer? get localRenderer => _localRenderer;
  RTCVideoRenderer? get remoteRenderer => _remoteRenderer;

  void disconnect() {
    _socket.disconnect();
  }

  bool get isConnected => _socket.connected;
}
