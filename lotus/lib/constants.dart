import 'package:flutter/material.dart';


const auth1gradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF92A3FD),
    Color(0xFF9DCEFF),
  ],
);
const chatusergradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [
    Color(0xFFEEA4CE),
    Color(0xFFC58BF2),
  ],
);

const chatbotgradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [
    Color(0xFF9DCEFF),
    Color(0xFF92A3FD),
    
  ],
);

const white = Color(0xFFFFFFFF);
const black = Color(0xFF000000);
const peri = Color(0xFF5856D6);

const auth1heading = TextStyle(
  fontFamily: 'Inter',
  fontSize: 36,
  fontWeight: FontWeight.w700,
  color: Colors.white, 
  height: 1.5,
  letterSpacing: 0,
);
const auth1body = TextStyle(
  fontFamily: 'Inter',
  fontSize: 16,
  fontWeight: FontWeight.w700,
  color: Colors.white, 
  height: 1.5,
  letterSpacing: 0,
);
const onboardingheading = TextStyle(
  fontFamily: 'Inter',
  fontSize: 20,
  fontWeight: FontWeight.w700,
  color: Color(0xFF5856D6), 
  height: 1.5,
  letterSpacing: 0,
);  
const onboardingbody = TextStyle(
  fontFamily: 'Inter',
  fontSize: 12,
  fontWeight: FontWeight.w400,
  color: Color(0xFF5856D6), 
  height: 1.5,
  letterSpacing: 0,
);
const eventbody = TextStyle(
  fontFamily: 'Poppins-Regular',
  fontSize: 12,
  fontWeight: FontWeight.w400,
  color: Color(0xFF7B6F72), 
  height: 1.5,
  letterSpacing: 0,
);
const eventheading = TextStyle(
  fontFamily: 'Poppins-Bold',
  fontSize: 14,
  fontWeight: FontWeight.w500,
  color: Color(0xFF1D1617), 
  height: 1.5,
  letterSpacing: 0,
);
const chatbody = TextStyle(
  fontFamily: 'OpenSans-VariableFont_wdth,wght.ttf',
  fontSize: 12,
  fontWeight: FontWeight.w400,
  color: Color(0xFF000000), 
  height: 1.5,
  letterSpacing: 0,
);