import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<String> users = []; // Список пользователей

  // Контроллеры для ввода данных нового пользователя
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final String serverUrl = 'https://retrochelik228.pythonanywhere.com/api/api/users/'; // URL API

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Загрузка списка пользователей при запуске
  }

  // Функция для загрузки списка пользователей с сервера
  Future<void> _fetchUsers() async {
    try {
      final response = await http.get(Uri.parse(serverUrl));
      if (response.statusCode == 200) {
        final List<dynamic> userData = jsonDecode(response.body);
        setState(() {
          users = userData.map((user) => user['username'] as String).toList();
        });
      } else {
        _showErrorSnackBar('Ошибка загрузки пользователей: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка сети: $e');
    }
  }

  // Функция для добавления нового пользователя на сервер
  Future<void> _addUser(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 201) {
        setState(() {
          users.add(username); // Обновляем локальный список
        });
        _showSuccessSnackBar('Пользователь добавлен');
      } else {
        _showErrorSnackBar('Ошибка добавления пользователя: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка сети: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи'),
      ),
      body: Column(
        children: [
          // Список пользователей
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(users[index]),
                );
              },
            ),
          ),

          // Поднятая кнопка для добавления нового пользователя
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: ElevatedButton(
              onPressed: () => _showAddUserDialog(context),
              child: const Text('Добавить пользователя'),
            ),
          ),
        ],
      ),
    );
  }

  // Диалоговое окно для добавления нового пользователя
  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Добавить пользователя'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Закрыть диалог
              },
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                if (usernameController.text.isNotEmpty &&
                    passwordController.text.isNotEmpty) {
                  _addUser(usernameController.text, passwordController.text);
                  usernameController.clear();
                  passwordController.clear();
                  Navigator.pop(context); // Закрыть диалог
                } else {
                  _showErrorSnackBar('Пожалуйста, заполните все поля');
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }

  // Функция для отображения ошибок
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(color: Colors.red))),
    );
  }

  // Функция для отображения успеха
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(color: Colors.green))),
    );
  }
}
