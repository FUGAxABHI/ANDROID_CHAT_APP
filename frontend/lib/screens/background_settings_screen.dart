import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/theme_provider.dart';

class BackgroundSettingsScreen extends StatelessWidget {
  const BackgroundSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  themeProvider.setBackgroundImage(pickedFile.path);
                }
              },
              child: const Text('Set Background Image'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                themeProvider.clearBackgroundImage();
              },
              child: const Text('Remove Background Image'),
            ),
          ],
        ),
      ),
    );
  }
}
