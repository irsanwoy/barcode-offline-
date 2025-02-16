import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../database/db_helper.dart';

class TransactionScreen extends StatefulWidget {
  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final DBHelper _dbHelper = DBHelper();
  List<Product> cartItems = [];
  double total = 0.0;
  final _manualBarcodeController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  Future<void> _scanBarcode() async {
    final MobileScannerController controller = MobileScannerController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Scaffold(
        body: MobileScanner(
          controller: controller,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final String barcode = barcodes.first.rawValue ?? '';
              _handleScannedBarcode(barcode);
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  Future<void> _handleScannedBarcode(String barcode) async {
    final product = await _dbHelper.getProductByBarcode(barcode);
    if (product != null) {
      _addToCart(product);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produk tidak ditemukan')),
      );
    }
  }

  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Input Manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _manualBarcodeController,
              decoration: InputDecoration(
                labelText: 'Barcode',
                hintText: 'Masukkan barcode',
              ),
            ),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Jumlah',
                hintText: 'Masukkan jumlah',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final product = await _dbHelper.getProductByBarcode(
                _manualBarcodeController.text,
              );
              if (product != null) {
                _addToCart(product, quantity: int.parse(_quantityController.text));
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Produk tidak ditemukan')),
                );
              }
            },
            child: Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _addToCart(Product product, {int quantity = 1}) {
    setState(() {
      // Cek apakah produk sudah ada di keranjang
      final existingIndex = cartItems.indexWhere((item) => item.id == product.id);
      
      if (existingIndex != -1) {
        // Update quantity jika sudah ada
        final existingProduct = cartItems[existingIndex];
        cartItems[existingIndex] = existingProduct.copyWith(
          unitPrice: existingProduct.unitPrice * quantity,
        );
      } else {
        // Tambahkan sebagai item baru
        cartItems.add(product.copyWith(
          unitPrice: product.unitPrice * quantity,
        ));
      }
      
      total += product.unitPrice * quantity;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaksi'),
        actions: [
          IconButton(
            icon: Icon(Icons.calculate),
            onPressed: _showManualEntryDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(cartItems[index].name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Harga Satuan: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ').format(cartItems[index].unitPrice)}'),
                    Text('Harga Grosir: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ').format(cartItems[index].wholesalePrice)}'),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      total -= cartItems[index].unitPrice;
                      cartItems.removeAt(index);
                    });
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Total: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ').format(total)}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanBarcode,
        tooltip: 'Scan Barcode',
        child: Icon(Icons.qr_code_scanner),
      ),
    );
  }
}