import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/purchase_v2_models.dart';
import '../../services/api_service.dart';
import 'purchase_v2_detail_screen.dart';

class PurchaseV2HistoryScreen extends StatefulWidget {
  const PurchaseV2HistoryScreen({super.key});

  @override
  State<PurchaseV2HistoryScreen> createState() =>
      _PurchaseV2HistoryScreenState();
}

class _PurchaseV2HistoryScreenState extends State<PurchaseV2HistoryScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String? _error;

  List<PurchaseV2Summary> _purchases = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _purchases = await _api.getPurchaseV2List(page: 0, size: 20);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase V2 History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Failed to load purchases: $_error'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16.0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: _purchases.length,
                    itemBuilder: (context, index) {
                      final p = _purchases[index];
                      return Card(
                        child: ListTile(
                          title: Text(p.billNo),
                          subtitle: Text(
                            '${p.supplierName} | ${p.billDate.toIso8601String().split('T').first}',
                          ),
                          trailing: Text(p.totalAmount.toStringAsFixed(2)),
                          isThreeLine: true,
                          onTap: () => context.go('/purchase-v2/${p.id}'),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

