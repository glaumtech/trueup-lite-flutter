import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../models/purchase_v2_models.dart';
import '../../services/api_service.dart';

class PurchaseV2DetailScreen extends StatefulWidget {
  final int? purchaseId;

  const PurchaseV2DetailScreen({super.key, required this.purchaseId});

  @override
  State<PurchaseV2DetailScreen> createState() =>
      _PurchaseV2DetailScreenState();
}

class _PurchaseV2DetailScreenState extends State<PurchaseV2DetailScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String? _error;
  PurchaseV2Detail? _detail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _detail = null;
    });

    if (widget.purchaseId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Missing purchaseId';
      });
      return;
    }

    try {
      _detail = await _api.getPurchaseV2Detail(widget.purchaseId!);
    } catch (e) {
      _error = '$e';
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    return Scaffold(
      appBar: AppBar(
        title: Text('Purchase Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/purchase-v2/history'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Failed to load details: $_error'))
              : d == null
                  ? const Center(child: Text('No details found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    d.billNo,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Supplier: ${d.supplier?.name ?? '-'}'),
                                  Text(
                                    'Bill date: ${DateFormat('yyyy-MM-dd').format(d.billDate)}',
                                  ),
                                  Text('Payment mode: ${d.paymentMode}'),
                                  const SizedBox(height: 8),
                                  if (d.billImageUrl != null &&
                                      d.billImageUrl!.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: CachedNetworkImage(
                                        imageUrl:
                                            '${ApiService.baseUrl}${d.billImageUrl}',
                                        height: 200,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const SizedBox(
                                          height: 200,
                                          child: Center(
                                            child:
                                                CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                        errorWidget: (context, url, err) =>
                                            Container(
                                          height: 200,
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: Text('Bill image not found'),
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      height: 120,
                                      color: Colors.grey[100],
                                      child: const Center(
                                        child: Text('No bill image'),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Total Amount: ${d.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Items (Expiry Tracking)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          ...d.items.map(
                            (item) => Card(
                              child: ListTile(
                                title: Text(item.name),
                                subtitle: Text(
                                  'Qty: ${item.qty} ${item.unit}\nManufacture: ${item.manufactureDate != null ? DateFormat('yyyy-MM-dd').format(item.manufactureDate!) : '-'}\nExpiry: ${item.expiryDate != null ? DateFormat('yyyy-MM-dd').format(item.expiryDate!) : '-'}',
                                ),
                                trailing: Text(
                                  item.total.toStringAsFixed(2),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
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

