import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  List<dynamic> _transactionHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactionHistory();
  }

  Future<void> _fetchTransactionHistory() async {
    try {
      final response = await http.get(
        Uri.parse('https://retrochelik228.pythonanywhere.com/api/api/transactions/'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _transactionHistory = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load transaction history');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Отобразить ошибку пользователю
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ошибка'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Событие'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _transactionHistory.isEmpty
              ? const Center(
                  child: Text('История транзакций отсутствует'),
                )
              : ListView.builder(
                  itemCount: _transactionHistory.length,
                  itemBuilder: (context, index) {
                    final transaction = _transactionHistory[index];
                    final currencyCode = transaction['currency']['code'] ?? 'Неизвестно';  // Получаем код валюты из объекта currency
                    return ListTile(
                      leading: Icon(
                        transaction['status'] == 'buy'
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: transaction['status'] == 'buy'
                            ? Colors.red
                            : Colors.green,
                      ),
                      title: Text('Валюта: $currencyCode'),  // Выводим код валюты
                      subtitle: Text(
                          'Курс: ${transaction['rate']}, Количество: ${transaction['amount']}'),
                      trailing: Text(
                        transaction['status'] == 'buy' ? 'Покупка' : 'Продажа',
                        style: TextStyle(
                          color: transaction['status'] == 'buy'
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

