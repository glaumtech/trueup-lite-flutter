import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../models/po_basket_item.dart';
import '../../models/ordered_item.dart';
import '../../providers/order_suggestions_provider.dart';
import '../../services/api_service.dart';

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
    if (!mounted) return;
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

      if (mounted) {
        setState(() {
          _groupedItems = grouped;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

    // Get supplier ID from supplierInfo or first item (for future use)
    // final supplierId = supplierInfo?['id'] ??
    //     supplierInfo?['supplierId'] ??
    //     (items.isNotEmpty ? items.first.supplierId : null);

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
          if (mounted) {
            setState(() {
              if (expanded) {
                _collapsedSuppliers.remove(supplierName);
              } else {
                _collapsedSuppliers.add(supplierName);
              }
            });
          }
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
    // Format: Product Name, Quantity and Unit
    final buffer = StringBuffer();

    for (var item in items) {
      final productName = item.name ?? 'Unknown Product';
      final quantity = item.quantity ?? 0;
      final unit = item.unit ?? 'Piece';
      buffer.writeln('$productName - $quantity $unit');
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
          duration: const Duration(seconds: 5),
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
      try {
        await ref.read(orderedItemsProvider.notifier).markAsOrdered(items);

        // Remove from basket without auto-refresh and track successful removals
        final List<POBasketItem> successfullyRemovedItems = [];
        for (var item in items) {
          if (item.id != null) {
            try {
              final response = await ref
                  .read(basketProvider.notifier)
                  .removeItemWithoutRefresh(item.id!);
              if (response.success) {
                successfullyRemovedItems.add(item);
              }
            } catch (e) {
              print('Error removing item ${item.name} from basket: $e');
            }
          }
        }

        // Remove only successfully removed items from local state
        if (mounted) {
          for (var item in successfullyRemovedItems) {
            _removeItemFromLocalState(item);
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
                  // Refresh after undo to reload the items
                  if (mounted) {
                    _loadBasketItems();
                  }
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error marking items as ordered: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
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
                if (item.id != null && mounted) {
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
              if (item.id != null && mounted) {
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
        if (!_isMultiSelectMode && item.id != null && mounted) {
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
            onPressed: (_) => _showEditItemDialog(item),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
          ),
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

  Future<void> _markItemAsOrderedFromDialog(POBasketItem item) async {
    // Show confirmation dialog
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
      try {
        await ref.read(orderedItemsProvider.notifier).markAsOrdered([item]);

        if (item.id != null) {
          final response = await ref
              .read(basketProvider.notifier)
              .removeItemWithoutRefresh(item.id!);

          // Only remove from local state if API call was successful
          if (response.success && mounted) {
            _removeItemFromLocalState(item);
          } else if (!response.success) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Failed to remove item from basket: ${response.message ?? 'Unknown error'}'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
            return;
          }
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
                    // Refresh after undo to reload the item
                    if (mounted) {
                      _loadBasketItems();
                    }
                  }
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error marking item as ordered: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
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
      try {
        await ref.read(orderedItemsProvider.notifier).markAsOrdered([item]);

        if (item.id != null) {
          final response = await ref
              .read(basketProvider.notifier)
              .removeItemWithoutRefresh(item.id!);

          // Only remove from local state if API call was successful
          if (response.success && mounted) {
            _removeItemFromLocalState(item);
          } else if (!response.success) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Failed to remove item from basket: ${response.message ?? 'Unknown error'}'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
            return;
          }
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
                    // Refresh after undo to reload the item
                    if (mounted) {
                      _loadBasketItems();
                    }
                  }
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error marking item as ordered: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
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
      // Refresh basket immediately after API success
      if (mounted) {
        _loadBasketItems();
      }
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

    try {
      await ref
          .read(orderedItemsProvider.notifier)
          .markAsOrdered(selectedItems);

      // Remove from basket without auto-refresh and track successful removals
      final List<POBasketItem> successfullyRemovedItems = [];
      for (var item in selectedItems) {
        if (item.id != null) {
          try {
            final response = await ref
                .read(basketProvider.notifier)
                .removeItemWithoutRefresh(item.id!);
            if (response.success) {
              successfullyRemovedItems.add(item);
            }
          } catch (e) {
            print('Error removing item ${item.name} from basket: $e');
          }
        }
      }

      if (mounted) {
        setState(() {
          _selectedItemIds.clear();
          _isMultiSelectMode = false;
        });
      }

      // Remove only successfully removed items from local state
      if (mounted) {
        for (var item in successfullyRemovedItems) {
          _removeItemFromLocalState(item);
        }
      }

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
                // Refresh after undo to reload the items
                if (mounted) {
                  _loadBasketItems();
                }
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking items as ordered: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
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
      try {
        final basketItems = ref.read(basketProvider);
        final itemsToRemove = basketItems
            .where((item) =>
                item.id != null && _selectedItemIds.contains(item.id!))
            .toList();

        // Remove from API without auto-refresh and track successful removals
        final List<POBasketItem> successfullyRemovedItems = [];
        final List<String> failedRemovals = [];

        for (var item in itemsToRemove) {
          if (item.id != null) {
            try {
              final response = await ref
                  .read(basketProvider.notifier)
                  .removeItemWithoutRefresh(item.id!);
              if (response.success) {
                successfullyRemovedItems.add(item);
              } else {
                failedRemovals.add(item.name ?? 'Unknown item');
              }
            } catch (e) {
              failedRemovals.add(item.name ?? 'Unknown item');
            }
          }
        }

        if (mounted) {
          setState(() {
            _selectedItemIds.clear();
            _isMultiSelectMode = false;
          });
        }

        // Remove only successfully removed items from local state
        if (mounted && successfullyRemovedItems.isNotEmpty) {
          for (var item in successfullyRemovedItems) {
            _removeItemFromLocalState(item);
          }
        }

        if (mounted) {
          if (successfullyRemovedItems.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '${successfullyRemovedItems.length} items removed from basket'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 5),
              ),
            );
          }

          if (failedRemovals.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Failed to remove ${failedRemovals.length} items: ${failedRemovals.join(', ')}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing items: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
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
      if (mounted) {
        setState(() {
          _groupedItems = null;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Basket cleared successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing basket: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _toggleGroupView() {
    if (_groupedItems == null) {
      _loadBasketItems(); // This will load grouped view
    } else {
      if (mounted) {
        setState(() {
          _groupedItems = null;
        });
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
            onPressed: () async {
              Navigator.of(context).pop();
              await _showEditItemDialog(item);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, size: 18),
                SizedBox(width: 4),
                Text('Edit'),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _markItemAsOrderedFromDialog(item);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 18),
                SizedBox(width: 4),
                Text('Mark as Ordered'),
              ],
            ),
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

  Future<void> _showEditItemDialog(POBasketItem item) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _EditItemDialog(
        item: item,
        apiService: ref.read(apiServiceProvider),
      ),
    );

    if (result != null && mounted) {
      final updatedName = result['name'] as String?;
      final updatedQuantity = result['quantity'] as int?;
      final updatedPrice = result['price'] as int?;
      final selectedBrand = result['brand'] as Map<String, dynamic>?;

      if (updatedName != null &&
          updatedQuantity != null &&
          updatedPrice != null) {
        await _updateBasketItemWithBrand(
          item,
          updatedName,
          updatedQuantity,
          updatedPrice,
          selectedBrand,
        );
      }
    }
  }

  Future<void> _updateBasketItemWithBrand(
    POBasketItem originalItem,
    String newName,
    int newQuantity,
    int newPrice,
    Map<String, dynamic>? selectedBrand,
  ) async {
    if (originalItem.id == null) return;

    try {
      final basketNotifier = ref.read(basketProvider.notifier);
      final apiService = ref.read(apiServiceProvider);

      // First, remove the original item
      final removeResponse =
          await basketNotifier.removeItemWithoutRefresh(originalItem.id!);

      // Only proceed if removal was successful
      if (!removeResponse.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to update item: ${removeResponse.message ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      _removeItemFromLocalState(originalItem);

      // If brand is selected, get all suppliers for that brand
      List<Map<String, dynamic>> suppliers = [];
      if (selectedBrand != null && selectedBrand['id'] != null) {
        try {
          final brandId = (selectedBrand['id'] as num?)?.toInt();
          if (brandId != null) {
            suppliers = await apiService.getSuppliers(brandId: brandId);
          }
        } catch (e) {
          print('Error fetching suppliers for brand: $e');
        }
      }

      // If no suppliers found for the brand (or no brand selected), add as single item without supplier
      if (suppliers.isEmpty) {
        final updatedItem = originalItem.copyWith(
          name: newName,
          quantity: newQuantity,
          price: newPrice,
          supplierId: null,
          supplierName: null,
        );

        final response = await basketNotifier.addItem(updatedItem);
        if (response.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$newName updated successfully'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          // Refresh to get updated state
          _loadBasketItems();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Failed to update item: ${response.message ?? 'Unknown error'}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } else {
        // Add one item per supplier (so it appears in all supplier groups)
        int addedCount = 0;
        for (var supplier in suppliers) {
          final supplierId = (supplier['id'] as num?)?.toInt();
          final supplierName = supplier['name'] as String?;

          final updatedItem = originalItem.copyWith(
            name: newName,
            quantity: newQuantity,
            price: newPrice,
            supplierId: supplierId,
            supplierName: supplierName,
            id: '${DateTime.now().millisecondsSinceEpoch}_${supplierId ?? addedCount}',
          );

          await basketNotifier.addItem(updatedItem);
          addedCount++;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                addedCount > 1
                    ? '$newName updated and added to $addedCount supplier groups'
                    : '$newName updated successfully',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        // Refresh to get updated state
        _loadBasketItems();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating item: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Remove item from local state (both basketProvider and _groupedItems)
  void _removeItemFromLocalState(POBasketItem item) {
    if (item.id == null) return;

    // Remove from basket provider state
    final currentBasket = ref.read(basketProvider);
    final updatedBasket =
        currentBasket.where((basketItem) => basketItem.id != item.id).toList();
    ref.read(basketProvider.notifier).setItems(updatedBasket);

    // Remove from grouped items structure
    if (_groupedItems != null) {
      final groupedData = Map<String, dynamic>.from(_groupedItems!);
      final supplierGroupsList =
          groupedData['supplierGroups'] as List<dynamic>? ?? [];

      // Update supplier groups by removing the item
      for (var group in supplierGroupsList) {
        if (group is Map<String, dynamic>) {
          final itemsRaw = group['items'] as List<dynamic>?;
          if (itemsRaw != null) {
            // Remove the item from this supplier's items
            itemsRaw.removeWhere((itemJson) {
              try {
                final basketItem = itemJson is Map<String, dynamic>
                    ? POBasketItem.fromJson(itemJson)
                    : POBasketItem.fromJson(
                        Map<String, dynamic>.from(itemJson));
                return basketItem.id == item.id;
              } catch (e) {
                return false;
              }
            });

            // Update group totals
            final remainingItems = itemsRaw
                .map((itemJson) {
                  try {
                    return itemJson is Map<String, dynamic>
                        ? POBasketItem.fromJson(itemJson)
                        : POBasketItem.fromJson(
                            Map<String, dynamic>.from(itemJson));
                  } catch (e) {
                    return null;
                  }
                })
                .where((item) => item != null)
                .cast<POBasketItem>()
                .toList();

            group['totalItems'] = remainingItems.length;
            group['totalCost'] = remainingItems.fold<int>(
                0, (sum, item) => sum + item.totalCost);
          }
        }
      }

      // Remove empty supplier groups
      supplierGroupsList.removeWhere((group) {
        if (group is Map<String, dynamic>) {
          final itemsRaw = group['items'] as List<dynamic>?;
          return itemsRaw == null || itemsRaw.isEmpty;
        }
        return false;
      });

      // Update overall totals
      final allItems = <POBasketItem>[];
      for (var group in supplierGroupsList) {
        if (group is Map<String, dynamic>) {
          final itemsRaw = group['items'] as List<dynamic>?;
          if (itemsRaw != null) {
            for (var itemJson in itemsRaw) {
              try {
                final basketItem = itemJson is Map<String, dynamic>
                    ? POBasketItem.fromJson(itemJson)
                    : POBasketItem.fromJson(
                        Map<String, dynamic>.from(itemJson));
                allItems.add(basketItem);
              } catch (e) {
                // Skip invalid items
              }
            }
          }
        }
      }

      groupedData['totalItems'] = allItems.length;
      groupedData['totalCost'] =
          allItems.fold<int>(0, (sum, item) => sum + item.totalCost);
      groupedData['totalSuppliers'] = supplierGroupsList.length;
      groupedData['supplierGroups'] = supplierGroupsList;

      setState(() {
        _groupedItems = groupedData;
      });
    }
  }

  Future<void> _removeItem(POBasketItem item) async {
    if (item.id == null) return;

    try {
      // Use removeItemWithoutRefresh to avoid automatic page refresh
      final response = await ref
          .read(basketProvider.notifier)
          .removeItemWithoutRefresh(item.id!);

      // Only remove item from local state if API call was successful
      if (response.success) {
        if (mounted) {
          _removeItemFromLocalState(item);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} removed from basket'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        // API call failed, show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to remove item: ${response.message ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing item: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

class _EditItemDialog extends StatefulWidget {
  final POBasketItem item;
  final ApiService apiService;

  const _EditItemDialog({
    required this.item,
    required this.apiService,
  });

  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;

  List<Map<String, dynamic>> _brands = [];
  Map<String, dynamic>? _selectedBrand;
  bool _isLoadingBrands = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name ?? '');
    _quantityController =
        TextEditingController(text: widget.item.quantity?.toString() ?? '1');
    _priceController =
        TextEditingController(text: widget.item.price?.toString() ?? '0');

    // Add listeners to update total cost in real-time
    _quantityController.addListener(_updateTotalCost);
    _priceController.addListener(_updateTotalCost);

    _loadBrands();
  }

  void _updateTotalCost() {
    setState(() {
      // This will trigger rebuild and recalculate _calculateTotalCost()
    });
  }

  @override
  void dispose() {
    _quantityController.removeListener(_updateTotalCost);
    _priceController.removeListener(_updateTotalCost);
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    setState(() {
      _isLoadingBrands = true;
    });

    try {
      final brands = await widget.apiService.getBrands();
      setState(() {
        _brands = brands.where((b) => b['name'] != null).toList()
          ..sort(
              (a, b) => (a['name'] as String).compareTo(b['name'] as String));
        _isLoadingBrands = false;
      });
    } catch (e) {
      print('Error loading brands: $e');
      setState(() {
        _isLoadingBrands = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Item Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name *',
                hintText: 'Enter product name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),

            // Brand Dropdown (similar to add custom item)
            if (_isLoadingBrands)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<Map<String, dynamic>>(
                decoration: const InputDecoration(
                  labelText: 'Brand (Optional)',
                  border: OutlineInputBorder(),
                ),
                value: _selectedBrand,
                items: [
                  const DropdownMenuItem<Map<String, dynamic>>(
                    value: null,
                    child: Text('None'),
                  ),
                  ..._brands
                      .map((brand) => DropdownMenuItem<Map<String, dynamic>>(
                            value: brand,
                            child: Text(brand['name'] as String),
                          )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedBrand = value;
                  });
                },
              ),
            const SizedBox(height: 16),

            // Quantity
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity *',
                hintText: 'Enter quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Price
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price per Unit (₹)',
                hintText: 'Enter price',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Total Cost Display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Cost:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '₹${_calculateTotalCost()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _validateAndSave,
          child: const Text('Update'),
        ),
      ],
    );
  }

  int _calculateTotalCost() {
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    final price = int.tryParse(_priceController.text.trim()) ?? 0;
    return quantity * price;
  }

  void _validateAndSave() {
    final name = _nameController.text.trim();
    final quantityStr = _quantityController.text.trim();
    final priceStr = _priceController.text.trim();

    // Validation
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product name is required'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    final quantity = int.tryParse(quantityStr);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid quantity (greater than 0)'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    final price = int.tryParse(priceStr);
    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid price (0 or greater)'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    // Return the updated values
    Navigator.pop(context, {
      'name': name,
      'quantity': quantity,
      'price': price,
      'brand': _selectedBrand,
    });
  }
}
