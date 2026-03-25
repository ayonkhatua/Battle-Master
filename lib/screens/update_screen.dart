import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateScreen extends StatelessWidget {
  final String appLink;

  const UpdateScreen({super.key, required this.appLink});

  Future<void> _launchURL() async {
    final Uri url = Uri.parse(appLink);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch $appLink");
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Back button block karne ke liye (User screen close nahi kar payega)
      child: Scaffold(
        backgroundColor: const Color(0xFF111827), // Dark Background
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.system_update_alt_rounded, color: Color(0xFFfacc15), size: 100),
              const SizedBox(height: 30),
              const Text(
                "Update Required!",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 15),
              const Text(
                "A new version of the app is available. Please update the app to continue playing tournaments.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563eb), // Blue button
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _launchURL, // Link open karne ke liye
                  child: const Text(
                    "UPDATE NOW",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}