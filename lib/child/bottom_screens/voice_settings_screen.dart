import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/voice_service.dart';
import '../../utils/constans.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceSettingsScreen extends StatefulWidget {
  const VoiceSettingsScreen({super.key});

  @override
  State<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
  bool _isVoiceEnabled = true;
  final TextEditingController _phraseController = TextEditingController();
  String _currentPhrase = "help";

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkPermission();
  }

  String _permissionStatus = "Checking...";

  Future<void> _checkPermission() async {
    var status = await Permission.microphone.status;
    setState(() {
      _permissionStatus = status.isGranted ? "Granted ✅" : "Denied ❌";
    });
  }

  Future<void> _requestPermission() async {
    await Permission.microphone.request();
    _checkPermission();
    VoiceService.initialize(); // Re-init
  }

  Future<void> _loadSettings() async {
    bool enabled = await VoiceService.isEnabled();
    String phrase = await VoiceService.getTriggerPhrase();
    
    setState(() {
      _isVoiceEnabled = enabled;
      _currentPhrase = phrase;
      _phraseController.text = phrase;
    });
  }

  Future<void> _saveSettings() async {
    if (_phraseController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Please enter a valid phrase");
      return;
    }

    await VoiceService.setEnabled(_isVoiceEnabled);
    await VoiceService.setTriggerPhrase(_phraseController.text);
    
    setState(() {
      _currentPhrase = _phraseController.text;
    });
    
    Fluttertoast.showToast(msg: "Voice settings saved!");
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Voice Impact Settings"),
        backgroundColor: Colors.pink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enable/Disable Switch
            SwitchListTile(
              title: Text(
                "Enable Voice Activation",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Text("Turn on/off voice detection for siren"),
              value: _isVoiceEnabled,
              onChanged: (bool value) {
                setState(() {
                  _isVoiceEnabled = value;
                });
              },
              activeColor: Colors.pink,
            ),
            
            Divider(),
            SizedBox(height: 20),
            
            // Custom Phrase Input
            Text(
              "Custom Trigger Phrase",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "The siren will loop when you say this phrase.",
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 15),
            
            TextField(
              controller: _phraseController,
              decoration: InputDecoration(
                labelText: "Enter Phrase (e.g., Help Me, Save Me)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.record_voice_over),
              ),
            ),
            
            SizedBox(height: 30),
            
            // Current Settings Display
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.pink[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.pink.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.pink),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Current Trigger: '$_currentPhrase'"),
                      Text("Say 'Stop' to silence the siren."),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // Permission Status
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: _permissionStatus.contains("Granted") ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _permissionStatus.contains("Granted") ? Colors.green.shade100 : Colors.red.shade100
                ),
              ),
              child: Row(
                children: [
                   Icon(
                     _permissionStatus.contains("Granted") ? Icons.mic : Icons.mic_off,
                     color: _permissionStatus.contains("Granted") ? Colors.green : Colors.red
                   ),
                   SizedBox(width: 10),
                   Expanded(child: Text("Mic Permission: $_permissionStatus")),
                   if (!_permissionStatus.contains("Granted"))
                     TextButton(
                       onPressed: _requestPermission,
                       child: Text("Allow"),
                     )
                ],
              ),
            ),

            Spacer(),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "SAVE SETTINGS",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
