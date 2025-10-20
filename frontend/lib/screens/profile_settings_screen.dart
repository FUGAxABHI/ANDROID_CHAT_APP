import 'package:flutter/material.dart';
import 'package:frontend/config.dart';
import 'package:frontend/providers/profile_provider.dart';
import 'package:frontend/providers/theme_provider.dart'; // Import ThemeProvider
import 'package:frontend/screens/background_settings_screen.dart';
import 'package:frontend/theme.dart'; // Import AppTheme
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:logging/logging.dart';

final log = Logger('ProfileSettingsScreen');

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {

  final TextEditingController _bioController = TextEditingController();

  bool _notificationsEnabled = true;

  String _selectedLanguage = 'en';

  @override

  void initState() {

    super.initState();
    log.info('initState called');

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    if (profileProvider.user != null) {
      log.info('User data found in profile provider');
      _bioController.text = profileProvider.user!.bio;

      _selectedLanguage = profileProvider.user!.language;

    } else {
      log.warning('User data not found in profile provider');
    }

  }


  Future<void> _pickImage(ProfileProvider profileProvider) async {
    log.info('Picking image');
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      log.info('Image picked: ${pickedFile.name}');
      final fileBytes = await pickedFile.readAsBytes();
      final filename = pickedFile.name;
      await profileProvider.uploadProfilePicture(fileBytes, filename);
      log.info('Profile picture upload process finished');
    } else {
      log.info('Image picking cancelled');
    }
  }


  @override

  Widget build(BuildContext context) {
    log.info('Building profile settings screen');
    return Scaffold(

      appBar: AppBar(

        title: const Text('Profile Settings'),

      ),

      body: Consumer<ProfileProvider>(

        builder: (context, profileProvider, child) {
          log.info('Building consumer for profile provider');
          if (profileProvider.isLoading) {
            log.info('Profile provider is loading');
            return const Center(child: CircularProgressIndicator());

          }



          return Container(

            decoration: BoxDecoration(

              gradient: LinearGradient(

                colors: [Colors.blue.shade800, Colors.purple.shade800],

                begin: Alignment.topLeft,

                end: Alignment.bottomRight,

              ),

            ),

            child: ListView(

              children: [

                const SizedBox(height: 20),

                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 80,
                        backgroundImage: NetworkImage(profileProvider.user?.avatar ?? ''),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: () {
                            log.info('Pick image button pressed');
                            _pickImage(profileProvider);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const SizedBox(height: 20),

                Padding(

                  padding: const EdgeInsets.symmetric(horizontal: 20.0),

                  child: TextField(

                    controller: _bioController,

                    maxLines: 3,

                    decoration: InputDecoration(

                      labelText: 'Set Bio',

                      border: OutlineInputBorder(

                        borderRadius: BorderRadius.circular(20),

                      ),

                      filled: true,

                      fillColor: Colors.white.withOpacity(0.1),

                    ),

                  ),

                ),

                const SizedBox(height: 20),

                Padding(

                  padding: const EdgeInsets.symmetric(horizontal: 20.0),

                  child: DropdownButton<String>(

                    value: _selectedLanguage,

                    onChanged: (String? newValue) {
                      log.info('Language changed to: $newValue');
                      setState(() {

                        _selectedLanguage = newValue!;

                      });

                    },

                    items: <String>['en', 'es', 'fr', 'de', 'hi']

                        .map<DropdownMenuItem<String>>((String value) {

                      return DropdownMenuItem<String>(

                        value: value,

                        child: Text(value),

                      );

                    }).toList(),

                  ),

                ),

                const SizedBox(height: 20),

                SwitchListTile(

                  title: const Text('Enable Notifications', style: TextStyle(color: Colors.white)),

                  value: _notificationsEnabled,

                  onChanged: (bool value) {
                    log.info('Notifications enabled: $value');
                    setState(() {

                      _notificationsEnabled = value;

                    });

                  },

                  secondary: const Icon(Icons.notifications, color: Colors.white),

                ),
                // Theme Switch
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return SwitchListTile(
                      title: const Text('Glassmorphism Theme', style: TextStyle(color: Colors.white)),
                      value: themeProvider.currentTheme == AppTheme.glassTheme,
                      onChanged: (bool value) {
                        log.info('Glassmorphism theme enabled: $value');
                        themeProvider.setTheme(value ? AppTheme.glassTheme : AppTheme.darkTheme);
                      },
                      secondary: const Icon(Icons.blur_on, color: Colors.white),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ElevatedButton(
                    onPressed: () {
                      log.info('Background settings button pressed');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BackgroundSettingsScreen(),
                        ),
                      );
                    },
                    child: const Text('Background Settings'),
                  ),
                ),

                const SizedBox(height: 40),

                Padding(

                  padding: const EdgeInsets.symmetric(horizontal: 20.0),

                  child: ElevatedButton(

                    onPressed: () {
                      log.info('Save changes button pressed');
                      profileProvider.updateUserProfile(

                        _bioController.text,

                        profileProvider.user?.avatar ?? '',

                        _selectedLanguage,

                      );

                      Navigator.pop(context);

                    },

                    style: ElevatedButton.styleFrom(

                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),

                      shape: RoundedRectangleBorder(

                        borderRadius: BorderRadius.circular(20),

                      ),

                    ),

                    child: Text('Save Changes', style: const TextStyle(fontSize: 18)),

                  ),

                ),

              ],

            ),

          );

        },

      ),

    );

  }

}
