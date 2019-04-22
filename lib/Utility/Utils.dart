import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:vifaa_express/Models/fares.dart';
import 'package:vifaa_express/Models/user.dart';
import 'package:vifaa_express/Utility/MyColors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';

class Utils {
  RemoteConfig remoteConfig;
  DatabaseReference configRef;
  String currency = '', code = '';

  Future<void> initializeRemoteConfig(String country) async {
//    remoteConfig = await RemoteConfig.instance;
//    await remoteConfig.fetch(expiration: const Duration(seconds: 1));
//    //if(remoteConfig)
//    await remoteConfig.activateFetched();
    configRef =
        FirebaseDatabase.instance.reference().child('settings/configuration');
    configRef.child(country).child('currency').once().then((val) {
      currency = (val == null) ? 'USD' : val.value.toString();
    });
    configRef.child(country).child('code').once().then((val) {
      code = (val == null) ? 'USD' : val.value.toString();
    });
  }

  String fetchCurrency() {
//    bool isFetched = await remoteConfig.activateFetched();
//    if (isFetched) {
//      Map<String, String> values = json.decode(remoteConfig.getString(country));
//      return values['currency'];
//    }
//    return "USD";
//    configRef.child(country).child('currency').once().then((val) {
//      if(val == null){
//        return "USD";
//      }
//      return val.toString();
//    });
//    return null;
    return currency;
  }

  String fetchCurrencyCode() {
//    bool isFetched = await remoteConfig.activateFetched();
//    if (isFetched) {
//      Map<String, String> values = json.decode(remoteConfig.getString(country));
//      return values['code'].toUpperCase();
//    }
//    return "USD";
//    configRef.child(country).child('code').once().then((val) {
//      if (val == null) {
//        return "USD";
//      }
//      return val.toString();
//    });
//    return null;
    return code;
  }

  Future<Null> neverSatisfied(
      BuildContext context, String _title, String _body) async {
    return showDialog<Null>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text(_title),
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[
                new Text(_body),
              ],
            ),
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<Null> displayFareInformation(BuildContext context, String _title,
      Fares snapshot, String currency) async {
    return showDialog<Null>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text(_title),
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[
                new ListTile(
                  leading: new Text(
                    'Start fare',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: new Text(
                    '$currency${snapshot.start_fare}',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                new ListTile(
                  leading: new Text(
                    'Wait time fee',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: new Text(
                    '$currency${snapshot.wait_time_fee}',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                new ListTile(
                  leading: new Text(
                    'Fee per distance',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: new Text(
                    '$currency${snapshot.per_distance}',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                new ListTile(
                  leading: new Text(
                    'Fee per duration',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: new Text(
                    '$currency${snapshot.per_duration}',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showToast(String text, bool isLong) {
    Fluttertoast.showToast(
        msg: text,
        toastLength: isLong ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Color(MyColors().secondary_color),
        textColor: Color(MyColors()
            .button_text_color)); // backgroundColor: '#FFCA40', textColor: '#12161E');
  }

  String sms_USERNAME = "vifaaexpress";

  String sms_PASSWORD = "vifaa1234";

  String token =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6ImEwYmNjMGI4MzAxNmE0YTllYjg1NmEyNWI2NzZlMzFmMWIwZTUyOWYzZjk1NGZkYzhmNDBiNmU1ZTUyMjZkODUwODRjNjBkZmQ4YzI1Y2U2In0.eyJhdWQiOiIxIiwianRpIjoiYTBiY2MwYjgzMDE2YTRhOWViODU2YTI1YjY3NmUzMWYxYjBlNTI5ZjNmOTU0ZmRjOGY0MGI2ZTVlNTIyNmQ4NTA4NGM2MGRmZDhjMjVjZTYiLCJpYXQiOjE1NTU1OTMwMzMsIm5iZiI6MTU1NTU5MzAzMywiZXhwIjoxNTg3MjE1NDMzLCJzdWIiOiIyODQxOCIsInNjb3BlcyI6W119.C8Ic5dADIQX1T8YwRkx41gs_JaA66CJHZVGb7WPvjLovOZgznka0Kd1aKcxLhwYxHAB3E_9aYY0ohhG35vYexshHnI_-c8EvuAYx4hP1W05bvE0AKSuzV2R6hUb2IsPbUpUj64Mq0yXxh5cMJX54zL0eP_6tP2vY7bKav43_Ot6UsdWI3XK8emsdE-Lpxx1Pn34m0ZydFUfSWY0ekfNYqOWLdGlYaMllV3vDjN9IhUqojPbh0IpcRhxx9hC_3a1ZEi0bfg199mtQsxLaIBlkEb9ZTZeQH1SsNI7iyue0tPnCzlHUCnufvOVVv0WZndHHMakeW5iZ7flzq1P05o06x8NKMridPTgfUk6Rl_u4ixe3ANeSPKup-QNYrAUcsxMrNs2F-j0naohT87xhPs9RfKZgIsQRrQ33kgfUcOBFaXjwmkb3hUO9X04SbeivQ-JGsAJuN-gJdantRKRJRFIZo_pbSULBbkhvHaGXIATGOnEobckV7Mh-aMJXAGG_SG_glU7qAaaslkWGqcZWiOcM3oQThL66Fx5laD4WZUJ3w_YENIFsy5i1Zt1I1Fpw8B0wiZNIWxXt5Jr6PUDaZx-BsADuVQslQJMbcdarFDg6IqptaYEvqobNKAZ6ROUEdvjF-Rtayobc5ZtkzVeNJDiEPaG1YHvdAsHc381vopj50KY';

  Future<bool> sendSmsNotification(
      String body, String recipient) async {
    String sms_URL =
        'https://api.loftysms.com/simple/sendsms?username=$sms_USERNAME&password=$sms_PASSWORD&sender=Vifaa&sms_type=1&corporate=1&recipient=$recipient&message=$body'; //https://jusibe.com/smsapi/send_sms
    final response = await http.get(sms_URL, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    });
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> sendPushNotification(String to, String title, String msg) async {
    final postUrl = 'https://fcm.googleapis.com/fcm/send';

    final data = {
      "notification": {"body": "$msg", "title": "$title"},
      "priority": "high",
//      "data": {
//        "click_action": "FLUTTER_NOTIFICATION_CLICK",
//        "id": "1",
//        "status": "done"
//      },
      "to": "$to"
    };

    final headers = {
      'content-type': 'application/json',
      'Authorization':
          'AAAAk7MijUo:APA91bHlIA6Yn1fddxhEZYJyxBBdHAS1sGJI_CHhjtL6a-FNxggUHDeT0GgCQMmiZmY2lje4X5RoGcqZap5ckSYqCmAc200feOADWt3QpyV9iigndvbmD69qVASw0jgoO39UKeUvJRCq'
    };

    final response = await http.post(postUrl,
        body: json.encode(data),
        encoding: Encoding.getByName('utf-8'),
        headers: headers);

    print('SendNotification: ${response.body}');
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  void saveUserInfo(User user) {
    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    _prefs.then((pref) {
      pref.setString('id', user.id);
      pref.setString('fullname', user.fullname);
      pref.setString('email', user.email);
      pref.setString('number', user.number);
      pref.setString('msgId', user.msgId);
      pref.setString('uid', user.uid);
      pref.setString('device_info', user.device_info);
      pref.setString('referralCode', user.referralCode);
      pref.setString('country', user.country);
      pref.setBool('userBlocked', user.userBlocked);
    });
  }

  User getUser() {
    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    //User users;
    _prefs.then((pref) {
      return new User(
          pref.getString('id'),
          pref.getString('fullname'),
          pref.getString('email'),
          pref.getString('number'),
          pref.getString('msgId'),
          pref.getString('uid'),
          pref.getString('device_info'),
          pref.getString('referralCode'),
          pref.getString('country'),
          pref.getBool('userBlocked'));
    });
    return null;
  }

  double distance(
      double lat1, double lon1, double lat2, double lon2, String unit) {
    if ((lat1 == lat2) && (lon1 == lon2)) {
      return 0;
    } else {
      double theta = lon1 - lon2;
      double dist = sin(radians(lat1)) * sin(radians(lat2)) +
          cos(radians(lat1)) * cos(radians(lat2)) * cos(radians(theta));
      dist = acos(dist);
      dist = degrees(dist);
      dist = dist * 60 * 1.1515;
      if (unit == "K") {
        dist = dist * 1.609344;
      } else if (unit == "N") {
        dist = dist * 0.8684;
      }
      return (dist);
    }
  }
}
