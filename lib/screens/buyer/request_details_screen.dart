// Request Details Screen for Buyers

import 'package:flutter/material.dart';

class RequestDetailsScreen extends StatelessWidget {
  const RequestDetailsScreen({Key? key, required this.requestId})
      : super(key: key);

  final String requestId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الطلب'),
      ),
      body: Center(
        child: Text(
          'رقم الطلب: $requestId',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
