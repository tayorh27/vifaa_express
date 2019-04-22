import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:vifaa_express/Models/driver.dart';
import 'package:vifaa_express/Models/fares.dart';
import 'package:vifaa_express/Models/favorite_places.dart';
import 'package:vifaa_express/Models/general_promotion.dart';
import 'package:vifaa_express/Models/payment_method.dart';
import 'package:vifaa_express/Models/reviews.dart';
import 'package:vifaa_express/Users/home_user.dart';
import 'package:vifaa_express/Utility/MyColors.dart';
import 'package:vifaa_express/Utility/Utils.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_rating/flutter_rating.dart';
import 'package:http/http.dart' as http;

class ReviewDriver extends StatefulWidget {
  String driver_email, trip_total_price, current_trip_id;

  ReviewDriver(this.driver_email, this.trip_total_price, this.current_trip_id);

  @override
  State<StatefulWidget> createState() => _ReviewDriver();
}

class _ReviewDriver extends State<ReviewDriver> {
  DriverDetails driverDetails;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  String _email = '', _name = '';
  final formKey = new GlobalKey<FormState>();
  String comment;
  double rating = 0.0;
  double total_rating = 0.0;
  bool _inAsyncCall = false;
  DataSnapshot snapshot;

  FavoritePlaces fp;
  FavoritePlaces fp2;
  GeneralPromotions gp;
  PaymentMethods pm;
  Fares fares;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  Future<void> getDriverDetails() async {
    DatabaseReference driverRef = FirebaseDatabase.instance
        .reference()
        .child('drivers/${widget.driver_email.replaceAll('.', ',')}');
    await driverRef.child('signup').once().then((snapshot) {
      setState(() {
        driverDetails = DriverDetails.fromSnapshot(snapshot);
      });
    });
  }

  Future<void> getDriverReviews() async {
    DatabaseReference driverRef = FirebaseDatabase.instance
        .reference()
        .child('drivers/${widget.driver_email.replaceAll('.', ',')}');
    await driverRef.child('reviews').once().then((snapshot) {
      if (snapshot.value != null) {
        setState(() {
          for (var value in snapshot.value.values) {
            Reviews reviews = new Reviews.fromJson(value);
            double rate_star = double.parse(reviews.rate_star);
            total_rating = total_rating + rate_star;
          }
        });
      }
    });
  }

  Future<void> getIncomingOrderDetails() async {
    DatabaseReference tripRef2 = FirebaseDatabase.instance.reference().child(
        'users/${_email.replaceAll('.', ',')}/trips/incoming/${widget.current_trip_id}');
    tripRef2.once().then((snapshot) {
      setState(() {
        this.snapshot = snapshot;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    _prefs.then((pref) {
      setState(() {
        _email = pref.getString('email');
        _name = pref.getString('fullname');
      });
    });
    getIncomingOrderDetails();
    getDriverDetails();
    getDriverReviews();
    return new Scaffold(
        backgroundColor: Color(MyColors().primary_color),
        appBar: new AppBar(
          title: new Text('Rate Driver',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25.0,
              )),
        ),
        body: new ModalProgressHUD(
            inAsyncCall: _inAsyncCall,
            opacity: 0.5,
            progressIndicator: CircularProgressIndicator(),
            child: new Container(
                margin: EdgeInsets.only(
                    left: 20.0, right: 20.0, bottom: 20.0, top: 5.0),
                child: new ListView(
                  scrollDirection: Axis.vertical,
                  children: buildPage(),
                ))));
  }

  List<Widget> buildPage() {
    return [
      new Center(
          child: new Container(
              width: 100.0,
              height: 100.0,
              margin: EdgeInsets.only(top: 10.0),
              decoration: new BoxDecoration(
                  shape: BoxShape.circle,
                  image: new DecorationImage(
                    fit: BoxFit.cover,
                    image: (driverDetails != null)
                        ? new NetworkImage(driverDetails.image)
                        : AssetImage('user_dp.png'),
                  )))),
      new Container(
          margin: EdgeInsets.only(top: 20.0),
          child: new Center(
            child: (driverDetails != null)
                ? new Text(driverDetails.fullname,
                    style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.white))
                : new Text(''),
          )),
      new Container(
          margin: EdgeInsets.all(20.0),
          child: new Center(
            child: new Form(
                key: formKey,
                child: new SingleChildScrollView(
                  child: new ListBody(
                    children: <Widget>[
                      new TextFormField(
                        validator: (value) => value.isEmpty
                            ? 'Please write a short comment'
                            : null,
                        onSaved: (value) => comment = value,
                        decoration: new InputDecoration(
                            labelText: 'Enter Commenent',
                            fillColor: Colors.white),
                      )
                    ],
                  ),
                )),
          )),
      new Container(
          margin: EdgeInsets.all(10.0),
          child: new Center(
            child: new StarRating(
              rating: rating,
              starCount: 5,
              size: 45.0,
              borderColor: Colors.grey,
              color: Colors.green,
              onRatingChanged: (rate) {
                setState(() {
                  rating = rate;
                });
              },
            ),
          )),
      new Padding(
        padding: EdgeInsets.all(20.0),
        child: new FlatButton(
          onPressed: () {
            submitRating();
          },
          child: new Text('SUBMIT'),
          color: Color(MyColors().secondary_color),
          textColor: Colors.white,
        ),
      )
    ];
  }

  bool validateAndSave() {
    final form = formKey.currentState;
    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }

  void submitRating() {
    if (validateAndSave()) {
      if (rating == 0.0) {
        new Utils().neverSatisfied(context, 'Error', 'Please assign a rating.');
        return;
      }
      setState(() {
        _inAsyncCall = true;
      });
      uploadRatings();
    }
  }

  Future<void> uploadRatings() async {
    try {
      DatabaseReference ref = FirebaseDatabase.instance
          .reference()
          .child('drivers')
          .child(widget.driver_email.replaceAll('.', ','))
          .child('reviews');
      String id = ref.push().key;
      await ref.push().set({
        'id': id,
        'username': _name,
        'user_email': _email,
        'avatar': 'user_dp',
        'comment': comment,
        'date': new DateTime.now().toString(),
        'rate_star': '$rating'
      }).then((complete) {
        deleteTripStatusForUser();
      });
    } catch (e) {
      setState(() {
        _inAsyncCall = false;
      });
      new Utils().neverSatisfied(context, 'Error', e.toString());
    }
  }

  Future<void> deleteTripStatusForUser() async {
    try {
      fp = FavoritePlaces.fromJson(snapshot.value['current_location']);
      fp2 = FavoritePlaces.fromJson(snapshot.value['destination']);
      gp = (snapshot.value['promo_used'])
          ? GeneralPromotions.fromJson(snapshot.value['promotion'])
          : null;
      pm = (snapshot.value['card_trip'])
          ? PaymentMethods.fromJson(snapshot.value['payment_method'])
          : null;
      fares = Fares.fromJson(snapshot.value['fare']);
      DatabaseReference ref = FirebaseDatabase.instance
          .reference()
          .child('users')
          .child(_email.replaceAll('.', ','))
          .child('trips');

      await ref.child('past/${widget.current_trip_id}').set({
        'id': snapshot.value['id'].toString(),
        'currency': snapshot.value['currency'].toString(),
        'country': snapshot.value['country'].toString(),
        'dimensions': snapshot.value['dimensions'].toString(),
        'item_type': snapshot.value['item_type'].toString(),
        'payment_by': snapshot.value['payment_by'].toString(),
        'receiver_number': snapshot.value['receiver_number'].toString(),
        'current_location': fp.toJSON(),
        'destination': fp2.toJSON(),
        'trip_distance': snapshot.value['trip_distance'].toString(),
        'trip_duration': snapshot.value['trip_duration'].toString(),
        'payment_method': (snapshot.value['card_trip']) ? pm.toJSON() : 'cash',
        'vehicle_type': snapshot.value['vehicle_type'].toString(),
        'promotion': (gp != null) ? gp.toJSON() : 'no_promo',
        'card_trip': (snapshot.value['card_trip']) ? true : false,
        'promo_used': (gp != null) ? true : false,
        'scheduled_date': snapshot.value['scheduled_date'].toString(),
        'status': 'past',
        'created_date': snapshot.value['created_date'].toString(),
        'price_range': snapshot.value['price_range'].toString(),
        'trip_total_price': snapshot.value['trip_total_price'].toString(),
        'fare': fares.toJSON(),
        'assigned_driver': snapshot.value['assigned_driver'].toString()
      }).whenComplete(() {
        ref.child('status').remove().then((complete) {
          ref
              .child('incoming/${widget.current_trip_id}')
              .remove()
              .then((complete) {
            DatabaseReference genRef = FirebaseDatabase.instance
                .reference()
                .child('general_trips/${widget.current_trip_id}');
            genRef.remove().then((complete) {
              calculateTotalStars();
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

  Future<void> calculateTotalStars() async {
    double tt = total_rating + rating;
    try {
      DatabaseReference ref = FirebaseDatabase.instance
          .reference()
          .child('drivers')
          .child(widget.driver_email.replaceAll('.', ','))
          .child('signup');
      await ref.update({
        'rating': '$tt',
      }).then((complete) {
        String subj = "VifaaExpress Receipt";
        DateTime dt =
            DateTime.parse(snapshot.value['scheduled_date'].toString());
        var days = [
          "Sunday",
          "Monday",
          "Tuesday",
          "Wednesday",
          "Thursday",
          "Friday",
          "Saturday"
        ];
        String day = 'Your VifaaExpress Trip on ${days[(dt.weekday - 1)]}';
        String payment_type = (pm == null) ? 'Cash' : '•••• ${pm.number}';
        String total_amount = snapshot.value['trip_total_price'].toString();
        String trip_distance = snapshot.value['trip_distance'].toString();
        String trip_duration = snapshot.value['trip_duration'].toString();
        var url =
            "http://vifaaexpress.com/emailsending/receipt_rider.php?subject=$subj&sub_subject=$day&payment_type=$payment_type&total_amount=$total_amount&trip_distance=$trip_distance&trip_duration=$trip_duration&current_location=${fp.loc_address}&destination=${fp2.loc_address}&driver_image=${driverDetails.image}&driver_name=${driverDetails.fullname}";
        http.get(url).then((response) {
          setState(() {
            _inAsyncCall = false;
          });
          new Utils().showToast('Thank you for choosing VifaaExpress', false);
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => UserHomePage()));
        });
      });
    } catch (e) {
      setState(() {
        _inAsyncCall = false;
      });
      new Utils().neverSatisfied(context, 'Error', e.toString());
    }
  }
}
