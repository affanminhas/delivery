import 'package:delivery/constants/app_constants.dart';
import 'package:delivery/views/order_tracking_view.dart';
import 'package:flutter/material.dart';

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: Constants.appName,
      home: OrderTrackingView(),
    );
  }
}
