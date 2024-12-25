import 'package:flutter/material.dart';

class CashboxPage extends StatelessWidget {
  const CashboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Касса'),
      ),
      body: const Center(
        child: Text('Страница кассы'),
      ),
    );
  }
}