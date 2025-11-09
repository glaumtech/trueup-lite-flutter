import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/weekly_purchase_history.dart';
import '../../providers/order_suggestions_provider.dart';

class WeeklyPurchaseHistoryScreen extends ConsumerStatefulWidget {
  const WeeklyPurchaseHistoryScreen({super.key});

  @override
  ConsumerState<WeeklyPurchaseHistoryScreen> createState() =>
      _WeeklyPurchaseHistoryScreenState();
}

class _WeeklyPurchaseHistoryScreenState
    extends ConsumerState<WeeklyPurchaseHistoryScreen> {
  int _selectedWeeks = 4;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWeeklyHistory();
  }

  Future<void> _loadWeeklyHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(weeklyPurchaseHistoryProvider.notifier)
          .loadWeeklyHistory(weeks: _selectedWeeks);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final weeklyHistory = ref.watch(weeklyPurchaseHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Purchase History'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_list),
            onSelected: (weeks) {
              setState(() {
                _selectedWeeks = weeks;
              });
              _loadWeeklyHistory();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 2,
                child: Text('Last 2 weeks'),
              ),
              const PopupMenuItem(
                value: 4,
                child: Text('Last 4 weeks'),
              ),
              const PopupMenuItem(
                value: 8,
                child: Text('Last 8 weeks'),
              ),
              const PopupMenuItem(
                value: 12,
                child: Text('Last 12 weeks'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeeklyHistory,
          ),
        ],
      ),
      body: _buildContent(weeklyHistory),
    );
  }

  Widget _buildContent(List<WeeklyPurchaseHistory> weeklyHistory) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading weekly history...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading history',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWeeklyHistory,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (weeklyHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_view_week,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Purchase History',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'No purchases found for the selected period',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWeeklyHistory,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Summary Header
        _buildSummaryHeader(weeklyHistory),

        // Weekly History List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadWeeklyHistory,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: weeklyHistory.length,
              itemBuilder: (context, index) {
                return _buildWeekCard(weeklyHistory[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader(List<WeeklyPurchaseHistory> weeklyHistory) {
    final totalItems =
        weeklyHistory.fold(0, (sum, week) => sum + week.totalItems);
    final totalAmount =
        weeklyHistory.fold(0.0, (sum, week) => sum + week.totalAmount);
    final averageWeeklyAmount =
        weeklyHistory.isNotEmpty ? totalAmount / weeklyHistory.length : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Last $_selectedWeeks Weeks Summary',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Items',
                  '$totalItems',
                  Icons.inventory,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Total Amount',
                  '₹${totalAmount.toStringAsFixed(0)}',
                  Icons.currency_rupee,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Weekly Avg',
                  '₹${averageWeeklyAmount.toStringAsFixed(0)}',
                  Icons.trending_up,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekCard(WeeklyPurchaseHistory week) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Icon(
            Icons.calendar_view_week,
            color: Colors.green[800],
          ),
        ),
        title: Text(
          week.formattedWeekRange,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${week.totalItems} items • ₹${week.totalAmount.toStringAsFixed(0)}'),
            if (week.itemsBySupplier.isNotEmpty)
              Text(
                '${week.itemsBySupplier.length} suppliers',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        children: [
          if (week.purchaseItems.isNotEmpty) ...[
            // Supplier breakdown
            if (week.itemsBySupplier.length > 1)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supplier Breakdown:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...week.itemsBySupplier.entries.map((entry) {
                      final supplierTotal = entry.value.fold(
                          0.0, (sum, item) => sum + (item.totalAmount ?? 0));
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              '${entry.value.length} items • ₹${supplierTotal.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

            const Divider(),

            // Individual items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items Purchased:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...week.purchaseItems
                      .take(5)
                      .map((item) => _buildPurchaseItem(item)),
                  if (week.purchaseItems.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '... and ${week.purchaseItems.length - 5} more items',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No detailed item information available',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPurchaseItem(WeeklyPurchaseItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName ?? 'Unknown Product',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (item.supplierName != null)
                  Text(
                    'Supplier: ${item.supplierName}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                if (item.purchaseDate != null)
                  Text(
                    'Date: ${item.purchaseDate!.day}/${item.purchaseDate!.month}/${item.purchaseDate!.year}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Qty: ${item.quantity ?? 0}',
                style: const TextStyle(fontSize: 12),
              ),
              if (item.unitPrice != null)
                Text(
                  '@ ₹${item.unitPrice!.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              Text(
                '₹${(item.totalAmount ?? 0).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
