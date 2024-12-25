import 'dart:convert';
import 'package:flutter/material.dart';
import 'login.dart'; // Login page import
import 'currency.dart'; // Currency page
import 'report.dart'; // Report page
import 'cash.dart'; // Cash page
import 'users.dart'; // Users page
import 'event.dart'; // Event page
import 'package:http/http.dart' as http;

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LoginPage(),  // Login screen as initial screen
    );
  }
}

class MainPage extends StatefulWidget {
  final String username; // User's name
  final int userId; // User's ID

  const MainPage({super.key, required this.username, required this.userId});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String selectedCurrency = ''; // Default currency
  int? selectedCurrencyId; // To store selected currency ID
  TextEditingController amountController = TextEditingController();
  TextEditingController rateController = TextEditingController();
  double result = 0;
  List<Map<String, dynamic>> currencies = []; // List to store currency codes and ids
  bool isLoading = true; // Flag to indicate if data is loading

  @override
  void initState() {
    super.initState();
    selectedCurrency = 'USD'; // Set default currency
    _loadCurrencies(); // Load currencies on initialization
  }

  // Function to load currencies from server
  Future<void> _loadCurrencies() async {
    final url = Uri.parse('https://retrochelik228.pythonanywhere.com/api/api/currencies');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          currencies = data.map((currency) {
            return {
              'id': currency['id'],   // Store currency ID
              'code': currency['code'], // Store currency code
            };
          }).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Не удалось загрузить валюты с сервера'),
        ));
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ошибка сети. Попробуйте снова.'), 
      ));
    }
  }

  // Function to add a transaction
 Future<void> _addTransaction(String transactionType) async {
  final double amount = double.tryParse(amountController.text) ?? 0;
  final double rate = double.tryParse(rateController.text) ?? 0;

  if (selectedCurrencyId == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Пожалуйста, выберите валюту.'),
    ));
    return;
  }

  if (amount > 0 && rate > 0) {
    final url = Uri.parse('https://retrochelik228.pythonanywhere.com/api/api/transactions/');

    final transactionData = {
      'user_id': widget.userId,  // Передаем user_id
      'currency_id': selectedCurrencyId, // Передаем выбранную валюту
      'status': transactionType, // Тип транзакции (buy или sell)
      'rate': rate.toString(),  // Курс как строка
      'amount': amount.toString(),  // Количество как строка
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(transactionData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Транзакция успешно добавлена!'),
        ));
      } else {
        throw Exception('Ошибка при добавлении транзакции');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ошибка при добавлении транзакции.'),
      ));
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Пожалуйста, заполните количество и курс.'),
    ));
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Главная страница'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Меню',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Валюта'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CurrencyPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Отчет'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_atm),
              title: const Text('Касса'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CashboxPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Пользователи'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UsersPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Очистить историю'),
              onTap: () {
                _showConfirmationDialog(context);
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Привет, ${widget.username}!'),
            const SizedBox(height: 16),
            isLoading
                ? const CircularProgressIndicator()
                : TextField(
                    controller: TextEditingController(text: selectedCurrency),
                    decoration: InputDecoration(
                      labelText: 'Валюта',
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                    ),
                    readOnly: true,
                    onTap: () {
                      _showCurrencySelectionDialog();
                    },
                  ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Количество',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: rateController,
              decoration: const InputDecoration(
                labelText: 'Курс',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Результат: ${result.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _calculate,
              child: const Text('Расчитать'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _addTransaction('buy'),
              child: const Text('Покупка'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _addTransaction('sell'),
              child: const Text('Продажа'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openEventPage,
              child: const Text('Событие'),
            ),
          ],
        ),
      ),
    );
  }

  void _calculate() {
    final double amount = double.tryParse(amountController.text) ?? 0;
    final double rate = double.tryParse(rateController.text) ?? 0;
    setState(() {
      result = amount * rate;
    });
  }

  void _showCurrencySelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Выберите валюту'),
          content: SingleChildScrollView(
            child: Column(
              children: currencies.map((currency) {
                return ListTile(
                  title: Text(currency['code']), // Display currency code
                  onTap: () {
                    setState(() {
                      selectedCurrency = currency['code'];  // Update selected currency code
                      selectedCurrencyId = currency['id'];  // Update selected currency ID
                    });
                    Navigator.pop(context);  // Close dialog
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _openEventPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EventPage()),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Подтверждение'),
          content: const Text('Вы уверены, что хотите очистить историю?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Очистка истории
              },
              child: const Text('Очистить'),
            ),
          ],
        );
      },
    );
  }
}
