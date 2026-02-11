import 'package:flutter/material.dart';
import 'package:eats/utils/constants.dart';

// Color(0xffDA4167)

ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.lightGreen),
  scaffoldBackgroundColor: Color(0xff0f0f0f),
  appBarTheme: AppBarTheme(
      backgroundColor: Color(0xff0F1020),
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: Color(0xffD6E3F8),
      )),
  cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadiusGeometry.circular(25.0) // for making the cards round
          ),
      elevation: 6,
      shadowColor: Color(0xff66635b)),
  buttonTheme: ButtonThemeData(),
  inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.lightGreen),
      )),
  textTheme: TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.grey)),
);
