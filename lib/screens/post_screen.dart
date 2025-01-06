import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'select_location_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostScreen extends StatefulWidget {
  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  File? _selectedImage;
  String _description = '';
  LatLng? _selectedLocation;
  bool _isLoading = false;

  // Cloudinary API bilgileri
  static const String uploadPreset = 'post_img_preset';

  final _descriptionController = TextEditingController();

  String? _selectedPostType; // Başlangıçta null

  // Fotoğraf seçme fonksiyonu
  Future<void> _pickImage() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  // Fotoğrafı Cloudinary'ye yükleme fonksiyonu
  Future<String?> _uploadImage(File imageFile) async {
    final uri =
        Uri.parse('https://api.cloudinary.com/v1_1/dwuvx3j8b/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data = json.decode(responseBody);

    if (response.statusCode == 200) {
      return data['secure_url'];
    } else {
      print('Yükleme hatası: $data');
      return null;
    }
  }

  // Fotoğrafı Firestore'a kaydetme
  Future<void> _submitPost(String imageUrl) async {
    if (_description.isEmpty || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen açıklama ve konum girin!')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("Kullanıcı giriş yapmamış!");
      }

      final userId = user.uid;

      final postRef = FirebaseFirestore.instance.collection('posts').doc();

      await postRef.set({
        'userId': userId,
        'description': _description,
        'photoURL': imageUrl,
        'location': {
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
        },
        'postType': _selectedPostType,
        'timestamp': FieldValue.serverTimestamp(),
        'postId': postRef.id,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İlan başarıyla paylaşıldı!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('İlan eklerken hata oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu!')),
      );
    }
  }

  // Fotoğrafı yükleyip Firestore'a kaydetme
  Future<void> _handlePost() async {
    if (_selectedImage != null) {
      final url = await _uploadImage(_selectedImage!);
      if (url != null) {
        _submitPost(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yükleme hatası!')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen bir fotoğraf seçin!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('İlan Paylaş',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        backgroundColor: Color(0xFFE3963E),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        // Scrollable hale getirdik
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: _selectedImage == null
                    ? Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: Icon(Icons.add_a_photo, size: 50),
                      )
                    : Image.file(
                        _selectedImage!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Açıklama',
                  labelStyle: TextStyle(color: Color(0xFFE3963E)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 3,
                onChanged: (value) => setState(() => _description = value),
              ),
              SizedBox(height: 16),
              Column(
                children: [
                  RadioListTile<String>(
                    title: Text('Kayıp Hayvan İlanı'),
                    value: 'lost',
                    groupValue: _selectedPostType,
                    onChanged: (value) {
                      setState(() {
                        _selectedPostType = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: Text('Bulunan Hayvan İlanı'),
                    value: 'found',
                    groupValue: _selectedPostType,
                    onChanged: (value) {
                      setState(() {
                        _selectedPostType = value;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final LatLng location = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => SelectLocationScreen(),
                    ),
                  );
                  setState(() {
                    _selectedLocation = location;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE3963E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text(
                  'Konum Seç',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _handlePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE3963E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text(
                  'İlan Paylaş',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              if (_isLoading) SizedBox(height: 20),
              if (_isLoading) CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
