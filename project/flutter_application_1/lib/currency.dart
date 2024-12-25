import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CurrencyPage extends StatefulWidget {
  const CurrencyPage({super.key});

  @override
  _CurrencyPageState createState() => _CurrencyPageState();
}

class _CurrencyPageState extends State<CurrencyPage> {
  List<Map<String, dynamic>> currencies = [];
  bool isLoading = true;

  // Контроллеры для полей ввода в диалоге
  TextEditingController codeController = TextEditingController();
  TextEditingController amountController = TextEditingController();

  // Переменная для статуса основной валюты
  bool isMainCurrency = false;

  // Получение валют с сервера
  Future<void> _getCurrencies() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('https://retrochelik228.pythonanywhere.com/api/api/currencies/');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          currencies = data.map((currency) {
            return {
              'id': currency['id'],  // ID для уникальности
              'code': currency['code'],
              'amount': currency['amount'].toString(),
              'is_main': currency['is_main'], // Основная валюта
            };
          }).toList();
        });
      } else {
        throw Exception('Не удалось загрузить валюты');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ошибка при загрузке валют.'), // Сообщение об ошибке
      ));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Функция для добавления валюты на сервер
  Future<void> _addCurrency() async {
    final String code = codeController.text;
    final String amount = amountController.text;

    if (code.isNotEmpty && amount.isNotEmpty) {
      final url = Uri.parse('https://retrochelik228.pythonanywhere.com/api/api/currencies/');
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'code': code,
            'amount': amount,
            'is_main': isMainCurrency, // Отправляем статус основной валюты
          }),
        );

        if (response.statusCode == 201) {
          _getCurrencies(); // Обновляем валюты после добавления
          Navigator.pop(context);
          codeController.clear();
          amountController.clear();
        } else {
          throw Exception('Ошибка при добавлении валюты');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ошибка при добавлении валюты.'),
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Пожалуйста, заполните все поля!'),
      ));
    }
  }

  // Диалоговое окно для добавления валюты
  void _showAddCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Добавить валюту'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Код валюты',
                ),
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Количество',
                ),
                keyboardType: TextInputType.number,
              ),
              Row(
                children: [
                  const Text('Основная валюта:'),
                  Checkbox(
                    value: isMainCurrency,
                    onChanged: (bool? value) {
                      setState(() {
                        isMainCurrency = value ?? false; // Убедимся, что получаем boolean значение
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Закрыть окно без сохранения
              },
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: _addCurrency,
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _getCurrencies(); // Загружаем валюты при инициализации
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Валюта'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: currencies.length,
              itemBuilder: (context, index) {
                final currency = currencies[index];
                return ListTile(
                  title: Text(currency['code']),
                  subtitle: Text('Количество: ${currency['amount']}'),
                  trailing: currency['is_main']
                      ? const Icon(Icons.star, color: Colors.yellow) // Иконка для основной валюты
                      : const Icon(Icons.currency_exchange),
                );
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 30.0),
        child: FloatingActionButton(
          onPressed: _showAddCurrencyDialog,
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
