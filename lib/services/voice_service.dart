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
  static bool _isInitialized = false;
  static String _triggerPhrase = "help";
  static BuildContext? _context;
  
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
    if (enabled && !_isListening) {
      _startListeningInternal();
    } else if (!enabled) {
      stopListening();
    }
  }

  static Future<String> getTriggerPhrase() async {
    if (_triggerPhrase == "help") {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String stored = prefs.getString('voice_trigger_phrase') ?? "help";
      _triggerPhrase = stored.toLowerCase();
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
    if (_isInitialized) return;

    try {
      // Load settings
      await isEnabled();
      await getTriggerPhrase();
      
      // Request microphone permission explicitly
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        print("Requesting microphone permission...");
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
             if (_isEnabled && _isListening) {
               // Immediate restart check
               print("Restarting listener...");
               _reStartListening();
             }
          }
        },
        onError: (error) {
          print('❌ Voice Error: $error');
          // Restart on error too
          if (_isEnabled && _isListening) {
             _reStartListening();
          }
        },
      );
      
      if (available) {
        _isInitialized = true;
        print('✅ Speech recognition initialized');
        // Fluttertoast.showToast(msg: "Voice Service Initialized");
      } else {
        print('❌ Speech recognition not available');
        Fluttertoast.showToast(msg: "Voice recognition not available on this device");
      }
    } catch (e) {
      print('❌ Error initializing voice service: $e');
      Fluttertoast.showToast(msg: "Error initializing Voice Service: $e");
    }
  }

  static void _reStartListening() {
    Future.delayed(Duration(milliseconds: 500), () {
        _startListeningInternal();
    });
  }

  /// Start listening for trigger phrase
  static void startListening(BuildContext context) async {
    _context = context; 
    _isListening = true;
    
    if (!_isInitialized) {
      await initialize();
    }
    
    if (_isEnabled) {
      _startListeningInternal();
    }
  }

  static void _startListeningInternal() async {
    if (!_isEnabled || !_isInitialized) {
        print("Declined to start listening: Enabled: $_isEnabled, Initialized: $_isInitialized");
        return;
    }
    if (_speechToText.isListening) {
        print("Already listening");
        return;
    }

    try {
      print("Attempting to start listening...");
      // Android often has a system limit on listening duration. 
      // We set a long duration, but valid restarts are key for "always on".
      await _speechToText.listen(
        onResult: (result) {
          String recognizedWords = result.recognizedWords.toLowerCase();
          print('🗣️ Heard: "$recognizedWords"'); // Verbose logging
          
          if (_context == null) return;

          // Check for trigger phrase
          if (recognizedWords.contains(_triggerPhrase) || 
              recognizedWords.contains("bachao") || 
              recognizedWords.contains("help") || // explicitly adding help
              recognizedWords.contains("save me")) {
            print('🚨 Trigger phrase detected: "$recognizedWords"');
            SirenService.playSiren(_context!);
            Fluttertoast.showToast(msg: "Siren Activated by Voice!");
          }
          
          // Check for STOP command
          if (recognizedWords.contains("stop")) {
            print('🛑 Stop command detected');
            SirenService.stopSiren();
          }
        },
        listenFor: Duration(seconds: 30), // Reduce to standard limit, rely on restart
        pauseFor: Duration(seconds: 5),   // Shorter pause to detect silence and restart
        partialResults: true,
        cancelOnError: true, // Cancel on error to trigger restart logic
        listenMode: ListenMode.confirmation, // Try confirmation or search for better continuous
      );
      print("Listening started");
    } catch (e) {
      print('❌ Error starting listener: $e');
      // Try to restart if it failed to start
      _reStartListening();
    }
  }

  /// Stop listening
  static void stopListening() {
    _isListening = false;
    _speechToText.stop();
    print("Stopped listening");
  }
}
