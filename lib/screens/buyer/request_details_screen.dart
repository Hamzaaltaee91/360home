// Request Details Screen for Buyers

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RequestDetailsScreen extends StatelessWidget {
  const RequestDetailsScreen({Key? key, required this.requestId})
      : super(key: key);

  final String requestId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الطلب'),
        actions: [
          IconButton(
            tooltip: 'تعديل الطلب',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/edit-request/$requestId'),
          ),
        ],
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
