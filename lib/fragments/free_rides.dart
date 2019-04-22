import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:vifaa_express/Users/home_user.dart';
import 'package:vifaa_express/Utility/MyColors.dart';
import 'package:vifaa_express/Utility/Utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/services.dart';

class FreeRides extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _FreeRides();
}

class _FreeRides extends State<FreeRides> {

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  String _email = '';
  String _refCode = '';
  String _promo_price = '', _country = '', _currency = '';
  Utils mUtils = new Utils();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //new Utils().initializeRemoteConfig();
  }

  @override
  Widget build(BuildContext context) {
    _prefs.then((pref) {
      setState(() {
        _email = pref.getString('email');
        _refCode = pref.getString('referralCode');
        _country = pref.getString('country');
      });
    });
    mUtils.initializeRemoteConfig(_country).whenComplete((){
      setState(() {
        _currency = mUtils.fetchCurrency();
      });
    });
//    new Utils().fetchCurrency(_country).then((cur){
//      setState(() {
//        _currency = cur;
//      });
//    });
    loadRefPrice();
    // TODO: implement build
    return new Scaffold(
        backgroundColor: Color(MyColors().primary_color),
        appBar: new AppBar(
          title: new Text('Free Rides',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25.0,
              )),
          leading: new IconButton(
              icon: Icon(Icons.keyboard_arrow_left),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => UserHomePage()));
              }),
        ),
        body: new ListView(
          scrollDirection: Axis.vertical,
          children: <Widget>[
            new Container(
              margin: EdgeInsets.only(top: 20.0),
              color: Color(MyColors().button_text_color),
              padding: EdgeInsets.all(20.0),
              child: new Text(
                'Want more from VifaaExpress for less?',
                style: TextStyle(color: Colors.white, fontSize: 16.0),
              ),
            ),
            new Container(
              margin: EdgeInsets.only(top: 0.0),
              padding: EdgeInsets.all(20.0),
              child: new Text(
                'Get a free ride worth up to $_currency$_promo_price when you refer a friend to try VifaaExpress.',
                style: TextStyle(color: Colors.white, fontSize: 16.0),
              ),
            ),
            new Container(
              margin: EdgeInsets.only(top: 0.0, left: 20.0),
              padding: EdgeInsets.all(0.0),
              child: new Text(
                'How invites work',
                style: TextStyle(color: Color(MyColors().secondary_color), fontSize: 16.0),
              ),
            ),
            new Container(
              margin: EdgeInsets.only(top: 20.0,right: 40.0, bottom: 40.0),
              alignment: Alignment.topRight,
              child: new Image.asset('invites.png'),
            ),
            new Container(
              margin: EdgeInsets.only(top: 20,),
              height: 195.0,
              alignment: Alignment.bottomCenter,
              width: MediaQuery.of(context).size.width,
              color: Color(MyColors().button_text_color),
              child: new Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  new Container(
                    margin: EdgeInsets.only(top: 10.0, left: 20.0, bottom: 20.0),
                    child: new Text(
                      'Share Your Invite Code',
                      style: TextStyle(color: Colors.white, fontSize: 16.0),
                    ),
                  ),
                  new Container(
                    margin: EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
                    color: Color(MyColors().secondary_color),
                    height: 50.0,
                    child: new Container(
                      color: Color(MyColors().button_text_color),
                      margin: EdgeInsets.all(1.5),
                      child: new Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          new Container(margin: EdgeInsets.only(left: 20.0),),
                          new Text(
                            '$_refCode',
                            style: TextStyle(color: Colors.white, fontSize: 16.0),
                          ),
                          IconButton(icon: Icon(Icons.content_copy), onPressed: (){
                            Clipboard.setData(ClipboardData(text: _refCode));
                            new Utils().showToast('Copied', false);
                          },alignment: Alignment.centerRight,color: Colors.white,highlightColor: Color(MyColors().secondary_color),tooltip: 'Copy referral code',)
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 0.0, left: 20.0, right: 20.0, bottom: 20.0),
                    child: new RaisedButton(
                      child: new Text('INVITE FRIENDS',
                          style: new TextStyle(
                              fontSize: 18.0,
                              color: Color(MyColors().button_text_color))),
                      color: Color(MyColors().secondary_color),
                      disabledColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30.0)),
                      ),
                      onPressed: () async => await _shareText(),
                      padding: EdgeInsets.all(15.0),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ));
  }

  Future _shareText() async {
    try {
      await EsysFlutterShare.shareText(
          'Hey there,\n\nClick here to download the VifaaExpress App\nhttps://vifaaexpress.page.link/Tn65\n\nEnjoy discount on your first ride when you use my referral code.\n\n$_refCode', 'VifaaExpress - Invite Friends');
    } catch (e) {
      print('error: $e');
    }
  }

  Future<void> loadRefPrice() async {
    DatabaseReference ref = FirebaseDatabase.instance
        .reference()
        .child('settings/promotions/$_country/referral_get_back_value');
    await ref.once().then((snapshot) {
      setState(() {
        _promo_price = snapshot.value;
      });
    });
  }
}
