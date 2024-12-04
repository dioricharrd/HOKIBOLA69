import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator
import 'package:geocoding/geocoding.dart'; // Import geocoding

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  String _latitude = "";
  String _longitude = "";
  String _locationMessage = "Menunggu lokasi...";
  String _address = "Menunggu alamat...";

  @override
  void initState() {
    super.initState();
  }

  /// Fungsi untuk mendapatkan lokasi saat ini
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Periksa apakah layanan lokasi diaktifkan
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationMessage = "Layanan lokasi dinonaktifkan.";
      });
      return;
    }

    // Periksa izin lokasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationMessage = "Izin lokasi ditolak.";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationMessage = "Izin lokasi ditolak secara permanen.";
      });
      return;
    }

    // Ambil lokasi saat ini
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _latitude = position.latitude.toString();
      _longitude = position.longitude.toString();
      _locationMessage = "Latitude: $_latitude, Longitude: $_longitude";
    });

    // Ambil alamat dari koordinat
    await _getAddressFromCoordinates(position.latitude, position.longitude);
  }

  /// Fungsi untuk mendapatkan alamat dari koordinat
  Future<void> _getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      Placemark place = placemarks[0];
      setState(() {
        _address = "${place.street}, ${place.subLocality}, "
            "${place.locality}, ${place.postalCode}, ${place.country}";
      });
    } catch (e) {
      setState(() {
        _address = "Gagal mendapatkan alamat: $e";
      });
    }
  }

  /// Fungsi untuk membuka lokasi di Google Maps menggunakan koordinat yang diambil
  void _openGoogleMaps() {
    if (_latitude.isNotEmpty && _longitude.isNotEmpty) {
      final url = 'https://www.google.com/maps/place/$_latitude,$_longitude';
      _launchURL(url);
    } else {
      setState(() {
        _locationMessage = "Tidak ada koordinat yang dapat dibuka.";
      });
    }
  }

  /// Fungsi untuk meluncurkan URL
  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Tidak dapat membuka $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF004A7C), // Warna biru yang lebih gelap
        title: Text(
          "Lokasi Saya",
        ),
        centerTitle: true,
        elevation: 6,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on,
                size: 80,
                color: Color(0xFF004A7C), // Warna ikon
              ),
              const SizedBox(height: 20),
              Text(
                'Titik Koordinat',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004A7C), // Warna teks
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _locationMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Alamat',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004A7C), // Warna teks
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _address,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _getCurrentLocation, // Mendapatkan lokasi saat ini
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Color(0xFF005B96), // Biru terang untuk tombol
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cari Lokasi Saya',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white, // Mengubah warna teks menjadi putih
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _openGoogleMaps, // Membuka lokasi di Google Maps
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Color(0xFF005B96), // Biru terang untuk tombol
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Buka Google Maps',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white, // Mengubah warna teks menjadi putih
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
