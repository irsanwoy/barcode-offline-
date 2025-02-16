import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/product.dart';
import '../database/db_helper.dart';

class ProductManagementScreen extends StatefulWidget {
  @override
  _ProductManagementScreenState createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final DBHelper _dbHelper = DBHelper();
  late Future<List<Product>> _products;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _wholesalePriceController = TextEditingController();
  final _barcodeController = TextEditingController();
  Product? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _refreshProductList();
  }

  void _refreshProductList() {
    setState(() {
      _products = _dbHelper.getProducts();
    });
  }

  void _showProductForm(Product? product) async {
    _selectedProduct = product;
    
    if (product != null) {
      _nameController.text = product.name;
      _unitPriceController.text = product.unitPrice.toString();
      _wholesalePriceController.text = product.wholesalePrice.toString();
      _barcodeController.text = product.barcode;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nama Produk'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama produk harus diisi';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _unitPriceController,
                decoration: InputDecoration(labelText: 'Harga Satuan'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga satuan harus diisi';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Harga harus berupa angka';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _wholesalePriceController,
                decoration: InputDecoration(labelText: 'Harga Grosir'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga grosir harus diisi';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Harga harus berupa angka';
                  }
                  return null;
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeController,
                      decoration: InputDecoration(labelText: 'Barcode'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Barcode harus diisi';
                        }
                        return null;
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.qr_code_scanner),
                    onPressed: _scanBarcodeForProduct,
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final product = Product(
                          id: _selectedProduct?.id,
                          name: _nameController.text,
                          unitPrice: double.parse(_unitPriceController.text),
                          wholesalePrice: double.parse(_wholesalePriceController.text),
                          barcode: _barcodeController.text,
                        );

                        // Cek duplikasi barcode
                        final existingProduct = await _dbHelper.getProductByBarcode(_barcodeController.text);
                        if (existingProduct != null && existingProduct.id != product.id) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Barcode sudah digunakan oleh produk lain')),
                          );
                          return;
                        }

                        if (_selectedProduct == null) {
                          await _dbHelper.insertProduct(product);
                        } else {
                          await _dbHelper.updateProduct(product);
                        }

                        _refreshProductList();
                        Navigator.pop(context);
                        _clearForm();
                      }
                    },
                    child: Text(_selectedProduct == null ? 'Simpan' : 'Update'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _clearForm();
                    },
                    child: Text('Batal'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scanBarcodeForProduct() async {
    final MobileScannerController controller = MobileScannerController();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String barcode = barcodes.first.rawValue ?? '';
            setState(() {
              _barcodeController.text = barcode;
            });
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _unitPriceController.clear();
    _wholesalePriceController.clear();
    _barcodeController.clear();
    _selectedProduct = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manajemen Produk'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showProductForm(null),
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _products,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Belum ada produk'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final product = snapshot.data![index];
                return ListTile(
                  title: Text(product.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Barcode: ${product.barcode}'),
                      Text('Harga: Rp${product.unitPrice}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _showProductForm(product),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          await _dbHelper.deleteProduct(product.id!);
                          _refreshProductList();
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}