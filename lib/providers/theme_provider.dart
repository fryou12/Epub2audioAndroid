import 'package:flutter/material.dart';
import '../constants/colors.dart';

class ThemeProvider extends ChangeNotifier {
  static final ThemeProvider _instance = ThemeProvider._internal();
  factory ThemeProvider() => _instance;
  ThemeProvider._internal();

  bool get isDarkTheme => AppColors.current == AppColors.darkTheme;

  void toggleTheme() {
    AppColors.current = AppColors.current == AppColors.lightTheme 
        ? AppColors.darkTheme 
        : AppColors.lightTheme;
    notifyListeners();
  }
}
