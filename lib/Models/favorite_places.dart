import 'package:firebase_database/firebase_database.dart';

class FavoritePlaces {
  String id, loc_name, loc_address, latitude, longitude, type;

  FavoritePlaces(this.id, this.loc_name, this.loc_address, this.latitude, this.longitude, this.type);

  Map<String, dynamic> toJSON(){
    return new Map.from({
      'id':id,
      'loc_name':loc_name,
      'loc_address':loc_address,
      'latitude':latitude,
      'longitude':longitude,
      'type':type
    });
  }

  FavoritePlaces.fromSnapshot(DataSnapshot snapshot){
    id = snapshot.value['id'];
    loc_name = snapshot.value['loc_name'];
    loc_address = snapshot.value['loc_address'];
    latitude = snapshot.value['latitude'];
    longitude = snapshot.value['longitude'];
    type = snapshot.value['type'];
  }

  FavoritePlaces.fromJson(var snapshot){
    id = snapshot['id'];
    loc_name = snapshot['loc_name'];
    loc_address = snapshot['loc_address'];
    latitude = snapshot['latitude'];
    longitude = snapshot['longitude'];
    type = snapshot['type'];
  }
}