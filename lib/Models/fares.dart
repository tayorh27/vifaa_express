import 'package:firebase_database/firebase_database.dart';

class Fares {
  String min_fare, per_distance, per_duration, start_fare, wait_time_fee;

  Fares(this.min_fare, this.per_distance, this.per_duration, this.start_fare,
      this.wait_time_fee);

  Map<String, dynamic> toJSON() {
    return new Map.from({
      'min_fare': min_fare,
      'per_distance': per_distance,
      'per_duration': per_duration,
      'start_fare': start_fare,
      'wait_time_fee': wait_time_fee
    });
  }

  Fares.fromSnapshot(DataSnapshot snapshot) {
    min_fare = snapshot.value['min_fare'];
    per_distance = snapshot.value['per_distance'];
    per_duration = snapshot.value['per_duration'];
    start_fare = snapshot.value['start_fare'];
    wait_time_fee = snapshot.value['wait_time_fee'];
  }

  Fares.fromJson(var snapshot) {
    min_fare = snapshot['min_fare'];
    per_distance = snapshot['per_distance'];
    per_duration = snapshot['per_duration'];
    start_fare = snapshot['start_fare'];
    wait_time_fee = snapshot['wait_time_fee'];
  }
}
