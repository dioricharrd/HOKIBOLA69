import 'package:bolanet76/app/modules/home/controllers/auth_controller.dart';
import 'package:bolanet76/app/modules/home/controllers/newssearchcontroller.dart';
import 'package:bolanet76/app/modules/views/discover_screen.dart';
import 'package:bolanet76/app/modules/views/profile.dart';
import 'package:bolanet76/app/modules/views/save_screen.dart';
import 'package:bolanet76/app/modules/views/schedule_screen.dart';
import 'package:bolanet76/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeView> {
  int _indeksSaatIni = 0;
  final NewsSearchController searchController = Get.put(NewsSearchController());
  final List<Widget> _layar = [
    DiscoverScreen(),
    ScheduleScreen(),
    SaveScreen(),
    ProfileScreen(),
  ];
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _onTap(int index) {
    setState(() {
      _indeksSaatIni = index;
    });
  }

  Future<void> _requestPermission() async {
    PermissionStatus status = await Permission.microphone.request();
    if (status.isGranted) {
      print("Microphone permission granted");
    } else {
      print("Microphone permission denied");
    }
  }

  Future<void> _startListening(Function(String) updateQuery) async {
    await _requestPermission();
    if (!_isListening) {
      bool available = await _speech.initialize(
        onError: (error) {
          print("Speech recognition error: $error");
        },
        onStatus: (status) => print("Speech recognition status: $status"),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            updateQuery(val.recognizedWords);
            setState(() => _isListening = false);
          },
          listenFor: Duration(seconds: 30),
          pauseFor: Duration(seconds: 3),
          partialResults: false,
        );
      } else {
        setState(() => _isListening = false);
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // Updated fetchDataById to fetch the document by its specific ID
  Future<List<Map<String, dynamic>>> fetchDataById(String query) async {
    try {
      // Fetch document by the provided ID
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('news') // Your Firestore collection
          .doc('ggbG8MlOSsRUkGFDJaWZ') // Provided document ID
          .get();

      // Check if document exists
      if (snapshot.exists) {
        // Return the document data as a list containing one map
        return [snapshot.data() as Map<String, dynamic>];
      } else {
        return []; // Return an empty list if no document is found
      }
    } catch (e) {
      print('Error fetching document: $e');
      return []; // Return an empty list in case of error
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF005B96), // Biru terang
        elevation: 0,
        title: Row(
          children: [
            Image.network(
              'https://thumbs.dreamstime.com/b/sports-news-logo-clipart-sport-broadcast-media-symbol-business-broadcasting-channel-live-stream-icons-251944836.jpg',
              width: 40,
            ),
            const SizedBox(width: 10),
            const Text("HOKIBOLA76", style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(
                  searchController,
                  _startListening,
                  _isListening,
                  fetchDataById, // Pass the fetch function to the search delegate
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _layar[_indeksSaatIni],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indeksSaatIni,
        onTap: _onTap,
        selectedItemColor: Color(0xFF005B96), // Biru terang
        unselectedItemColor: Colors.grey,
        backgroundColor: Color(0xFF0288D1),
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.save),
            label: 'Save',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profille',
          ),
        ],
      ),
    );
  }
}

class CustomSearchDelegate extends SearchDelegate {
  final NewsSearchController searchController;
  final Future<void> Function(Function(String)) startListening;
  final bool isListening;
  final Future<List<Map<String, dynamic>>> Function(String) fetchDataById;

  CustomSearchDelegate(
    this.searchController,
    this.startListening,
    this.isListening,
    this.fetchDataById,
  );

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.mic, color: isListening ? Colors.red : Colors.black),
        onPressed: () {
          startListening((text) {
            query = text;
            searchController.updateSearchQuery(query);
          });
        },
      ),
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          searchController.updateSearchQuery(query);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    searchController.updateSearchQuery(query);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchDataById(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No results found"));
        }

        final articles = snapshot.data!;
        return ListView.builder(
          itemCount: articles.length,
          itemBuilder: (context, index) {
            final article = articles[index];
            return ListTile(
              title: Text(article['title'] ?? 'Title not found'),
              subtitle:
                  Text(article['description'] ?? 'Description not available'),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}
