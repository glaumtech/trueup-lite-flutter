import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../models/po_basket_item.dart';
import '../../models/ordered_item.dart';
import '../../models/request_models.dart';
import '../../providers/order_suggestions_provider.dart';
import '../../utils/whatsapp_formatter.dart';

class OrderSuggestionsBasketScreen extends ConsumerStatefulWidget {
  const OrderSuggestionsBasketScreen({super.key});

  @override
  ConsumerState<OrderSuggestionsBasketScreen> createState() =>
      _OrderSuggestionsBasketScreenState();
}

class _OrderSuggestionsBasketScreenState
    extends ConsumerState<OrderSuggestionsBasketScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _groupedItems;

  // Multi-select state
  bool _isMultiSelectMode = false;
  final Set<String> _selectedItemIds = {};

  // Collapsed suppliers
  final Set<String> _collapsedSuppliers = {};

  // Show ordered items
  bool _showOrderedItems = true;

  // Helper function to safely convert values from int or String to String?
  String? _safeStringFromJson(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is int) return value.toString();
    return value.toString();
  }

  @override
  void initState() {
    super.initState();
    _loadBasketItems();
    // Load ordered items
    Future.microtask(() {
      ref.read(orderedItemsProvider.notifier).loadOrderedItems();
    });
  }

  Future<void> _loadBasketItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load grouped basket items with supplier information (single API call)
      final apiService = ref.read(apiServiceProvider);
      final grouped = await apiService.getBasketItemsGroupedBySupplier();

      // Extract all items from grouped response and update basket provider
      // This avoids a second API call to /basket
      final supplierGroupsList =
          grouped['supplierGroups'] as List<dynamic>? ?? [];
      List<POBasketItem> allItems = [];

      for (var group in supplierGroupsList) {
        if (group is Map<String, dynamic>) {
          final itemsRaw = group['items'] as List<dynamic>?;
          if (itemsRaw != null) {
            for (var itemJson in itemsRaw) {
              try {
                if (itemJson is Map<String, dynamic>) {
                  allItems.add(POBasketItem.fromJson(itemJson));
                } else {
                  allItems.add(POBasketItem.fromJson(
                      Map<String, dynamic>.from(itemJson)));
                }
              } catch (e) {
                print('⚠️ Error parsing item from grouped response: $e');
              }
            }
          }
        }
      }

      // Update basket provider with extracted items (for count/total calculations)
      // This avoids a second API call to /basket since we already have all items from grouped response
      ref.read(basketProvider.notifier).setItems(allItems);

      setState(() {
        _groupedItems = grouped;
      });
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
    final basketItems = ref.watch(basketProvider);
    final basketTotal = ref.watch(basketTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('PO Basket (${basketItems.length})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to order suggestions screen
            context.go('/order-suggestions');
          },
          tooltip: 'Back to Order Suggestions',
        ),
        actions: [
          if (basketItems.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: ListTile(
                    leading: Icon(Icons.clear_all, color: Colors.red),
                    title: Text('Clear Basket'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'group_view',
                  child: ListTile(
                    leading: Icon(Icons.group),
                    title: Text('Group by Supplier'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'create_po',
                  child: ListTile(
                    leading: Icon(Icons.create),
                    title: Text('Create Purchase Order'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildContent(basketItems, basketTotal),
      floatingActionButton: _isMultiSelectMode && _selectedItemIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showBulkActionsDialog,
              icon: const Icon(Icons.more_vert),
              label: Text('${_selectedItemIds.length} selected'),
            )
          : null,
      bottomNavigationBar: basketItems.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Items: ${basketItems.length}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            'Total Cost: ₹$basketTotal',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showCreatePODialog(),
                      icon: const Icon(Icons.create),
                      label: const Text('Create PO'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildContent(List<POBasketItem> basketItems, int basketTotal) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading basket items...'),
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
              'Error loading basket',
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
              onPressed: _loadBasketItems,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (basketItems.isEmpty) {
      // Show empty basket message and ordered items section
      return Column(
        children: [
          // Empty basket message
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_basket_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Basket is Empty',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add items from order suggestions to get started',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/order-suggestions'),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Browse Suggestions'),
                  ),
                ],
              ),
            ),
          ),
          // Always show ordered items section
          _buildOrderedItemsSection(),
        ],
      );
    }

    // Always show grouped view with supplier information
    if (_groupedItems != null) {
      return _buildGroupedView(_groupedItems!);
    }

    // Fallback to list view if grouped data is not available yet
    return _buildListView(basketItems);
  }

  Widget _buildListView(List<POBasketItem> basketItems) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: basketItems.length,
      itemBuilder: (context, index) {
        return _buildBasketItemCard(basketItems[index]);
      },
    );
  }

  Widget _buildGroupedView(Map<String, dynamic> groupedData) {
    // Backend returns supplierGroups as a List of group objects
    // Each group has: supplierName, supplier (info), items, totalItems, totalCost
    dynamic supplierGroupsRaw = groupedData['supplierGroups'];
    List<dynamic> supplierGroupsList;

    if (supplierGroupsRaw is List) {
      supplierGroupsList = supplierGroupsRaw;
    } else if (supplierGroupsRaw is Map) {
      // Handle legacy Map format if needed
      print(
          '⚠️ Warning: supplierGroups is a Map, expected List. Converting...');
      supplierGroupsList = [];
      supplierGroupsRaw.forEach((key, value) {
        if (value is List) {
          supplierGroupsList.add({
            'supplierName': key,
            'items': value,
          });
        }
      });
    } else {
      supplierGroupsList = [];
      print(
          '⚠️ Warning: supplierGroups is null or unexpected type: ${supplierGroupsRaw.runtimeType}');
    }

    final totalItems = (groupedData['totalItems'] as num?)?.toInt() ?? 0;
    final totalCost = (groupedData['totalCost'] as num?)?.toInt() ?? 0;
    final totalSuppliers = (groupedData['totalSuppliers'] as num?)?.toInt() ??
        supplierGroupsList.length;

    return Column(
      children: [
        // Summary Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basket Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text('$totalSuppliers suppliers • $totalItems items'),
                  ],
                ),
              ),
              Text(
                '₹$totalCost',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
              ),
            ],
          ),
        ),

        // Grouped Items
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: supplierGroupsList.length + (_showOrderedItems ? 1 : 0),
            itemBuilder: (context, index) {
              // Show ordered items section at the end
              if (_showOrderedItems && index == supplierGroupsList.length) {
                return _buildOrderedItemsSection();
              }
              final group = supplierGroupsList[index] as Map<String, dynamic>;
              final supplierName =
                  group['supplierName'] as String? ?? 'Unknown Supplier';
              final supplierInfo = group['supplier'] as Map<String, dynamic>?;
              final itemsRaw = group['items'] as List<dynamic>?;
              final groupTotalItems = (group['totalItems'] as num?)?.toInt();
              final groupTotalCost = (group['totalCost'] as num?)?.toInt();

              List<POBasketItem> items = [];
              if (itemsRaw != null) {
                items = itemsRaw.map<POBasketItem>((json) {
                  try {
                    if (json is Map<String, dynamic>) {
                      return POBasketItem.fromJson(json);
                    } else {
                      return POBasketItem.fromJson(
                          Map<String, dynamic>.from(json));
                    }
                  } catch (e) {
                    print('❌ Error parsing basket item: $e');
                    print('   Item data: $json');
                    rethrow;
                  }
                }).toList();
              }

              return _buildSupplierGroup(
                supplierName,
                items,
                supplierInfo: supplierInfo,
                groupTotalItems: groupTotalItems,
                groupTotalCost: groupTotalCost,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSupplierGroup(
    String supplierName,
    List<POBasketItem> items, {
    Map<String, dynamic>? supplierInfo,
    int? groupTotalItems,
    int? groupTotalCost,
  }) {
    // Use provided totals or calculate from items
    final totalItems = groupTotalItems ?? items.length;
    final total = groupTotalCost ??
        items.fold<int>(0, (sum, item) => sum + (item.totalCost));

    // Get supplier ID from supplierInfo or first item
    final supplierId = supplierInfo?['id'] ??
        supplierInfo?['supplierId'] ??
        (items.isNotEmpty ? items.first.supplierId : null);

    // Get additional supplier details from supplierInfo
    final supplierPhone =
        supplierInfo != null && supplierInfo.containsKey('phone')
            ? _safeStringFromJson(supplierInfo['phone'])
            : null;

    final isCollapsed = _collapsedSuppliers.contains(supplierName);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Icon(Icons.business, color: Colors.green[800]),
        ),
        title: Text(
          supplierName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$totalItems items • ₹$total'),
            if (supplierPhone != null)
              Text(
                'Phone: $supplierPhone',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        initiallyExpanded: !isCollapsed,
        onExpansionChanged: (expanded) {
          setState(() {
            if (expanded) {
              _collapsedSuppliers.remove(supplierName);
            } else {
              _collapsedSuppliers.add(supplierName);
            }
          });
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy list for WhatsApp',
              onPressed: () => _copySupplierList(supplierName, items),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Mark all as ordered',
              onPressed: () => _markSupplierAsOrdered(supplierName, items),
            ),
          ],
        ),
        children: items.map((item) => _buildBasketItemTile(item)).toList(),
      ),
    );
  }

  Future<void> _copySupplierList(
      String supplierName, List<POBasketItem> items) async {
    // Format: Only Product Name and Quantity
    final buffer = StringBuffer();

    for (var item in items) {
      final productName = item.name ?? 'Unknown Product';
      final quantity = item.quantity ?? 0;
      buffer.writeln('$productName - $quantity');
    }

    final formattedText = buffer.toString().trim();

    await Clipboard.setData(ClipboardData(text: formattedText));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$supplierName list copied to clipboard'),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () => Share.share(formattedText),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _markSupplierAsOrdered(
    String supplierName,
    List<POBasketItem> items,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark all items as ordered?'),
        content: Text(
          'Mark all ${items.length} items from $supplierName as ordered?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark as Ordered'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(orderedItemsProvider.notifier).markAsOrdered(items);

      // Remove from basket
      for (var item in items) {
        if (item.id != null) {
          await ref.read(basketProvider.notifier).removeItem(item.id!);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${items.length} items marked as ordered'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                await ref.read(orderedItemsProvider.notifier).unmarkAsOrdered(
                      items
                          .where((i) => i.id != null)
                          .map((i) => i.id!)
                          .toList(),
                    );
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }

      _loadBasketItems();
    }
  }

  Widget _buildBasketItemCard(POBasketItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: _buildBasketItemTile(item),
    );
  }

  Widget _buildBasketItemTile(POBasketItem item) {
    final isSelected = _isMultiSelectMode &&
        item.id != null &&
        _selectedItemIds.contains(item.id!);

    final tile = ListTile(
      leading: _isMultiSelectMode
          ? Checkbox(
              value: isSelected,
              onChanged: (value) {
                if (item.id != null) {
                  setState(() {
                    if (value == true) {
                      _selectedItemIds.add(item.id!);
                    } else {
                      _selectedItemIds.remove(item.id!);
                      if (_selectedItemIds.isEmpty) {
                        _isMultiSelectMode = false;
                      }
                    }
                  });
                }
              },
            )
          : CircleAvatar(
              backgroundColor:
                  item.isUrgent ? Colors.red[100] : Colors.blue[100],
              child: Icon(
                Icons.inventory,
                color: item.isUrgent ? Colors.red[800] : Colors.blue[800],
              ),
            ),
      title: Text(
        item.name ?? 'Unknown Item',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.supplierName != null)
            Row(
              children: [
                Icon(Icons.business, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Supplier: ${item.supplierName}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (item.supplierId != null)
                  Text(
                    ' (ID: ${item.supplierId})',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.shopping_cart, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text('Qty: ${item.quantity ?? 0} ${item.unit ?? ''}'),
            ],
          ),
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Notes: ${item.notes}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '₹${item.price ?? 0}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            '₹${item.totalCost}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (item.isUrgent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'URGENT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: _isMultiSelectMode
          ? () {
              if (item.id != null) {
                setState(() {
                  if (_selectedItemIds.contains(item.id!)) {
                    _selectedItemIds.remove(item.id!);
                    if (_selectedItemIds.isEmpty) {
                      _isMultiSelectMode = false;
                    }
                  } else {
                    _selectedItemIds.add(item.id!);
                  }
                });
              }
            }
          : () => _showItemDetailsDialog(item),
      onLongPress: () {
        if (!_isMultiSelectMode && item.id != null) {
          setState(() {
            _isMultiSelectMode = true;
            _selectedItemIds.add(item.id!);
          });
        }
      },
    );

    // Wrap with Slidable if not in multi-select mode
    if (_isMultiSelectMode) {
      return tile;
    }

    return Slidable(
      key: ValueKey(item.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _markItemAsOrdered(item),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            icon: Icons.check_circle,
            label: 'Order',
          ),
          SlidableAction(
            onPressed: (_) => _removeItem(item),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Remove',
          ),
        ],
      ),
      child: tile,
    );
  }

  Future<void> _markItemAsOrdered(POBasketItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as ordered?'),
        content: Text('Mark "${item.name}" as ordered?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark as Ordered'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(orderedItemsProvider.notifier).markAsOrdered([item]);

      if (item.id != null) {
        await ref.read(basketProvider.notifier).removeItem(item.id!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} marked as ordered'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                if (item.id != null) {
                  await ref
                      .read(orderedItemsProvider.notifier)
                      .unmarkAsOrdered([item.id!]);
                }
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }

      _loadBasketItems();
    }
  }

  Widget _buildOrderedItemsSection() {
    final orderedItems = ref.watch(orderedItemsProvider);

    // Always show the section header, even if empty
    if (orderedItems.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Ordered Items',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'No ordered items yet',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Group by supplier
    final groupedBySupplier = <String, List<OrderedItem>>{};
    for (var item in orderedItems) {
      final supplier = item.supplierName ?? 'Unknown Supplier';
      groupedBySupplier.putIfAbsent(supplier, () => []).add(item);
    }

    // Sort suppliers by their most recent order date (descending)
    final sortedSuppliers = groupedBySupplier.entries.toList()
      ..sort((a, b) {
        // Get the most recent date from each supplier's items
        final aMaxDate = a.value
            .map((item) => item.orderedDate)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        final bMaxDate = b.value
            .map((item) => item.orderedDate)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        // Sort descending (newest first)
        return bMaxDate.compareTo(aMaxDate);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Ordered Items',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        ...sortedSuppliers.map((entry) {
          // Sort items within supplier by date descending
          final sortedItems = List<OrderedItem>.from(entry.value)
            ..sort((a, b) => b.orderedDate.compareTo(a.orderedDate));
          return _buildOrderedSupplierGroup(entry.key, sortedItems);
        }),
      ],
    );
  }

  Widget _buildOrderedSupplierGroup(
      String supplierName, List<OrderedItem> items) {
    // Group by date
    final groupedByDate = <DateTime, List<OrderedItem>>{};
    for (var item in items) {
      final date = DateTime(
        item.orderedDate.year,
        item.orderedDate.month,
        item.orderedDate.day,
      );
      groupedByDate.putIfAbsent(date, () => []).add(item);
    }

    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.check_circle, color: Colors.white),
        ),
        title: Text(supplierName),
        subtitle: Text('${items.length} items ordered'),
        children: sortedDates.map((date) {
          final dateItems = groupedByDate[date]!;
          return _buildOrderedDateGroup(date, dateItems);
        }).toList(),
      ),
    );
  }

  Widget _buildOrderedDateGroup(DateTime date, List<OrderedItem> items) {
    final totalCost = items.fold<int>(0, (sum, item) => sum + item.totalCost);

    // Sort items within date group by orderedDate descending (newest first)
    final sortedItems = List<OrderedItem>.from(items)
      ..sort((a, b) => b.orderedDate.compareTo(a.orderedDate));

    return ExpansionTile(
      title: Text(DateFormat('dd MMM yyyy').format(date)),
      subtitle: Text('${items.length} items • ₹$totalCost'),
      children: sortedItems.map((item) {
        return ListTile(
          leading: const Icon(Icons.inventory_2, color: Colors.green),
          title: Text(item.name ?? 'Unknown'),
          subtitle: Text(
            'Qty: ${item.quantity ?? 0} ${item.unit ?? ''} • ₹${item.price ?? 0} each',
          ),
          trailing: Text(
            '₹${item.totalCost}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onTap: () => _unmarkAsOrdered(item),
        );
      }).toList(),
    );
  }

  Future<void> _unmarkAsOrdered(OrderedItem item) async {
    if (item.id != null) {
      await ref.read(orderedItemsProvider.notifier).unmarkAsOrdered([item.id!]);
      _loadBasketItems();
    }
  }

  void _showBulkActionsDialog() {
    if (_selectedItemIds.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Mark as Ordered'),
              onTap: () {
                Navigator.pop(context);
                _bulkMarkAsOrdered();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Remove'),
              onTap: () {
                Navigator.pop(context);
                _bulkRemove();
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bulkMarkAsOrdered() async {
    final basketItems = ref.read(basketProvider);
    final selectedItems = basketItems
        .where((item) => item.id != null && _selectedItemIds.contains(item.id!))
        .toList();

    if (selectedItems.isEmpty) return;

    await ref.read(orderedItemsProvider.notifier).markAsOrdered(selectedItems);

    // Remove from basket
    for (var item in selectedItems) {
      if (item.id != null) {
        await ref.read(basketProvider.notifier).removeItem(item.id!);
      }
    }

    setState(() {
      _selectedItemIds.clear();
      _isMultiSelectMode = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selectedItems.length} items marked as ordered'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await ref.read(orderedItemsProvider.notifier).unmarkAsOrdered(
                    selectedItems
                        .where((i) => i.id != null)
                        .map((i) => i.id!)
                        .toList(),
                  );
            },
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }

    _loadBasketItems();
  }

  Future<void> _bulkRemove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove items?'),
        content: Text('Remove ${_selectedItemIds.length} items from basket?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (var itemId in _selectedItemIds) {
        await ref.read(basketProvider.notifier).removeItem(itemId);
      }

      setState(() {
        _selectedItemIds.clear();
        _isMultiSelectMode = false;
      });

      _loadBasketItems();
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear':
        _showClearBasketDialog();
        break;
      case 'group_view':
        _toggleGroupView();
        break;
      case 'create_po':
        _showCreatePODialog();
        break;
    }
  }

  void _showClearBasketDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Basket'),
        content: const Text(
            'Are you sure you want to remove all items from the basket?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearBasket();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearBasket() async {
    try {
      await ref.read(basketProvider.notifier).clearBasket();
      setState(() {
        _groupedItems = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Basket cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing basket: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleGroupView() {
    if (_groupedItems == null) {
      _loadBasketItems(); // This will load grouped view
    } else {
      setState(() {
        _groupedItems = null;
      });
    }
  }

  void _showCreatePODialog() {
    final basketItems = ref.read(basketProvider);
    if (basketItems.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => _CreatePODialog(
        basketItems: basketItems,
        onCreatePO: _createPurchaseOrder,
      ),
    );
  }

  Future<void> _createPurchaseOrder(
      CreateBasketPurchaseOrderRequest request) async {
    try {
      final response = await ref
          .read(basketProvider.notifier)
          .createPurchaseOrderFromBasket(request);

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Purchase order created: ${response.orderNumber ?? 'Unknown'}'),
              backgroundColor: Colors.green,
            ),
          );

          if (request.clearBasketAfterOrder) {
            setState(() {
              _groupedItems = null;
            });
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response.message ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating purchase order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showItemDetailsDialog(POBasketItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name ?? 'Item Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Type', item.type ?? 'Unknown'),
            _buildDetailRow('Supplier', item.supplierName ?? 'Not specified'),
            _buildDetailRow(
                'Quantity', '${item.quantity ?? 0} ${item.unit ?? ''}'),
            _buildDetailRow('Unit Price', '₹${item.price ?? 0}'),
            _buildDetailRow('Total Cost', '₹${item.totalCost}'),
            if (item.currentStock != null)
              _buildDetailRow('Current Stock', '${item.currentStock}'),
            if (item.reorderLevel != null)
              _buildDetailRow('Reorder Level', '${item.reorderLevel}'),
            if (item.notes != null && item.notes!.isNotEmpty)
              _buildDetailRow('Notes', item.notes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeItem(item);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _removeItem(POBasketItem item) async {
    if (item.id == null) return;

    try {
      await ref.read(basketProvider.notifier).removeItem(item.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} removed from basket'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _CreatePODialog extends StatefulWidget {
  final List<POBasketItem> basketItems;
  final Function(CreateBasketPurchaseOrderRequest) onCreatePO;

  const _CreatePODialog({
    required this.basketItems,
    required this.onCreatePO,
  });

  @override
  State<_CreatePODialog> createState() => _CreatePODialogState();
}

class _CreatePODialogState extends State<_CreatePODialog> {
  final _notesController = TextEditingController();
  final _deliveryDateController = TextEditingController();
  String _priority = 'MEDIUM';
  bool _clearBasketAfterOrder = true;

  @override
  Widget build(BuildContext context) {
    final totalCost =
        widget.basketItems.fold(0, (sum, item) => sum + item.totalCost);

    return AlertDialog(
      title: const Text('Create Purchase Order'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Order Summary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text('${widget.basketItems.length} items • ₹$totalCost'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Add any special instructions...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            // Expected Delivery Date
            TextField(
              controller: _deliveryDateController,
              decoration: const InputDecoration(
                labelText: 'Expected Delivery Date (Optional)',
                hintText: 'YYYY-MM-DD',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Priority
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'LOW', child: Text('Low')),
                DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                DropdownMenuItem(value: 'HIGH', child: Text('High')),
              ],
              onChanged: (value) {
                setState(() {
                  _priority = value ?? 'MEDIUM';
                });
              },
            ),

            const SizedBox(height: 16),

            // Clear basket option
            CheckboxListTile(
              title: const Text('Clear basket after creating order'),
              value: _clearBasketAfterOrder,
              onChanged: (value) {
                setState(() {
                  _clearBasketAfterOrder = value ?? true;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final request = CreateBasketPurchaseOrderRequest(
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              expectedDeliveryDate: _deliveryDateController.text.trim().isEmpty
                  ? null
                  : _deliveryDateController.text.trim(),
              priority: _priority,
              clearBasketAfterOrder: _clearBasketAfterOrder,
            );

            Navigator.of(context).pop();
            widget.onCreatePO(request);
          },
          child: const Text('Create PO'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _deliveryDateController.dispose();
    super.dispose();
  }
}
