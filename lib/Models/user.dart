import 'package:firebase_database/firebase_database.dart';

class User {

  String id, fullname,email,number,msgId,uid,device_info, referralCode, country;
  bool userBlocked;

  User(this.id, this.fullname, this.email, this.number, this.msgId,this.uid,this.device_info, this.referralCode, this.country,
      this.userBlocked);

//  Map<String, dynamic> toJSON() {
//    return new Map.from({
//      'id': id,
//      'fullname': fullname,
//      'number': number,
//      'available': available,
//      'maximum_value': maximum_value,
//      'number_of_rides_used': number_of_rides_used,
//      'promo_code': promo_code,
//      'status': status
//    });
//  }

  User.fromSnapshot(DataSnapshot snapshot){
    id = snapshot.value['id'];
    fullname = snapshot.value['fullname'];
    email = snapshot.value['email'];
    number = snapshot.value['number'];
    msgId = snapshot.value['msgId'];
    uid = snapshot.value['uid'];
    device_info = snapshot.value['device_info'];
    referralCode = snapshot.value['referralCode'];
    country = snapshot.value['country'];
    userBlocked = snapshot.value['userBlocked'];
  }

}