import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/data_provider.dart';
import 'views/home_page.dart';
import 'core/styles.dart';

void main() {
  runApp(const ExSlateApp());
}

/// Entry point for ExSlate - Excel reconciliation app
class ExSlateApp extends StatelessWidget {
  const ExSlateApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DataProvider(),
      child: MaterialApp(
        title: 'ExSlate - Excel Reconciliation',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: AppStyles.appBarTheme,
          elevatedButtonTheme: AppStyles.elevatedButtonTheme,
          inputDecorationTheme: AppStyles.inputDecorationTheme,
        ),
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
