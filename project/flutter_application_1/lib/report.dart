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

  List<dynamic> transactions = [];
  List<dynamic> filteredTransactions = [];
  List<String> currencies = ["Все валюты"];
  String selectedCurrency = "Все валюты";
  String selectedStatus = "Все";

  @override
  void initState() {
    super.initState();
    fetchReport();
  }

  Future<void> fetchReport() async {
    try {
      // Запрос отчета
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

      // Запрос истории транзакций
      final transactionsResponse = await http.get(Uri.parse('https://retrochelik228.pythonanywhere.com/api/api/transactions/'));
      if (transactionsResponse.statusCode == 200) {
        List<dynamic> transactionData = json.decode(transactionsResponse.body);
        setState(() {
          transactions = transactionData;
          filteredTransactions = transactions;

          // Получение списка уникальных валют
          currencies = ["Все валюты"];
          currencies.addAll(transactionData.map((t) => t['currency']['code']).toSet().cast<String>());
        });
      } else {
        throw Exception('Не удалось загрузить историю транзакций');
      }
    } catch (e) {
      print('Ошибка при загрузке отчета: $e');
    }
  }

  // Фильтрация транзакций
  void filterTransactions() {
    setState(() {
      filteredTransactions = transactions.where((transaction) {
        // Проверяем совпадение валюты
        final matchesCurrency = selectedCurrency == "Все валюты" || transaction['currency']['code'] == selectedCurrency;
        // Проверяем совпадение статуса
        final matchesStatus = selectedStatus == "Все" || transaction['status'] == selectedStatus;
        return matchesCurrency && matchesStatus;
      }).toList();

      // Проверяем результат фильтрации
      if (filteredTransactions.isEmpty) {
        print("Нет подходящих транзакций для текущих фильтров");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Касса'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('KGS в базе: $totalKgsAmount'),
                Row(
                  children: [
                    Text('Среднее значение покупки: ${averageBuyRate.toStringAsFixed(2)}'),
                    const SizedBox(width: 10),
                    Text('Среднее значение продажи: ${averageSellRate.toStringAsFixed(2)}'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Прибыль: $profit'),
            const SizedBox(height: 20),
            // Фильтры
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Выберите валюту:", style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButtonFormField<String>(
                        value: selectedCurrency,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                        ),
                        items: currencies.map((currency) {
                          return DropdownMenuItem(
                            value: currency,
                            child: Text(currency),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCurrency = value!;
                            filterTransactions();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Выберите статус:", style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                        ),
                        items: ["Все", "buy", "sell"].map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value!;
                            filterTransactions();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Список транзакций
            Expanded(
              child: ListView.builder(
                itemCount: filteredTransactions.length,
                itemBuilder: (context, index) {
                  var transaction = filteredTransactions[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text('Пользователь: ${transaction['user']}'),
                      subtitle: Text(
                          'Валюта: ${transaction['currency']['code']}, Сумма: ${transaction['amount']}, Курс: ${transaction['rate']}, Статус: ${transaction['status']}, Дата: ${transaction['timestamp']}'),
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
