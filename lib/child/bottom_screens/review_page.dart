import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewPageLocal extends StatefulWidget {
  const ReviewPageLocal({Key? key}) : super(key: key);

  @override
  State<ReviewPageLocal> createState() => _ReviewPageLocalState();
}

class _ReviewPageLocalState extends State<ReviewPageLocal> {
  late AudioPlayer _audioPlayer;
  bool _isAlarmActive = false;
  final TextEditingController _reviewController = TextEditingController();
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  List<String> _localReviews = [];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _localReviews = prefs.getStringList('local_reviews') ?? [];
    });
  }

  Future<void> _saveReviews() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('local_reviews', _localReviews);
  }

  void _toggleAlarm() async {
    if (_isAlarmActive) {
      await _audioPlayer.stop();
    } else {
      await _audioPlayer.play(AssetSource('police_siren.mp3'));
    }

    setState(() {
      _isAlarmActive = !_isAlarmActive;
    });
  }

  void _showAlarmExplanation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "How the Alarm Works",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "This alarm feature is designed to help you alert others in case of an emergency.\n\n"
            "When you tap 'Activate Alarm', a loud siren or scream sound will play from your device, alerting others nearby.\n\n"
            "Additionally, if your device battery goes below 10%, the alarm will automatically activate (this is a simulated feature in this local version).",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.pink),
              child: const Text("Got it!"),
            ),
          ],
        );
      },
    );
  }

  void _submitReview() async {
    if (_key.currentState!.validate()) {
      setState(() {
        _localReviews.insert(0, _reviewController.text.trim());
      });
      await _saveReviews();
      _reviewController.clear();
      Fluttertoast.showToast(
        msg: "Review added locally!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green.shade400,
        textColor: Colors.white,
      );
    }
  }

  Widget _buildReviewList() {
    if (_localReviews.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message, size: 48, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              "No reviews available yet.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: _localReviews.length,
      separatorBuilder:
          (context, index) => const Divider(height: 1, color: Colors.grey),
      itemBuilder: (context, index) {
        final review = _localReviews[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.pink.shade300,
                foregroundColor: Colors.white,
                child: const Icon(Icons.person),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text(
                      "You (Local)",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: _key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Add a Review",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reviewController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Share your thoughts...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.pink),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter a review.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Submit Review",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Community Reviews & Safety Alarm",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.pink,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings, color: Colors.white),
            onSelected: (String value) {
              if (value == 'Activate Alarm') {
                _toggleAlarm();
              } else if (value == 'Info') {
                _showAlarmExplanation(context);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'Activate Alarm',
                  child: Row(
                    children: [
                      Icon(
                        _isAlarmActive ? Icons.alarm_off : Icons.alarm,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isAlarmActive ? 'Deactivate Alarm' : 'Activate Alarm',
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'Info',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('How the Alarm Works'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Community Reviews",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildReviewList()),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _toggleAlarm,
                    icon: Icon(
                      _isAlarmActive ? Icons.alarm_off : Icons.alarm,
                      color: Colors.white,
                    ),
                    label: Text(
                      _isAlarmActive
                          ? 'Deactivate Safety Alarm'
                          : 'Activate Safety Alarm',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isAlarmActive ? Colors.grey : Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Note: The safety alarm is a local simulation to alert nearby individuals.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReviewSheet,
        backgroundColor: Colors.pink,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
