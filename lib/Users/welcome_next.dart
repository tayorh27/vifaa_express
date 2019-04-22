import 'package:flutter/material.dart';
import 'package:vifaa_express/Users/home_user.dart';
import 'package:vifaa_express/Utility/MyColors.dart';

class OpenWelcomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _OpenWelcomePage();
}

class _OpenWelcomePage extends State<OpenWelcomePage> {
  PageController ctrl = new PageController(viewportFraction: 0.8);
  int currentPage = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    ctrl.addListener(() {
      int next = ctrl.page.round();
      if (currentPage != next) {
        setState(() {
          currentPage = next;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        floatingActionButton: new FloatingActionButton(
            backgroundColor: Color(MyColors().wrapper_color),
            foregroundColor: Color(MyColors().secondary_color),
            onPressed: () {
              Route route =
                  MaterialPageRoute(builder: (context) => UserHomePage());
              Navigator.pushReplacement(context, route);
            },
            child: Icon(Icons.arrow_forward, color: Colors.white),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(50.0)))),
        body: PageView(
          scrollDirection: Axis.horizontal,
          controller: ctrl,
          children: <Widget>[
            buildItem('https://images.pexels.com/photos/799443/pexels-photo-799443.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940', 'SLIDE 1'),
            buildItem('https://images.pexels.com/photos/1173777/pexels-photo-1173777.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500', 'SLIDE 2'),
            buildItem('https://images.pexels.com/photos/402185/pexels-photo-402185.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500', 'SLIDE 3'),
          ],
        ));
  }

  Widget buildItem(String image, String text) {
    final blur = 30.0;
    double offset = 20.0;
    final top = 60.0;

    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOutQuint,
      margin: EdgeInsets.only(top: top, bottom: 60.0, right: 30.0),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          image: DecorationImage(image: NetworkImage(image), fit: BoxFit.cover),
          boxShadow: [
            BoxShadow(
                color: Colors.black87,
                blurRadius: blur,
                offset: Offset(offset, offset))
          ]),
      child: Center(
        child: Text(
          text,
          style: TextStyle(fontSize: 40.0, color: Colors.white),
        ),
      ),
    );
  }
}
