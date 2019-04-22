import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vifaa_express/Users/home_user.dart';
import 'package:vifaa_express/Users/user_login.dart';
import 'package:vifaa_express/Utility/MyColors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  //MapView.setApiKey("AIzaSyDlMdDnOh3BQtZhF8gku4Xq1uFB-ZhLdig");
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'VifaaExpress',
      theme: new ThemeData(
          fontFamily: 'Montserrat',
          primarySwatch: MaterialColor(0xFF6644A3, <int, Color>{
            50: const Color(0xFF6644A3),
            100: const Color(0xFF6644A3),
            200: const Color(0xFF6644A3),
            300: const Color(0xFF6644A3),
            400: const Color(0xFF6644A3),
            500: const Color(0xFF6644A3),
            600: const Color(0xFF6644A3),
            700: const Color(0xFF6644A3),
            800: const Color(0xFF6644A3),
            900: const Color(0xFF6644A3),
          }),
          accentColor: Color(MyColors().secondary_color)),
      debugShowCheckedModeBanner: false,
      home: new MyHomePage(title: 'VifaaExpress'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Timer _timer;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  _MyHomePageState() {
    FirebaseAuth.instance.currentUser().then((user) {
      _timer = new Timer(new Duration(seconds: 3), () {
        _prefs.then((p) {
          bool isLogged =
              (p.getBool('isLogged') == null) ? false : p.getBool('isLogged');
          if (isLogged && user != null) {
            Route route =
                MaterialPageRoute(builder: (context) => UserHomePage());
            Navigator.pushReplacement(context, route);
          } else {
            Route route = MaterialPageRoute(builder: (context) => UserLogin());
            Navigator.pushReplacement(context, route);
          }
        });
      });
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    if (_timer != null) {
      _timer.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: new Center(
            child: new Container(
          child: Image.asset('sus_middle.png'),
          alignment: Alignment.center,
        )),
      ),
    );
//    return Stack(
//      children: <Widget>[
////        Positioned.fill(
////            child: new Container(
////              child: Image.asset('sus_top.png'),
////              alignment: Alignment.topRight,
////            )
////        ),
//        new Center(
//            child: new Container(
//          child: Image.asset('sus_middle.png'),
//          alignment: Alignment.center,
//        )),
////        new Container(
////          child: Image.asset('sus_bottom.png'),
////          alignment: Alignment.bottomLeft,
////        ),
//      ],
//    );
  }
}
