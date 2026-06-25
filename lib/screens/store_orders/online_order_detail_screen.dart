import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/admin_store_order.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

const _statusOptions = [
  'Pending',
  'Accepted',
  'Shipped',
  'Delivered',
  'Cancelled',
];

class OnlineOrderDetailScreen extends ConsumerStatefulWidget {
  final String? orderRef;

  const OnlineOrderDetailScreen({super.key, required this.orderRef});

  @override
  ConsumerState<OnlineOrderDetailScreen> createState() =>
      _OnlineOrderDetailScreenState();
}

class _OnlineOrderDetailScreenState
    extends ConsumerState<OnlineOrderDetailScreen> {
  bool _isLoading = true;
  String? _error;
  AdminStoreOrder? _order;
  bool _updatingStatus = false;
  bool _savingNotes = false;

  final _notesController = TextEditingController();
  Timer? _notesDebounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesDebounce?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (widget.orderRef == null || widget.orderRef!.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Missing order reference';
      });
      return;
    }

    try {
      final api = ref.read(authenticatedApiProvider);
      final order = await api.getAdminOrder(widget.orderRef!);
      _order = order;
      _notesController.text = order.staffNotes ?? '';
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = '$e';
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String status) async {
    if (_order == null || _updatingStatus) return;

    setState(() => _updatingStatus = true);
    try {
      final api = ref.read(authenticatedApiProvider);
      final updated =
          await api.updateAdminOrderStatus(_order!.id, status);
      setState(() => _order = updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $status')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  void _onNotesChanged(String value) {
    _notesDebounce?.cancel();
    _notesDebounce = Timer(const Duration(milliseconds: 800), () {
      _saveNotes(value);
    });
  }

  Future<void> _saveNotes(String notes) async {
    if (_order == null || _savingNotes) return;
    if (notes == (_order!.staffNotes ?? '')) return;

    setState(() => _savingNotes = true);
    try {
      final api = ref.read(authenticatedApiProvider);
      final updated =
          await api.updateAdminOrderNotes(_order!.id, notes);
      setState(() => _order = updated);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _savingNotes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: Text(order?.id ?? 'Order Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/online-orders'),
        ),
        actions: [
          if (_savingNotes)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Failed to load order: $_error'))
              : order == null
                  ? const Center(child: Text('Order not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.id,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Placed: ${order.date}'),
                                  const SizedBox(height: 8),
                                  _DetailStatusChip(status: order.status),
                                  Text(
                                    'Payment: ${order.paymentMethod}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'Update Status',
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _statusOptions.map((status) {
                                final selected =
                                    normalizeOrderStatus(order.status) == status;
                                return FilterChip(
                                  label: Text(status),
                                  selected: selected,
                                  onSelected: _updatingStatus
                                      ? null
                                      : (_) => _updateStatus(status),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'Items',
                            child: Column(
                              children: order.items.map((item) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              '${item.qty} × ${currency.format(item.price)}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        currency.format(lineTotal(item)),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'Bill Summary',
                            child: Column(
                              children: [
                                _SummaryRow(
                                  label: 'Subtotal',
                                  value: currency.format(order.subtotal),
                                ),
                                _SummaryRow(
                                  label: 'Courier',
                                  value: currency.format(order.shippingFee),
                                ),
                                const Divider(),
                                _SummaryRow(
                                  label: 'Total',
                                  value: currency.format(order.total),
                                  bold: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'Ship To',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(order.shippingAddress.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                                if (order.shippingAddress.street.isNotEmpty)
                                  Text(order.shippingAddress.street),
                                Text(
                                  [
                                    order.shippingAddress.city,
                                    order.shippingAddress.state,
                                    order.shippingAddress.zip,
                                  ].where((s) => s.isNotEmpty).join(', '),
                                ),
                                if (order.shippingAddress.phone.isNotEmpty)
                                  Text('Phone: ${order.shippingAddress.phone}'),
                                if (order.shippingAddress.email.isNotEmpty)
                                  Text('Email: ${order.shippingAddress.email}'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'Staff Notes',
                            child: TextField(
                              controller: _notesController,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                hintText: 'Internal notes for fulfillment…',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: _onNotesChanged,
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _DetailStatusChip extends StatelessWidget {
  final String status;

  const _DetailStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = normalizeOrderStatus(status);
    final color = switch (normalized) {
      'Pending' => Colors.amber,
      'Accepted' => Colors.blue,
      'Shipped' => Colors.indigo,
      'Delivered' => Colors.green,
      'Cancelled' => Colors.red,
      _ => Colors.grey,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Chip(
        label: Text(normalized),
        backgroundColor: color.withOpacity(0.15),
        labelStyle: TextStyle(color: color.shade800, fontWeight: FontWeight.w600),
      ),
    );
  }
}
