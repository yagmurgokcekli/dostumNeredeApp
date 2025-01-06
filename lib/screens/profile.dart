import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'auth_screen.dart';
import 'dart:typed_data';

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String _profilePhotoUrl = ''; // Stores the profile photo URL of the user.
  String _userName = 'Kullanıcı Adı'; // Default username placeholder.
  File? _selectedImage; // Holds the selected image file.
  final _imagePicker =
      ImagePicker(); // ImagePicker instance for selecting images.

  static const String cloudName = 'dwuvx3j8b'; // Cloudinary cloud name.
  static const String uploadPreset =
      'user_img_preset'; // Cloudinary upload preset.
  User? _user; // Firebase Auth user instance.

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetches user data when the widget is initialized.
  }

  // Fetches the current user's data from Firestore.
  Future<void> _fetchUserData() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _profilePhotoUrl = userDoc['profilePhotoUrl'] ?? '';
          _userName = userDoc['userName'] ?? 'Kullanıcı Adı';
        });
      }
    }
  }

  // Opens the image picker to select a new profile photo.
  Future<void> _pickImage() async {
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      _updateProfilePhoto();
    }
  }

  // Uploads the selected image to Cloudinary and returns the URL.
  Future<String?> _uploadImage(File imageFile) async {
    final uri =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data = json.decode(responseBody);

    if (response.statusCode == 200) {
      return data['secure_url'];
    } else {
      return null;
    }
  }

  // Updates the profile photo URL in Firestore and UI.
  Future<void> _updateProfilePhoto() async {
    if (_selectedImage != null) {
      final url = await _uploadImage(_selectedImage!);
      if (url != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({'profilePhotoUrl': url});

        setState(() {
          _profilePhotoUrl = url;
        });
      }
    }
  }

  // Updates the username in Firestore and UI.
  Future<void> _updateUserName(String newUserName) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .update({'userName': newUserName});
    setState(() {
      _userName = newUserName;
    });
  }

  // Deletes the profile photo from Firestore and resets the URL.
  Future<void> _deleteProfilePhoto() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .update({'profilePhotoUrl': ''});
    setState(() {
      _profilePhotoUrl = '';
    });
  }

  // Fetches the posts created by the current user.
  Stream<QuerySnapshot> _fetchUserPosts() {
    if (_user != null) {
      return FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: _user!.uid)
          .orderBy('timestamp', descending: true)
          .snapshots();
    }
    return Stream.empty();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF5EE), // Background color.
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceBetween, // Aligns elements horizontally.
              children: [
                Row(
                  children: [
                    // Profile photo with edit functionality.
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: _profilePhotoUrl.isNotEmpty
                            ? NetworkImage(_profilePhotoUrl)
                            : null,
                        child: _profilePhotoUrl.isEmpty
                            ? const Icon(Icons.camera_alt,
                                size: 40, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Display the user's name.
                    Text(
                      _userName,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                // Edit and logout buttons.
                Row(
                  mainAxisSize:
                      MainAxisSize.min, // Removes unnecessary spacing.
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: _showEditDialog,
                    ),
                    IconButton(
                      icon: const Icon(Icons.exit_to_app, size: 30),
                      onPressed: _logout,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          // Grid view for displaying user posts.
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _fetchUserPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("Henüz bir ilan paylaşmadınız."));
                }

                final posts = snapshot.data!.docs;

                return GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PostDetailScreen(postId: post.id),
                            ),
                          );
                        },
                        child: Image.network(
                          post['photoURL'],
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Logs out the user and redirects to the authentication screen.
  Future<void> _logout() async {
    bool? shouldLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Çıkış Yap'),
          content:
              const Text('Oturumunuzu kapatmak istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              child: const Text('Hayır'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Evet'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    }
  }

  // Displays a bottom sheet for editing user profile details.
  Future<void> _showEditDialog() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          children: [
            ListTile(
              title: const Text("Fotoğrafı Sil"),
              onTap: _deleteProfilePhoto,
            ),
            ListTile(
              title: const Text("Fotoğraf Ekle"),
              onTap: _pickImage,
            ),
            ListTile(
              title: const Text("Kullanıcı Adı Değiştir"),
              onTap: () async {
                String? newUserName = await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) {
                    TextEditingController controller =
                        TextEditingController(text: _userName);
                    return AlertDialog(
                      title: const Text('Yeni Kullanıcı Adı'),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                            hintText: 'Yeni kullanıcı adınızı girin'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(controller.text);
                          },
                          child: const Text('Kaydet'),
                        ),
                      ],
                    );
                  },
                );
                if (newUserName != null && newUserName.isNotEmpty) {
                  _updateUserName(newUserName);
                }
              },
            ),
          ],
        );
      },
    );
  }
}

// Screen for displaying the details of a specific post.
class PostDetailScreen extends StatelessWidget {
  final String postId;

  const PostDetailScreen({Key? key, required this.postId}) : super(key: key);

  // Converts a timestamp into a human-readable "time ago" string.
  String _getTimeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final postTime = timestamp.toDate();
    final difference = now.difference(postTime);

    if (difference.inMinutes < 60) {
      return '\${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '\${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '\${(difference.inDays / 7).floor()} hafta önce';
    } else if (difference.inDays < 30) {
      return '\${(difference.inDays / 30).floor()} ay önce';
    } else {
      return '\${(difference.inDays / 365).floor()} yıl önce';
    }
  }

  Future<Uint8List> _fetchImageBytes(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception(
            'Image download failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Image loading error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("İlan Detayı"),
        backgroundColor: const Color(0xFFFFF5EE),
      ),
      backgroundColor: const Color(0xFFFFF5EE),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('posts').doc(postId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
                  return const Center(child: CircularProgressIndicator());
                }

                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final user =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  final postTime = post['timestamp'] as Timestamp;
                  final timeAgo = _getTimeAgo(postTime);

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(post['photoURL'],
                            errorBuilder: (context, error, stackTrace) {
                          return const Center(
                              child: Icon(Icons.broken_image, size: 100));
                        }),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    user['userName'] ?? 'Bilinmeyen Kullanıcı',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    timeAgo,
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.grey),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                post['description'] ?? 'Açıklama yok.',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return const Center(
                      child: Text("Kullanıcı bilgileri bulunamadı."));
                }
              },
            );
          } else {
            return const Center(child: Text("İlan bulunamadı."));
          }
        },
      ),
    );
  }
}
