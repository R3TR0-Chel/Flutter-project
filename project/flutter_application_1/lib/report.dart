import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  double totalKgsAmount = 0.0;
  double averageBuyRate = 0.0;
  double averageSellRate = 0.0;
  double profit = 0.0;

  List<dynamic> transactions = [];  // Список транзакций

  @override
  void initState() {
    super.initState();
    fetchReport();  // Запрашиваем отчет при загрузке страницы
  }

  // Метод для запроса отчета с API
  Future<void> fetchReport() async {
    try {
      // Запрос для отчета
      final reportResponse = await http.get(Uri.parse('https://retrochelik228.pythonanywhere.com/api/api/reports/'));
      
      if (reportResponse.statusCode == 200) {
        Map<String, dynamic> data = json.decode(reportResponse.body);
        setState(() {
          totalKgsAmount = data['total_kgs_amount'];
          averageBuyRate = data['average_buy_rate'];
          averageSellRate = data['average_sell_rate'];
          profit = data['profit'];
        });
      } else {
        throw Exception('Не удалось загрузить отчет');
      }

      // Запрос для истории транзакций
      final transactionsResponse = await http.get(Uri.parse('https://retrochelik228.pythonanywhere.com/api/api/transactions/'));

      if (transactionsResponse.statusCode == 200) {
        List<dynamic> transactionData = json.decode(transactionsResponse.body);
        setState(() {
          transactions = transactionData;
        });
      } else {
        throw Exception('Не удалось загрузить историю транзакций');
      }
    } catch (e) {
      print('Ошибка при загрузке отчета: $e');
    }
  }

  // Метод для форматирования даты
  String formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);  // Преобразование строки в объект DateTime
      return '${date.day}-${date.month}-${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return 'Неверный формат даты';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отчет'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Контейнер с количеством KGS, средним курсом и прибылью
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('KGS в базе: $totalKgsAmount'),
                Row(
                  children: [
                    Text('Средний курс покупки: ${averageBuyRate.toStringAsFixed(2)}'),
                    const SizedBox(width: 10),
                    Text('Средний курс продажи: ${averageSellRate.toStringAsFixed(2)}'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Прибыль: $profit'),
            const SizedBox(height: 20),
            // Список транзакций
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  var transaction = transactions[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text('Пользователь: ${transaction['user']}'),
                      subtitle: Text(
                          'Валюта: ${transaction['currency']}, Сумма: ${transaction['amount']}, Курс: ${transaction['rate']}, Статус: ${transaction['status']}, Дата: ${formatDate(transaction['date'] ?? '')}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
