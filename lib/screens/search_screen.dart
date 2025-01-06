import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All'; // Filtreleme için kullanılacak değişken
  String _selectedSort = 'Newest'; // Sıralama için kullanılacak değişken

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF5EE), // Arka plan rengi
      body: Column(
        children: [
          // Arama çubuğu ve butonlar aynı satırda olacak şekilde düzenlendi
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Arama çubuğu
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Arama yapın...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (query) {
                      setState(
                          () {}); // Arama metni değiştikçe sayfayı güncelle
                    },
                  ),
                ),
                const SizedBox(
                    width: 16), // Butonlar ve arama çubuğu arasında boşluk
                // Filtreleme butonu
                IconButton(
                  icon: Icon(Icons.filter_list),
                  onPressed: () {
                    _showFilterDialog();
                  },
                ),
                // Sıralama butonu
                IconButton(
                  icon: Icon(Icons.sort),
                  onPressed: () {
                    _showSortDialog();
                  },
                ),
              ],
            ),
          ),

          // İlanlar listesi
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('posts').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Bir hata oluştu.'));
                }

                var posts = snapshot.data!.docs;

                // Arama ve filtreleme işlemleri
                if (_searchController.text.isNotEmpty) {
                  posts = posts.where((post) {
                    return post['description']
                        .toString()
                        .toLowerCase()
                        .contains(_searchController.text.toLowerCase());
                  }).toList();
                }

                if (_selectedFilter != 'All') {
                  posts = posts.where((post) {
                    return post['postType'] == _selectedFilter;
                  }).toList();
                }

                // İlanların sıralanması
                if (_selectedSort == 'Newest') {
                  posts.sort((a, b) {
                    return (b['timestamp'] as Timestamp)
                        .compareTo(a['timestamp'] as Timestamp);
                  });
                } else {
                  posts.sort((a, b) {
                    return (a['timestamp'] as Timestamp)
                        .compareTo(b['timestamp'] as Timestamp);
                  });
                }

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    var post = posts[index];
                    var userId = post['userId']; // userId'yi al
                    var description = post['description'] ?? 'Açıklama yok.';
                    var photoURL = post['photoURL'] ?? '';
                    var postType = post['postType'] ?? 'lost';
                    var timestamp = post['timestamp'] as Timestamp?;
                    var postTime = _formatTimestamp(timestamp);

                    // Marker rengi belirle
                    Color markerColor =
                        postType == 'lost' ? Colors.red : Colors.green;

                    // userName'i users koleksiyonundan al
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return ListTile(
                            title: Text('Yükleniyor...'),
                            subtitle: Text(description),
                          );
                        }

                        if (userSnapshot.hasError) {
                          return ListTile(
                            title: Text('Hata oluştu'),
                            subtitle: Text(description),
                          );
                        }

                        var userName = userSnapshot.data?.get('userName') ??
                            'Bilinmeyen Kullanıcı';

                        // İlanları listelerken açıklamanın uzunluğunu kontrol et ve ekle
                        return InkWell(
                          onTap: () {
                            // Tıklandığında PostDetailScreen'e yönlendirilir
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PostDetailScreen(
                                  postId: post.id, // İlanın ID'sini geçir
                                ),
                              ),
                            );
                          },
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(photoURL),
                            ),
                            title: Text(
                              userName,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Description'ı kısıtla ve fazla metni "Daha fazla göster..." şeklinde ekle
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            Colors.black), // Default text style
                                    children: [
                                      TextSpan(
                                        text: description.length > 100
                                            ? description.substring(0, 100)
                                            : description,
                                      ),
                                      TextSpan(
                                        text: description.length > 100
                                            ? '... Daha fazla göster'
                                            : '',
                                        style: TextStyle(
                                            color: Colors
                                                .grey), // Change color to grey
                                      ),
                                    ],
                                  ),
                                ),

                                Text(postTime),
                              ],
                            ),
                            trailing: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: markerColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      },
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

  // Filtreleme için dialog
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filtrele'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text('Hepsi'),
                value: 'All',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: Text('Kayıp'),
                value: 'lost',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: Text('Bulunan'),
                value: 'found',
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Sıralama için dialog
  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sıralama'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text('Yeniye Göre'),
                value: 'Newest',
                groupValue: _selectedSort,
                onChanged: (value) {
                  setState(() {
                    _selectedSort = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: Text('Eskiye Göre'),
                value: 'Oldest',
                groupValue: _selectedSort,
                onChanged: (value) {
                  setState(() {
                    _selectedSort = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Zamanı formatlayacak fonksiyon
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';

    DateTime date = timestamp.toDate();
    Duration diff = DateTime.now().difference(date);

    if (diff.inDays >= 365) {
      return '${(diff.inDays / 365).floor()} yıl önce';
    } else if (diff.inDays >= 30) {
      return '${(diff.inDays / 30).floor()} ay önce';
    } else if (diff.inDays >= 1) {
      return '${diff.inDays} gün önce';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours} saat önce';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }
}

// İlan detay sayfası
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
      appBar: AppBar(
        title: Text("İlan Detayı"),
        backgroundColor: Color(0xFFFFF5EE),
      ),
      backgroundColor: Color(0xFFFFF5EE), // Arka plan rengi
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

                  // Zamanı hesapla
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
                                    timeAgo, // Paylaşılma süresi
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
