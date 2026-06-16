import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VoiceInputWidget extends StatefulWidget {
  const VoiceInputWidget({super.key});

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget> {
  final SpeechToText _speech = SpeechToText();
  final TextEditingController _controller = TextEditingController();

  bool _isListening = false;
  bool _isRestarting = false;

  double _soundLevel = 0.0;
  double _smoothLevel = 0.0;

  // ================= START LISTEN =================
  void _startListening() async {
    if (_speech.isListening) return;

    bool available = await _speech.initialize(
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') && _isListening) {
          _restartListening();
        }
      },
      onError: (error) {
        _restartListening();
      },
    );

    if (!available) return;

    await _speech.stop();
    await Future.delayed(const Duration(milliseconds: 200));

    setState(() => _isListening = true);

    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _controller.text =
              (_controller.text + " " + result.recognizedWords).trim();

          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        }
      },
      partialResults: true,
      localeId: 'en_US',
      cancelOnError: false,

      onSoundLevelChange: (level) {
        // 🎯 smooth sound level
        _smoothLevel = (_smoothLevel * 0.7) + (level * 0.3);

        setState(() {
          _soundLevel = _smoothLevel;
        });
      },
    );
  }

  // ================= RESTART =================
  void _restartListening() {
    if (!_isListening || _isRestarting) return;

    _isRestarting = true;

    Future.delayed(const Duration(milliseconds: 400), () async {
      try {
        await _speech.stop();
      } catch (_) {}

      _isRestarting = false;

      if (_isListening) {
        _startListening();
      }
    });
  }

  // ================= STOP =================
  void _stopListening() {
    _isRestarting = false;

    if (_isListening) {
      _speech.stop();

      setState(() {
        _isListening = false;
        _soundLevel = 0;
      });
    }
  }

  // ================= WAVE UI =================
  Widget _buildSoundWaveVisualization() {
    double displayLevel = _soundLevel > 1
        ? _soundLevel
        : (5 + (DateTime.now().millisecond % 10));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(15, (index) {
        final randomFactor = (index % 5) * 2;

        double height = 12 + (displayLevel * 2) + randomFactor;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: EdgeInsets.symmetric(horizontal: 2.w),
          width: 3.w,
          height: _isListening ? height.clamp(10, 45) : 10,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade400,
                Colors.blue.shade700,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(3.r),
          ),
        );
      }),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          if (_isListening) _buildSoundWaveVisualization(),

          SizedBox(height: 10.h),

          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: "Speak something...",
              border: OutlineInputBorder(),
            ),
          ),

          SizedBox(height: 20.h),

          GestureDetector(
            onTap: () {
              if (_isListening) {
                _stopListening();
              } else {
                _startListening();
              }
            },
            child: CircleAvatar(
              radius: 30,
              backgroundColor: _isListening ? Colors.red : Colors.blue,
              child: Icon(
                _isListening ? Icons.stop : Icons.mic,
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(height: 10.h),

          Text(
            _isListening ? "Recording..." : "Tap mic to start",
            style: TextStyle(
              color: _isListening ? Colors.red : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}