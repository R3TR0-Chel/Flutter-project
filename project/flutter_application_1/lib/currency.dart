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
              'id': currency['id'],
              'code': currency['code'],
              'amount': currency['amount'].toString(),
              'is_main': currency['is_main'],
            };
          }).toList();
        });
      } else {
        throw Exception('Не удалось загрузить валюты');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ошибка при загрузке валют.'),
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
            'is_main': isMainCurrency,
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

  // Функция для добавления количества к валюте
  Future<void> _addAmountToCurrency(String code, String amount) async {
    final url = Uri.parse('https://retrochelik228.pythonanywhere.com/api/api/currencies/add_amount/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'code': code,
          'amount': amount,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Успешно добавлено: ${data['new_amount']}'),
        ));
        _getCurrencies(); // Обновляем список валют
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ошибка: $e'),
      ));
    }
  }

  // Диалоговое окно для добавления количества к валюте
  void _showAddAmountDialog(String code) {
    TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Добавить количество к $code'),
          content: TextField(
            controller: amountController,
            decoration: const InputDecoration(labelText: 'Количество'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                final amount = amountController.text;
                if (amount.isNotEmpty) {
                  _addAmountToCurrency(code, amount);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Введите количество!')),
                  );
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
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
                        isMainCurrency = value ?? false;
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
                Navigator.pop(context);
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
    _getCurrencies();
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      currency['is_main']
                          ? const Icon(Icons.star, color: Colors.yellow)
                          : const Icon(Icons.currency_exchange),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          _showAddAmountDialog(currency['code']);
                        },
                      ),
                    ],
                  ),
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
