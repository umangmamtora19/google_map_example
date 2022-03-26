// ignore_for_file: invalid_required_named_param, must_be_immutable

import 'dart:async';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'constant.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Position? userLocation;
  String userAddress = "";
  GoogleMapController? controller;
  Set<Marker> markers = <Marker>{};
  CameraPosition initPosition = const CameraPosition(
      target: LatLng(23.039890507168632, 72.51163382386147), zoom: 15);

  @override
  void initState() {
    _determinePosition().then((value) {
      setState(() {
        userLocation = value;
        initPosition = CameraPosition(
          target: LatLng(value.latitude, value.longitude),
          zoom: 15,
        );
        controller?.animateCamera(CameraUpdate.newCameraPosition(initPosition));
        getAddress(initPosition.target)
            .then((address) => {userAddress = address});
      });
    });
    super.initState();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition();
  }

  void addMarker(LatLng ll) {
    markers.clear();
    setState(() {
      markers.add(
        Marker(
          markerId: MarkerId(
            ll.toString(),
          ),
          position: ll,
          // infoWindow: InfoWindow(
          //     title: "${ll.latitude}\n ${ll.longitude}", snippet: "dasdfas"),
        ),
      );
      controller?.animateCamera(CameraUpdate.newLatLng(ll));
      getAddress(ll).then((address) => {userAddress = address});
    });
  }

  Future<String> getAddress(LatLng ll) async {
    final placemarkes = await GeocodingPlatform.instance
        .placemarkFromCoordinates(ll.latitude, ll.longitude);
    final placemark = placemarkes.first;
    setState(() {
      userAddress =
          "${placemark.name}, ${placemark.street}, ${placemark.administrativeArea}, ${placemark.locality}, ${placemark.postalCode}, ${placemark.country}";
    });
    return "${placemark.name}, ${placemark.locality}, ${placemark.postalCode}, ${placemark.country}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            initialCameraPosition: initPosition,
            onMapCreated: (GoogleMapController controller) {
              setState(() {
                this.controller = controller;
              });
            },
            markers: markers,
            onTap: addMarker,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(10),
                    strokeWidth: 2,
                    color: Colors.black,
                    dashPattern: const [4, 5],
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        color: Colors.white,
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SelectLocation(
                                action: () {},
                                image: Images.location,
                                title: userAddress,
                              ),
                              const Divider(color: Colors.grey),
                              SelectLocation(
                                action: () {
                                  markers.clear();
                                  controller?.animateCamera(
                                    CameraUpdate.newCameraPosition(
                                        initPosition),
                                  );
                                  getAddress(initPosition.target).then(
                                      (address) => {userAddress = address});
                                },
                                image: Images.gps,
                                title: "Use My Location",
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Padding(
                          padding: EdgeInsets.all(14.0),
                          child: Text(
                            "Confirm Address",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SelectLocation extends StatelessWidget {
  SelectLocation({
    Key? key,
    required this.image,
    required this.title,
    required this.action,
  }) : super(key: key);

  String image;
  String title;
  VoidCallback action;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Image.asset(
            image,
            height: 25,
            width: 25,
            fit: BoxFit.contain,
          ),
          const SizedBox(
            width: 8,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                ),
                maxLines: 2,
              ),
            ),
          )
        ],
      ),
    );
  }
}
