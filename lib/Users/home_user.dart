import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:vifaa_express/Models/user.dart';
import 'package:vifaa_express/Users/user_login.dart';
import 'package:vifaa_express/Utility/MyColors.dart';
import 'package:vifaa_express/Utility/Utils.dart';
import 'package:vifaa_express/fragments/first_fragment.dart';
import 'package:vifaa_express/fragments/free_rides.dart';
import 'package:vifaa_express/fragments/help.dart';
import 'package:vifaa_express/fragments/legal.dart';
import 'package:vifaa_express/fragments/payment.dart';
import 'package:vifaa_express/fragments/settings.dart';
import 'package:vifaa_express/fragments/trips.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class UserHomePage extends StatefulWidget {
  final drawerItems = [
    new DrawerItem("Home", sidebarIcons(innerIcon: Icons.home), new Text('')),
    new DrawerItem(
        "Your Trips", sidebarIcons(innerIcon: Icons.directions), new Text('')),
    new DrawerItem(
        "Payment", sidebarIcons(innerIcon: Icons.payment), new Text('')),
    new DrawerItem("Help", sidebarIcons(innerIcon: Icons.help), new Text('')),
    new DrawerItem("Free Rides", sidebarIcons(innerIcon: Icons.free_breakfast),
        new Text('')),
    new DrawerItem(
        "Settings", sidebarIcons(innerIcon: Icons.settings), new Text('')),
    new DrawerItem(
        "Legal",
        sidebarIcons(innerIcon: Icons.pages),
        new Text(
          'v1.0',
          style: TextStyle(color: Colors.white),
        ))
  ];

  @override
  State<StatefulWidget> createState() => _UserHomePage();
}

Widget sidebarIcons({IconData innerIcon}) {
  return Container(
    width: 39.0,
    height: 39.0,
    decoration: new BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Color(MyColors().secondary_color), width: 1.0),
    ),
    child: Icon(
      innerIcon,
      color: Colors.white,
      size: 18.0,
    ),
  );
}

class DrawerItem {
  String title;

  //IconData icon;
  Widget icon;
  Widget trailing;

  DrawerItem(this.title, this.icon, this.trailing);
}

class _UserHomePage extends State<UserHomePage> {
  GlobalKey<ScaffoldState> _key = new GlobalKey<ScaffoldState>();

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  int _selectedDrawerIndex = 0;
  Utils utils = new Utils();
  User user;
  bool isAppBar = false;
  bool isStack = true;
  String _name = '', _email = '';
  bool destination_entered = false;

  _getDrawerItemWidget(int pos) {
    switch (pos) {
      case 0:
        return new MapFragment();
      case 1:
        _closeAppBar();
        return new MyTrips();
      case 2:
        _closeAppBar();
        return new Payment(false);
      case 3:
        _closeAppBar();
        return new HelpPage();
      case 4:
        _closeAppBar();
        return new FreeRides();
      case 5:
        _closeAppBar();
        return new Settings();
      case 6:
        _closeAppBar();
        return new LegalPage();
      default:
        return new MapFragment();
    }
  }

  _closeAppBar() {
    setState(() {
      isStack = false;
      isAppBar = false;
    });
  }

  _onSelectItem(int index) {
    setState(() => _selectedDrawerIndex = index);
    Navigator.of(context).pop(); // close the drawer
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  _checkBlockStatus() async {
    DatabaseReference checkBlock = FirebaseDatabase.instance
        .reference()
        .child('users/${_email.replaceAll('.', ',')}/signup');
    checkBlock.once().then((data) {
      bool userBlocked = data.value['userBlocked'];
      if (userBlocked) {
        new Utils().neverSatisfied(context, 'User Blocked',
            'Sorry you have been blocked from this account. Please contact support for futher assistance.');
        _prefs.then((pref) {
          pref.clear();
        });
        FirebaseAuth.instance.signOut();
        Route route = MaterialPageRoute(builder: (context) => UserLogin());
        Navigator.pushReplacement(context, route);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _prefs.then((pref) {
      setState(() {
        _name = pref.getString('fullname');
        _email = pref.getString('email');
      });
    });
    var drawerOptions = <Widget>[];
    for (var i = 0; i < widget.drawerItems.length; i++) {
      var d = widget.drawerItems[i];
      drawerOptions.add(new ListTile(
        leading: d.icon,
        title: new Text(
          d.title,
          style: TextStyle(color: Colors.white, fontSize: 19.0),
        ),
        trailing: d.trailing,
        selected: i == _selectedDrawerIndex,
        onTap: () => _onSelectItem(i),
      ));
    }
    listenForDestinationEntered();
    _checkBlockStatus();
    // TODO: implement build
    return new Scaffold(
      key: _key,
      appBar: (isAppBar)
          ? new AppBar(
              title:
                  new Text('')) //widget.drawerItems[_selectedDrawerIndex].title
          : null,
      drawer: new Drawer(
          child: new Container(
              color: Color(MyColors().button_text_color),
              child: new ListView(children: <Widget>[
                new Column(
                  children: <Widget>[
                    new UserAccountsDrawerHeader(
                      accountName: new Text((_name == null) ? '' : _name),
                      accountEmail: new Text((_email == null) ? '' : _email),
                      currentAccountPicture: new Container(
                          width: 100.0,
                          height: 100.0,
                          decoration: new BoxDecoration(
                              shape: BoxShape.circle,
                              image: new DecorationImage(
                                fit: BoxFit.cover,
                                image: AssetImage('user_dp.png'),
                              ))),
                    ),
                    new Divider(
                      color: Color(MyColors().secondary_color),
                      height: 1.0,
                    ),
                    new Container(
                        margin: EdgeInsets.only(top: 10.0, bottom: 10.0),
                        padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                        color: Color(MyColors().secondary_color),
                        child: Center(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                'Do more with your account',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w900),
                              ),
                              new Container(
                                  margin:
                                      EdgeInsets.only(left: 20.0, right: 20.0),
                                  child: new RaisedButton(
                                    child: new Text('Make money while driving',
                                        style: new TextStyle(
                                            fontSize: 13.0,
                                            color: Color(
                                                MyColors().button_text_color))),
                                    color: Color(MyColors().secondary_color),
                                    disabledColor: Colors.grey,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(30.0)),
                                    ),
                                    onPressed: driverClick,
                                  )),
                            ],
                          ),
                        )),
                    new Divider(
                      color: Color(MyColors().secondary_color),
                      height: 1.0,
                    ),
                    new Column(children: drawerOptions),
                    new Container(
                      margin: EdgeInsets.only(top: 20.0, bottom: 20.0),
                      child: new Divider(
                        color: Color(MyColors().secondary_color),
                        height: 1.0,
                      ),
                    )
                  ],
                ),
              ]))),
      body: (!isStack)
          ? _getDrawerItemWidget(_selectedDrawerIndex)
          : new Padding(
              padding: EdgeInsets.only(top: 25.0),
              child: new Stack(
                fit: StackFit.passthrough,
                children: <Widget>[
                  _getDrawerItemWidget(_selectedDrawerIndex),
                  (!destination_entered)
                      ? new IconButton(
                          icon: Icon(
                            Icons.person_pin,
                            color: Color(MyColors().primary_color),
                            size: 48.0,
                          ),
                          onPressed: () {
                            _key.currentState.openDrawer();
                          })
                      : new IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: Color(MyColors().primary_color),
                            size: 24.0,
                          ),
                          onPressed: () {
                            setCancelModeForDestination();
                          }),
                ],
              )),
    );
  }

  Future<void> listenForDestinationEntered() async {
    DatabaseReference ref = FirebaseDatabase.instance.reference().child(
        'users/${_email.replaceAll('.', ',')}/trips/current_trip_status');
    await ref.once().then((val) {
      if (val != null) {
        String value = val.value;
        if (value == 'request') {
          setState(() {
            destination_entered = true;
          });
        } else if (value == 'none') {
          setState(() {
            destination_entered = false;
          });
        }
      }
    });
  }

  Future<void> setCancelModeForDestination() async {
    DatabaseReference ref = FirebaseDatabase.instance.reference().child(
        'users/${_email.replaceAll('.', ',')}/trips/current_trip_status');
    await ref.set('none').whenComplete(() {
      setState(() {
        destination_entered = false;
      });
    });
  }

  Future<Null> driverClick() async {
    if (await canLaunch('https://gidiridedriver.page.link/Zi7X')) {
      await launch('https://gidiridedriver.page.link/Zi7X',
          forceSafariVC: true, forceWebView: true);
    } else {
      new Utils().showToast('Cannot open parameter.', false);
    }
  }

  Future<Null> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
