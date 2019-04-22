import 'package:firebase_database/firebase_database.dart';

class DriverDetails {

  String fullname, vehicle_model,vehicle_plate_number, rating, number, image, email;

  DriverDetails.fromSnapshot(DataSnapshot snapshot){
      fullname = snapshot.value['fullname'];
      vehicle_model = snapshot.value['vehicle_model'];
      vehicle_plate_number = snapshot.value['vehicle_plate_number'];
      rating = snapshot.value['rating'];
      number = snapshot.value['number'];
      image = snapshot.value['image'];
      email = snapshot.value['email'];
  }
}