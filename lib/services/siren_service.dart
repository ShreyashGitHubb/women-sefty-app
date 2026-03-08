import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class SirenService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isPlaying = false;
  
  // Use the local asset instead of an online URL (which may be broken/unavailable)
  static const String _sirenAsset = 'police_siren.mp3';

  static bool get isPlaying => _isPlaying;

  /// Play the siren sound in a loop
  static Future<void> playSiren(BuildContext context) async {
    if (_isPlaying) return;

    try {
      _isPlaying = true;
      await _audioPlayer.setReleaseMode(ReleaseMode.loop); // Loop the siren
      await _audioPlayer.play(AssetSource(_sirenAsset));   // Use local asset
      
      // Show visual indicator that siren is playing
      if (context.mounted) {
        _showStopSirenDialog(context);
      }
      
      print('🚨 Siren started!');
    } catch (e) {
      print('❌ Error playing siren: $e');
      _isPlaying = false;
    }
  }

  /// Stop the siren
  static Future<void> stopSiren() async {
    if (!_isPlaying) return;
    
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      print('🔕 Siren stopped');
    } catch (e) {
      print('❌ Error stopping siren: $e');
    }
  }

  /// Show a dialog to stop the siren
  static void _showStopSirenDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Prevent back button
        child: AlertDialog(
          backgroundColor: Colors.red,
          title: Center(
            child: Text(
              '🚨 SIREN ACTIVE 🚨',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.campaign, size: 80, color: Colors.white),
              SizedBox(height: 20),
              Text(
                'Say "STOP" or tap below',
                style: TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  stopSiren();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text(
                  'STOP SIREN',
                  style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
