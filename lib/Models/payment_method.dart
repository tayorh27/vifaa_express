import 'package:firebase_database/firebase_database.dart';

class PaymentMethods {
  String id, payment_code, number;
  bool available;
  PaymentMethods(this.id, this.payment_code, this.number, this.available);

  Map<String, dynamic> toJSON() {
    return new Map.from({
      'id': id,
      'payment_code': payment_code,
      'number': number,
      'available': available
    });
  }

  PaymentMethods.fromJson(var snapshot) {
    id = snapshot['id'];
    payment_code = snapshot['payment_code'];
    number = snapshot['number'];
    available = snapshot['available'];
  }

  PaymentMethods.fromSnapShot(DataSnapshot snapshot){
    id = snapshot.value['id'];
    payment_code = snapshot.value['payment_code'];
    number = snapshot.value['number'];
    available = snapshot.value['available'];
  }
}