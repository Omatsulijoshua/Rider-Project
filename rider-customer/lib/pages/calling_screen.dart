import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:rider/service/calling_service.dart';

class CallingScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final bool isInitiator;

  const CallingScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
    this.isInitiator = false,
  });

  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> {
  late CallingService _callingService;
  bool _isMuted = false;
  bool _isCameraOff = false;

  @override
  void initState() {
    super.initState();
    _initializeCalling();
  }

  Future<void> _initializeCalling() async {
    _callingService = CallingService();

    _callingService.onIncomingCall = (callInfo) {
      // Show incoming call dialog
      _showIncomingCallDialog(callInfo);
    };

    _callingService.onCallStateChanged = (callInfo) {
      setState(() {});
    };

    _callingService.onLocalStream = (renderer) {
      setState(() {});
    };

    _callingService.onRemoteStream = (renderer) {
      setState(() {});
    };

    _callingService.onError = (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    };

    await _callingService.initialize();

    // Start call if initiator is true
    if (widget.isInitiator) {
      await _callingService.startCall(widget.recipientId, widget.recipientName);
    }
  }

  void _showIncomingCallDialog(CallInfo callInfo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Incoming Call'),
        content: Text('${callInfo.callerName} is calling you...'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _callingService.rejectCall();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Reject',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _callingService.acceptCall();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'Accept',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    // TODO: Implement audio mute logic
  }

  void _toggleCamera() {
    setState(() {
      _isCameraOff = !_isCameraOff;
    });
    // TODO: Implement camera toggle logic
  }

  void _endCall() {
    _callingService.endCall();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _callingService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentCall = _callingService.currentCall;
    final localRenderer = _callingService.localRenderer;
    final remoteRenderer = _callingService.remoteRenderer;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video (full screen)
            if (remoteRenderer != null &&
                currentCall?.state == CallState.connected)
              RTCVideoView(remoteRenderer)
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.shade700,
                      child: Text(
                        widget.recipientName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.recipientName,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentCall == null
                          ? 'Loading...'
                          : currentCall.state == CallState.calling
                              ? 'Calling...'
                              : currentCall.state == CallState.ringing
                                  ? 'Incoming call...'
                                  : currentCall.state == CallState.connected
                                      ? 'Connected'
                                      : 'Call ended',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),

            // Local video (small, bottom right corner)
            if (localRenderer != null)
              Positioned(
                bottom: 100,
                right: 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 100,
                    height: 150,
                    child: RTCVideoView(localRenderer),
                  ),
                ),
              ),

            // Call controls
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mute button
                  FloatingActionButton(
                    onPressed: _toggleMute,
                    backgroundColor:
                        _isMuted ? Colors.red : Colors.grey.shade700,
                    child: Icon(
                      _isMuted ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 20),

                  // End call button (red, prominent)
                  FloatingActionButton(
                    onPressed: _endCall,
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.call_end, color: Colors.white),
                  ),
                  const SizedBox(width: 20),

                  // Camera toggle
                  FloatingActionButton(
                    onPressed: _toggleCamera,
                    backgroundColor:
                        _isCameraOff ? Colors.red : Colors.grey.shade700,
                    child: Icon(
                      _isCameraOff ? Icons.videocam_off : Icons.videocam,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Call timer
            if (currentCall?.state == CallState.connected)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: StreamBuilder<Duration>(
                    stream: Stream.periodic(const Duration(seconds: 1)),
                    builder: (context, snapshot) {
                      final elapsed =
                          DateTime.now().difference(currentCall!.startTime);
                      return Text(
                        '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
