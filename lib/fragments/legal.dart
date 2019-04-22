import 'package:flutter/material.dart';
import 'package:vifaa_express/Users/home_user.dart';
import 'package:vifaa_express/Utility/MyColors.dart';
import 'package:vifaa_express/Utility/Utils.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LegalPage();
}

class _LegalPage extends State<LegalPage> {
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

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new Scaffold(
        backgroundColor: Color(MyColors().primary_color),
        appBar: new AppBar(
          title: new Text('Legal',
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
                title: new Text('Copyright', style: TextStyle(color: Colors.white),),
                leading: new Icon(Icons.branding_watermark, color: Colors.white,),
                enabled: true,
                trailing: new Icon(Icons.keyboard_arrow_right, color: Colors.white,),
                onTap: (){
                  const url = 'http://vifaaexpress.com/copyright';
                  _launchInWebViewOrVC(url);
                },
              ),
              Divider(color: Color(MyColors().secondary_color),),
              new ListTile(
                title: new Text('Privacy Policy', style: TextStyle(color: Colors.white),),
                leading: new Icon(Icons.security, color: Colors.white,),
                enabled: true,
                trailing: new Icon(Icons.keyboard_arrow_right, color: Colors.white,),
                onTap: (){
                  const url = 'http://vifaaexpress.com/privacy';
                  _launchInWebViewOrVC(url);
                },
              ),
              Divider(color: Color(MyColors().secondary_color),),
              new ListTile(
                title: new Text('Terms and Conditions', style: TextStyle(color: Colors.white),),
                leading: new Icon(Icons.wrap_text, color: Colors.white,),
                enabled: true,
                trailing: new Icon(Icons.keyboard_arrow_right, color: Colors.white,),
                onTap: (){
                  const url = 'http://vifaaexpress.com/terms';
                  _launchInWebViewOrVC(url);
                },
              ),
              Divider(color: Color(MyColors().secondary_color),),

            ],
          ),
        ));
  }
}
