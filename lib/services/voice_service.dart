import 'package:speech_to_text/speech_to_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'siren_service.dart';

class VoiceService {
  static final SpeechToText _speechToText = SpeechToText();
  static bool _isEnabled = true;
  static bool _isInitialized = false;
  static String _triggerPhrase = "help";
  static BuildContext? _context;

  /// Whether we WANT the mic to be running (set false by stopListening)
  static bool _shouldBeListening = false;

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
    if (enabled && _shouldBeListening) {
      _startListeningInternal();
    } else if (!enabled) {
      stopListening();
    }
  }

  static Future<String> getTriggerPhrase() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _triggerPhrase = prefs.getString('voice_trigger_phrase') ?? "help";
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
          // Only restart if we SHOULD be listening (haven't been stopped externally)
          if ((status == 'done' || status == 'notListening') &&
              _isEnabled &&
              _shouldBeListening &&
              !SirenService.isPlaying) {
            // Use a longer delay to avoid rapid restart loop that blocks other audio
            Future.delayed(const Duration(seconds: 2), () {
              if (_shouldBeListening && _isEnabled) {
                _startListeningInternal();
              }
            });
          }
        },
        onError: (error) {
          print('❌ Voice Error: $error');
          // Only restart on non-permanent errors
          if (_shouldBeListening && _isEnabled && error.errorMsg != 'error_no_match') {
            Future.delayed(const Duration(seconds: 3), () {
              if (_shouldBeListening && _isEnabled) {
                _startListeningInternal();
              }
            });
          }
        },
      );

      if (available) {
        _isInitialized = true;
        print('✅ Speech recognition initialized');
      } else {
        print('❌ Speech recognition not available');
        Fluttertoast.showToast(msg: "Voice recognition not available on this device");
      }
    } catch (e) {
      print('❌ Error initializing voice service: $e');
    }
  }

  /// Start listening for trigger phrase — call only when on the Home tab
  static void startListening(BuildContext context) async {
    _context = context;
    _shouldBeListening = true;

    if (!_isInitialized) {
      await initialize();
    }

    if (_isEnabled && _isInitialized) {
      _startListeningInternal();
    }
  }

  static void _startListeningInternal() async {
    if (!_isEnabled || !_isInitialized || !_shouldBeListening) {
      return;
    }
    if (_speechToText.isListening) {
      return;
    }
    // Don't start mic while siren is playing — it would compete with audio
    if (SirenService.isPlaying) {
      return;
    }

    try {
      print("🎤 Starting voice listener...");
      await _speechToText.listen(
        onResult: (result) {
          String recognizedWords = result.recognizedWords.toLowerCase();
          print('🗣️ Heard: "$recognizedWords"');

          if (_context == null) return;

          // Check for trigger phrase
          if (recognizedWords.contains(_triggerPhrase) ||
              recognizedWords.contains("bachao") ||
              recognizedWords.contains("help me") ||
              recognizedWords.contains("save me")) {
            print('🚨 Trigger phrase detected: "$recognizedWords"');
            SirenService.playSiren(_context!);
            Fluttertoast.showToast(msg: "🚨 Siren Activated by Voice!");
          }

          // Check for STOP command
          if (recognizedWords.contains("stop")) {
            print('🛑 Stop command detected');
            SirenService.stopSiren();
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 8), // Longer pause = fewer mic restarts
        partialResults: true,
        cancelOnError: false, // Don't cancel on match-error, just let it run
        listenMode: ListenMode.dictation, // Dictation mode = best for long phrases
      );
      print("🎤 Listening started");
    } catch (e) {
      print('❌ Error starting listener: $e');
    }
  }

  /// Stop listening — call when leaving the Home tab
  static void stopListening() {
    _shouldBeListening = false; // Prevents any pending restart from firing
    if (_speechToText.isListening) {
      _speechToText.stop();
    }
    print("🎤 Stopped listening");
  }
}

