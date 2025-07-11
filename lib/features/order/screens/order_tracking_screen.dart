import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:pretty_http_logger/pretty_http_logger.dart';
import 'package:sixam_mart/Model/live_track.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/map_decode_polyline.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/location/widgets/permission_dialog_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/marker_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/features/order/widgets/track_details_view_widget.dart';
import 'package:sixam_mart/features/order/widgets/tracking_stepper_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String? orderID;
  final String? contactNumber;
  const OrderTrackingScreen(
      {super.key, required this.orderID, this.contactNumber});

  @override
  OrderTrackingScreenState createState() => OrderTrackingScreenState();
}

class OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Set<Polyline> polyLines = HashSet<Polyline>();
  LiveTrack liveTrackLatLan = LiveTrack();
  GoogleMapController? _controller;

  bool  _isLoading = true;
  Set<Marker> _markers = HashSet<Marker>();
  Timer? _timer;
  bool showChatPermission = true;
  bool isHovered = false;
  void _loadData() async {
    await Get.find<OrderController>().trackOrder(widget.orderID, null, true,
        contactNumber: widget.contactNumber);
    await Get.find<LocationController>().getCurrentLocation(true,
        notify: false,
        defaultLatLng: LatLng(
          double.parse(AddressHelper.getUserAddressFromSharedPref()!.latitude!),
          double.parse(
              AddressHelper.getUserAddressFromSharedPref()!.longitude!),
        ));
  }

  void _startApiCall() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      Get.find<OrderController>().timerTrackOrder(widget.orderID.toString(),
          contactNumber: widget.contactNumber);
    });
  }

  ///.................live Track..............
  Timer? _locationUpdateTimer;

  void _startLocationUpdate() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      updateDeliveryBoyApi();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _startApiCall();
    _startLocationUpdate();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _timer?.cancel();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  void onEntered(bool isHovered) {
    setState(() {
      this.isHovered = isHovered;
    });
  }

  Future<String> _estimateArrivalTime(LatLng origin, LatLng destination) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/distancematrix/json'
      '?origins=${origin.latitude},${origin.longitude}'
      '&destinations=${destination.latitude},${destination.longitude}'
      '&mode=driving&key=${AppConstants.googleMapKey}',
    );

    try {
      final response =
          await HttpClient().getUrl(url).then((req) => req.close());
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body);

      if (data['status'] == 'OK') {
        final duration = data['rows'][0]['elements'][0]['duration']
            ['text']; // e.g., "8 mins"
        return duration;
      } else {
        debugPrint('Distance Matrix Error: ${data['status']}');
        return "N/A";
      }
    } catch (e) {
      debugPrint('ETA Error: $e');
      return "N/A";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'order_tracking'.tr),
      endDrawer: const MenuDrawer(),
      endDrawerEnableOpenDragGesture: false,
      body: GetBuilder<OrderController>(builder: (orderController) {
        OrderModel? track;
        if (orderController.trackModel != null) {
          track = orderController.trackModel;

          if (track!.orderType != 'parcel') {
            if (track.store!.storeBusinessModel == 'commission') {
              showChatPermission = true;
            } else if (track.store!.storeSubscription != null &&
                track.store!.storeBusinessModel == 'subscription') {
              showChatPermission = track.store!.storeSubscription!.chat == 1;
            } else {
              showChatPermission = false;
            }
          } else {
            showChatPermission = AuthHelper.isLoggedIn();
          }
        }

        return track != null
            ? SingleChildScrollView(
                physics: isHovered || !ResponsiveHelper.isDesktop(context)
                    ? const NeverScrollableScrollPhysics()
                    : const AlwaysScrollableScrollPhysics(),
                child: FooterView(
                  child: Center(
                      child: SizedBox(
                          width: Dimensions.webMaxWidth,
                          height: ResponsiveHelper.isDesktop(context)
                              ? 700
                              : MediaQuery.of(context).size.height * 0.85,
                          child: Stack(children: [
                            MouseRegion(
                              onEnter: (event) => onEntered(true),
                              onExit: (event) => onEntered(false),
                              child: GoogleMap(
                                polylines: polyLines,
                                initialCameraPosition: CameraPosition(
                                    target: LatLng(
                                      double.parse(
                                          track.deliveryAddress!.latitude!),
                                      double.parse(
                                          track.deliveryAddress!.longitude!),
                                    ),
                                    zoom: 16),
                                minMaxZoomPreference:
                                    const MinMaxZoomPreference(0, 16),
                                zoomControlsEnabled: false,
                                markers: _markers,
                                onMapCreated: (GoogleMapController controller) {
                                  _controller = controller;
                                  _isLoading = false;
                                  setMarker(
                                    track!.orderType == 'parcel'
                                        ? Store(
                                            latitude:
                                                track.receiverDetails!.latitude,
                                            longitude: track
                                                .receiverDetails!.longitude,
                                            address:
                                                track.receiverDetails!.address,
                                            name: track.receiverDetails!
                                                .contactPersonName)
                                        : track.store,
                                    track.deliveryMan,
                                    track.orderType == 'take_away'
                                        ? Get.find<LocationController>()
                                                    .position
                                                    .latitude ==
                                                0
                                            ? track.deliveryAddress
                                            : AddressModel(
                                                latitude: Get.find<
                                                        LocationController>()
                                                    .position
                                                    .latitude
                                                    .toString(),
                                                longitude: Get.find<
                                                        LocationController>()
                                                    .position
                                                    .longitude
                                                    .toString(),
                                                address: Get.find<
                                                        LocationController>()
                                                    .address,
                                              )
                                        : track.deliveryAddress,
                                    track.orderType == 'take_away',
                                    track.orderType == 'parcel',
                                    track.moduleType == 'food',
                                  );
                                },
                                style: Get.isDarkMode
                                    ? Get.find<ThemeController>().darkMap
                                    : Get.find<ThemeController>().lightMap,
                              ),
                            ),
                            _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : const SizedBox(),
                            Positioned(
                              top: Dimensions.paddingSizeSmall,
                              left: Dimensions.paddingSizeSmall,
                              right: Dimensions.paddingSizeSmall,
                              child: track.orderStatus?.toLowerCase() ==
                                      'confirmed'
                                  ? FutureBuilder<String>(
                                      future: _estimateArrivalTime(
                                        LatLng(
                                          double.tryParse(liveTrackLatLan
                                                      .location?.latitude
                                                      ?.toString() ??
                                                  '0') ??
                                              0,
                                          double.tryParse(liveTrackLatLan
                                                      .location?.longitude
                                                      ?.toString() ??
                                                  '0') ??
                                              0,
                                        ),
                                        LatLng(
                                          double.tryParse(track.deliveryAddress
                                                      ?.latitude ?? '0') ??
                                              0,
                                          double.tryParse(track.deliveryAddress
                                                      ?.longitude ??
                                                  '0') ??
                                              0,
                                        ),
                                      ),
                                      builder: (context, snapshot) {
                                        final eta = snapshot.data ?? '...';
                                        return Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.directions_bike,
                                                  color: Colors.blue),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Arriving in $eta',
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    )
                                  : TrackingStepperWidget(
                                      status: track.orderStatus,
                                      takeAway: track.orderType == 'take_away',
                                    ),
                            ),
                            Positioned(
                              right: 15,
                              bottom: track.orderType != 'take_away' &&
                                      track.deliveryMan == null
                                  ? 150
                                  : 220,
                              child: InkWell(
                                onTap: () => _checkPermission(() async {
                                  AddressModel address =
                                      await Get.find<LocationController>()
                                          .getCurrentLocation(false,
                                              mapController: _controller);
                                  setMarker(
                                    track!.orderType == 'parcel'
                                        ? Store(
                                            latitude:
                                                track.receiverDetails!.latitude,
                                            longitude: track
                                                .receiverDetails!.longitude,
                                            address:
                                                track.receiverDetails!.address,
                                            name: track.receiverDetails!
                                                .contactPersonName)
                                        : track.store,
                                    track.deliveryMan,
                                    track.orderType == 'take_away'
                                        ? Get.find<LocationController>()
                                                    .position
                                                    .latitude ==
                                                0
                                            ? track.deliveryAddress
                                            : AddressModel(
                                                latitude: Get.find<
                                                        LocationController>()
                                                    .position
                                                    .latitude
                                                    .toString(),
                                                longitude: Get.find<
                                                        LocationController>()
                                                    .position
                                                    .longitude
                                                    .toString(),
                                                address: Get.find<
                                                        LocationController>()
                                                    .address,
                                              )
                                        : track.deliveryAddress,
                                    track.orderType == 'take_away',
                                    track.orderType == 'parcel',
                                    track.moduleType == 'food',
                                    currentAddress: address,
                                    fromCurrentLocation: true,
                                  );
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(
                                      Dimensions.paddingSizeSmall),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color: Colors.white),
                                  child: Icon(Icons.my_location_outlined,
                                      color: Theme.of(context).primaryColor,
                                      size: 25),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: Dimensions.paddingSizeSmall,
                              left: Dimensions.paddingSizeSmall,
                              right: Dimensions.paddingSizeSmall,
                              child: TrackDetailsViewWidget(
                                  status: track.orderStatus,
                                  track: track,
                                  showChatPermission: showChatPermission,
                                  callback: () async {
                                    _timer?.cancel();
                                    await Get.toNamed(RouteHelper.getChatRoute(
                                      notificationBody: NotificationBodyModel(
                                          deliverymanId: track!.deliveryMan!.id,
                                          orderId: int.parse(widget.orderID!)),
                                      user: User(
                                          id: track.deliveryMan!.id,
                                          fName: track.deliveryMan!.fName,
                                          lName: track.deliveryMan!.lName,
                                          imageFullUrl:
                                              track.deliveryMan!.imageFullUrl),
                                    ));
                                    _startApiCall();
                                  }),
                            ),
                          ]))),
                ),
              )
            : const Center(child: CircularProgressIndicator());
      }),
    );
  }

  void setMarker(
    Store? store,
    DeliveryMan? deliveryMan,
    AddressModel? addressModel,
    bool takeAway,
    bool parcel,
    bool isRestaurant, {
    AddressModel? currentAddress,
    bool fromCurrentLocation = false,
  }) async {
    try {
      BitmapDescriptor restaurantImageData =
          await MarkerHelper.convertAssetToBitmapDescriptor(
        width: (isRestaurant || parcel) ? 30 : 50,
        imagePath: parcel
            ? Images.userMarker
            : isRestaurant
                ? Images.restaurantMarker
                : Images.markerStore,
      );

      BitmapDescriptor deliveryBoyImageData =
          await MarkerHelper.convertAssetToBitmapDescriptor(
        width: 30,
        imagePath: Images.mapDeliveryManIcon,
      );

      BitmapDescriptor destinationImageData =
          await MarkerHelper.convertAssetToBitmapDescriptor(
        width: 30,
        imagePath: takeAway ? Images.myLocationMarker : Images.homeMap,
      );

      LatLngBounds? bounds;
      double rotation = 0;
      if (_controller != null && addressModel != null && store != null) {
        if (double.parse(addressModel.latitude!) <
            double.parse(store.latitude!)) {
          bounds = LatLngBounds(
            southwest: LatLng(double.parse(addressModel.latitude!),
                double.parse(addressModel.longitude!)),
            northeast: LatLng(
                double.parse(store.latitude!), double.parse(store.longitude!)),
          );
          rotation = 0;
        } else {
          bounds = LatLngBounds(
            southwest: LatLng(
                double.parse(store.latitude!), double.parse(store.longitude!)),
            northeast: LatLng(double.parse(addressModel.latitude!),
                double.parse(addressModel.longitude!)),
          );
          rotation = 180;
        }
      }

      LatLng centerBounds = LatLng(
        (bounds!.northeast.latitude + bounds.southwest.latitude) / 2,
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
      );

      if (fromCurrentLocation && currentAddress != null) {
        LatLng currentLocation = LatLng(
          double.parse(currentAddress.latitude!),
          double.parse(currentAddress.longitude!),
        );
        _controller!.moveCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              target: currentLocation, zoom: GetPlatform.isWeb ? 7 : 15),
        ));
      }

      if (!fromCurrentLocation) {
        _controller!.moveCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              target: centerBounds, zoom: GetPlatform.isWeb ? 10 : 17),
        ));
        if (!ResponsiveHelper.isWeb()) {
          zoomToFit(_controller, bounds, centerBounds,
              padding: GetPlatform.isWeb ? 15 : 3);
        }
      }

      _markers = HashSet<Marker>();

      if (currentAddress != null) {
        _markers.add(Marker(
          markerId: const MarkerId('current_location'),
          visible: true,
          draggable: false,
          zIndex: 2,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          position: LatLng(
            double.parse(currentAddress.latitude!),
            double.parse(currentAddress.longitude!),
          ),
          icon: destinationImageData,
        ));
      }

      if (currentAddress == null && addressModel != null) {
        _markers.add(Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(double.parse(addressModel.latitude!),
              double.parse(addressModel.longitude!)),
          infoWindow: InfoWindow(
            title: parcel ? 'sender'.tr : 'Destination'.tr,
            snippet: addressModel.address,
          ),
          icon: destinationImageData,
        ));
      }

      if (store != null) {
        _markers.add(Marker(
          markerId: const MarkerId('store'),
          position: LatLng(
              double.parse(store.latitude!), double.parse(store.longitude!)),
          infoWindow: InfoWindow(
            title: parcel
                ? 'receiver'.tr
                : Get.find<SplashController>()
                        .configModel!
                        .moduleConfig!
                        .module!
                        .showRestaurantText!
                    ? 'store'.tr
                    : 'store'.tr,
            snippet: store.address,
          ),
          icon: restaurantImageData,
        ));
      }

      if (deliveryMan != null) {
        _markers.add(Marker(
          markerId: const MarkerId('delivery_boy'),
          position: LatLng(double.parse(deliveryMan.lat ?? '0'),
              double.parse(deliveryMan.lng ?? '0')),
          infoWindow: InfoWindow(
            title: 'delivery_man'.tr,
            snippet: deliveryMan.location,
          ),
          rotation: rotation,
          icon: deliveryBoyImageData,
        ));
      }

      polyLines.clear();

      if (deliveryMan != null && addressModel != null) {
        LatLng deliveryManLatLng = LatLng(
          double.parse(deliveryMan.lat ?? '0'),
          double.parse(deliveryMan.lng ?? '0'),
        );
        LatLng destinationLatLng = LatLng(
          double.parse(addressModel.latitude!),
          double.parse(addressModel.longitude!),
        );

        polyLines.add(
          Polyline(
            polylineId: const PolylineId('delivery_route'),
            points: [deliveryManLatLng, destinationLatLng],
            width: 4,
            color: Colors.blue,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
        );
      } else if (store != null && addressModel != null) {
        LatLng storeLatLng = LatLng(
          double.parse(store.latitude!),
          double.parse(store.longitude!),
        );
        LatLng destinationLatLng = LatLng(
          double.parse(addressModel.latitude!),
          double.parse(addressModel.longitude!),
        );

        polyLines.add(
          Polyline(
            polylineId: const PolylineId('store_to_destination'),
            points: [storeLatLng, destinationLatLng],
            width: 4,
            color: Colors.green,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
        );
      }
    } catch (_) {}

    setState(() {});
  }

  Future<void> zoomToFit(GoogleMapController? controller, LatLngBounds? bounds,
      LatLng centerBounds,
      {double padding = 0.5}) async {
    bool keepZoomingOut = true;

    while (keepZoomingOut) {
      final LatLngBounds screenBounds = await controller!.getVisibleRegion();
      if (fits(bounds!, screenBounds)) {
        keepZoomingOut = false;
        final double zoomLevel = await controller.getZoomLevel() - padding;
        controller.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: centerBounds,
          zoom: zoomLevel,
        )));
        break;
      } else {
        final double zoomLevel = await controller.getZoomLevel() - 0.1;
        controller.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: centerBounds,
          zoom: zoomLevel,
        )));
      }
    }
  }

  bool fits(LatLngBounds fitBounds, LatLngBounds screenBounds) {
    final bool northEastLatitudeCheck =
        screenBounds.northeast.latitude >= fitBounds.northeast.latitude;
    final bool northEastLongitudeCheck =
        screenBounds.northeast.longitude >= fitBounds.northeast.longitude;

    final bool southWestLatitudeCheck =
        screenBounds.southwest.latitude <= fitBounds.southwest.latitude;
    final bool southWestLongitudeCheck =
        screenBounds.southwest.longitude <= fitBounds.southwest.longitude;

    return northEastLatitudeCheck &&
        northEastLongitudeCheck &&
        southWestLatitudeCheck &&
        southWestLongitudeCheck;
  }

  void _checkPermission(Function onTap) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      showCustomSnackBar('you_have_to_allow'.tr);
    } else if (permission == LocationPermission.deniedForever) {
      Get.dialog(const PermissionDialogWidget());
    } else {
      onTap();
    }
  }

  ///..............live track...................
  LatLng? _previousDeliveryPosition;

  Future<void> updateDeliveryBoyApi() async {
    HttpWithMiddleware http = HttpWithMiddleware.build(middlewares: [
      HttpLogger(logLevel: LogLevel.BODY),
    ]);

    try {
      var response = await http.get(
        Uri.parse(
            "${AppConstants.baseUrl}${AppConstants.getLocationDeliveryBoy}${widget.orderID}"),
        headers: {
          'content-type': 'application/json',
          'accept': 'application/json',
        },
      );

      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status'] == true) {
        liveTrackLatLan = LiveTrack.fromJson(jsonResponse);

        double lat = double.tryParse(
                liveTrackLatLan.location?.latitude?.toString() ?? '') ??
            0;
        double lng = double.tryParse(
                liveTrackLatLan.location?.longitude?.toString() ?? '') ??
            0;
        LatLng currentLatLng = LatLng(lat, lng);

        double rotation = 0;
        if (_previousDeliveryPosition != null) {
          rotation =
              _calculateBearing(_previousDeliveryPosition!, currentLatLng);
        }
        _previousDeliveryPosition = currentLatLng;

        BitmapDescriptor deliveryBoyImageData =
            await MarkerHelper.convertAssetToBitmapDescriptor(
          width: 30,
          imagePath: Images.mapDeliveryManIcon,
        );

        Marker updatedDeliveryMarker = Marker(
          markerId: const MarkerId('delivery_boy'),
          position: currentLatLng,
          infoWindow: InfoWindow(
            title: 'delivery_man'.tr,
            snippet:
                'Lat: ${lat.toStringAsFixed(5)}, Lng: ${lng.toStringAsFixed(5)}',
          ),
          icon: deliveryBoyImageData,
          rotation: rotation,
          anchor: const Offset(0.5, 0.5),
          flat: true,
        );

        _markers
            .removeWhere((marker) => marker.markerId.value == 'delivery_boy');
        _markers.add(updatedDeliveryMarker);

        if (_markers.any((m) => m.markerId.value == 'destination')) {
          Marker destinationMarker =
              _markers.firstWhere((m) => m.markerId.value == 'destination');

          List<LatLng> route = await getRouteCoordinates(
            currentLatLng,
            destinationMarker.position,
          );

          polyLines = {
            Polyline(
              polylineId: const PolylineId('delivery_route'),
              points: route,
              width: 4,
              color: Colors.blue,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
            )
          };
        }
        setState(() {});
      } else {
        debugPrint("Failed to update location: ${jsonResponse['message']}");
      }
    } catch (error) {
      debugPrint("Error in updateLocationApi: $error");
    }
  }

  double _calculateBearing(LatLng start, LatLng end) {
    double lat1 = start.latitude * (pi / 180);
    double lat2 = end.latitude * (pi / 180);
    double deltaLng = (end.longitude - start.longitude) * (pi / 180);

    double y = sin(deltaLng) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLng);
    double bearing = atan2(y, x) * (180 / pi);
    return (bearing + 360) % 360;
  }

  Future<List<LatLng>> getRouteCoordinates(
      LatLng origin, LatLng destination) async {
    // const apiKey = 'AIzaSyCaCSJ0BZItSyXqBv8vpD1N4WBffJeKhLQ'; // Replace this!
    // const apiKey = 'AIzaSyD7fSNx2zaxcHmraMpgojfk18m3y-Spk7Y'; // Replace this!
    final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=driving&key=${AppConstants.googleMapKey}");

    final response = await HttpClient().getUrl(url).then((req) => req.close());
    final responseBody = await response.transform(utf8.decoder).join();
    final jsonData = jsonDecode(responseBody);

    if (jsonData['status'] == 'OK') {
      final points = jsonData['routes'][0]['overview_polyline']['points'];
      return decodePolyline(points);
    } else {
      print("Route fetch failed: ${jsonData['status']}");
      return [];
    }
  }
}
