import 'package:flutter/material.dart';
import 'package:frontend/config.dart';
import 'package:frontend/providers/profile_provider.dart';
import 'package:frontend/screens/background_settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {

  final TextEditingController _bioController = TextEditingController();

  // final TextEditingController _avatarController = TextEditingController(); // No longer needed

  bool _notificationsEnabled = true;

  String _selectedLanguage = 'en';



  @override

  void initState() {

    super.initState();

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

    if (profileProvider.user != null) {

      _bioController.text = profileProvider.user!.bio;

      // _avatarController.text = profileProvider.user!.avatar; // No longer needed

      _selectedLanguage = profileProvider.user!.language;

    }

  }


  Future<void> _pickImage(ProfileProvider profileProvider) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      await profileProvider.uploadProfilePicture(pickedFile.path);
    }
  }


  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text('Profile Settings'),

      ),

      body: Consumer<ProfileProvider>(

        builder: (context, profileProvider, child) {

          if (profileProvider.isLoading) {

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
                          onPressed: () => _pickImage(profileProvider),
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

                    setState(() {

                      _notificationsEnabled = value;

                    });

                  },

                  secondary: const Icon(Icons.notifications, color: Colors.white),

                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ElevatedButton(
                    onPressed: () {
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

                      profileProvider.updateUserProfile(

                        _bioController.text,

                        _avatarController.text,

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
