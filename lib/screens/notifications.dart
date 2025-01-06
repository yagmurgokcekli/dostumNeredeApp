import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch posts near the user's location
  Future<List<Map<String, dynamic>>> getNearbyPosts(
      Position userPosition, double distanceInKm, String currentUserId) async {
    final postsSnapshot = await _firestore.collection('posts').get();

    List<Map<String, dynamic>> nearbyPosts = [];

    for (var postDoc in postsSnapshot.docs) {
      var post = postDoc.data();
      var location = post['location']; // Retrieve location object
      double postLat = location['latitude'];
      double postLng = location['longitude'];

      // If the post belongs to the user, skip distance filtering
      if (post['userId'] == currentUserId) {
        nearbyPosts.add(post); // Add user's post without filtering
      } else {
        // Calculate the distance between the user's location and the post's location
        double distance = Geolocator.distanceBetween(userPosition.latitude,
                userPosition.longitude, postLat, postLng) /
            1000;

        if (distance <= distanceInKm) {
          // Filter posts within the specified distance
          nearbyPosts.add(post);
        }
      }
    }

    // Sort posts by their timestamp in descending order
    nearbyPosts.sort((a, b) {
      Timestamp timestampA = a['timestamp'];
      Timestamp timestampB = b['timestamp'];
      return timestampB.compareTo(timestampA);
    });

    return nearbyPosts;
  }
}

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  List<Map<String, dynamic>> _nearbyPosts = [];
  String currentUserId = ''; // Holds the ID of the logged-in user
  bool isLoading = true; // Tracks whether data is loading

  @override
  void initState() {
    super.initState();
    _loadNearbyPosts();
    _getCurrentUserId(); // Fetch the user's ID
  }

  // Fetch the user's ID using Firebase Authentication
  Future<void> _getCurrentUserId() async {
    // Retrieve the logged-in user from FirebaseAuth
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() {
        currentUserId = currentUser.uid; // Store the user ID
      });
    }
  }

  // Fetch the user's location and nearby posts
  Future<void> _loadNearbyPosts() async {
    try {
      Position userPosition = await _getUserLocation();
      NotificationService notificationService = NotificationService();
      List<Map<String, dynamic>> posts = await notificationService
          .getNearbyPosts(userPosition, 5.0, currentUserId); // Default 5 km

      if (mounted) {
        setState(() {
          _nearbyPosts = posts;
          isLoading = false; // Disable loading state once data is fetched
        });
      }
    } catch (e) {
      print('Error while fetching location: $e');
      setState(() {
        isLoading = false; // Disable loading state even in case of an error
      });
    }
  }

  // Fetch the user's current location
  Future<Position> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location service is not enabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permission denied');
      }
    }

    return await Geolocator.getCurrentPosition();
  }

  // Calculate time elapsed since the post was shared
  String _getTimeAgo(Timestamp timestamp) {
    DateTime postTime = timestamp.toDate();
    Duration difference = DateTime.now().difference(postTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF5EE), // Background color
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Loading indicator
          : _nearbyPosts.isEmpty
              ? const Center(child: Text('Konumunuza yakın ilan bulunmuyor'))
              : ListView.builder(
                  itemCount: _nearbyPosts.length,
                  itemBuilder: (context, index) {
                    var post = _nearbyPosts[index];
                    var postId = post['postId'] ?? '';
                    var postType = post['postType'] ?? 'lost';

                    // Show a specific message if the user owns the post
                    String notificationMessage = post['userId'] == currentUserId
                        ? 'İlanınız başarıyla paylaşıldı'
                        : (postType == 'lost'
                            ? 'Yakınlarınızda bir dost kayboldu!'
                            : 'Yakınlarınızda bir dost bulundu!');

                    TextStyle textStyle = TextStyle(
                        fontSize: 16,
                        fontWeight: post['isRead'] ?? false
                            ? FontWeight.normal
                            : FontWeight.bold);

                    return ListTile(
                      leading: post['photoURL'] != null
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(post['photoURL']),
                              radius: 30.0,
                            )
                          : const CircleAvatar(
                              backgroundColor: Colors.grey,
                              radius: 30.0,
                              child: Icon(Icons.image),
                            ),
                      title: Text(notificationMessage, style: textStyle),
                      subtitle: Text(_getTimeAgo(post['timestamp'])),
                      trailing: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: post['postType'] == 'lost'
                              ? Colors.red
                              : Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostDetailScreen(
                              postId: postId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}

// Post detail screen
class PostDetailScreen extends StatelessWidget {
  final String postId;

  const PostDetailScreen({Key? key, required this.postId}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("İlan Detayı")),
      backgroundColor: Color(0xFFFFF5EE), // Background color
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('posts').doc(postId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data!.exists) {
            final post = snapshot.data!.data() as Map<String, dynamic>;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(post['userId'])
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final user =
                      userSnapshot.data!.data() as Map<String, dynamic>;

                  // Calculate elapsed time
                  final postTime = post['timestamp'] as Timestamp;
                  final timeAgo = _getTimeAgo(postTime);

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(post['photoURL']),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    user['userName'] ?? 'Bilinmeyen Kullanıcı',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    timeAgo, // Elapsed time since posting
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                post['description'] ?? 'Açıklama yok.',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Center(child: Text("Kullanıcı bilgileri bulunamadı."));
                }
              },
            );
          } else {
            return Center(child: Text("İlan bulunamadı."));
          }
        },
      ),
    );
  }
}
