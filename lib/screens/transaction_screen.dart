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

  // Variable untuk menyimpan barcode yang dipindai fisik
  String _barcodeFromPhysicalScanner = '';

  // Fokus untuk raw keyboard listener (pemindai fisik)
  final FocusNode _barcodeFocusNode = FocusNode();

  // Method untuk menangani pemindaian barcode
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

  // Menangani barcode yang dipindai
  Future<void> _handleScannedBarcode(String barcode) async {
    // Menghapus karakter tambahan jika ada
    String cleanedBarcode = barcode.trim();
    print("Barcode yang diterima: $cleanedBarcode");

    final product = await _dbHelper.getProductByBarcode(cleanedBarcode);
    if (product != null) {
      _addToCart(product);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produk tidak ditemukan')),
      );
    }
  }

  // Dialog untuk input manual
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

  // Menambahkan item ke dalam keranjang
  void _addToCart(Product product, {int quantity = 1}) {
    setState(() {
      // Cek apakah produk sudah ada di keranjang
      final existingIndex = cartItems.indexWhere((item) => item.id == product.id);

      if (existingIndex != -1) {
        // Update quantity jika sudah ada
        final existingProduct = cartItems[existingIndex];
        cartItems[existingIndex] = existingProduct.copyWith(
          unitPrice: existingProduct.unitPrice + (product.unitPrice * quantity),
          wholesalePrice: existingProduct.wholesalePrice + (product.wholesalePrice * quantity),
        );
      } else {
        // Tambahkan sebagai item baru dengan harga satuan dan grosir
        cartItems.add(product.copyWith(
          unitPrice: product.unitPrice * quantity,
          wholesalePrice: product.wholesalePrice * quantity,
        ));
      }

      // Menambahkan total harga satuan dan harga grosir ke total keseluruhan
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
          // Membungkus ListView dengan Expanded agar bisa mengisi ruang yang tersedia
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _scanBarcode, // Tombol untuk scan kamera
            tooltip: 'Scan Barcode (Kamera)',
            child: Icon(Icons.qr_code_scanner),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _listenToPhysicalScanner, // Tombol untuk scan fisik
            tooltip: 'Scan Barcode (Perangkat Fisik)',
            child: Icon(Icons.bluetooth),
          ),
        ],
      ),
      bottomNavigationBar: RawKeyboardListener(
        focusNode: _barcodeFocusNode,
        onKey: (RawKeyEvent event) {
          if (event.runtimeType.toString() == "RawKeyDownEvent") {
            final inputBarcode = event.logicalKey.keyLabel;
            print("Input Barcode dari Pemindai Fisik: $inputBarcode"); // Debugging log untuk melihat input
            if (inputBarcode != null && inputBarcode.isNotEmpty && inputBarcode != 'Enter') {
              setState(() {
                _barcodeFromPhysicalScanner += inputBarcode; // Gabungkan karakter barcode
              });
            }

            // Jika input adalah 'Enter', proses barcode yang sudah terkumpul
            if (inputBarcode == 'Enter' && _barcodeFromPhysicalScanner.isNotEmpty) {
              _handleScannedBarcode(_barcodeFromPhysicalScanner); // Proses barcode setelah input selesai
              _barcodeFromPhysicalScanner = ''; // Reset setelah diproses
            }
          }
        },
        child: SizedBox(), // Gak perlu widget di sini, cukup listener
      ),
    );
  }

  // Fungsi untuk mendengarkan input dari pemindai fisik
  void _listenToPhysicalScanner() {
    _barcodeFocusNode.requestFocus(); // Meminta fokus ke RawKeyboardListener untuk menangkap input dari perangkat fisik
  }
}
