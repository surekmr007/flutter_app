import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class ListenLocationWidget extends StatefulWidget {
  const ListenLocationWidget({super.key});

  @override
  _ListenLocationState createState() => _ListenLocationState();
}

class _ListenLocationState extends State<ListenLocationWidget> {
  final Location location = Location();

  LocationData? _location;
  StreamSubscription<LocationData>? _locationSubscription;
  String? _error;

  GoogleMapController? mapController;
  Set<Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  Set<Marker> markers = {}; // Add this line

  Future<void> _listenLocation() async {
    _locationSubscription =
        location.onLocationChanged.handleError((dynamic err) {
      if (err is PlatformException) {
        setState(() {
          _error = err.code;
        });
      }
      _locationSubscription?.cancel();
      setState(() {
        _locationSubscription = null;
      });
    }).listen(
      (currentLocation) {
        setState(
          () {
            _error = null;
            _location = currentLocation;

            // Add the new location to the polyline
            polylineCoordinates.add(LatLng(
                _location?.latitude ?? 0.0, _location?.longitude ?? 0.0));
            markers.clear();
            markers.add(
              Marker(
                markerId: const MarkerId('currentLocation'),
                position: LatLng(
                    _location?.latitude ?? 0.0, _location?.longitude ?? 0.0),
              ),
            );

            polylines.clear();
            polylines.add(
              Polyline(
                polylineId: const PolylineId('navigationPath'),
                points: polylineCoordinates,
                color: Colors.blue,
                width: 10,
              ),
            );

            // Animate the camera to the new location
            mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(
                _location?.latitude ?? 0.0, _location?.longitude ?? 0.0)));
          },
        );
      },
    );
  }

  Future<void> _stopListen() async {
    await _locationSubscription?.cancel();
    setState(() {
      _locationSubscription = null;
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    setState(() {
      _locationSubscription = null;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Listen location: ${_error ?? '${_location ?? "unknown"}'}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Row(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(right: 42),
              child: ElevatedButton(
                onPressed:
                    _locationSubscription == null ? _listenLocation : null,
                child: const Text('Listen'),
              ),
            ),
            ElevatedButton(
              onPressed: _locationSubscription != null ? _stopListen : null,
              child: const Text('Stop'),
            ),
          ],
        ),
        SizedBox(
          width: double.infinity,
          height: 500,
          child: GoogleMap(
            onMapCreated: (controller) {
              mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(
                  _location?.latitude ?? 0.0, _location?.longitude ?? 0.0),
              zoom: 15.0,
            ),
            polylines: polylines,
            markers: markers, // Add this line
          ),
        ),
      ],
    );
  }
}
