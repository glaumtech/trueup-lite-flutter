import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order_suggestion_history.dart';
import '../../providers/order_suggestions_provider.dart';

class OrderSuggestionsHistoryScreen extends ConsumerStatefulWidget {
  const OrderSuggestionsHistoryScreen({super.key});

  @override
  ConsumerState<OrderSuggestionsHistoryScreen> createState() => _OrderSuggestionsHistoryScreenState();
}

class _OrderSuggestionsHistoryScreenState extends ConsumerState<OrderSuggestionsHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory({bool refresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(orderSuggestionHistoryProvider.notifier).loadHistory(refresh: refresh);
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

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      final notifier = ref.read(orderSuggestionHistoryProvider.notifier);
      if (notifier.hasMore && !notifier.isLoading) {
        notifier.loadHistory();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyItems = ref.watch(orderSuggestionHistoryProvider);
    final notifier = ref.read(orderSuggestionHistoryProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Suggestion History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadHistory(refresh: true),
          ),
        ],
      ),
      body: _buildContent(historyItems, notifier),
    );
  }

  Widget _buildContent(List<OrderSuggestionHistory> historyItems, notifier) {
    if (_isLoading && historyItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading history...'),
          ],
        ),
      );
    }

    if (_errorMessage != null && historyItems.isEmpty) {
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
              onPressed: () => _loadHistory(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (historyItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No History Available',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Order suggestion history will appear here',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadHistory(refresh: true),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadHistory(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: historyItems.length + (notifier.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == historyItems.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          
          return _buildHistoryCard(historyItems[index]);
        },
      ),
    );
  }

  Widget _buildHistoryCard(OrderSuggestionHistory history) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        history.supplierName ?? 'Unknown Supplier',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        history.formattedActionDate,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getActionColor(history.actionTaken),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    history.actionTypeDisplay,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Statistics Row
            Row(
              children: [
                _buildStatChip(
                  icon: Icons.inventory,
                  label: 'Products',
                  value: '${history.totalProducts}',
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  icon: Icons.shopping_cart,
                  label: 'Quantity',
                  value: '${history.totalSuggestedQuantity}',
                  color: Colors.green,
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  icon: Icons.currency_rupee,
                  label: 'Cost',
                  value: '${history.estimatedCost}',
                  color: Colors.orange,
                ),
              ],
            ),
            
            // Action by and Notes
            if (history.actionBy != null || (history.notes != null && history.notes!.isNotEmpty))
              const SizedBox(height: 12),
            
            if (history.actionBy != null)
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'By: ${history.actionBy}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            
            if (history.notes != null && history.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notes:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        history.notes!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getActionColor(String? actionTaken) {
    switch (actionTaken) {
      case 'GENERATED':
        return Colors.blue;
      case 'MODIFIED':
        return Colors.orange;
      case 'ORDER_CREATED':
        return Colors.green;
      case 'EXPORTED':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
