import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runaway/features/onboarding/screens/start_page.dart';
import 'package:runaway/features/running/running_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RunningProvider()),
      ],
      child: MaterialApp(
        title: 'Runaway',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const StartPage(),
      ),
    );
  }
}
