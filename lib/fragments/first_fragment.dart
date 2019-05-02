import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:vifaa_express/Models/driver.dart';
import 'package:vifaa_express/Models/fares.dart';
import 'package:vifaa_express/Models/favorite_places.dart';
import 'package:vifaa_express/Models/general_promotion.dart';
import 'package:vifaa_express/Models/payment_method.dart';
import 'package:vifaa_express/Models/trip.dart';
import 'package:vifaa_express/Users/home_user.dart';
import 'package:vifaa_express/Users/review_driver.dart';
import 'package:vifaa_express/Utility/MyColors.dart';
import 'package:vifaa_express/Utility/Utils.dart';
import 'package:vifaa_express/fragments/payment.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

//import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:google_maps_webservice/places.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:screen/screen.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:latlong/latlong.dart' as dist;
import 'package:flutter_form_builder/flutter_form_builder.dart';

class MapFragment extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MapFragment();
}

const kGoogleApiKey =
    "AIzaSyBEtkYnNolbg_c7aKZkFuqlq_V_4TIyveI"; //"AIzaSyBy5V3DT_MgUZCoTXYLIpW6d_aQjF8Ql6E";
const api_key =
    "AIzaSyBEtkYnNolbg_c7aKZkFuqlq_V_4TIyveI"; //"AIzaSyBy5V3DT_MgUZCoTXYLIpW6d_aQjF8Ql6E";
GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);
final homeScaffoldKey = GlobalKey<ScaffoldState>();
final searchScaffoldKey = GlobalKey<ScaffoldState>();
String _email = '', _number = '', _name = '', _msg = '', _country = '';
String address_type = 'current';
bool isSavedPlace = false;

enum DialogType { request, arriving, driving }

class _MapFragment extends State<MapFragment> {
  DialogType dialogType = DialogType.request;

  var _startLocation;
  loc.LocationData _currentLocation;

  StreamSubscription<loc.LocationData> _locationSubscription;

  var _location;
  var mLocation = new loc.Location();
  bool _permission = false;
  String error;
  final dateFormat = DateFormat("EEEE, MMMM d, yyyy 'at' h:mma");
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  PaymentMethods _method = null;
  GeneralPromotions _general_promotion = null;
  Prediction getPrediction = null;

  FavoritePlaces current_location = null;
  FavoritePlaces destination_location = null;

  GoogleMapController mapController;

  //Completer<GoogleMapController> _controller = Completer();
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  MarkerId selectedMarker;
  int _markerIdCounter = 1;

  String current_trip_id;
  CurrentTrip currentTrip;
  DriverDetails driverDetails;

  bool isCarAvail = false;
  bool isBikeAvail = false;
  Utils mUtils = new Utils();

  void _onMapCreated(GoogleMapController controller) {
    //_controller.complete(controller);
    setState(() {
      mapController = controller;
    });
  }

  bool isCash = false,
      isRefreshing = true,
      isBottomSheet = false,
      _inAsyncCall = false;
  String payment_type = '';
  String promotion_type = '';
  double request_progress = null;
  String trip_distance = '0 km', trip_duration = '0 min';
  int trip_calculation;
  Fares car_fares = null;
  Fares bike_fare = null;
  bool isLoaded = false, isScheduled = false, isAlreadyBooked = false;
  bool isButtonDisabled = false;
  String errorLoaded = '';

  String ride_option_type_id = '', _date_scheduled = '';
  bool ride_option_selected_car = false;
  bool ride_option_selected_bike = false;

  String appBarTitle = 'Driver arrives in --';
  bool isPromoApplied = false;
  String _currency = '', _currencyCode = '';
  int _max_distance = 0;
  List<dynamic> _driverSnapshots = new List();
  String button_title = 'Request VifaaExpress';
  String type_of_item = '', dimensions = '', who_pays = '', receiver_number = '';
  bool merchant_pays = false;
  bool receiver_pays = false;

  double bottom_height = 200;
  TabController _controller;

  double mCurrentLatitude = 0, mCurrentLongitude = 0;


  @override
  void dispose() {
    _locationSubscription.cancel();
  }

  @override
  void initState() {
    // TODO: implement initState
    //super.initState();
    Screen.keepOn(true);
    listenForDestinationEntered();
    initPlatformState();

    _locationSubscription =
        mLocation.onLocationChanged().listen((loc.LocationData result) {
      double lat = result.latitude;
      double lng = result.longitude;
      print('lat = $lat\nlng = $lng');
      setState(() {
        mCurrentLatitude = lat;
        mCurrentLongitude = lng;
        if (mapController != null) {
          updateMapCamera(lat, lng);
        }
        _currentLocation = result;
      });
    });
    //new Utils().initializeRemoteConfig();
  }

  initPlatformState() async {
    try {
      _permission = await mLocation.hasPermission();
      _location = await mLocation.getLocation();
      error = null;
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        error = 'Permission denied';
      } else if (e.code == 'PERMISSION_DENIED_NEVER_ASK') {
        error =
            'Permission denied - please ask the user to enable it from the app settings';
      }
    }
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
    setState(() {
      _startLocation = _location;
    });
  }

  Future<void> getBookingFares() async {
    DatabaseReference ref =
        FirebaseDatabase.instance.reference().child('settings');
    await ref
        .child('fees')
        .child(_country)
        .child('booking_fee')
        .child('car')
        .once()
        .then((val) {
      setState(() {
        car_fares = Fares.fromSnapshot(val);
      });
    });
    await ref
        .child('fees')
        .child(_country)
        .child('booking_fee')
        .child('bike')
        .once()
        .then((val) {
      setState(() {
        bike_fare = Fares.fromSnapshot(val);
      });
    });
    await ref.child('availability').child(_country).once().then((val) {
      setState(() {
        isCarAvail = val.value['isCarAvailable'];
        isBikeAvail = val.value['isBikeAvailable'];
      });
    });

    await ref.child('searching').child(_country).once().then((val) {
      setState(() {
        _max_distance =
            int.parse(val.value['max_distance_to_merchant'].toString());
      });
    });
  }

  void updateMapCamera(double lat, double lng) {
    markers.clear();
    if (dialogType == DialogType.request) {
      setState(() {
        isRefreshing = true;
        if (address_type != 'destination') address_type = 'current';
      });
      mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          bearing: 90.0,
          target: LatLng(lat, lng),
          tilt: 30.0,
          zoom: 15.0,
        ),
      ));
      final MarkerId markerId = MarkerId('request');
      final Marker marker = Marker(
          markerId: markerId,
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(title: 'Your location', snippet: ''),
          icon: BitmapDescriptor.defaultMarker,
          alpha: 1.0,
          draggable: false);
      markers[markerId] = marker;

      if(_driverSnapshots.length > 0) {
        print('I dey here');
        int driver_index = 0;
        _driverSnapshots.forEach((driver) {
          Map<dynamic, dynamic> dd = driver['signup'];
          Map<dynamic, dynamic> driverD = driver['location'];
          String vehicle_type = dd['vehicle_type'].toString().toLowerCase();
          double driverLat = double.parse(driverD['latitude'].toString());
          double driverLng = double.parse(driverD['longitude'].toString());
          final dist.Distance distance = new dist.Distance();
          final num km = distance.as(
              dist.LengthUnit.Kilometer,
              new dist.LatLng(mCurrentLatitude,
                  mCurrentLongitude),
              new dist.LatLng(driverLat, driverLng));
          final MarkerId markerId = MarkerId('driver_display_$driver_index');
          final Marker marker = Marker(
              markerId: markerId,
              position: LatLng(driverLat, driverLng),
              infoWindow: InfoWindow(title: 'Driver location', snippet: '${km.toInt()}km away'),
              icon: (vehicle_type.toLowerCase() == 'car')
                  ? BitmapDescriptor.fromAsset('assets/vecar.png')
                  : BitmapDescriptor.fromAsset('assets/vebike.png'),
              alpha: 1.0,
              draggable: false);
          markers[markerId] = marker;
          driver_index = driver_index + 1;
        });
      }
      getMapLocation(lat, lng);
    }
    if (dialogType == DialogType.arriving) {
      if (!_locationSubscription.isPaused) {
        _locationSubscription.pause();
      }
      mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          bearing: 90.0,
          target: LatLng(lat, lng),
          tilt: 30.0,
          zoom: 20.0,
        ),
      ));
      final MarkerId markerId = MarkerId('arriving');
      final Marker marker = Marker(
          markerId: markerId,
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
              title: 'Driver location',
              snippet: (driverDetails.fullname == null)
                  ? ''
                  : '${driverDetails.fullname}'),
          icon: (currentTrip.vehicle_type.toLowerCase() == 'car')
              ? BitmapDescriptor.fromAsset('assets/vecar.png')
              : BitmapDescriptor.fromAsset('assets/vebike.png'),
          alpha: 1.0,
          draggable: false);
      markers[markerId] = marker;
//      mapController.addMarker(MarkerOptions(
//          position: LatLng(lat, lng),
//          alpha: 1.0,
//          draggable: false,
//          icon: (currentTrip.vehicle_type.toLowerCase() == 'car')
//              ? BitmapDescriptor.fromAsset('assets/vecar.png')
//              : BitmapDescriptor.fromAsset('assets/vebike.png'),
//          infoWindowText: InfoWindowText(
//              'Driver location',
//              (driverDetails.fullname == null)
//                  ? ''
//                  : '${driverDetails.fullname}')));
    }
    if (dialogType == DialogType.driving) {
      if (!_locationSubscription.isPaused) {
        _locationSubscription.pause();
      }
      final MarkerId markerId = MarkerId('driving');
      final Marker marker = Marker(
          markerId: markerId,
          position: LatLng(double.parse(destination_location.latitude),
              double.parse(destination_location.longitude)),
          infoWindow: InfoWindow(
              title: 'Driver Destination',
              snippet: '${destination_location.loc_name}'),
          icon: BitmapDescriptor.defaultMarker,
          alpha: 1.0,
          draggable: false);
      markers[markerId] = marker;
//      mapController.addMarker(MarkerOptions(
//          position: LatLng(double.parse(destination_location.latitude),
//              double.parse(destination_location.longitude)),
//          alpha: 1.0,
//          draggable: false,
//          icon: BitmapDescriptor.defaultMarker,
//          infoWindowText: InfoWindowText(
//              'Your Destination', '${destination_location.loc_name}')));
    }
  }

  Future<void> getMapLocation(double lat, double lng) async {
    String url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$api_key';
    http.get(url).then((res) async {
      Map<String, dynamic> resp = json.decode(res.body);
      String status = resp['status'];
      //new Utils().neverSatisfied(context, 'hello', res.body); /////////////////////////////////
      if (status != null && status == 'OK') {
        Map<String, dynamic> result = resp['results'][0];
        String place_id = result['place_id'];
        PlacesDetailsResponse detail =
            await _places.getDetailsByPlaceId(place_id);
        String loc_name = detail.result.name;
        String loc_address = detail.result.formattedAddress;
        String _lat = detail.result.geometry.location.lat.toString();
        String _lng = detail.result.geometry.location.lng.toString();
        setState(() {
          if (address_type == 'current') {
            current_location =
                FavoritePlaces('', loc_name, loc_address, '$_lat', '$_lng', '');
          }
//          else {
//            destination_location =
//                FavoritePlaces('', loc_name, loc_address, '$_lat', '$_lng', '');
//          }
          isRefreshing = false;
        });
      } else {
        setState(() {
          isRefreshing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _prefs.then((pref) {
      setState(() {
        _email = pref.getString('email');
        _name = pref.getString('fullname');
        _number = pref.getString('number');
        _msg = pref.getString('msgId');
        _country = pref.getString('country');
        if (pref.getString('payment') != null) {
          payment_type = pref.getString('payment');
          if (pref.getString('payment') == 'cash') {
            isCash = true;
            payment_type = 'cash';
          }
        } else {
          isCash = true;
          payment_type = 'cash';
        }
        promotion_type = (pref.getString('promotion_type') != null)
            ? pref.getString('promotion_type')
            : '';
      });
    });
    mUtils.initializeRemoteConfig(_country).whenComplete(() {
      setState(() {
        _currency = mUtils.fetchCurrency();
        _currencyCode = mUtils.fetchCurrencyCode();
      });
    });
//    Query _driverRef = FirebaseDatabase.instance
//        .reference()
//        .child('drivers')
//        .orderByChild('signup/country')
//        .equalTo(_country);
//    _driverRef.once().then((data) {
//      if (data.value != null) {
//        Map<dynamic, dynamic> values = data.value;
//        values.forEach((key, vals) {
//          Map<dynamic, dynamic> driverD = vals['location'];
//          Map<dynamic, dynamic> dd = vals['signup'];
//          print(
//              '====================${dd['email'].toString()}===================');
//        });
//      } else {
//        print('=======================not available=======================');
//      }
//    });
//    new Utils().fetchCurrency(_country).then((cur) {
//      setState(() {
//        _currency = cur;
//      });
//    });
//    new Utils().fetchCurrencyCode(_country).then((code) {
//      setState(() {
//        _currencyCode = code;
//      });
//    });
    getBookingFares();
    loadPayment();
    loadPromotion(); //change payment method
    checkAlreadyBooked();
    _getAvailableDrivers();
    // TODO: implement build
    return new Scaffold(
        appBar: (dialogType == DialogType.arriving ||
                dialogType == DialogType.driving)
            ? new AppBar(
                title: new Text(appBarTitle),
              )
            : null,
        //appBar: new AppBar(title: Text('Hello Map'),leading: new IconButton(icon: Icon(Icons.menu, color: Colors.white,), onPressed: (){}),),
        body: ModalProgressHUD(
            inAsyncCall: _inAsyncCall,
            opacity: 0.5,
            progressIndicator: CircularProgressIndicator(),
            color: Color(MyColors().button_text_color),
            child: new Container(
                child: new Stack(
              overflow: Overflow.clip,
              fit: StackFit.passthrough,
              children: <Widget>[
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition:
                      CameraPosition(target: LatLng(0.0, 0.0)),
                  compassEnabled: false,
                  mapType: MapType.normal,
                  myLocationEnabled: true,
                  //trackCameraPosition: true,
                  rotateGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                  markers: Set<Marker>.of(markers.values),
                ),
                (dialogType == DialogType.arriving &&
                        dialogType == DialogType.driving)
                    ? Text('')
                    : new Container(
                        margin:
                            EdgeInsets.only(top: 60.0, left: 13.0, right: 13.0),
                        child: new Column(
                          children: <Widget>[
                            new Container(
                                color: Color(MyColors().primary_color),
                                child: new ListTile(
                                  leading: (!isRefreshing)
                                      ? Icon(
                                          Icons.my_location,
                                          color: Colors.green,
                                        )
                                      : new Container(
                                          height: 18.0,
                                          width: 18.0,
                                          child: CircularProgressIndicator(
                                            value: null,
                                          ),
                                        ),
                                  trailing: Icon(
                                    Icons.keyboard_arrow_right,
                                    color: Colors.white,
                                  ),
                                  title: Text(
                                    (current_location == null)
                                        ? 'Enter pickup location'
                                        : current_location.loc_name,
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16.0),
                                  ),
                                  onTap: (currentTrip == null)
                                      ? () {
                                          setState(() {
                                            address_type = 'current';
                                          });
                                          _buttonTapped();
                                        }
                                      : null,
                                )),
                            new Container(
                              height: 2.0,
                            ),
                            new Container(
                                color: Color(MyColors().primary_color),
                                child: new ListTile(
                                  leading: Icon(
                                    Icons.directions,
                                    color: Colors.red,
                                  ),
                                  trailing: Icon(
                                    Icons.keyboard_arrow_right,
                                    color: Colors.white,
                                  ),
                                  title: Text(
                                    (destination_location == null)
                                        ? 'Enter Destination'
                                        : destination_location.loc_name,
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16.0),
                                  ),
                                  onTap: (currentTrip == null)
                                      ? () {
                                          setState(() {
                                            address_type = 'destination';
                                          });
                                          _buttonTapped();
                                        }
                                      : null,
                                )),
                          ],
                        )),
                (isBottomSheet)
                    ? new Container(
                        margin: EdgeInsets.only(
                            top: (MediaQuery.of(context).size.height -
                                bottom_height)),
                        alignment: Alignment.bottomCenter,
                        height: bottom_height,
                        width: MediaQuery.of(context).size.width,
                        color: Colors.white,
                        child: ListView(
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          children: bottomSheetWidgets1() +
                              bottomSheetWidgets2() +
                              bottomSheetWidgets3(),
                        ),
                      )
                    : new Text(''),
                (currentTrip != null && driverDetails != null)
                    ? dialogTypeAfterRequest()
                    : new Text('')
              ],
            ))));
  }

  List<Widget> bottomSheetWidgets1() {
    return [
      new LinearProgressIndicator(
        value: request_progress,
        valueColor:
            AlwaysStoppedAnimation<Color>(Color(MyColors().secondary_color)),
      ),
      (isLoaded)
          ? vehicleTypeOptions('car', 'vecar.png', 'VifaaExpress Van', '1-4',
              getPrice('car'), ride_option_selected_car, isCarAvail)
          : new Text(''),
      (isLoaded)
          ? vehicleTypeOptions('bike', 'vebike.png', 'VifaaExpress Bike', '1',
              getPrice('bike'), ride_option_selected_bike, isBikeAvail)
          : new Text(''),
    ];
  }

  List<Widget> bottomSheetWidgets2() {
    return (isLoaded) ? _otherOptions() : [new Text('')];
  }

  List<Widget> bottomSheetWidgets3() {
    return [
      new Container(
        margin: EdgeInsets.only(left: 20.0, right: 20.0, top: 5.0),
        child: Divider(
          height: 1.0,
          color: Colors.black,
        ),
      ),
      new ListTile(
          title: Row(
            children: <Widget>[
              (!isCash)
                  ? Text('${(_method != null) ? '•••• ${_method.number}' : ''}')
                  : new Text('Cash',
                      style: TextStyle(color: Colors.black, fontSize: 16.0)),
              //(isPromoApplied) ? buildPromo('Promo Applied') : Text('')
            ],
          ),
          onTap: () {
            _changePaymentMethod();
          },
          leading: (!isCash)
              ? new Icon(
                  Icons.credit_card,
                  color: Color(MyColors().secondary_color),
                )
              : new Icon(
                  Icons.monetization_on,
                  color: Color(MyColors().secondary_color),
                ),
          trailing: new FlatButton.icon(
              onPressed: () {
                DatePicker.showDateTimePicker(context, showTitleActions: true,
                    //min: DateTime.now(),
                    onChanged: (date) {
                  _date_scheduled = date.toString();
                }, onConfirm: (date) {
                  _date_scheduled = date.toString();
                  setState(() {
                    isScheduled = true;
                    button_title = 'Confirm Booking';
                  });
                }, currentTime: DateTime.now(), locale: LocaleType.en);
              },
              icon: Icon(
                (isScheduled) ? Icons.event_available : Icons.event,
                color: (isScheduled) ? Colors.green : Colors.black,
              ),
              label: new Text(
                'Schedule',
                style: TextStyle(
                    fontSize: 16.0,
                    color: (isScheduled) ? Colors.green : Colors.black),
              ))),
      new Container(
        margin: EdgeInsets.only(left: 20.0, right: 20.0),
        child: Padding(
          padding: EdgeInsets.only(top: 0.0, left: 0.0, right: 0.0),
          child: new RaisedButton(
            child: new Text(button_title,
                style: new TextStyle(
                    fontSize: 18.0,
                    color: Color(MyColors().button_text_color))),
            color: Color(MyColors().secondary_color),
            disabledColor: Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0)),
            ),
            onPressed: (isLoaded) ? _confirmBooking : null,
            //buttonDisabled
            padding: EdgeInsets.all(15.0),
          ),
        ),
      ),
      new Container(
        height: 5.0,
      ),
      new Container(
        child: Center(
          child: new FlatButton(
            onPressed: () {
              setModeForDestination('none');
              setState(() {
                isBottomSheet = false;
                destination_location = null;
              });
            },
            child: new Text('Cancel',
                style: new TextStyle(
                    fontSize: 14.0,
                    color: Color(MyColors().button_text_color))),
          ),
        ),
      )
    ];
  }

  Widget buildPromo(String value) {
    return Container(
        height: 80.0,
        width: 30.0,
        child: Center(
            child: Container(
          height: 80.0,
          width: 30.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Color(MyColors().secondary_color),
              border: Border(
                  top: BorderSide(
                      color: Color(MyColors().secondary_color), width: 2.0),
                  left: BorderSide(
                      color: Color(MyColors().secondary_color), width: 2.0),
                  right: BorderSide(
                      color: Color(MyColors().secondary_color), width: 2.0),
                  bottom: BorderSide(
                      color: Color(MyColors().secondary_color), width: 2.0)),
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          child: Center(
            child: Text(
              '$value',
              style: TextStyle(
                color: Color(MyColors().wrapper_color),
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        )));
  }

  Widget vehicleTypeOptions(String id, String image, String title, String seats,
      String price_range, bool isSelected, bool isAvail) {
    return new Container(
      padding: EdgeInsets.all(0.0),
      margin: EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0),
      decoration: (isSelected)
          ? BoxDecoration(
              border: Border.all(
                  color: Color(MyColors().secondary_color),
                  width: 1.5,
                  style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(10.0))
          : null,
      child: new ListTile(
        leading: new Image.asset(image, height: 64.0, width: 53.0),
        title: new Text(
          title,
          style: TextStyle(
            fontSize: 12.0,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: new Row(
          children: <Widget>[
            new Icon(
              Icons.person,
              size: 18.0,
            ),
            new Text(
              seats,
              style: TextStyle(
                fontSize: 10.0,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: new Column(
          children: <Widget>[
            new Text(
              price_range,
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        onTap: () {
          if (!isAvail) {
            new Utils().neverSatisfied(context, 'Error',
                'Sorry this option is not available at the moment. Try again later.');
            return;
          }
          setState(() {
            ride_option_type_id = id;
            if (id == 'car') {
              ride_option_selected_car = true;
              ride_option_selected_bike = false;
            } else {
              ride_option_selected_bike = true;
              ride_option_selected_car = false;
            }
          });
        },
        onLongPress: () {
          _infoPressed(id);
        },
      ),
    );
  }

  Widget marginContainer(bool isTop, {Widget child}) {
    return Container(
        margin:
            EdgeInsets.only(left: 20.0, right: 20.0, top: (isTop) ? 5.0 : 0.0),
        child: child);
  }

  List<Widget> _otherOptions() {
//    Container(
//        margin: EdgeInsets.only(left: 20.0, right: 20.0, top: 5.0),
//    child: Column(children: <Widget>
    return [
      marginContainer(true,
          child: Divider(
            height: 1.0,
            color: Colors.black,
          )),
      marginContainer(true,
          child: Text(
            'Type of Item:',
            style: TextStyle(fontSize: 16.0, color: Colors.black),
          )),
      marginContainer(false,
          child: FormBuilder(context, onChanged: (value) {
            setState(() {
              type_of_item = value['dropdown'].toString();
            });
            //print(type_of_item);
          }, autovalidate: true, controls: [
            FormBuilderInput.dropdown(
              attribute: "dropdown",
              // require: true,
              decoration: InputDecoration(
                  labelText: "", hintText: "Choose type of item"),
              options: [
                FormBuilderInputOption(value: "Document"),
                FormBuilderInputOption(value: "Food"),
                FormBuilderInputOption(value: "Clothing"),
              ],
            ),
          ])),
      marginContainer(true,
          child: Text(
            'Dimensions:',
            style: TextStyle(fontSize: 16.0, color: Colors.black),
          )),
      marginContainer(false,
          child: FormBuilder(context, onChanged: (value) {
            setState(() {
              dimensions = value['dimensions'].toString();
            });
            //print(dimensions);
          }, autovalidate: false, controls: [
            FormBuilderInput.textField(
              type: FormBuilderInput.TYPE_TEXT,
              require: false,
              attribute: "dimensions",
              decoration: InputDecoration(
                  labelText: "",
                  hintText: "Enter item dimension here (optional)"),
            )
          ])),
      marginContainer(true,
          child: Text(
            "Receiver's number:",
            style: TextStyle(fontSize: 16.0, color: Colors.black),
          )),
      marginContainer(false,
          child: FormBuilder(context, onChanged: (value) {
            setState(() {
              receiver_number = value['receiver_number'].toString();
            });
            //print(dimensions);
          }, autovalidate: false, controls: [
            FormBuilderInput.textField(
              type: FormBuilderInput.TYPE_PHONE,
              require: true,
              attribute: "receiver_number",
              decoration: InputDecoration(
                  labelText: "",
                  hintText: "Enter the number of the receiver"),
            )
          ])),
      marginContainer(true,
          child: Text(
            'Who makes payment:',
            style: TextStyle(fontSize: 16.0, color: Colors.black),
          )),
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Container(
              margin: EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0),
              decoration: BoxDecoration(
                  border: Border.all(
                      color: (merchant_pays)
                          ? Color(MyColors().secondary_color)
                          : Colors.grey,
                      width: 1.5,
                      style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(10.0)),
              child: GestureDetector(
                child: Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Text(
                      'MERCHANT',
                      style: TextStyle(
                        fontSize: 18.0,
                      ),
                    )),
                onTap: () {
                  setState(() {
                    merchant_pays = true;
                    receiver_pays = false;
                    who_pays = 'merchant';
                  });
                },
              )),
          Container(
              margin: EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0),
              decoration: BoxDecoration(
                  border: Border.all(
                      color: (receiver_pays)
                          ? Color(MyColors().secondary_color)
                          : Colors.grey,
                      width: 1.5,
                      style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(10.0)),
              child: GestureDetector(
                child: Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Text('RECEIVER',
                        style: TextStyle(
                          fontSize: 18.0,
                        ))),
                onTap: () {
                  setState(() {
                    merchant_pays = false;
                    receiver_pays = true;
                    who_pays = 'receiver';
                  });
                },
              )),
        ],
      )
    ];
  }

  void _infoPressed(String type) {
    if (type == 'car') {
      new Utils()
          .displayFareInformation(context, 'Van Fares', car_fares, _currency);
    } else {
      new Utils()
          .displayFareInformation(context, 'Bike Fares', bike_fare, _currency);
    }
  }

  Widget dialogTypeAfterRequest() {
    if (dialogType == DialogType.arriving || dialogType == DialogType.driving) {
      return new Container(
        margin:
            EdgeInsets.only(top: (MediaQuery.of(context).size.height - 300)),
        alignment: Alignment.bottomCenter,
        height: 300.0,
        width: MediaQuery.of(context).size.width,
        color: Colors.white,
        child: new Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            new ListTile(
              leading: new Column(
                children: <Widget>[
                  new Container(
                      width: 60.0,
                      height: 60.0,
                      decoration: new BoxDecoration(
                          shape: BoxShape.circle,
                          image: new DecorationImage(
                            fit: BoxFit.cover,
                            image: (driverDetails != null)
                                ? new NetworkImage(driverDetails.image)
                                : AssetImage('user_dp.png'),
                          ))),
                  new Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        color: Colors.grey,
                        border: Border(
                            top: BorderSide(
                                color: Color(MyColors().secondary_color),
                                width: 2.0),
                            left: BorderSide(
                                color: Color(MyColors().secondary_color),
                                width: 2.0),
                            right: BorderSide(
                                color: Color(MyColors().secondary_color),
                                width: 2.0),
                            bottom: BorderSide(
                                color: Color(MyColors().secondary_color),
                                width: 2.0)),
                        borderRadius: BorderRadius.all(Radius.circular(5.0))),
                    width: 50.0,
                    height: 25.0,
                    child: new Row(
                      children: <Widget>[
                        new Icon(
                          Icons.star,
                          size: 18.0,
                          color: Color(MyColors().wrapper_color),
                        ),
                        new Text(
                          (driverDetails != null)
                              ? driverDetails.rating
                              : '0.0',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Color(MyColors().wrapper_color),
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
              isThreeLine: true,
              title: new Text(
                driverDetails.fullname,
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: new Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    height: 5.0,
                  ),
                  new Text(driverDetails.vehicle_model,
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      )),
                  new Text(driverDetails.vehicle_plate_number,
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ))
                ],
              ),
              trailing: new IconButton(
                  icon: Icon(Icons.call),
                  onPressed: () {
                    _launchURL(driverDetails.number);
                  }),
            ),
            new Container(
              height: 10.0,
            ),
            new Divider(
              height: 1.0,
              color: Colors.grey,
            ),
            new Container(
              color: Colors.white,
              child: new Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  new Row(
                    children: <Widget>[
                      new FlatButton.icon(
                        onPressed: null,
                        icon: (currentTrip.card_trip)
                            ? new Icon(
                                Icons.credit_card,
                                color: Color(MyColors().secondary_color),
                              )
                            : new Icon(
                                Icons.monetization_on,
                                color: Color(MyColors().secondary_color),
                              ),
                        label: (currentTrip.card_trip)
                            ? Text(
                                '${(currentTrip.payment_method != null) ? currentTrip.payment_method.number : ''}',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w900),
                              )
                            : new Text('Cash',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w900)),
                      )
                    ],
                  ),
                  new Text(
                    currentTrip.price_range,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  (currentTrip.promo_used)
                      ? new Text(
                          (currentTrip.promotion.discount_type == 'percent')
                              ? '-${currentTrip.promotion.discount_value}%'
                              : '-$_currency${currentTrip.promotion.discount_value} Promo',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : new Text(''),
                  new FlatButton(
                    onPressed: () {
                      _confirmCancelTrip();
                    },
                    child: new Text('Cancel',
                        style: new TextStyle(
                            fontSize: 14.0,
                            color: Color(MyColors().button_text_color))),
                  )
                ],
              ),
            )
          ],
        ),
      );
    } else {
      return new Text('');
    }
  }

  void _confirmCancelTrip() {
    showDialog<Null>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text('Confirmation'),
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[
                new Text('Are you sure you want to cancel this ride?'),
              ],
            ),
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text(
                'Continue',
                style: TextStyle(color: Color(MyColors().button_text_color)),
              ),
              onPressed: () {
                setState(() {
                  _inAsyncCall = true;
                  isBottomSheet = false;
                  destination_location = null;
                  dialogType = DialogType.request;
                  trip_distance = '0 km';
                  trip_duration = '0 min';
                });
                setModeForDestination('none');
                deleteTripStatusForUser();
              },
            ),
          ],
        );
      },
    );
  }

  void _getAvailableDrivers() {
    try {
      Query driverRef = FirebaseDatabase.instance
          .reference()
          .child('drivers')
          .orderByChild('signup/country')
          .equalTo(_country);
      driverRef.onValue.listen((snapshot) {
        if (snapshot.snapshot.value != null) {
          _driverSnapshots.clear();
          Map<dynamic, dynamic> values = snapshot.snapshot.value;
          values.forEach((key, vals) {
            Map<dynamic, dynamic> driverD = vals['location'];
            Map<dynamic, dynamic> dd = vals['signup'];
            //print('====================${dd['email'].toString()}===================');
            String vehicle_type = dd['vehicle_type'].toString().toLowerCase();
            bool verified = dd['userVerified'];
            double driverLat = double.parse(driverD['latitude'].toString());
            double driverLng = double.parse(driverD['longitude'].toString());
            final dist.Distance distance = new dist.Distance();
            final num km = distance.as(
                dist.LengthUnit.Kilometer,
                new dist.LatLng(mCurrentLatitude,
                    mCurrentLongitude), //double.parse(current_location.latitude
                new dist.LatLng(driverLat, driverLng));

            //print('=========$vehicle_type===========${km.toInt()}==========$ride_option_type_id=========$verified==========$_max_distance=========');
            if (km.toInt() <= _max_distance &&
                verified) {
              setState(() {
                _driverSnapshots.add(vals);
              });
            }
          });
//          if (_driverSnapshots.length > 1) {
//            sendEachDriverRequest(0);
//          } else {
//            _displayRequestError(
//                'No dispatcher rider available to accept your request. Please contact customer care.');
//          }
        } else {
          //_displayRequestError('No dispatcher rider available to accept your request. Please contact customer care.');
        }
      });
    } catch (e) {
      _displayRequestError(e.toString());
    }
  }

  Future<void> sendEachDriverRequest(int index) async {
    setState(() {
      _inAsyncCall = true;
    });
    Map<dynamic, dynamic> vals = _driverSnapshots[index];
    Map<dynamic, dynamic> driverD = vals['signup'];
    String email = driverD['email'].toString();
    String notification_id = driverD['msgId'].toString();
    String vehicle_type = driverD['vehicle_type'].toString().toLowerCase();
    if(ride_option_type_id == vehicle_type) {
      DatabaseReference tripRef = FirebaseDatabase.instance
          .reference()
          .child('drivers/${email.replaceAll('.', ',')}');
      //String id = tripRef.push().key;
      tripRef.child('request').set({
        'id': incoming_id,
        'currency': _currency,
        'country': _country,
        'dimensions': dimensions,
        'item_type': type_of_item,
        'payment_by': who_pays,
        'receiver_number':receiver_number,
        'current_location': current_location.toJSON(),
        'destination': destination_location.toJSON(),
        'trip_distance': trip_distance,
        'trip_duration': trip_duration,
        'payment_method': (!isCash) ? _method.toJSON() : 'cash',
        'vehicle_type': ride_option_type_id,
        'promotion': (_general_promotion != null)
            ? _general_promotion.toJSON()
            : 'no_promo',
        'card_trip': (!isCash) ? true : false,
        'promo_used': (_general_promotion != null) ? true : false,
        'scheduled_date': _date_scheduled,
        'status': 'incoming',
        'created_date': DateTime.now().toString(),
        'price_range': getPrice(ride_option_type_id),
        'trip_total_price': '',
        'fare':
        (ride_option_selected_car) ? car_fares.toJSON() : bike_fare.toJSON(),
        'assigned_driver': 'none',
        'rider_email': _email,
        'rider_name': _name,
        'rider_number': _number,
        'rider_msgId': _msg
      });
      mUtils.sendPushNotification(notification_id, 'VifaaExpress',
          'You have an incoming request. Accept the request now.')
          .whenComplete(() {
        Timer(Duration(seconds: 20), () {
          if (currentTrip == null) {
            tripRef.child('request').remove();
            int next_index = index + 1;
            if (next_index <= (_driverSnapshots.length - 1)) {
              sendEachDriverRequest(next_index);
            } else {
              _displayRequestError(
                  'No dispatcher rider available to accept your request. Please contact customer care.');
            }
          } else {
            setState(() {
              _inAsyncCall = false;
            });
            Route route = MaterialPageRoute(
                builder: (context) => UserHomePage());
            Navigator.pushReplacement(context, route);
          }
        });
      });
    }else {
      int next_index = index + 1;
      if (next_index <= (_driverSnapshots.length - 1)) {
        sendEachDriverRequest(next_index);
      } else {
        _displayRequestError(
            'No dispatcher rider available to accept your request. Please contact customer care.');
      }
    }
  }

  void _displayRequestError(String text) {
    if (incoming_id.isNotEmpty) {
      DatabaseReference ref = FirebaseDatabase.instance
          .reference()
          .child('users')
          .child(_email.replaceAll('.', ','))
          .child('trips');
      ref.child('status').remove().then((complete) {
        ref.child('incoming/$incoming_id').remove();
      });
    }
    setState(() {
      _inAsyncCall = false;
    });
    new Utils().neverSatisfied(context, 'Message', text);
  }

  Future<void> deleteTripStatusForUser() async {
    try {
      DatabaseReference ref = FirebaseDatabase.instance
          .reference()
          .child('users')
          .child(_email.replaceAll('.', ','))
          .child('trips');
      await ref.child('past/${currentTrip.id}').set({
        'id': currentTrip.id,
        'current_location': current_location.toJSON(),
        'currency': currentTrip.currency,
        'country': currentTrip.country,
        'dimensions': currentTrip.dimensions,
        'item_type': currentTrip.item_type,
        'payment_by': currentTrip.payment_by,
        'receiver_number': currentTrip.receiver_number,
        'destination': destination_location.toJSON(),
        'trip_distance': currentTrip.trip_distance,
        'trip_duration': currentTrip.trip_duration,
        'payment_method': (currentTrip.card_trip)
            ? currentTrip.payment_method.toJSON()
            : 'cash',
        'vehicle_type': currentTrip.vehicle_type,
        'promotion': (currentTrip.promo_used)
            ? currentTrip.promotion.toJSON()
            : 'no_promo',
        'card_trip': currentTrip.card_trip ? true : false,
        'promo_used': currentTrip.promo_used ? true : false,
        'scheduled_date': currentTrip.scheduled_date,
        'status': '0',
        'created_date': currentTrip.created_date,
        'price_range': currentTrip.price_range,
        'trip_total_price': '$_currency 0.00',
        'fare': currentTrip.fare.toJSON(),
        'assigned_driver': currentTrip.assigned_driver
      }).whenComplete(() {
        ref.child('status').remove().then((complete) {
          ref.child('incoming/${currentTrip.id}').remove().then((complete) {
            DatabaseReference genRef = FirebaseDatabase.instance
                .reference()
                .child('general_trips/${currentTrip.id}');
            genRef.remove().then((complete) {
              if (driverDetails != null) {
                new Utils().sendSmsNotification(
                    "The rider has canceled this trip. Please check the app and make another request.",
                    driverDetails.number);
              }
              setState(() {
                _inAsyncCall = false;
              });
              new Utils().showToast(
                  'Ride successfully deleted. Thank you for choosing VifaaExpress',
                  false);
            });
          });
        });
      });
    } catch (e) {
      setState(() {
        _inAsyncCall = false;
      });
      new Utils().neverSatisfied(context, 'Error', e.toString());
    }
  }

  Future<Null> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  String getPrice(String id) {
    double dist = double.parse(trip_distance.split(' ')[0]);
    double dur = double.parse(trip_distance.split(' ')[0]);
    if (id == 'car') {
      double total = (dist * double.parse(car_fares.per_distance)) +
          (dur * double.parse(car_fares.per_duration)) +
          double.parse(car_fares.start_fare);
      double total_range = total + 400;
      return '$_currency${total.ceil()}';
    } else {
      double total = (dist * double.parse(bike_fare.per_distance)) +
          (dur * double.parse(bike_fare.per_duration)) +
          double.parse(bike_fare.start_fare);
      double total_range = total + 200;
      return '$_currency${total.ceil()}';
    }
  }

  _confirmBooking() async {
    if (isAlreadyBooked) {
      new Utils().neverSatisfied(context, 'Error',
          'You have booked a ride that has not yet been completed.');
      return;
    }
//    if (!isScheduled) {
//      new Utils().neverSatisfied(context, 'Error', 'Please set a date.');
//      return;
//    }
    if (_method != null) {
      if (!_method.available) {
        new Utils().neverSatisfied(
            context, 'Error', 'Payment method not available for use');
        return;
      }
    }
    if (ride_option_type_id == '') {
      new Utils()
          .neverSatisfied(context, 'Error', 'Please select a ride option.');
      return;
    }
    if (type_of_item == '') {
      new Utils()
          .neverSatisfied(context, 'Error', 'Please select type of item.');
      return;
    }
    if (receiver_number == '') {
      new Utils()
          .neverSatisfied(context, 'Error', "Please enter the receiver's number.");
      return;
    }
    if (who_pays == '') {
      new Utils().neverSatisfied(
          context, 'Error', 'Please select who is making the payment.');
      return;
    }
    if (isScheduled) {
      setState(() {
        request_progress = null;
        isButtonDisabled = true;
        _inAsyncCall = true;
      });
      _confirmBookingDatabaseInput();
    } else {
      _uploadIncomingForUser();
      //_getAvailableDrivers();
      if (_driverSnapshots.length > 1) {
        sendEachDriverRequest(0);
      } else {
        _displayRequestError(
            'No dispatcher rider available to accept your request. Please contact customer care.');
      }
    }
  }

  String incoming_id = '';

  void _uploadIncomingForUser() async {
    DatabaseReference mTripRef = FirebaseDatabase.instance.reference();
    String id = mTripRef.push().key;
    incoming_id = id;
    await mTripRef
        .child('users/${_email.replaceAll('.', ',')}/trips/incoming')
        .child(id)
        .set({
      'id': id,
      'currency': _currency,
      'country': _country,
      'dimensions': dimensions,
      'item_type': type_of_item,
      'payment_by': who_pays,
      'current_location': current_location.toJSON(),
      'destination': destination_location.toJSON(),
      'trip_distance': trip_distance,
      'trip_duration': trip_duration,
      'payment_method': (!isCash) ? _method.toJSON() : 'cash',
      'receiver_number':receiver_number,
      'vehicle_type': ride_option_type_id,
      'promotion': (_general_promotion != null)
          ? _general_promotion.toJSON()
          : 'no_promo',
      'card_trip': (!isCash) ? true : false,
      'promo_used': (_general_promotion != null) ? true : false,
      'scheduled_date': _date_scheduled,
      'status': 'incoming',
      'created_date': DateTime.now().toString(),
      'price_range': getPrice(ride_option_type_id),
      'trip_total_price': '',
      'fare':
          (ride_option_selected_car) ? car_fares.toJSON() : bike_fare.toJSON(),
      'assigned_driver': 'none'
    }).whenComplete(() async {
      DatabaseReference mAfterTripRef = FirebaseDatabase.instance
          .reference()
          .child('users/${_email.replaceAll('.', ',')}/trips/status');
      await mAfterTripRef.set(
          {'current_ride_id': id, 'current_ride_status': 'awaiting response'});
    });
  }

  void _confirmBookingDatabaseInput() async {
    DatabaseReference tripRef = FirebaseDatabase.instance.reference();
    String id = tripRef.push().key;
    await tripRef
        .child('users/${_email.replaceAll('.', ',')}/trips/incoming')
        .child(id)
        .set({
      'id': id,
      'currency': _currency,
      'country': _country,
      'dimensions': dimensions,
      'item_type': type_of_item,
      'payment_by': who_pays,
      'receiver_number': receiver_number,
      'current_location': current_location.toJSON(),
      'destination': destination_location.toJSON(),
      'trip_distance': trip_distance,
      'trip_duration': trip_duration,
      'payment_method': (!isCash) ? _method.toJSON() : 'cash',
      'vehicle_type': ride_option_type_id,
      'promotion': (_general_promotion != null)
          ? _general_promotion.toJSON()
          : 'no_promo',
      'card_trip': (!isCash) ? true : false,
      'promo_used': (_general_promotion != null) ? true : false,
      'scheduled_date': _date_scheduled,
      'status': 'incoming',
      'created_date': DateTime.now().toString(),
      'price_range': getPrice(ride_option_type_id),
      'trip_total_price': '',
      'fare':
          (ride_option_selected_car) ? car_fares.toJSON() : bike_fare.toJSON(),
      'assigned_driver': 'none'
    }).whenComplete(() {
      tripRef.child('general_trips').child(id).set({
        'id': id,
        'currency': _currency,
        'country': _country,
        'dimensions': dimensions,
        'item_type': type_of_item,
        'payment_by': who_pays,
        'receiver_number': receiver_number,
        'current_location': current_location.toJSON(),
        'destination': destination_location.toJSON(),
        'trip_distance': trip_distance,
        'trip_duration': trip_duration,
        'payment_method': (!isCash) ? _method.toJSON() : 'cash',
        'vehicle_type': ride_option_type_id,
        'promotion': (_general_promotion != null)
            ? _general_promotion.toJSON()
            : 'no_promo',
        'card_trip': (!isCash) ? true : false,
        'promo_used': (_general_promotion != null) ? true : false,
        'scheduled_date': _date_scheduled,
        'status': 'incoming',
        'created_date': DateTime.now().toString(),
        'price_range': getPrice(ride_option_type_id),
        'trip_total_price': '',
        'fare': (ride_option_selected_car)
            ? car_fares.toJSON()
            : bike_fare.toJSON(),
        'assigned_driver': 'none',
        'rider_email': _email,
        'rider_name': _name,
        'rider_number': _number,
        'rider_msgId': _msg
      }).whenComplete(() {
        _afterBooking(id);
      });
    });
  }

  _afterBooking(String id) async {
    DatabaseReference afterTripRef = FirebaseDatabase.instance
        .reference()
        .child('users/${_email.replaceAll('.', ',')}/trips/status');
    await afterTripRef.set({
      'current_ride_id': id,
      'current_ride_status': 'awaiting response'
    }).whenComplete(() {
      String subj = "A user just booked for a ride";
      String message =
          "Below are details of the ride booked.\n\nRide ID: $id\nUser Fullname: $_name\nUser Email Address: $_email\nUser Mobile Number: $_number\nScheduled At: $_date_scheduled\nPickup Address: ${current_location.loc_address}\nDrop off Address: ${destination_location.loc_address}\n\nVifaaExpress Team";
      var url =
          "http://vifaaexpress.com/emailsending/sendbooking.php?subject=$subj&body=$message";
      http.get(url).then((response) {
        setState(() {
          _inAsyncCall = false;
        });
        new Utils().showToast('Ride successfully booked.', true);
        Route route = MaterialPageRoute(builder: (context) => UserHomePage());
        Navigator.pushReplacement(context, route);

        //send notification to all drivers
        //
      });
    });
  }

  _buttonTapped() async {
    _locationSubscription.pause();
    final results = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CustomSearchScaffold()),
    );
    if (results != null) {
      setState(() {
        if (address_type == 'current') {
          current_location = results;
          updateMapCamera(double.parse(current_location.latitude),
              double.parse(current_location.longitude));
        } else {
          destination_location = results;
        }
      });
      if (destination_location != null && current_location != null) {
        displayBottomDialog();
      }
    }
  }

  _changePaymentMethod() async {
    final results = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Payment(true)),
    );
    if (results != null) {
      setState(() {
        payment_type = results;
        if (payment_type != 'cash') {
          loadPayment();
        }
      });
      //new Utils().neverSatisfied(context, 'error', 'payment type = $payment_type');
      //displayBottomDialog();
    }
  }

  Future<void> getPlaceAutoComplete(String type) async {
    try {
      Prediction p = await PlacesAutocomplete.show(
          context: context,
          apiKey: kGoogleApiKey,
          mode: Mode.fullscreen,
          // Mode.fullscreen
          onError: onError);
      setState(() {
        getPrediction = p;
        address_type = type;
      });
    } catch (e) {}
  }

  void onError(PlacesAutocompleteResponse response) {
    print('error ====== ${response.errorMessage}');
  }

  Future<void> loadPayment() async {
    if (payment_type != 'cash') {
      DatabaseReference payRef2 = FirebaseDatabase.instance
          .reference()
          .child('users/${_email.replaceAll('.', ',')}/payments/$payment_type');
      await payRef2.once().then((snapshot) {
        if (snapshot != null) {
          setState(() {
            _method = PaymentMethods.fromSnapShot(snapshot);
            isCash = false;
          });
        }
      });
    }
  }

  Future<void> loadPromotion() async {
    if (promotion_type.isNotEmpty) {
      DatabaseReference promoRef2 = FirebaseDatabase.instance.reference().child(
          'users/${_email.replaceAll('.', ',')}/promotions/$promotion_type');
      await promoRef2.once().then((snapshot) {
        if (snapshot != null) {
          GeneralPromotions check_validity =
              GeneralPromotions.fromSnapShot(snapshot);
          List<String> gp_date = check_validity.expires.split('.');
          DateTime current = DateTime.now();
          DateTime expire = DateTime(int.parse(gp_date[2]),
              int.parse(gp_date[1]), int.parse(gp_date[0]));
          int td = expire.difference(current).inMilliseconds;
          if (check_validity.status &&
              td > 0 &&
              int.parse(check_validity.number_of_rides_used) > 0) {
            setState(() {
              _general_promotion = GeneralPromotions.fromSnapShot(snapshot);
              isPromoApplied = true;
            });
          }
        }
      });
    }
  }

  Future<void> checkAlreadyBooked() async {
    DatabaseReference statusRef = FirebaseDatabase.instance
        .reference()
        .child('users/${_email.replaceAll('.', ',')}/trips/status');
    statusRef.onValue.listen((snapshot) {
      if (snapshot.snapshot.value != null) {
        String val = snapshot.snapshot.value['current_ride_status'].toString();
        setState(() {
          current_trip_id =
              snapshot.snapshot.value['current_ride_id'].toString();
          isAlreadyBooked = true;
          if (val == 'driver assigned') {
            dialogType = DialogType.arriving;
          } else if (val == 'en-route') {
            dialogType = DialogType.driving;
            appBarTitle = 'Driving to destination';
          }
        });
        if (val == 'review driver') {
          getCurrentTripDetails(current_trip_id, true);
        } else if (val != 'awaiting response') {
          getCurrentTripDetails(current_trip_id, false);
        }
      } else {
        setState(() {
          isAlreadyBooked = false;
        });
      }
    });
  }

  Future<void> addFavoritePlace(String type) async {
    try {
      if (getPrediction != null) {
        PlacesDetailsResponse detail =
            await _places.getDetailsByPlaceId(getPrediction.placeId);
        String loc_name = detail.result.name;
        String loc_address = detail.result.formattedAddress;
        String lat = detail.result.geometry.location.lat.toString();
        String lng = detail.result.geometry.location.lng.toString();
        DatabaseReference ref = FirebaseDatabase.instance
            .reference()
            .child('users/${_email.replaceAll('.', ',')}/places');
        String id = ref.push().key;
        ref.child(id).set({
          'id': id,
          'loc_name': loc_name,
          'loc_address': loc_address,
          'latitude': lat,
          'longitude': lng,
          'type': type
        });
      }
    } catch (e) {}
  }

  void displayBottomDialog() {
    setState(() {
      isBottomSheet = true;
      request_progress = null;
    });
    setModeForDestination('request');
    getDistanceDuration();
  }

  void getDistanceDuration() {
    try {
      String url =
          'https://maps.googleapis.com/maps/api/distancematrix/json?origins=${current_location.loc_address.replaceAll(' ', '%20')}&destinations=${destination_location.loc_address.replaceAll(' ', '%20')}&key=$api_key';
      //print(url);
      http.get(url).then((res) {
        //new Utils().neverSatisfied(context, 'response', '${res.body}');
        //print(res.body);
        Map<String, dynamic> resp = json.decode(res.body);
        String status = resp['status'];
        //new Utils().neverSatisfied(context, 'status', '$status');
        if (status != null && status == 'OK') {
          Map<String, dynamic> result = resp['rows'][0];
          Map<String, dynamic> element = result['elements'][0];
          Map<String, dynamic> distance = element['distance'];
          Map<String, dynamic> duration = element['duration'];
          //new Utils().neverSatisfied(context, 'distance', distance['text']);
          setState(() {
            trip_distance = distance['text'];
            trip_duration = duration['text'];
            isLoaded = true;
            bottom_height = 400;
            errorLoaded = '';
            request_progress = 0.0;
          });
        } else {
          //new Utils().neverSatisfied(context, 'after if', 'sth wrong');
          setState(() {
            request_progress = 0.0;
            errorLoaded = 'An error occured. Please try again.';
          });
        }
      });
    } catch (e) {
      print('${e.toString()}');
    }
  }

  Future<void> listenForDestinationEntered() async {
    DatabaseReference ref = FirebaseDatabase.instance.reference().child(
        'users/${_email.replaceAll('.', ',')}/trips/current_trip_status');
    await ref.once().then((val) {
      if (val != null) {
        String value = val.value;
        if (value == 'none') {
          setState(() {
            isBottomSheet = false;
          });
          _locationSubscription.resume();
        }
      }
    });
  }

  Future<void> setModeForDestination(String value) async {
    DatabaseReference ref = FirebaseDatabase.instance.reference().child(
        'users/${_email.replaceAll('.', ',')}/trips/current_trip_status');
    await ref.set(value);
  }

  Future<void> getCurrentTripDetails(
      String current_trip_id, bool review_driver) async {
    DatabaseReference tripRef2 = FirebaseDatabase.instance.reference().child(
        'users/${_email.replaceAll('.', ',')}/trips/incoming/$current_trip_id');
    await tripRef2.once().then((snapshot) {
      setState(() {
        currentTrip = CurrentTrip.fromSnapshot(snapshot);
        current_location = currentTrip.current_location;
        destination_location = currentTrip.destination;
        if (review_driver) {
          Route route = MaterialPageRoute(
              builder: (context) => ReviewDriver(currentTrip.assigned_driver,
                  currentTrip.trip_total_price, current_trip_id));
          Navigator.pushReplacement(context, route);
        }
        if (currentTrip.assigned_driver != 'none' &&
            currentTrip.assigned_driver.contains('@')) {
          getDriverDetails(currentTrip.assigned_driver);
        }
      });
    });
  }

  Future<void> getDriverDetails(String assigned_driver) async {
    DatabaseReference driverRef = FirebaseDatabase.instance
        .reference()
        .child('drivers/${assigned_driver.replaceAll('.', ',')}');
    await driverRef.child('signup').once().then((snapshot) {
      setState(() {
        driverDetails = DriverDetails.fromSnapshot(snapshot);
      });
    });
    driverRef.child('location').onValue.listen((data) {
      double latitude = double.parse(data.snapshot.value['latitude']);
      double longitude = double.parse(data.snapshot.value['longitude']);
      getDriverDistanceDuration(latitude, longitude);
    });
  }

  void getDriverDistanceDuration(double lat, double lng) {
    String latlng = '$lat,$lng';
    String current = _currentLocation.latitude.toString() +
        "," +
        _currentLocation.longitude.toString();
    String url =
        'https://maps.googleapis.com/maps/api/distancematrix/json?origins=$latlng&destinations=$current&key=$api_key';
    //print(url);
    http.get(url).then((res) async {
      Map<String, dynamic> resp = json.decode(res.body);
      String status = resp['status'];
      if (status != null && status == 'OK') {
        Map<String, dynamic> result = resp['rows'][0];
        Map<String, dynamic> element = result['elements'][0];
        Map<String, dynamic> distance = element['distance'];
        Map<String, dynamic> duration = element['duration'];
        String driver_distance = distance['text'];
        String driver_duration = duration['text'];
        updateMapCamera(lat, lng);
        if (!mounted) return;
        setState(() {
          if (dialogType == DialogType.arriving) {
            appBarTitle = 'Rider arrives in $driver_duration';
          }
          if (dialogType == DialogType.driving) {
            appBarTitle = 'Driving to destination';
          }
        });
      }
    });
  }
}

Future<Null> displayPrediction(Prediction p, ScaffoldState scaffold) async {
  if (p != null) {
    // get detail (lat/lng)
    PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(p.placeId);
    String loc_name = detail.result.name;
    String loc_address = detail.result.formattedAddress;
    String lat = detail.result.geometry.location.lat.toString();
    String lng = detail.result.geometry.location.lng.toString();
    FavoritePlaces p_fp =
        FavoritePlaces('', loc_name, loc_address, lat, lng, 'history');
    isSavedPlace = true;
    Navigator.pop(scaffold.context, p_fp);
  }
}

class CustomSearchScaffold extends PlacesAutocompleteWidget {
  CustomSearchScaffold()
      : super(
          apiKey: kGoogleApiKey,
        );

  @override
  _CustomSearchScaffoldState createState() => _CustomSearchScaffoldState();
}

class _CustomSearchScaffoldState extends PlacesAutocompleteState {
  List<FavoritePlaces> _fav_places = new List();

  @override
  Widget build(BuildContext context) {
    loadFavoritePlaces();
    final appBar = AppBar(
      title: AppBarPlacesAutoCompleteTextField(),
      leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          }),
    );
    final body = PlacesAutocompleteResult(
      onTap: (p) {
        displayPrediction(p, searchScaffoldKey.currentState);
      },
      logo: ListView(
        children: getMorePlaces(),
      ),
    );
    return Scaffold(key: searchScaffoldKey, appBar: appBar, body: body);
  }

  Future<void> loadFavoritePlaces() async {
    DatabaseReference ref = FirebaseDatabase.instance
        .reference()
        .child('users/${_email.replaceAll('.', ',')}/places');
    await ref.once().then((snapshot) {
      if (snapshot.value != null) {
        _fav_places.clear();
        setState(() {
          for (var value in snapshot.value.values) {
            FavoritePlaces fp = new FavoritePlaces.fromJson(value);
            _fav_places.add(fp);
          }
        });
      }
    }).whenComplete(() {});
  }

  List<Widget> getMorePlaces() {
    List<Widget> m = new List();
    for (var i = 0; i < _fav_places.length; i++) {
      FavoritePlaces fp = _fav_places[i];
      m.add(new Container(
          margin: EdgeInsets.only(left: 0.0),
          color: Colors.white,
          child: new ListTile(
            leading: Icon(
              Icons.location_on,
              color: Colors.grey,
            ),
            title: Text(
              '${fp.loc_name}',
              style: TextStyle(
                  color: Color(MyColors().primary_color), fontSize: 16.0),
            ),
            onTap: () {
              FavoritePlaces selected_fp = fp;
              Navigator.pop(context, selected_fp);
            },
          )));
    }
    return m;
  }

  @override
  void onResponseError(PlacesAutocompleteResponse response) {
    super.onResponseError(response);
//    searchScaffoldKey.currentState.showSnackBar(
//      SnackBar(content: Text(response.errorMessage)),
//    );
  }

  @override
  void onResponse(PlacesAutocompleteResponse response) {
    super.onResponse(response);
//    if (response != null && response.predictions.isNotEmpty) {
//      searchScaffoldKey.currentState.showSnackBar(
//        SnackBar(content: Text("Got answer")),
//      );
//    }
  }
}
