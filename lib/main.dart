import 'package:flutter/material.dart';
import './home.dart';
import './properties.dart';

void main() async {
  await Property.init();
  runApp(OrgTodo());
}

class OrgTodo extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrgTodo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(title: 'OrgTodo'),
    );
  }
}
