import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../models/purchase_v2_models.dart';
import '../../services/api_service.dart';

class PurchaseV2CreateScreen extends StatefulWidget {
  const PurchaseV2CreateScreen({super.key});

  @override
  State<PurchaseV2CreateScreen> createState() =>
      _PurchaseV2CreateScreenState();
}

class _PurchaseV2CreateScreenState extends State<PurchaseV2CreateScreen> {
  final ApiService _api = ApiService();

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isUploadingBillImage = false;

  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _itemsWithSuppliers = [];

  int? _vendorId;
  String _paymentMode = 'Cash';

  String? _billNo;
  DateTime _billDate = DateTime.now();
  DateTime? _dueDate;

  // Photo state
  XFile? _billImageFile;
  String? _uploadedBillImageUrl;

  // Item line builder state
  Map<String, dynamic>? _selectedItem;
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController(text: '0');
  DateTime? _manufactureDate;
  DateTime? _expiryDate;

  List<PurchaseV2CreateItemLine> _lines = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final suppliers = await _api.getSuppliers();
      final items = await _api.getItemsWithSuppliers();
      final billNo = await _api.generatePurchaseV2BillNumber();

      setState(() {
        _suppliers = suppliers;
        _itemsWithSuppliers = items;
        _billNo = billNo;
      });
    } catch (_) {
      // Keep UI responsive; show error via snackbar below.
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _api.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_vendorId == null) return const [];

    return _itemsWithSuppliers.where((item) {
      final suppliers = (item['suppliers'] as List<dynamic>?) ?? const [];
      return suppliers.any((s) => s is Map && (s['id'] as num?)?.toInt() == _vendorId);
    }).toList();
  }

  void _onSupplierChanged(int? newVendorId) {
    setState(() {
      _vendorId = newVendorId;
      _selectedItem = null;
      _qtyController.text = '1';
      _priceController.text = '0';
      _manufactureDate = null;
      _expiryDate = null;
    });
  }

  void _onSelectedItemChanged(Map<String, dynamic>? item) {
    if (item == null) return;

    final productId = (item['id'] as num?)?.toInt();
    if (productId == null) return;

    final suppliers = (item['suppliers'] as List<dynamic>?) ?? const [];
    final matching = suppliers.firstWhere(
      (s) => s is Map && (s['id'] as num?)?.toInt() == _vendorId,
      orElse: () => const {},
    );
    final supplierPrice = (matching is Map) ? (matching['supplierPrice'] as num?)?.toDouble() : null;

    final itemExpiryDate = _parseDateValue(item['expiryDate']);
    final itemManufactureDate = _parseDateValue(item['manufactureDate']);

    setState(() {
      _selectedItem = item;
      _qtyController.text = '1';
      _priceController.text = supplierPrice != null ? supplierPrice.toStringAsFixed(2) : '0';
      _manufactureDate = itemManufactureDate;
      _expiryDate = itemExpiryDate;
    });
  }

  DateTime? _parseDateValue(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Future<void> _pickBillImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera);
    if (file == null) return;

    setState(() {
      _billImageFile = file;
      _uploadedBillImageUrl = null;
      _isUploadingBillImage = true;
    });

    try {
      final url = await _api.uploadPurchaseBillImage(file.path);
      if (!mounted) return;
      setState(() {
        _uploadedBillImageUrl = url;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bill image upload failed: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isUploadingBillImage = false;
      });
    }
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _expiryDate = picked);
  }

  Future<void> _pickManufactureDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _manufactureDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _manufactureDate = picked);
  }

  void _addLine() {
    if (_vendorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a supplier first.')),
      );
      return;
    }
    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an item first.')),
      );
      return;
    }
    if (_manufactureDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Manufacture date is required for stock tracking.')),
      );
      return;
    }
    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expiry date is required for stock tracking.')),
      );
      return;
    }

    final qty = int.tryParse(_qtyController.text.trim());
    final price = double.tryParse(_priceController.text.trim());
    if (qty == null || qty <= 0 || price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity and price.')),
      );
      return;
    }

    final productId = (_selectedItem!['id'] as num?)?.toInt();
    final name = _selectedItem!['name'] as String?;
    final unit = _selectedItem!['unit'] as String?;
    if (productId == null || name == null || unit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected item is missing product info.')),
      );
      return;
    }

    final total = qty * price;
    final line = PurchaseV2CreateItemLine(
      productId: productId,
      name: name,
      unit: unit,
      qty: qty,
      price: price,
      discount: 0,
      tax: 0,
      total: total,
      manufactureDate: _manufactureDate!,
      expiryDate: _expiryDate,
    );

    setState(() {
      _lines.add(line);
      _selectedItem = null;
      _qtyController.text = '1';
      _priceController.text = '0';
      _manufactureDate = null;
      _expiryDate = null;
    });
  }

  Future<void> _submitPurchase() async {
    if (_billNo == null || _billNo!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bill number is missing.')),
      );
      return;
    }
    if (_vendorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a supplier.')),
      );
      return;
    }
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item.')),
      );
      return;
    }

    final totalAmount =
        _lines.fold<double>(0.0, (sum, line) => sum + (line.total));

    final request = PurchaseV2CreateRequest(
      vendorId: _vendorId!,
      purchase: PurchaseV2CreatePurchaseMeta(
        billNo: _billNo!,
        billDate: _billDate,
        paymentMode: _paymentMode,
        dueDate: _dueDate,
        poNo: null,
        poDate: null,
        termsConditions: null,
        privateNotes: null,
        shippingCharges: null,
        billImageUrl: _uploadedBillImageUrl,
      ),
      items: _lines,
      totalAmount: totalAmount,
    );

    setState(() => _isSubmitting = true);
    try {
      final response = await _api.createPurchaseV2(request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Purchase saved: ${response.billNo ?? ''} (ID: ${response.purchaseId ?? ''})',
          ),
        ),
      );
      context.go('/purchase-v2/${response.purchaseId}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create purchase failed: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final Map<String, dynamic>? selectedSupplier = _vendorId == null
        ? null
        : (() {
            final match = _suppliers
                .cast<Map<String, dynamic>>()
                .where((s) => (s['id'] as num?)?.toInt() == _vendorId)
                .toList();
            return match.isNotEmpty ? match.first : null;
          })();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase V2 (Stock Receiving)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Supplier
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Supplier & Bill Details',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          DropdownSearch<Map<String, dynamic>>(
                            items: _suppliers,
                            itemAsString: (s) => s['name'] as String? ?? '',
                            selectedItem: selectedSupplier,
                            onChanged: (selected) {
                              final id = (selected?['id'] as num?)?.toInt();
                              _onSupplierChanged(id);
                            },
                            dropdownDecoratorProps:
                                const DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                labelText: 'Supplier',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            initialValue: _billNo ?? '',
                            decoration: const InputDecoration(
                              labelText: 'Bill number',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => _billNo = v,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  readOnly: true,
                                  controller: TextEditingController(
                                    text: DateFormat('yyyy-MM-dd')
                                        .format(_billDate),
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Bill date',
                                    border: OutlineInputBorder(),
                                  ),
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _billDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked == null) return;
                                    setState(() => _billDate = picked);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _paymentMode,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Cash',
                                      child: Text('Cash'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Credit',
                                      child: Text('Credit'),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() => _paymentMode = v);
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Payment mode',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Due date (optional)',
                              border: OutlineInputBorder(),
                            ),
                            controller: TextEditingController(
                              text: _dueDate != null
                                  ? DateFormat('yyyy-MM-dd').format(_dueDate!)
                                  : '',
                            ),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _dueDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked == null) return;
                              setState(() => _dueDate = picked);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bill image
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Purchase Bill Photo',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          if (_billImageFile != null)
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(_billImageFile!.path),
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _billImageFile = null;
                                        _uploadedBillImageUrl = null;
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              ],
                            )
                          else
                            Container(
                              height: 160,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[100],
                              ),
                              child: const Center(
                                child: Text('No bill photo selected'),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isUploadingBillImage ? null : _pickBillImage,
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Take & Upload Photo'),
                                ),
                              ),
                              if (_uploadedBillImageUrl != null) ...[
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 46,
                                  height: 46,
                                  child: CachedNetworkImage(
                                    imageUrl:
                                        '${ApiService.baseUrl}$_uploadedBillImageUrl',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (_isUploadingBillImage)
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: LinearProgressIndicator(),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Items
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Add Items (Expiry Tracking)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          DropdownSearch<Map<String, dynamic>>(
                            enabled: _vendorId != null,
                            items: _filteredItems,
                            itemAsString: (item) => item['name'] as String? ?? '',
                            selectedItem: _selectedItem,
                            onChanged: (v) => _onSelectedItemChanged(v),
                            dropdownDecoratorProps:
                                const DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                labelText: 'Item',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _qtyController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    signed: false,
                                    decimal: false,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Quantity',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _priceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    signed: false,
                                    decimal: true,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Unit Price',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Manufacture date',
                              border: OutlineInputBorder(),
                            ),
                            controller: TextEditingController(
                              text: _manufactureDate != null
                                  ? DateFormat('yyyy-MM-dd').format(_manufactureDate!)
                                  : '',
                            ),
                            onTap: _pickManufactureDate,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Expiry date',
                              border: OutlineInputBorder(),
                            ),
                            controller: TextEditingController(
                              text: _expiryDate != null
                                  ? DateFormat('yyyy-MM-dd').format(_expiryDate!)
                                  : '',
                            ),
                            onTap: _pickExpiryDate,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _addLine,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Line'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Lines
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Added Items',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          if (_lines.isEmpty)
                            const Text('No items added yet.')
                          else
                            Column(
                              children: _lines
                                  .map(
                                    (l) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(l.name),
                                      subtitle: Text(
                                        'Qty: ${l.qty} ${l.unit} | Mfg: ${DateFormat('yyyy-MM-dd').format(l.manufactureDate)} | Exp: ${l.expiryDate != null ? DateFormat('yyyy-MM-dd').format(l.expiryDate!) : '-'}',
                                      ),
                                      trailing: Text(currency.format(l.total)),
                                      onLongPress: () {
                                        setState(() {
                                          _lines.remove(l);
                                        });
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            'Total: ${currency.format(_lines.fold<double>(0.0, (sum, line) => sum + line.total))}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitPurchase,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Purchase'),
                  ),
                ],
              ),
            ),
    );
  }
}

