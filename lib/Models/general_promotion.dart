import 'package:firebase_database/firebase_database.dart';

class GeneralPromotions {
  String id,
      discount_type,
      discount_value,
      expires,
      maximum_value,
      number_of_rides_used,
      promo_code;
  bool status;
  GeneralPromotions(this.id, this.discount_type, this.discount_value,
      this.expires, this.maximum_value, this.number_of_rides_used, this.promo_code, this.status);

  Map<String, dynamic> toJSON(){
    return new Map.from({
      'id':id,
      'discount_type':discount_type,
      'discount_value':discount_value,
      'expires':expires,
      'maximum_value':maximum_value,
      'number_of_rides_used':number_of_rides_used,
      'promo_code':promo_code,
      'status':status
    });
  }

  GeneralPromotions.fromJson(var snapshot) {
    id = snapshot['id'];
    discount_type = snapshot['discount_type'];
    discount_value = snapshot['discount_value'];
    expires = snapshot['expires'];
    maximum_value = snapshot['maximum_value'];
    number_of_rides_used = snapshot['number_of_rides_used'];
    promo_code = snapshot['promo_code'];
    status = snapshot['status'];
  }

  GeneralPromotions.fromSnapShot(DataSnapshot snapshot){
    id = snapshot.value['id'];
    discount_type = snapshot.value['discount_type'];
    discount_value = snapshot.value['discount_value'];
    expires = snapshot.value['expires'];
    maximum_value = snapshot.value['maximum_value'];
    number_of_rides_used = snapshot.value['number_of_rides_used'];
    promo_code = snapshot.value['promo_code'];
    status = snapshot.value['status'];
  }
}