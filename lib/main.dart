import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(
  MaterialApp(
    theme: getAppTheme(),
    home: MyHomePage(),
  ),
);

class QueueNumberGenerator {
  final SharedPreferences sharedPreferences;

  QueueNumberGenerator(this.sharedPreferences);

  int generateQueueNumber() {
    final currentQueueNumber = sharedPreferences.getInt('queue_number') ?? 0;
    final newQueueNumber = currentQueueNumber + 1;
    sharedPreferences.setInt('queue_number', newQueueNumber);
    return newQueueNumber;
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController nameController = TextEditingController();
  String? selectedProduct;
  TextEditingController quantityController = TextEditingController();
  int? selectedOrderType;
  DateTime? selectedDate;
  String? selectedTable; // Updated to use String for selectedTable

  final businessPhoneNumber = '+6281575995403';

  late QueueNumberGenerator queueNumberGenerator;
  late SharedPreferences sharedPreferences;

  List<String> menuItems = [
    'Magelangan : 10 Ribu',
    'Mie Ayam : 15 Ribu',
    'Nasi Telur : 12 Ribu',
    'Bakso : 10 Ribu',
    'Omelet : 8 Ribu',
    'Nasi Padang : 20 Ribu',
    'Nasi Goreng : 12 Ribu',
    'Nasi Uduk : 14 Ribu',
    'Nasi Kuning : 13 Ribu',
  ];

  Map<String, double> menuPrices = {
    'Magelangan': 10.0,
    'Mie Ayam': 15.0,
    'Nasi Telur': 12.0,
    'Bakso': 10.0,
    'Omelet': 8.0,
    'Nasi Padang': 20.0,
    'Nasi Goreng': 12.0,
    'Nasi Uduk': 14.0,
    'Nasi Kuning': 13.0,
  };

  List<String> tableNumbers = [
    'Meja 1',
    'Meja 2',
    'Meja 3',
    'Meja 4',
    'Meja 5',
  ];

  List<Order> orders = [];
  double total = 0.0;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      sharedPreferences = prefs;
      queueNumberGenerator = QueueNumberGenerator(sharedPreferences);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Resto App',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        leading: Image.asset(
          'assets/images/img_1.png',
          color: Colors.white,
          width: 59.0,
          height: 59.0,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Nama Pelanggan'),
              ),
              DropdownButton<String>(
                value: selectedProduct,
                onChanged: (value) {
                  setState(() {
                    selectedProduct = value;
                  });
                },
                items: menuItems.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                hint: Text('Pilih Menu'),
              ),
              TextField(
                keyboardType: TextInputType.number,
                controller: quantityController,
                decoration: InputDecoration(labelText: 'Jumlah Pesanan'),
              ),
              RadioListTile(
                title: Icon(Icons.restaurant),
                value: 1,
                groupValue: selectedOrderType,
                onChanged: (value) {
                  setState(() {
                    selectedOrderType = value;
                  });
                },
              ),
              RadioListTile(
                title: Icon(Icons.event_seat),
                value: 2,
                groupValue: selectedOrderType,
                onChanged: (value) {
                  setState(() {
                    selectedOrderType = value;
                  });
                },
              ),
              if (selectedOrderType == 1) // Show table selection for "Makan Di Tempat"
                DropdownButton<String>(
                  value: selectedTable,
                  onChanged: (value) {
                    setState(() {
                      selectedTable = value;
                    });
                  },
                  items: tableNumbers.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  hint: Text('Pilih Nomor Meja'),
                ),
              ElevatedButton(
                onPressed: () {
                  if (selectedDate != null &&
                      nameController.text.isNotEmpty &&
                      selectedProduct != null &&
                      selectedOrderType != null) {
                    if (selectedOrderType == 1 && selectedTable == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Harap pilih nomor meja.'),
                        ),
                      );
                    } else {
                      final customerName = nameController.text;
                      final productName = selectedProduct;
                      final quantity = quantityController.text;

                      final currentTime = DateTime.now();
                      final formatter = DateFormat("HH:mm");
                      final currentTimeFormatted = formatter.format(currentTime);
                      final queueNumber = queueNumberGenerator.generateQueueNumber();

                      var message = 'Halo, saya ingin memesan '
                          '$productName sebanyak $quantity oleh $customerName '
                          'dengan jenis pesanan: ${_getOrderTypeString(selectedOrderType!)}. '
                          'ID Transaksi: $queueNumber '
                          'pada tanggal ${DateFormat('dd MMMM yyyy').format(selectedDate!)} jam pemesanan $currentTimeFormatted';

                      if (selectedOrderType == 1) {
                        message = '$message\nNomor Meja: ${selectedTable ?? "Belum dipilih"}';
                      }

                      _sendWhatsAppMessage(message);

                      final order = Order(
                        productName: selectedProduct!,
                        quantity: int.parse(quantityController.text),
                        price: menuPrices[selectedProduct!]!,
                      );

                      setState(() {
                        orders.add(order);
                        total += order.getTotalPrice();
                      });

                      // Reset input fields
                      nameController.clear();
                      selectedProduct = null;
                      quantityController.clear();
                      selectedOrderType = null;
                      selectedTable = null;
                      selectedDate = null;
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Harap isi semua kolom!'),
                      ),
                    );
                  }
                },
                child: Icon(Icons.add_shopping_cart),
              ),
              ElevatedButton(
                onPressed: () {
                  _selectDate(context);
                },
                child: Icon(Icons.calendar_today),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (selectedDate != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => InvoiceScreen(
                  orderDate: selectedDate!,
                  customerName: nameController.text,
                  orders: orders,
                  total: total,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Pilih tanggal kedatangan terlebih dahulu.'),
              ),
            );
          }
        },
        child: Icon(Icons.receipt),
      ),
    );
  }

  void _sendWhatsAppMessage(String message) {
    final url = 'https://api.whatsapp.com/send?phone=$businessPhoneNumber&text=${Uri.encodeFull(message)}';
    launch(url);
  }

  String _getOrderTypeString(int orderType) {
    switch (orderType) {
      case 1:
        return 'Makan Di Tempat';
      case 2:
        return 'Dibungkus';
      default:
        return '';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }
}

// add the page for payment with code integration


class InvoiceScreen extends StatelessWidget {
  final DateTime orderDate;
  final String customerName;
  final List<Order> orders;
  final double total;

  InvoiceScreen({
    required this.orderDate,
    required this.customerName,
    required this.orders,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Invoice Content',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Order Date: ${DateFormat('dd MMMM yyyy').format(orderDate)}'),
            Text('Customer Name: $customerName'),
            Text('Daftar Pesanan:'),
            for (var order in orders)
              Text('${order.productName} x${order.quantity} - ${order.getTotalPrice()} Ribu'),
            Text('Total: $total Ribu'),
            ElevatedButton(
              onPressed: () {
                _chatWithBusiness();
              },
              child: Icon(Icons.chat),
            ),
          ],
        ),
      ),
    );
  }

  void _chatWithBusiness() {
    final businessPhoneNumber = '081215260149';
    final url = 'https://wa.me/$businessPhoneNumber';
    launch(url);
  }
}

class Order {
  final String productName;
  final int quantity;
  final double price;

  Order({
    required this.productName,
    required this.quantity,
    required this.price,
  });

  double getTotalPrice() {
    return quantity * price;
  }
}

ThemeData getAppTheme() {
  return ThemeData(
    scaffoldBackgroundColor: Colors.lightGreenAccent,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.yellow,
      shape: Border.all(color: Colors.purpleAccent, width: 5),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: Colors.yellow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    // Add the following lines to use a gradient color for the app theme
    primaryColor: Colors.blue,
    primaryColorLight: Colors.lightBlueAccent,
    primaryColorDark: Colors.blueGrey,
    hintColor: Colors.deepPurple,
    canvasColor: Colors.white,
    cardColor: Colors.white,
    indicatorColor: Colors.blue,
    splashColor: Colors.blue,
    splashFactory: InkRipple.splashFactory,
    unselectedWidgetColor: Colors.grey[300],
    disabledColor: Colors.grey,
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: Colors.blue[200],
      selectionHandleColor: Colors.blue[200],
      cursorColor: Colors.blue[200],
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blue),
        borderRadius: BorderRadius.circular(20),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blue[200]!),
        borderRadius: BorderRadius.circular(20),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blue[200]!),
        borderRadius: BorderRadius.circular(20),
      ),
    ), checkboxTheme: CheckboxThemeData(
 fillColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
 if (states.contains(MaterialState.disabled)) { return null; }
 if (states.contains(MaterialState.selected)) { return Colors.blue; }
 return null;
 }),
 ), radioTheme: RadioThemeData(
 fillColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
 if (states.contains(MaterialState.disabled)) { return null; }
 if (states.contains(MaterialState.selected)) { return Colors.blue; }
 return null;
 }),
 ), switchTheme: SwitchThemeData(
 thumbColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
 if (states.contains(MaterialState.disabled)) { return null; }
 if (states.contains(MaterialState.selected)) { return Colors.blue; }
 return null;
 }),
 trackColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
 if (states.contains(MaterialState.disabled)) { return null; }
 if (states.contains(MaterialState.selected)) { return Colors.blue; }
 return null;
 }),
 ), colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.pink).copyWith(background: Colors.grey[200]).copyWith(error: Colors.red),
  );
}
