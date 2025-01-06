import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'post_screen.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreen createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  GoogleMapController? _mapController; // Google Maps controller, nullable
  LatLng? _currentPosition; // Current user location, nullable
  final Set<Marker> _markers = {}; // Set to store map markers

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Fetch the user's current location
    _loadListings(); // Load posts from Firestore and add markers
  }

  // Fetch the user's current location
  Future<void> _getCurrentLocation() async {
    final hasPermission =
        await _checkLocationPermission(); // Check location permissions
    if (!hasPermission) return;

    // Get the user's current position with high accuracy
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    if (mounted) {
      // Update the current position if the widget is still active
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    }

    // Animate the map camera to the current position
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_currentPosition!),
      );
    }
  }

  // Copy text to the clipboard and show a confirmation message
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$text kopyalandı!')),
      );
    });
  }

  // Show detailed information about a post
  void _showPostDetails(BuildContext context, String postId, String description,
      String photoURL, String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFFFF5EE),
          content: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('posts')
                .doc(postId)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData && snapshot.data!.exists) {
                final post = snapshot.data!.data() as Map<String, dynamic>;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.network(post['photoURL'] ?? ''), // Post image
                    const SizedBox(height: 16),
                    Text(
                      post['description'] ?? 'Açıklama yok.',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                );
              } else {
                return Center(child: Text("İlan detayları bulunamadı."));
              }
            },
          ),
          actions: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      DocumentSnapshot userDoc = await FirebaseFirestore
                          .instance
                          .collection('users')
                          .doc(userId)
                          .get();

                      if (userDoc.exists) {
                        final user = userDoc.data() as Map<String, dynamic>;
                        String phone = user['phone'] ?? 'Telefon bilgisi yok';
                        String email = user['email'] ?? 'E-posta bilgisi yok';

                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: Color(0xFFFFF5EE),
                              title: const Text('İletişim Bilgileri'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text('Telefon: $phone'),
                                      IconButton(
                                        icon: Icon(Icons.copy),
                                        onPressed: () {
                                          _copyToClipboard(phone);
                                        },
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text('E-posta: $email'),
                                      IconButton(
                                        icon: Icon(Icons.copy),
                                        onPressed: () {
                                          _copyToClipboard(email);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              actions: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFFE3963E),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 30, vertical: 12),
                                  ),
                                  child: const Text(
                                    'Kapat',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE3963E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    child: const Text(
                      'İLETİŞİME GEÇ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE3963E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    child: const Text(
                      'Kapat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Calculate the time elapsed since a given timestamp
  String _getTimeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final postTime = timestamp.toDate();
    final difference = now.difference(postTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} hafta önce';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} ay önce';
    } else {
      return '${(difference.inDays / 365).floor()} yıl önce';
    }
  }

  // Check and request location permissions
  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

  // Load listings from Firestore and add them as markers on the map
  Future<void> _loadListings() async {
    final snapshot = await FirebaseFirestore.instance.collection('posts').get();

    if (mounted) {
      setState(() {
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;

          // Check if location data is available
          final location = data['location'] != null
              ? data['location'] as Map<String, dynamic>
              : null;

          if (location != null) {
            final position = LatLng(
              location['latitude'] ?? 0.0, // Default latitude if null
              location['longitude'] ?? 0.0, // Default longitude if null
            );

            // Set marker color based on post type
            Color markerColor = Colors.blue; // Default color
            if (data['postType'] == 'lost') {
              markerColor = Colors.red; // Lost post
            } else if (data['postType'] == 'found') {
              markerColor = Colors.green; // Found post
            }
            // Add the marker to the list
            _markers.add(
              Marker(
                markerId: MarkerId(doc
                    .id), // Unique ID for the marker, using the document ID from Firestore
                position: position, // Position of the marker on the map
                onTap: () {
                  // Show post details when the marker is tapped
                  _showPostDetails(
                    context,
                    doc.id, // ID of the post document
                    data['description'], // Description of the post
                    data['photoURL'], // Photo URL of the post
                    data['userId'], // User ID who created the post
                  );
                },
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  // Set the marker color based on the post type
                  markerColor == Colors.red
                      ? BitmapDescriptor.hueRed // Red for lost posts
                      : markerColor == Colors.green
                          ? BitmapDescriptor.hueGreen // Green for found posts
                          : BitmapDescriptor
                              .hueBlue, // Blue as the default color
                ),
              ),
            );
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Check if the user's current position is null and display a loading spinner if so
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    // Store the map controller when the map is created
                    _mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target:
                        _currentPosition!, // Initial map position is the user's current location
                    zoom: 14.0, // Initial zoom level
                  ),
                  myLocationEnabled:
                      true, // Enable the user's current location on the map
                  myLocationButtonEnabled:
                      false, // Disable the default location button
                  compassEnabled: false, // Disable the compass
                  zoomControlsEnabled: false, // Disable zoom controls
                  markers: _markers, // Set the markers to display on the map
                ),
                Positioned(
                  bottom:
                      16, // Position the buttons at the bottom of the screen
                  right:
                      16, // Position the buttons on the right side of the screen
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Floating action button to add a new post
                      FloatingActionButton(
                        backgroundColor: Color(0xFFE3963E), // Set button color
                        foregroundColor: Colors.white, // Set icon color
                        heroTag: 'addPost', // Unique tag for the button
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  PostScreen(), // Navigate to the PostScreen
                            ),
                          );
                        },
                        child: const Icon(Icons.add), // Icon for adding a post
                      ),
                      const SizedBox(height: 16), // Add space between buttons
                      // Floating action button to center the map on the user's current location
                      FloatingActionButton(
                        backgroundColor: Color(0xFFE3963E), // Set button color
                        foregroundColor: Colors.white, // Set icon color
                        heroTag: 'centerMap', // Unique tag for the button
                        onPressed: () {
                          if (_currentPosition != null &&
                              _mapController != null) {
                            // Animate the map camera to the user's current location
                            _mapController!.animateCamera(
                              CameraUpdate.newLatLng(_currentPosition!),
                            );
                          }
                        },
                        child: const Icon(
                            Icons.my_location), // Icon for centering the map
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
