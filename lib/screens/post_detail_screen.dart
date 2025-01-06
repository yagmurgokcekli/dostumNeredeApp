import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostDetailScreen extends StatelessWidget {
  final String postId;
  final String? userName;
  final String? description;

  const PostDetailScreen({
    Key? key,
    required this.postId,
    this.userName,
    this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(userName ??
              "İlan Detayı")), // Set app bar title, defaulting to "İlan Detayı"
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .get(), // Fetch post details from Firestore using postId
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child:
                    CircularProgressIndicator()); // Show loading spinner while waiting for data
          }

          if (snapshot.hasData && snapshot.data!.exists) {
            final post = snapshot.data!.data()
                as Map<String, dynamic>; // Parse the post data

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(
                    post['photoURL'], // Display the post's image
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (userName != null)
                          Text(
                            userName!, // Display the user's name if available
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          description ??
                              post['description'] ??
                              '', // Display the description, defaulting to empty if null
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
                child: Text(
                    "İlan bulunamadı.")); // Display a message if the post does not exist
          }
        },
      ),
    );
  }
}
