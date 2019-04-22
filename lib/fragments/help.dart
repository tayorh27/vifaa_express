import 'package:flutter/material.dart';
import 'package:vifaa_express/Users/home_user.dart';
import 'package:vifaa_express/Utility/MyColors.dart';
import 'package:vifaa_express/Utility/Utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zendesk/zendesk.dart';

const ZendeskApiKey = '6F888hSdWpJ789mZlJnOZ2rgpuHaTUgP';//'6DHspQwAAkhx6nw9oOuv4LXCmQbtf03Lp4yxadQRr2mdWuo6Us9GnEza562rteEo';

class HelpPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HelpPage();
}

class _HelpPage extends State<HelpPage> {

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  String _email = '', _name='', _number='';

  Future<Null> _launchInWebViewOrVC(String url) async {
    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: true, forceWebView: true);
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

  final Zendesk zendesk = Zendesk();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initZendesk();
  }

  Future<void> initZendesk() async {
    zendesk.init(ZendeskApiKey).then((r) {
      print('init finished');
    }).catchError((e) {
      print('failed with error $e');
    });

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    _prefs.then((pref) {
      setState(() {
        _email = pref.getString('email');
        _name = pref.getString('fullname');
        _number = pref.getString('number');
      });
    });
    zendesk.setVisitorInfo(
      name: _name,
      email: _email,
      phoneNumber: _number
    ).then((r) {
      print('setVisitorInfo finished');
    }).catchError((e) {
      print('error $e');
    });
    // TODO: implement build
    return new Scaffold(
        backgroundColor: Color(MyColors().primary_color),
        appBar: new AppBar(
          title: new Text('Help',
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
        body: new Container(
          margin: EdgeInsets.only(top: 20.0),
          child: new ListView(
            scrollDirection: Axis.vertical,
            children: <Widget>[
              new ListTile(
                title: new Text('Blog', style: TextStyle(color: Colors.white),),
                leading: new Icon(Icons.edit, color: Colors.white,),
                enabled: true,
                trailing: new Icon(Icons.keyboard_arrow_right, color: Colors.white,),
                onTap: (){
                  const url = 'http://vifaaexpress.com/blog';
                  _launchInWebViewOrVC(url);
                },
              ),
              Divider(color: Color(MyColors().secondary_color),),
              new ListTile(
                title: new Text('Chat with us', style: TextStyle(color: Colors.white),),
                leading: new Icon(Icons.chat, color: Colors.white,),
                enabled: true,
                trailing: new Icon(Icons.keyboard_arrow_right, color: Colors.white,),
                onTap: (){
                  zendesk.startChat().then((r) {
                    print('startChat finished');
                  }).catchError((e) {
                    print('error $e');
                  });
                },
              ),
              Divider(color: Color(MyColors().secondary_color),),
              new ListTile(
                title: new Text('Contact us', style: TextStyle(color: Colors.white),),
                leading: new Icon(Icons.call, color: Colors.white,),
                enabled: true,
                trailing: new Icon(Icons.keyboard_arrow_right, color: Colors.white,),
                onTap: (){
                  const url = 'tel:+2349082606602';
                  _launchURL(url);
                },
              ),
              Divider(color: Color(MyColors().secondary_color),),
              new ListTile(
                title: new Text('Email us', style: TextStyle(color: Colors.white),),
                leading: new Icon(Icons.email, color: Colors.white,),
                enabled: true,
                trailing: new Icon(Icons.keyboard_arrow_right, color: Colors.white,),
                onTap: (){
                  const url = 'mailto:support@vifaaexpress.com?subject=New Support&body=How%20may%20we%20assist%20you?';
                  _launchURL(url);
                },
              ),
              Divider(color: Color(MyColors().secondary_color),),
              new ListTile(
                title: new Text('FAQ', style: TextStyle(color: Colors.white),),
                leading: new Icon(Icons.question_answer, color: Colors.white,),
                enabled: true,
                trailing: new Icon(Icons.keyboard_arrow_right, color: Colors.white,),
                onTap: (){
                  const url = 'http://vifaaexpress.com/faq';
                  _launchInWebViewOrVC(url);
                },
              ),
              Divider(color: Color(MyColors().secondary_color),),
              new ListTile(
                title: new Text('Visit our website', style: TextStyle(color: Colors.white),),
                leading: new Icon(Icons.web, color: Colors.white,),
                enabled: true,
                trailing: new Icon(Icons.keyboard_arrow_right, color: Colors.white,),
                onTap: (){
                  const url = 'http://vifaaexpress.com/';
                  _launchInWebViewOrVC(url);
                },
              ),
              Divider(color: Color(MyColors().secondary_color),),

            ],
          ),
        ));
  }
}
