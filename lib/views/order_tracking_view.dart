import 'dart:async';
import 'dart:developer';

import 'package:delivery/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class OrderTrackingView extends StatefulWidget {
  const OrderTrackingView({Key? key}) : super(key: key);

  @override
  State<OrderTrackingView> createState() => _OrderTrackingViewState();
}

class _OrderTrackingViewState extends State<OrderTrackingView> {
  final Completer<GoogleMapController> _controller = Completer();

  LocationData? currentLocation;
  bool isLoading = true;
  bool permissionGranted = false;

  /// This is custom marker icon for source and destination location
  late BitmapDescriptor sourceIcon;
  late BitmapDescriptor destinationIcon;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polyLines = {};

  static const LatLng sourceLocation = LatLng(37.33500926, -122.03272188);
  static const LatLng destinationLocation = LatLng(37.33429383, -122.06600055);
  List<LatLng> polyCoordinates = [];

  void setPolyLines() async {
    PolylinePoints polyPoints = PolylinePoints();
    PolylineResult result = await polyPoints.getRouteBetweenCoordinates(
      Constants.googleApiKey,
      PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
      PointLatLng(destinationLocation.latitude, destinationLocation.longitude),
      travelMode: TravelMode.driving,
    );
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polyCoordinates.add(LatLng(point.latitude, point.longitude));
      }
      _polyLines.add(Polyline(polylineId: const PolylineId('route'), color: Colors.red, points: polyCoordinates, width: 6));
      setState(() {});
    }
  }

  void setSourceAndDestinationIcons() async {
    sourceIcon = await BitmapDescriptor.fromAssetImage(const ImageConfiguration(devicePixelRatio: 2.5), 'assets/driving_pin.png');
    destinationIcon = await BitmapDescriptor.fromAssetImage(const ImageConfiguration(devicePixelRatio: 2.5), 'assets/destination_icon.png');
  }

  void onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
    setMapPins();
    setPolyLines();
  }

  void getCurrentLocation() async {
    setState(() {
      isLoading = true;
    });
    Location location = Location();
    bool checkServiceEnable = await location.serviceEnabled();
    if (!checkServiceEnable) {
      bool requestServiceEnable = await location.requestService();
      if (!requestServiceEnable) {
        log('Location service is not enabled');
        permissionGranted = false;
        isLoading = false;
        setState(() {});
      } else {
        getLocation();
      }
    } else {
      getLocation();
    }
  }

  void getLocation() {
    Location location = Location();
    location.getLocation().then((value) {
      currentLocation = value;
      isLoading = false;
      permissionGranted = true;
      setState(() {});
    });
  }

  @override
  void initState() {
    getCurrentLocation();
    setSourceAndDestinationIcons();
    super.initState();
  }

  void setMapPins() {
    setState(() {
      /// current Location pin
      _markers.add(
          Marker(markerId: const MarkerId('source'), position: LatLng(currentLocation!.latitude!, currentLocation!.longitude!)));

      /// source pin
      _markers.add(Marker(markerId: const MarkerId('destination'), position: sourceLocation, icon: sourceIcon));

      /// destination pin
      _markers.add(Marker(markerId: const MarkerId('destination'), position: destinationLocation, icon: destinationIcon));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: const Text('Order Tracking', style: TextStyle(color: Colors.black)),
      ),
      body: !isLoading
          ? permissionGranted
              ? GoogleMap(
                  myLocationEnabled: true,
                  mapType: MapType.normal,
                  initialCameraPosition:
                      CameraPosition(target: LatLng(currentLocation!.latitude!, currentLocation!.longitude!), bearing: 30, tilt: 0, zoom: 13.5),
                  polylines: _polyLines,
                  onMapCreated: onMapCreated,
                  markers: _markers,
                )
              : Center(child: ShowPermissionDenied(getLocation: getCurrentLocation))
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class ShowPermissionDenied extends StatelessWidget {
  final VoidCallback getLocation;

  const ShowPermissionDenied({Key? key, required this.getLocation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Permission not granted', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 3),
        const Text('To Track your order, location service is required'),
        const SizedBox(height: 10),
        MaterialButton(onPressed: getLocation, color: Colors.blue, textColor: Colors.white, child: const Text('Grant Permission')),
      ],
    );
  }
}
