import 'package:flutter/material.dart';
import 'package:flutter_project/controllers/localization_controller.dart';
import 'package:flutter_project/views/ReloadSplashScreen.dart';
import 'package:flutter_project/views/WelcomeBack.dart';
import 'package:flutter_project/views/bottom_navigation_helper.dart';
import 'package:flutter_project/views/entries/entries.dart';
import 'package:flutter_project/views/home.dart';
import 'package:flutter_project/views/invoices.dart';
import 'package:flutter_project/views/login/Profile.dart';
import 'package:flutter_project/views/orders.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'locals/localization.dart';

void main() async {
  await GetStorage.init();
  // Load the selected language from GetStorage and set it to the controller
  LocalizationController localizationController =
      Get.put(LocalizationController());
  var savedLanguage = GetStorage().read<String>('language');
  if (savedLanguage != null && savedLanguage.isNotEmpty) {
    localizationController.currentLanguage.value = savedLanguage;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: getRememberMeStatus(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          bool rememberMe = snapshot.data!;
          Widget initialRoute =
              rememberMe ? ReloadSplashScreen() : WelcomeBackPage();
          debugPrint('$rememberMe');
          return GetMaterialApp(
            translations: Localization(), // Initialize the Localization class
            locale: Locale('en', 'US'), // Set the default locale for the app
            fallbackLocale: Locale('en', 'US'), // Set the fallback locale
            debugShowCheckedModeBanner: false,
            initialRoute: '/',
            getPages: [
              GetPage(name: '/', page: () => initialRoute),
              GetPage(name: '/login', page: () => WelcomeBackPage()),
              GetPage(name: '/home', page: () => Home()),
              GetPage(name: '/Profile', page: () => Profile()),
              GetPage(
                  name: '/Entries',
                  page: () => Entries(
                      bottomNavigationBar: handleBottomNavigationBar(1))),
              GetPage(name: '/Orders', page: () => Orders()),
              GetPage(name: '/Orders', page: () => Invoices()),
            ],
          );
        } else {
          // Show a loading indicator or splash screen while checking the status
          return CircularProgressIndicator();
        }
      },
    );
  }

  Future<bool> getRememberMeStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool rememberMeStatus = prefs.getBool('rememberMe') ?? false;
    return rememberMeStatus;
  }
}
