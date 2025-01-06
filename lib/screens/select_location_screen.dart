import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class SelectLocationScreen extends StatefulWidget {
  @override
  _SelectLocationScreenState createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  LatLng? _userLocation; // Kullanıcının mevcut konumu
  LatLng? _pickedLocation;
  GoogleMapController? _mapController; // Harita kontrolcüsü
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setUserLocation();
  }

  Future<void> _setUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lütfen konum servisini açın')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Konum izni verilmedi')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Konum izni kalıcı olarak reddedildi')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
    } catch (e) {
      print('Konum alma hatası: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectLocation(LatLng position) {
    setState(() {
      _pickedLocation = position;
    });
  }

  void _goToUserLocation() {
    if (_userLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _userLocation!, zoom: 14),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Konum Seç')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _userLocation ?? LatLng(41.0082, 28.9784),
                    zoom: 14,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onTap: _selectLocation,
                  markers: {
                    if (_userLocation != null)
                      Marker(
                        markerId: MarkerId('userLocation'),
                        position: _userLocation!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueBlue),
                      ),
                    if (_pickedLocation != null)
                      Marker(
                        markerId: MarkerId('pickedLocation'),
                        position: _pickedLocation!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed),
                      ),
                  },
                ),
                Positioned(
                  bottom: 80,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: 'goToUserLocation',
                    onPressed: _goToUserLocation,
                    child: Icon(Icons.my_location),
                    backgroundColor: Color(0xFFE3963E), // Button color
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'confirmSelection',
        child: Icon(Icons.check),
        onPressed: () {
          if (_pickedLocation != null) {
            Navigator.of(context).pop(_pickedLocation);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lütfen bir konum seçin')),
            );
          }
        },
        backgroundColor: Color(0xFFE3963E), // Button color
      ),
    );
  }
}
