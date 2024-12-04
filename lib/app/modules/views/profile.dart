import 'dart:io';
import 'package:bolanet76/app/modules/views/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'SettingsPage.dart';
import 'SpeakerPage.dart';
import 'LocationPage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? _videoController;

  // GetStorage instance
  final _storage = GetStorage();

  String? _storedImagePath;
  String? _storedVideoPath;

  @override
  void initState() {
    super.initState();
    // Load stored paths
    _storedImagePath = _storage.read('profile_image');
    _storedVideoPath = _storage.read('profile_video');
    if (_storedVideoPath != null) {
      _initializeVideoController(_storedVideoPath!);
    }
  }

  Future<void> _pickMedia(bool isVideo, ImageSource source) async {
    final XFile? selectedFile = await (isVideo
        ? _picker.pickVideo(source: source)
        : _picker.pickImage(source: source));

    if (selectedFile != null) {
      setState(() {
        if (isVideo) {
          _storedVideoPath = selectedFile.path;
          _storage.write('profile_video', _storedVideoPath);
          _initializeVideoController(_storedVideoPath!);
        } else {
          _storedImagePath = selectedFile.path;
          _storage.write('profile_image', _storedImagePath);
        }
      });
    }
  }

  void _initializeVideoController(String path) {
    _videoController = VideoPlayerController.file(File(path))
      ..initialize().then((_) {
        setState(() {});
        _videoController?.setLooping(true);
        _videoController?.play();
      }).catchError((error) {
        print('Error initializing video: $error');
      });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF005B96), // Blue light for AppBar
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24.0),
          _buildStatsSection(),
          const SizedBox(height: 24.0),
          _buildOptionsSection(context),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc('x3xm5nObS5aNHzF17O9H') // Ganti dengan ID pengguna dinamis
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('User data not found.'));
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        String name = userData['name'] ?? 'No name provided';
        String bio = userData['bio'] ?? 'No bio available';

        return Column(
          children: [
            GestureDetector(
              onTap: () => _showMediaOptions(),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                child: ClipOval(
                  child: _storedVideoPath != null
                      ? AspectRatio(
                          aspectRatio: 1,
                          child: VideoPlayer(_videoController!),
                        )
                      : _storedImagePath != null
                          ? Image.file(
                              File(_storedImagePath!),
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                            )
                          : const Icon(
                              Icons.camera_alt,
                              size: 50,
                              color: Colors.grey,
                            ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF003366), // Dark blue for name
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              bio,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Select Photo from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(false, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Select Video from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(true, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo with Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(false, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Record Video with Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(true, ImageSource.camera);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('Posts', '25'),
        _buildStatItem('Followers', '1.2K'),
        _buildStatItem('Following', '180'),
      ],
    );
  }

  Widget _buildStatItem(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF003366), // Dark blue for stats count
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildOptionsSection(BuildContext context) {
    return Column(
      children: [
        _buildOptionItem(Icons.speaker, 'Speaker', () {
          Get.to(() => SpeakerPage());
        }),
        _buildOptionItem(Icons.settings, 'Settings', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SettingsPage()),
          );
        }),
        _buildOptionItem(Icons.map, 'Location', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LocationPage()),
          );
        }),
        _buildOptionItem(Icons.logout, 'Log Out', () {
          _logout();
        }),
      ],
    );
  }

  Widget _buildOptionItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF003366)), // Dark blue for icon
      title: Text(
        label,
        style: const TextStyle(
            fontSize: 16, color: Color(0xFF003366)), // Dark blue for text
      ),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _logout() {
    // Clear stored data
    _storage.remove('profile_image');
    _storage.remove('profile_video');

    // Redirect to the Login page
    Get.offAll(() => LoginPage());
  }
}
