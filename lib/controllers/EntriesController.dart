import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:convert';

import '../models/Command.dart';
import '../widgets/CommandRow.dart';
import 'AuthController.dart';

class EntriesController extends GetxController {
  final RxList<Map<String, String>> rowData = <Map<String, String>>[].obs;
//final RxList<Command> filteredCommands = <Command>[].obs;
  List<dynamic> filteredCommands = [];
  // Declare originalCommands list
  List<dynamic> originalCommands = [];
  // Function to add a new row
  void addCommandRow() {
    rowData.add({
      'article': '',
      'quantity': '',
    });
    int index = commandRows.length;
    commandRows.add(CommandRow(index: index));
    update();
  }

  final commandRows = <CommandRow>[].obs;
  final selectedRow = RxInt(-1);

  void removeCommandRow(int index) {
    commandRows.removeAt(index);
    update();
  }

  void selectRow(int index) {
    selectedRow.value = index;
  }

  bool isRowSelected(int index) {
    return selectedRow.value == index;
  }

  void updateRowValue(int index, String field, String? value) {
    rowData[index][field] =
        value ?? ''; // Use an empty string if the value is null
    update();
  }

  var commands = <dynamic>[].obs;
  final RxString authToken = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAuthToken();
  }

  Future<void> fetchAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token != null) {
      authToken.value = token;
      fetchCommands(token);
    }
  }

  Future<void> fetchCommands(String token) async {
    if (token != null && token.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse('http://localhost:8000/api/entries/index'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final fetchedCommands = data['commands'] as List<dynamic>;
          commands.value =
              fetchedCommands.map((json) => Command.fromJson(json)).toList();
          // Populate originalCommands
          originalCommands = List.from(commands.value);
        } else {
          throw Exception('Failed to fetch commands');
        }
      } catch (e) {
        throw Exception('Failed to fetch commands: $e');
      }
    } else {
      // Handle the case when the user is not connected
      // You can show an error message or redirect to the login page
      print('User is not connected');
    }
  }

  /* String formattedTimeDifference(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      final formatter = DateFormat('MMMM d y');
      return formatter.format(createdAt);
    } else if (difference.inHours > 0) {
      return 'It\'s been ${difference.inHours} hours';
    } else if (difference.inMinutes > 0) {
      return 'It\'s been ${difference.inMinutes} minutes';
    } else {
      return 'Just now';
    }
  }*/
  String formattedTimeDifference(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    return timeago.format(now.subtract(difference));
  }

  Future<Command> fetchCommand(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');

    if (authToken != null && authToken.isNotEmpty) {
      final url = 'http://localhost:8000/api/show/$id';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['command'] != null) {
          final commandData =
              jsonData['command'][0]; // Assuming there's only one command
          final command = Command.fromJson(commandData);
          return command;
        } else {
          throw Exception('Invalid response format: command field is missing');
        }
      } else {
        throw Exception('Failed to fetch command');
      }
    } else {
      throw Exception('User is not authenticated');
    }
  }

  void onSearchChanged(String query) {
    filterCommands(query);
    //print(query);
  }

  void filterCommands(String query) {
    if (query.isEmpty) {
      //print("query empty");
      // If the query is empty, show all commands
      commands.value = originalCommands;
    } else {
      //print("query : "+ query);
      // Filter the commands based on the query
      commands.value = originalCommands
          .where((command) =>
              command.code.toLowerCase().contains(query.toLowerCase()) ||
              command.articlesCount
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              command.userName.toLowerCase().contains(query.toLowerCase()) ||
              command.price.toLowerCase().contains(query.toLowerCase()) ||
              command.status.toLowerCase().contains(query.toLowerCase()) ||
              timeago
                  .format(command.createdAt)
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              command.department.toLowerCase().contains(query.toLowerCase()))
          .toList();

      //print(commands.value);
    }

    //print(filteredCommands);
    update();
  }
}
