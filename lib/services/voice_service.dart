import 'package:speech_to_text/speech_to_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'siren_service.dart';

class VoiceService {
  static final SpeechToText _speechToText = SpeechToText();
  static bool _isListening = false;
  static bool _isEnabled = true;
  static String _triggerPhrase = "help";
  
  // Custom setter for trigger phrase
  static Future<void> setTriggerPhrase(String phrase) async {
    _triggerPhrase = phrase.toLowerCase().trim();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('voice_trigger_phrase', _triggerPhrase);
  }
  
  // Custom setter for enabling/disabling voice detection
  static Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_detection_enabled', enabled);
  }

  static Future<String> getTriggerPhrase() async {
    if (_triggerPhrase == "help") {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _triggerPhrase = prefs.getString('voice_trigger_phrase') ?? "help";
    }
    return _triggerPhrase;
  }
  
  static Future<bool> isEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('voice_detection_enabled') ?? true;
    return _isEnabled;
  }

  /// Initialize speech recognition
  static Future<void> initialize() async {
    try {
      // Load settings
      await isEnabled();
      await getTriggerPhrase();
      
      // Request microphone permission explicitly
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
        if (!status.isGranted) {
          print('❌ Microphone permission denied');
          Fluttertoast.showToast(msg: "Microphone permission required for voice features");
          return;
        }
      }

      bool available = await _speechToText.initialize(
        onStatus: (status) {
          print('🎤 Voice Status: $status');
          // Restart listener if it stops and should be running
          if (status == 'done' || status == 'notListening') {
             if (_isListening && _isEnabled) {
               // Restart after a short delay to prevent loop
               Future.delayed(Duration(seconds: 1), () {
                  _startListeningInternal();
               });
             }
          }
        },
        onError: (error) {
          print('❌ Voice Error: $error');
          // Restart on error too
          if (_isListening && _isEnabled) {
             Future.delayed(Duration(seconds: 2), () {
                _startListeningInternal();
             });
          }
        },
      );
      
      if (available) {
        print('✅ Speech recognition initialized');
      } else {
        print('❌ Speech recognition not available');
        Fluttertoast.showToast(msg: "Voice recognition not available on this device");
      }
    } catch (e) {
      print('❌ Error initializing voice service: $e');
    }
  }

  /// Start listening for trigger phrase
  static void startListening(BuildContext context) async {
    _context = context; // Store context for siren
    if (!_isEnabled || _isListening) return;
    _isListening = true;
    _startListeningInternal();
  }

  static BuildContext? _context;

  static void _startListeningInternal() async {
    if (!_isEnabled || !_isListening) return;
    if (_speechToText.isListening) return;

    try {
      await _speechToText.listen(
        onResult: (result) {
          String recognizedWords = result.recognizedWords.toLowerCase();
          print('🗣️ Heard: "$recognizedWords"');
          
          if (_context == null) return;

          // Check for trigger phrase
          if (recognizedWords.contains(_triggerPhrase)) {
            print('🚨 Trigger phrase detected: "$_triggerPhrase"');
            SirenService.playSiren(_context!);
          }
          
          // Check for STOP command
          if (recognizedWords.contains("stop")) {
            print('🛑 Stop command detected');
            SirenService.stopSiren();
          }
        },
        listenFor: Duration(seconds: 20),
        pauseFor: Duration(seconds: 3),
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
      );
    } catch (e) {
      print('❌ Error starting listener: $e');
    }
  }

  /// Stop listening
  static void stopListening() {
    _speechToText.stop();
    _isListening = false;
  }
}
