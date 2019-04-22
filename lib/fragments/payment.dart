import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:vifaa_express/Models/general_promotion.dart';
import 'package:vifaa_express/Models/payment_method.dart';
import 'package:vifaa_express/Users/home_user.dart';
import 'package:vifaa_express/Utility/MyColors.dart';
import 'package:vifaa_express/Utility/Utils.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_paystack/flutter_paystack.dart';
import 'package:http/http.dart' as http;

class Payment extends StatefulWidget {
  bool isBooking;

  Payment(this.isBooking);

  @override
  State<StatefulWidget> createState() => _Payment();
}

class _Payment extends State<Payment> {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  String _email = '',
      _refCode = '',
      _promo_price = '',
      _get_back_promo_price,
      _country = '', _currency = '', _currencyCode = '';
  bool isCash = false;
  String payment_type = '';
  String promotion_type = '';
  List<PaymentMethods> _methods = new List();
  List<GeneralPromotions> _general_promotions = new List();
  List<GeneralPromotions> _admin_general_promotions = new List();
  double progress_payment = null;
  double progress_promotion = null;
  bool isPromotionLoaded = false;
  Utils mUtils = new Utils();

  final formKey = GlobalKey<FormState>();
  String promo_entered;
  double _inAsyncCall = 0.0;
  bool _sync = false; //not used
  bool isFirstTrip = false;
  bool isPromoExist = false;

  var paystackPublicKey;
  var paystackSecretKey;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    FirebaseDatabase.instance
        .reference()
        .child('settings/keys')
        .once()
        .then((snapshot) {
      setState(() {
        paystackPublicKey = snapshot.value['paystackPublicKey'];
        paystackSecretKey = snapshot.value['paystackSecretKey'];
      });
      PaystackPlugin.initialize(
          publicKey: paystackPublicKey, secretKey: paystackSecretKey);
    });
    //new Utils().initializeRemoteConfig();
  }

  @override
  Widget build(BuildContext context) {
    _prefs.then((pref) {
      setState(() {
        _email = pref.getString('email');
        _refCode = pref.getString('referralCode');
        _country = pref.getString('country');
        if (pref.getString('payment') != null) {
          payment_type = pref.getString('payment');
          if (pref.getString('payment') == 'cash') {
            isCash = true;
          }
        } else {
          isCash = true;
        }
        promotion_type = (pref.getString('promotion_type') != null)
            ? pref.getString('promotion_type')
            : '';
      });
    });
    mUtils.initializeRemoteConfig(_country).whenComplete((){
      setState(() {
        _currency = mUtils.fetchCurrency();
        _currencyCode = mUtils.fetchCurrencyCode();
      });
    });
//    new Utils().fetchCurrency(_country).then((cur){
//      setState(() {
//        _currency = cur;
//      });
//    });
//    new Utils().fetchCurrencyCode(_country).then((code){
//      setState(() {
//        _currencyCode = code;
//      });
//    });
    loadRefPrice();
    loadPayments();
    loadPromotions();
    loadTrips();
    // TODO: implement build
    return new Scaffold(
        backgroundColor: Color(MyColors().button_text_color),
        appBar: new AppBar(
          title: new Text('Payment',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25.0,
              )),
          leading: new IconButton(
              icon: Icon(Icons.keyboard_arrow_left),
              onPressed: () {
                if (widget.isBooking) {
                  Navigator.pop(context, null);
                } else {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => UserHomePage()));
                }
              }),
        ),
        body: ModalProgressHUD(
            inAsyncCall: _sync,
            opacity: 0.5,
            progressIndicator: CircularProgressIndicator(),
            color: Color(MyColors().button_text_color),
            child: new ListView(
                scrollDirection: Axis.vertical,
                children: paymentMethods() + promotions())));
  }

  List<Widget> paymentMethods() {
    return [
      new Container(
        margin: EdgeInsets.only(top: 0.0),
        color: Color(MyColors().button_text_color),
        padding: EdgeInsets.all(20.0),
        child: new Text(
          'Payment Method',
          style: TextStyle(color: Colors.white, fontSize: 16.0),
        ),
      ),
      new Container(
        color: Color(MyColors().primary_color),
        padding: EdgeInsets.all(0.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: userPaymentMethods() + userPaymentMethodsOthers()),
      )
    ];
  }

  List<Widget> userPaymentMethodsOthers() {
    return [
      new ListTile(
        title:
            Text('Cash', style: TextStyle(color: Colors.white, fontSize: 16.0)),
        onTap: () {
          _prefs.then((prefs) {
            prefs.setString('payment', 'cash');
            setState(() {
              payment_type = 'cash';
              isCash = true;
            });
          });
          if (widget.isBooking) {
            Navigator.pop(context, 'cash');
          }
        },
        leading: new Image.asset('cash.png'),
        trailing: (isCash)
            ? Icon(
                Icons.check_circle,
                color: Color(MyColors().secondary_color),
              )
            : new Text(''),
      ),
      Divider(
        color: Color(MyColors().secondary_color),
        height: 1.0,
      ),
      new Container(
        height: 5.0,
      ),
      new FlatButton(
        onPressed: () {
          addPaymentMethod(context);
        },
        child: Text(
          'Add Payment Methods',
          style: TextStyle(
              color: Color(MyColors().secondary_color), fontSize: 16.0),
        ),
      ),
      new Container(
        height: 5.0,
      ),
    ];
  }

  Future<void> addPaymentMethod(BuildContext context) async {
    setState(() {
      _sync = true;
    });
    String reference = FirebaseDatabase.instance.reference().push().key;
    String v = '200';
    int total = int.parse(v);
    Charge charge = new Charge()
      ..amount = total
      ..currency = _currencyCode
      ..email = _email
      ..reference = reference;
    try {
      CheckoutResponse response = await PaystackPlugin.checkout(
        context,
        method: CheckoutMethod.card,
        charge: charge,
      );
      if (!response.status) {
        setState(() {
          _sync = false;
        });
        new Utils().neverSatisfied(context, 'Payment Error', response.message);
      } else {
        verifyTransaction(response.reference, response.card.last4Digits);
      }
    } catch (e) {
      setState(() {
        _sync = false;
      });
      new Utils().neverSatisfied(context, 'Error', e.toString());
    }
  }

  Future<void> verifyTransaction(String reference, String cardNumber) async {
    http.get('https://api.paystack.co/transaction/verify/$reference',
        headers: {'Authorization': 'Bearer $paystackSecretKey'}).then((res) {
      print(res.body);
      Map<String, dynamic> resp = json.decode(res.body);
      bool status = resp['status'];
      String message = resp['message'];
      if (status) {
        Map<String, dynamic> data = resp['data'];
        Map<String, dynamic> auth = data['authorization'];
        String auth_code = auth['authorization_code'];
        DatabaseReference promoRef = FirebaseDatabase.instance
            .reference()
            .child('users/${_email.replaceAll('.', ',')}/payments');
        String id = promoRef.push().key;
        promoRef.child(id).set({
          'number': cardNumber,
          'id': id,
          'payment_code': auth_code,
          'available': true,
        }).whenComplete(() {
          new Utils().showToast('Payment method added', false);
          setState(() {
            _sync = false;
          });
        });
      } else {
        setState(() {
          _sync = false;
        });
        new Utils().neverSatisfied(context, 'Error', message);
      }
    });
  }

  List<Widget> userPaymentMethods() {
    List<Widget> m = new List();
    m.add(new LinearProgressIndicator(
      backgroundColor: Color(MyColors().primary_color),
      value: progress_payment,
      valueColor:
          AlwaysStoppedAnimation<Color>(Color(MyColors().secondary_color)),
    ));
    for (var i = 0; i < _methods.length; i++) {
      PaymentMethods pm = _methods[i];
      m.add(new Column(
        children: <Widget>[
          new ListTile(
            title: Text('•••• ${pm.number}',
                style: TextStyle(color: Colors.white, fontSize: 16.0)),
            onTap: () {
              _prefs.then((prefs) {
                prefs.setString('payment', pm.id);
                setState(() {
                  payment_type = pm.id;
                  isCash = false;
                });
                if (widget.isBooking) {
                  Navigator.pop(context, pm.id);
                }
              });
            },
            leading: new Icon(
              Icons.credit_card,
              color: Colors.white,
            ),
            trailing: (pm.id == payment_type)
                ? Icon(
                    Icons.check_circle,
                    color: Color(MyColors().secondary_color),
                  )
                : new Text(''),
          ),
          Divider(
            color: Color(MyColors().secondary_color),
            height: 1.0,
          ),
        ],
      ));
    }
    return m;
  }

  List<Widget> promotions() {
    return [
      new Container(
        margin: EdgeInsets.only(top: 0.0),
        color: Color(MyColors().button_text_color),
        padding: EdgeInsets.all(20.0),
        child: new Text(
          'Promotions',
          style: TextStyle(color: Colors.white, fontSize: 16.0),
        ),
      ),
      new LinearProgressIndicator(
        backgroundColor: Color(MyColors().button_text_color),
        value: progress_promotion,
        valueColor:
            AlwaysStoppedAnimation<Color>(Color(MyColors().secondary_color)),
      ),
      new Container(
          color: Color(MyColors().primary_color),
          padding: EdgeInsets.all(0.0),
          height: 180.0,
          child: new ListView(
            scrollDirection: Axis.horizontal,
            children: userPromotions() + userPromotionOthers(),
          )),
    ];
  }

  List<Widget> userPromotionOthers() {
    return [
      new Container(
        height: 5.0,
      ),
      new FlatButton(
        onPressed: (!isPromotionLoaded)
            ? null
            : () {
                addPromoCode(context);
              },
        child: Text(
          'Add Promo code',
          style: TextStyle(
              color: Color(MyColors().secondary_color), fontSize: 16.0),
        ),
      ),
      new Container(
        height: 15.0,
      ),
    ];
  }

  List<Widget> userPromotions() {
    List<Widget> m = new List();
    for (var i = 0; i < _general_promotions.length; i++) {
      GeneralPromotions gp = _general_promotions[i];
      String discountValue = (gp.discount_type == 'percent')
          ? '-${gp.discount_value}%'
          : '-$_currency${gp.discount_value}';
      List<String> gp_date = gp.expires.split('.');
      DateTime current = DateTime.now();
      DateTime expire = DateTime(
          int.parse(gp_date[2]), int.parse(gp_date[1]), int.parse(gp_date[0]));
      int td = expire.difference(current).inMilliseconds;
      if (gp.status && td > 0 && int.parse(gp.number_of_rides_used) > 0) {
        m.add(new Container(
            alignment: Alignment.center,
            width: 150.0,
            child: new Card(
              color: Color(MyColors().primary_color),
              margin: EdgeInsets.all(5.0),
              child: new Center(
                child: new Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    new Container(
                      height: 50.0,
                      color: Color(MyColors().button_text_color),
                      child: new FlatButton.icon(
                          onPressed: () {
                            _prefs.then((pref) {
                              pref.setString('promotion_type', gp.id);
                              setState(() {
                                promotion_type = gp.id;
                              });
                            });
                          },
                          icon: (promotion_type == gp.id)
                              ? Icon(
                                  Icons.check_circle,
                                  color: Color(MyColors().secondary_color),
                                  size: 32.0,
                                )
                              : Icon(
                                  Icons.check_circle,
                                  color: Colors.grey,
                                  size: 32.0,
                                ),
                          label: new Text('')),
                    ),
                    innerPromotionContent(
                      child: new Text(
                        'DISCOUNT',
                        style: TextStyle(color: Colors.white, fontSize: 15.0),
                      ),
                    ),
                    innerPromotionContent(
                      child: new Text(
                        '$discountValue',
                        style: TextStyle(color: Colors.white, fontSize: 30.0),
                      ),
                    ),
                    (gp.discount_type == 'amount')
                        ? new Text('')
                        : innerPromotionContent(
                            child: new Text(
                              'Maximum value is $_currency${gp.maximum_value}',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 10.0),
                            ),
                          ),
                    (gp.number_of_rides_used == '1')
                        ? new Text('')
                        : innerPromotionContent(
                            child: new Text(
                              'Valid for ${gp.number_of_rides_used} rides',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 10.0),
                            ),
                          ),
                    innerPromotionContent(
                      child: new Text(
                        'Expires on ${gp.expires}',
                        style: TextStyle(color: Colors.white, fontSize: 12.0),
                      ),
                    ),
                  ],
                ),
              ),
            )));
      }
    }
    return m;
  }

  Widget innerPromotionContent({Widget child}) {
    return new Container(
      margin: EdgeInsets.only(top: 2.5, bottom: 2.5, left: 3.0, right: 3.0),
      child: new Center(
        child: child,
      ),
    );
  }

  Future<void> loadPayments() async {
    DatabaseReference refPay = FirebaseDatabase.instance
        .reference()
        .child('users/${_email.replaceAll('.', ',')}/payments');
    await refPay.once().then((snapshot) {
      if (snapshot.value != null) {
        _methods.clear();
        setState(() {
          for (var value in snapshot.value.values) {
            _methods.add(new PaymentMethods.fromJson(value));
          }
          progress_payment = 0.0;
        });
      } else {
        setState(() {
          progress_payment = 0.0;
        });
      }
    });
  }

  Future<void> loadPromotions() async {
    DatabaseReference refPro = FirebaseDatabase.instance
        .reference()
        .child('users/${_email.replaceAll('.', ',')}/promotions');
    await refPro.once().then((snapshot) {
      if (snapshot.value != null) {
        _general_promotions.clear();
        setState(() {
          for (var value in snapshot.value.values) {
            _general_promotions.add(new GeneralPromotions.fromJson(value));
          }
          progress_promotion = 0.0;
          isPromotionLoaded = true;
        });
      } else {
        setState(() {
          progress_promotion = 0.0;
          isPromotionLoaded = true;
        });
      }
    });
  }

  Future<void> loadRefPrice() async {
    DatabaseReference ref = FirebaseDatabase.instance
        .reference()
        .child('settings/promotions/$_country/referral_code_value');
    await ref.once().then((snapshot) {
      setState(() {
        _promo_price = snapshot.value;
      });
    });
    DatabaseReference ref2 = FirebaseDatabase.instance
        .reference()
        .child('settings/promotions/$_country/referral_get_back_value');
    await ref2.once().then((snapshot) {
      setState(() {
        _get_back_promo_price = snapshot.value;
      });
    });
  }

  Future<void> loadTrips() async {
    DatabaseReference ref = FirebaseDatabase.instance
        .reference()
        .child('users/${_email.replaceAll('.', ',')}/trips');
    await ref.once().then((snapshot) {
      if (snapshot.value == null) {
        setState(() {
          isFirstTrip = true;
        });
      } else {
        setState(() {
          isFirstTrip = false;
        });
      }
    });
  }

  Future<Null> addPromoCode(BuildContext ctx) {
    setState(() {
      _inAsyncCall = 0.0;
    });
    return showDialog<Null>(
      context: ctx,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text('ENTER PROMO CODE'),
          content: new Form(
              key: formKey,
              child: new SingleChildScrollView(
                child: new ListBody(
                  children: <Widget>[
                    new TextFormField(
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) =>
                          value.isEmpty ? 'Please enter promo code.' : null,
                      onSaved: (value) => promo_entered = value,
                      decoration: new InputDecoration(
                        labelText: 'Promo Code',
                      ),
                    ),
                    new LinearProgressIndicator(
                      backgroundColor: Colors.white,
                      value: _inAsyncCall,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Color(MyColors().secondary_color)),
                    )
                  ],
                ),
              )),
          actions: <Widget>[
            new FlatButton(
              child: new Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text(
                'APPLY',
                style: TextStyle(color: Color(MyColors().button_text_color)),
              ),
              onPressed: () {
                if (validateAndSave()) {
                  if (promo_entered.startsWith('GD')) {
                    if (isFirstTrip) {
                      if (_refCode == promo_entered) {
                        promoError(
                            'Please use another referral code apart from yours');
                      } else {
                        int countExist = 0;
                        for (var i = 0; i < _general_promotions.length; i++) {
                          if (_general_promotions[i].promo_code ==
                              promo_entered) {
                            countExist = countExist + 1;
                          }
                        }
                        if (countExist > 0) {
                          promoError('Promotion already exists');
                        } else {
                          setState(() {
                            _inAsyncCall = 0.0;
                            addPromotionToUser();
                          });
                        }
                      }
                    } else {
                      promoError('Promo code only applied to new users.');
                    }
                  } else {
                    isPromoCodeValid();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void isPromoCodeValid() {
    int countExist = 0;
    setState(() {
      _inAsyncCall = null;
    });
    DatabaseReference ref = FirebaseDatabase.instance
        .reference()
        .child('settings/promotions/$_country/general');
    ref.once().then((snapshot) {
      if (snapshot.value != null) {
        _admin_general_promotions.clear();
        setState(() {
          for (var value in snapshot.value.values) {
            GeneralPromotions ggp = new GeneralPromotions.fromJson(value);
            if (ggp.promo_code == promo_entered) {
              _admin_general_promotions.add(ggp);
            }
          }
        });
        if (_admin_general_promotions.length > 0) {
          if (_admin_general_promotions[0].promo_code == promo_entered) {
            for (var i = 0; i < _general_promotions.length; i++) {
              if (_general_promotions[i].promo_code == promo_entered) {
                countExist = countExist + 1;
              }
            }
            if (countExist > 0) {
              promoError('Promotion already exists');
            } else {
              if (_admin_general_promotions[0].status) {
                setState(() {
                  _inAsyncCall = 0.0;
                  addPromotionToUser();
                });
              } else {
                promoError('Invalid promo code');
              }
            }
          } else {
            promoError('Invalid promo code');
          }
        } else {
          promoError('Invalid promo code');
        }
      } else {
        promoError('Invalid promo code');
      }
    });
  }

  void promoError(String msg) {
    setState(() {
      _inAsyncCall = 0.0;
    });
    new Utils().showToast(msg, true);
    Navigator.of(context).pop();
  }

  void addPromotionToUser() {
    if (!isFirstTrip && !promo_entered.startsWith('GD') ||
        isFirstTrip && !promo_entered.startsWith('GD')) {
      DatabaseReference promoRef = FirebaseDatabase.instance
          .reference()
          .child('users/${_email.replaceAll('.', ',')}/promotions');
      String id = promoRef.push().key;
      promoRef.child(id).set({
        'discount_type': _admin_general_promotions[0].discount_type,
        'discount_value': _admin_general_promotions[0].discount_value,
        'expires': _admin_general_promotions[0].expires,
        'id': id, //_admin_general_promotions[0].id
        'maximum_value': _admin_general_promotions[0].maximum_value,
        'number_of_rides_used':
            _admin_general_promotions[0].number_of_rides_used,
        'promo_code': _admin_general_promotions[0].promo_code,
        'status': _admin_general_promotions[0].status,
      }).whenComplete(() {
        new Utils().showToast('Promo code applied successfully.', true);
        Navigator.of(context).pop();
      });
    } else if (isFirstTrip && promo_entered.startsWith('GD')) {
      DatabaseReference promoRef = FirebaseDatabase.instance
          .reference()
          .child('users/${_email.replaceAll('.', ',')}/promotions');
      String id = promoRef.push().key;
      promoRef.child(id).set({
        'discount_type': 'amount',
        'discount_value': _promo_price,
        'expires': '31.12.2022',
        'id': id,
        'maximum_value': _promo_price,
        'number_of_rides_used': '1',
        'promo_code': promo_entered,
        'status': true,
      }).whenComplete(() {
        checkIfIsReferral();
      });
    }
  }

  bool validateAndSave() {
    final form = formKey.currentState;
    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }

  void checkIfIsReferral() {
    DatabaseReference promoRef = FirebaseDatabase.instance
        .reference()
        .child('referralCodes/$promo_entered/email');
    promoRef.once().then((snapshot) {
      String recipient_email = snapshot.value;
      DatabaseReference promoRef = FirebaseDatabase.instance
          .reference()
          .child('users/${recipient_email.replaceAll('.', ',')}/promotions');
      String id = promoRef.push().key;
      promoRef.child(id).set({
        'discount_type': 'amount',
        'discount_value': _get_back_promo_price,
        'expires': '31.12.2022',
        'id': id,
        'maximum_value': _get_back_promo_price,
        'number_of_rides_used': '1',
        'promo_code': promo_entered,
        'status': true,
      }).whenComplete(() {
        new Utils().showToast('Promo code applied successfully.', true);
        Navigator.of(context).pop();
      });
    });
  }
}
