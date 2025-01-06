import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'notifications.dart';
import 'profile.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainApp(),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;

  // Sayfalar listesi
  final List<Widget> _pages = [
    const HomeScreen(),
    const SearchScreen(),
    const Notifications(),
    Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          // Farklı sayfalara göre AppBar başlığı
          _currentIndex == 0
              ? 'DOSTUM NEREDE'
              : _currentIndex == 1
                  ? 'İlanlar'
                  : _currentIndex == 2
                      ? 'Bildirimler'
                      : 'Profil',
          style: GoogleFonts.montserrat(
            fontSize: 22, // Büyük font boyutu
            fontWeight: FontWeight.w700, // Kalın font
            color: Colors.white, // Beyaz renk
            letterSpacing: 1.5, // Harfler arası boşluk
            shadows: [
              Shadow(
                blurRadius: 4.0, // Hafif gölge
                color: Colors.black26,
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
        backgroundColor: Color(0xFFE3963E),
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: _pages[_currentIndex], // Aktif sayfayı göster
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        unselectedItemColor: Colors.white,
        selectedItemColor: Colors.black,
        backgroundColor: Color(0xFFE3963E),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false, // Seçili etiketi gizle
        showUnselectedLabels: false, // Seçilmemiş etiketi gizle
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              _currentIndex == 0 ? Icons.home : Icons.home_outlined,
            ),
            label: 'Homepage',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _currentIndex == 1 ? Icons.search : Icons.search_outlined,
            ),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _currentIndex == 2
                  ? Icons.notifications
                  : Icons.notifications_none,
            ),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _currentIndex == 3
                  ? Icons.account_circle
                  : Icons.account_circle_outlined,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
