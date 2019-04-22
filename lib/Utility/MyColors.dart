import 'package:flutter/material.dart';

class MyColors {

//  final int primary_color = 0xFF21252E;
//  final int secondary_color = 0xFFFFCA40;
//  final int wrapper_color = 0xFF16181E;
//  final int button_text_color = 0xFF12161E;

  final int primary_color = 0xFF6644A3;
  final int secondary_color = 0xFFFFB100;
  final int wrapper_color = 0xFF8064B3;
  final int button_text_color = 0xFF12161E;

  Color hexToColor(String code) {
    return new Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
  }

  hexStringToHexInt(String hex) {
    hex = hex.replaceFirst('#', '');
    hex = hex.length == 6 ? 'ff' + hex : hex;
    int val = int.parse(hex, radix: 16);
    return val;
  }

}