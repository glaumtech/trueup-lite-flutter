import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/admin_store_order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_polling_provider.dart';
import '../../services/api_service.dart';

class OnlineOrdersListScreen extends ConsumerStatefulWidget {
  const OnlineOrdersListScreen({super.key});

  @override
  ConsumerState<OnlineOrdersListScreen> createState() =>
      _OnlineOrdersListScreenState();
}

class _OnlineOrdersListScreenState
    extends ConsumerState<OnlineOrdersListScreen> {
  bool _isLoading = true;
  String? _error;
  List<AdminStoreOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(authenticatedApiProvider);
      _orders = await api.getAdminOrders();
      await ref.read(orderPollingProvider).updateBaselineFromPending();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = '$e';
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await ref.read(orderPollingProvider).onStaffLogout();
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (!auth.isStaffLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/online-orders/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final counts = countOrdersByStatus(_orders);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Orders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _load,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout (${auth.session?.username ?? ''})',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Failed to load orders: $_error'),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _StatusSummaryRow(counts: counts),
                      const SizedBox(height: 16),
                      if (_orders.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(child: Text('No orders yet')),
                        )
                      else
                        ..._orders.map(
                          (order) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _OrderCard(
                              order: order,
                              currency: currency,
                              onTap: () =>
                                  context.go('/online-orders/${order.id}'),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _StatusSummaryRow extends StatelessWidget {
  final Map<String, int> counts;

  const _StatusSummaryRow({required this.counts});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SummaryChip(label: 'Pending', count: counts['Pending'] ?? 0, color: Colors.amber),
        _SummaryChip(label: 'Accepted', count: counts['Accepted'] ?? 0, color: Colors.blue),
        _SummaryChip(label: 'Shipped', count: counts['Shipped'] ?? 0, color: Colors.indigo),
        _SummaryChip(label: 'Delivered', count: counts['Delivered'] ?? 0, color: Colors.green),
        _SummaryChip(label: 'Cancelled', count: counts['Cancelled'] ?? 0, color: Colors.red),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color.withOpacity(0.2),
        child: Text(
          '$count',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
      label: Text(label),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final AdminStoreOrder order;
  final NumberFormat currency;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.currency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.id,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(order.shippingAddress.name.isNotEmpty
                        ? order.shippingAddress.name
                        : 'Customer'),
                    Text(
                      order.date,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusChip(status: order.status),
                  const SizedBox(height: 8),
                  Text(
                    currency.format(order.total),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        normalized,
        style: TextStyle(
          color: color.shade800,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
