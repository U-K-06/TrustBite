import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:barcode_scan2/barcode_scan2.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _barcode = '';
  String _productName = '';
  String _productGrade = '';
  List<String> _ingredients = [];
  List<String> _harmfulIngredients = ['Sugar', 'Salt', 'Palm oil', 'Additives'];

  Future<void> _scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      setState(() {
        _barcode = result.rawContent.isNotEmpty ? result.rawContent : 'No barcode found';
      });
      if (_barcode.isNotEmpty) {
        await _fetchProductInfo(_barcode);
      }
    } catch (e) {
      setState(() {
        _barcode = 'Error: $e';
      });
    }
  }

  Future<void> _fetchProductInfo(String barcode) async {
    final url = 'https://world.openfoodfacts.org/api/v0/product/$barcode.json';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _productName = data['product']?['product_name'] ?? 'Product name not found';
          _productGrade = data['product']?['nutriscore_grade'] ?? 'N/A';
          _ingredients = (data['product']?['ingredients_text'] ?? '')
              .toString()
              .split(',')
              .map((e) => e.trim())
              .toList()
              .cast<String>();
        });
      } else {
        setState(() {
          _productName = 'Error: Unable to retrieve product information';
          _productGrade = 'N/A';
          _ingredients = [];
        });
      }
    } catch (e) {
      setState(() {
        _productName = 'Error: $e';
        _productGrade = 'N/A';
        _ingredients = [];
      });
    }
  }


  Widget _buildIngredientBox(String ingredient) {
    final isHarmful = _harmfulIngredients.any((harmful) =>
        ingredient.toLowerCase().contains(harmful.toLowerCase()));

    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: isHarmful ? Colors.red[100] : Colors.green[100],
        border: Border.all(
          color: isHarmful ? Colors.red : Colors.green,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Text(
        ingredient,
        style: TextStyle(
          color: isHarmful ? Colors.red : Colors.green[800],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return Colors.yellow;
      case 'D':
        return Colors.orange;
      case 'E':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Tracker'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _scanBarcode,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan Barcode'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20.0),
            Card(
              elevation: 6.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product Name: ${_productName.isNotEmpty ? _productName : 'Not Scanned Yet'}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10.0),
                    Row(
                      children: [
                        const Text(
                          'Nutritional Grade: ',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: _getGradeColor(_productGrade),
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          child: Text(
                            _productGrade.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: Card(
                elevation: 4.0,
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: _ingredients.length,
                    itemBuilder: (context, index) {
                      return _buildIngredientBox(_ingredients[index]);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
