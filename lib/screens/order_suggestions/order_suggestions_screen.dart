import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/product_order_suggestion.dart';
import '../../providers/order_suggestions_provider.dart';
import '../../models/po_basket_item.dart';

class OrderSuggestionsScreen extends ConsumerStatefulWidget {
  const OrderSuggestionsScreen({super.key});

  @override
  ConsumerState<OrderSuggestionsScreen> createState() =>
      _OrderSuggestionsScreenState();
}

class _OrderSuggestionsScreenState extends ConsumerState<OrderSuggestionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  // Map to store TextEditingControllers for each product's quantity field
  final Map<int, TextEditingController> _quantityControllers = {};
  // Map to track if we're currently updating a quantity (to prevent controller reset)
  final Map<int, bool> _isUpdatingQuantity = {};

  String? _selectedCategory;
  String? _selectedBrand;
  String? _selectedSupplier;
  bool _inStockOnly = false;
  double? _minPrice;
  double? _maxPrice;

  // Multi-select state
  bool _isMultiSelectMode = false;
  final Set<int> _selectedProductIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedCategory = 'All Categories';
    _selectedBrand = 'All Brands';

    // Load categories, brands, and basket items when screen initializes
    // Note: orderSuggestionsProvider will auto-load via its build() method when watched
    Future.microtask(() {
      ref.read(categoriesProvider.notifier).loadCategories();
      ref.read(brandsProvider.notifier).loadBrands();
      // Load basket items to get current basket state
      ref.read(basketProvider.notifier).loadBasketItems().catchError((error) {
        print('Error loading basket items: $error');
      });
    });

    _searchController.addListener(() {
      final filter = ref.read(orderSuggestionFilterProvider);
      ref.read(orderSuggestionFilterProvider.notifier).state =
          OrderSuggestionFilter(
              searchTerm: _searchController.text,
              category: filter.category,
              brand: filter.brand);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    // Dispose all quantity controllers
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    _quantityControllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestionsAsync = ref.watch(orderSuggestionsProvider);
    ref.watch(basketProvider); // Watch to trigger rebuilds when basket changes
    final basketCount = ref.watch(basketCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Order Manager'),
        leading: const Icon(Icons.shopping_cart),
        actions: [
          // Display basket count badge - clickable to navigate to basket
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: () {
                context.go('/order-suggestions/basket');
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_basket, color: Colors.white),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: basketCount > 0 ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$basketCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabs(),
          _buildFilterControls(),
          Expanded(
            child: suggestionsAsync.when(
              data: (suggestions) => _buildProductList(suggestions),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          _isMultiSelectMode ? _buildMultiSelectActionBar() : null,
    );
  }

  Widget _buildMultiSelectActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_selectedProductIds.length} selected',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedProductIds.clear();
                      _isMultiSelectMode = false;
                    });
                  },
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text('Cancel',
                      style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _selectedProductIds.isEmpty
                      ? null
                      : () => _addSelectedToBasket(),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Add to Basket'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addSelectedToBasket() async {
    final suggestionsAsync = ref.read(orderSuggestionsProvider);
    final suggestions = suggestionsAsync.value ?? [];

    final selectedProducts = suggestions
        .where((product) =>
            product.productId != null &&
            _selectedProductIds.contains(product.productId!))
        .toList();

    if (selectedProducts.isEmpty) return;

    // Show quantity selector for all selected products
    for (var product in selectedProducts) {
      _showQuantitySelectorModal(product, defaultQuantity: 1);
    }

    setState(() {
      _selectedProductIds.clear();
      _isMultiSelectMode = false;
    });
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.black,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: Colors.blue,
        ),
        tabs: const [
          Tab(text: 'PRODUCTS'),
          Tab(text: 'SUPPLIERS'),
          Tab(text: 'CUSTOM'),
        ],
      ),
    );
  }

  Widget _buildFilterControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Filter chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'In Stock Only',
                  selected: _inStockOnly,
                  onSelected: (value) {
                    setState(() => _inStockOnly = value);
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Clear Filters',
                  selected: false,
                  onSelected: (_) => _clearAllFilters(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(flex: 3, child: _buildCategoryDropdown()),
              const SizedBox(width: 8),
              Expanded(flex: 3, child: _buildBrandDropdown()),
              const SizedBox(width: 8),
              Expanded(flex: 3, child: _buildSupplierDropdown()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
    );
  }

  void _clearAllFilters() {
    _searchController.clear();
    setState(() {
      _selectedCategory = 'All Categories';
      _selectedBrand = 'All Brands';
      _selectedSupplier = 'All Suppliers';
      _inStockOnly = false;
      _minPrice = null;
      _maxPrice = null;
    });
    ref.read(orderSuggestionFilterProvider.notifier).state =
        OrderSuggestionFilter();
  }

  Widget _buildSupplierDropdown() {
    final suggestionsAsync = ref.watch(orderSuggestionsProvider);

    return suggestionsAsync.when(
      data: (suggestions) {
        final suppliers = suggestions
            .where((s) => s.supplierName != null)
            .map((s) => s.supplierName!)
            .toSet()
            .toList()
          ..sort();

        final supplierList = ['All Suppliers', ...suppliers];

        return DropdownButtonFormField<String>(
          value: _selectedSupplier ?? 'All Suppliers',
          items: supplierList
              .map((supplier) => DropdownMenuItem(
                    value: supplier,
                    child: Text(supplier),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() => _selectedSupplier = value);
            final filter = ref.read(orderSuggestionFilterProvider);
            ref.read(orderSuggestionFilterProvider.notifier).state =
                OrderSuggestionFilter(
                    searchTerm: filter.searchTerm,
                    category: filter.category,
                    brand: filter.brand);
          },
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            border: OutlineInputBorder(),
            labelText: 'Supplier',
            isDense: true,
          ),
        );
      },
      loading: () => DropdownButtonFormField<String>(
        value: 'All Suppliers',
        items: const [
          DropdownMenuItem(
              value: 'All Suppliers', child: Text('All Suppliers')),
        ],
        onChanged: (_) {},
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          border: OutlineInputBorder(),
          hintText: 'Loading...',
        ),
      ),
      error: (_, __) => DropdownButtonFormField<String>(
        value: 'All Suppliers',
        items: const [
          DropdownMenuItem(
              value: 'All Suppliers', child: Text('All Suppliers')),
        ],
        onChanged: (_) {},
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        final categoryList = [
          'All Categories',
          ...categories.map((c) => c['name'] as String)
        ];
        return DropdownButtonFormField<String>(
          value: _selectedCategory,
          items: categoryList
              .map((category) =>
                  DropdownMenuItem(value: category, child: Text(category)))
              .toList(),
          onChanged: (value) {
            setState(() => _selectedCategory = value);
            final filter = ref.read(orderSuggestionFilterProvider);
            ref.read(orderSuggestionFilterProvider.notifier).state =
                OrderSuggestionFilter(
                    searchTerm: filter.searchTerm,
                    category: value,
                    brand: filter.brand);
          },
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            border: OutlineInputBorder(),
          ),
        );
      },
      loading: () => DropdownButtonFormField<String>(
        value: 'All Categories',
        items: const [
          DropdownMenuItem(
              value: 'All Categories', child: Text('All Categories')),
        ],
        onChanged: (value) {},
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          border: OutlineInputBorder(),
          hintText: 'Loading...',
        ),
      ),
      error: (error, stack) => DropdownButtonFormField<String>(
        value: 'All Categories',
        items: const [
          DropdownMenuItem(
              value: 'All Categories', child: Text('All Categories')),
        ],
        onChanged: (value) {},
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildBrandDropdown() {
    final brandsAsync = ref.watch(brandsProvider);

    return brandsAsync.when(
      data: (brands) {
        final brandList = [
          'All Brands',
          ...brands.map((b) => b['name'] as String)
        ];
        return DropdownButtonFormField<String>(
          value: _selectedBrand,
          items: brandList
              .map(
                  (brand) => DropdownMenuItem(value: brand, child: Text(brand)))
              .toList(),
          onChanged: (value) {
            setState(() => _selectedBrand = value);
            final filter = ref.read(orderSuggestionFilterProvider);
            ref.read(orderSuggestionFilterProvider.notifier).state =
                OrderSuggestionFilter(
                    searchTerm: filter.searchTerm,
                    category: filter.category,
                    brand: value);
          },
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            border: OutlineInputBorder(),
          ),
        );
      },
      loading: () => DropdownButtonFormField<String>(
        value: 'All Brands',
        items: const [
          DropdownMenuItem(value: 'All Brands', child: Text('All Brands')),
        ],
        onChanged: (value) {},
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          border: OutlineInputBorder(),
          hintText: 'Loading...',
        ),
      ),
      error: (error, stack) => DropdownButtonFormField<String>(
        value: 'All Brands',
        items: const [
          DropdownMenuItem(value: 'All Brands', child: Text('All Brands')),
        ],
        onChanged: (value) {},
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildProductList(List<ProductOrderSuggestion> suggestions) {
    if (suggestions.isEmpty) {
      return const Center(child: Text('No products found.'));
    }
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return _buildProductCard(suggestions[index]);
      },
    );
  }

  Widget _buildProductCard(ProductOrderSuggestion product) {
    final bool isLowStock =
        (product.currentStock ?? 0) < (product.minimumThreshold ?? 0);
    final basket = ref.watch(basketProvider);
    final basketItem = basket.firstWhere(
      (item) => item.productId == product.productId,
      orElse: () => const POBasketItem(quantity: 0),
    );
    final quantityInBasket = basketItem.quantity ?? 0;
    final isSelected = _isMultiSelectMode &&
        product.productId != null &&
        _selectedProductIds.contains(product.productId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: isSelected ? 4 : 1,
      color:
          isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      child: InkWell(
        onLongPress: () {
          if (!_isMultiSelectMode && product.productId != null) {
            setState(() {
              _isMultiSelectMode = true;
              _selectedProductIds.add(product.productId!);
            });
          }
        },
        onTap: () {
          if (_isMultiSelectMode && product.productId != null) {
            setState(() {
              if (_selectedProductIds.contains(product.productId!)) {
                _selectedProductIds.remove(product.productId!);
                if (_selectedProductIds.isEmpty) {
                  _isMultiSelectMode = false;
                }
              } else {
                _selectedProductIds.add(product.productId!);
              }
            });
          } else {
            // Quick add with default quantity 1
            _showQuantitySelectorModal(product, defaultQuantity: 1);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              if (_isMultiSelectMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    if (product.productId != null) {
                      setState(() {
                        if (value == true) {
                          _selectedProductIds.add(product.productId!);
                        } else {
                          _selectedProductIds.remove(product.productId!);
                          if (_selectedProductIds.isEmpty) {
                            _isMultiSelectMode = false;
                          }
                        }
                      });
                    }
                  },
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.productName ?? 'No Name',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: [
                        if (product.categoryName != null)
                          Chip(
                              label: Text(product.categoryName!),
                              backgroundColor: Colors.blue.shade100),
                        if (product.brandName != null)
                          Chip(
                              label: Text(product.brandName!),
                              backgroundColor: Colors.purple.shade100),
                        if (product.supplierName != null)
                          Chip(
                              label: Text(product.supplierName!),
                              backgroundColor: Colors.orange.shade100,
                              labelStyle: const TextStyle(fontSize: 11)),
                        if (isLowStock)
                          const Chip(
                              label: Text('LOW STOCK'),
                              backgroundColor: Colors.red,
                              labelStyle: TextStyle(color: Colors.white)),
                        if (product.mrp != null)
                          Chip(
                              label: Text('MRP: ₹${product.mrp}'),
                              backgroundColor: Colors.green.shade100),
                        if (product.currentStock != null)
                          Chip(
                              label: Text('Stock: ${product.currentStock}'),
                              backgroundColor: Colors.grey.shade200),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Order Quantity'),
                        _buildQuantitySelector(product, quantityInBasket),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuantitySelectorModal(
    ProductOrderSuggestion product, {
    int defaultQuantity = 1,
  }) {
    final quantityController = TextEditingController(
      text: defaultQuantity.toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.productName ?? 'Select Quantity',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (product.brandName != null)
                Text(
                  'Brand: ${product.brandName}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (product.supplierName != null)
                Text(
                  'Supplier: ${product.supplierName}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 24),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  suffixText: product.unit ?? 'Piece',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final quantity =
                          int.tryParse(quantityController.text) ?? 0;
                      if (quantity > 0) {
                        Navigator.pop(context);
                        _addProductToBasket(product, quantity);
                      }
                    },
                    child: const Text('Add to Basket'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addProductToBasket(
    ProductOrderSuggestion product,
    int quantity,
  ) async {
    if (product.productId == null) return;

    try {
      final basketItem = POBasketItem(
        id: 'product_${product.productId}',
        productId: product.productId,
        name: product.productName,
        unit: product.unit,
        quantity: quantity,
        price: product.supplierPrice?.toInt() ?? 0,
        type: 'product',
        supplierId: product.supplierId,
        supplierName: product.supplierName,
      );

      final response =
          await ref.read(basketProvider.notifier).addItem(basketItem);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.success
                ? 'Added to basket'
                : response.message ?? 'Failed to add'),
            backgroundColor: response.success ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildQuantitySelector(
      ProductOrderSuggestion product, int quantityInBasket) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle),
          onPressed: quantityInBasket > 0
              ? () async {
                  try {
                    // Minus button should decrement the current basket quantity, not the text field value
                    // This ensures that if user typed a value, it doesn't get decremented
                    final targetQuantity =
                        quantityInBasket > 0 ? quantityInBasket - 1 : 0;

                    // Update the controller to show the new quantity
                    final controller = _quantityControllers[product.productId];
                    if (controller != null) {
                      controller.text = targetQuantity.toString();
                    }

                    // Use the unified update method to handle update/remove
                    await _updateQuantityFromInput(
                        product, targetQuantity.toString());
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating basket: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              : null,
          color: Colors.red,
        ),
        SizedBox(
          width: 80,
          child: TextField(
            controller:
                _getQuantityController(product.productId, quantityInBasket),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              isDense: true,
            ),
            onSubmitted: (value) async {
              await _updateQuantityFromInput(product, value);
            },
            onEditingComplete: () async {
              final controller = _quantityControllers[product.productId];
              if (controller != null) {
                await _updateQuantityFromInput(product, controller.text);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        Text(product.unit ?? 'Piece'),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.add_circle),
          onPressed: () async {
            try {
              // Plus button behavior:
              // - If user has typed a value different from basket, submit that value (don't increment)
              // - If text field matches basket or is empty, increment basket quantity
              final controller = _quantityControllers[product.productId];
              int targetQuantity;

              if (controller != null && controller.text.isNotEmpty) {
                final textValue = int.tryParse(controller.text.trim());
                if (textValue != null && textValue != quantityInBasket) {
                  // User has typed a different value - submit it as-is (don't increment)
                  targetQuantity = textValue;
                } else {
                  // Text field matches basket or is invalid - increment basket quantity
                  targetQuantity = quantityInBasket + 1;
                  // Update controller to show incremented value
                  controller.text = targetQuantity.toString();
                }
              } else {
                // No text field value - increment basket quantity
                targetQuantity = quantityInBasket + 1;
                // Update controller to show incremented value
                if (controller != null) {
                  controller.text = targetQuantity.toString();
                }
              }

              // Use the unified update method to handle add/update
              await _updateQuantityFromInput(
                  product, targetQuantity.toString());
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
              print('Error adding to basket: $e');
            }
          },
          color: Colors.blue,
        ),
      ],
    );
  }

  /// Get or create a TextEditingController for a product's quantity field
  TextEditingController _getQuantityController(
      int? productId, int currentQuantity) {
    if (productId == null) {
      // Return a dummy controller if productId is null
      return TextEditingController(text: currentQuantity.toString());
    }

    if (!_quantityControllers.containsKey(productId)) {
      _quantityControllers[productId] =
          TextEditingController(text: currentQuantity.toString());
    } else {
      // Only update the controller's text if:
      // 1. We're not currently updating this quantity (user input in progress)
      // 2. The basket quantity actually differs from what's in the controller
      final controller = _quantityControllers[productId]!;
      final isUpdating = _isUpdatingQuantity[productId] ?? false;
      final controllerValue = int.tryParse(controller.text) ?? 0;

      // Only sync if not updating and values differ
      if (!isUpdating && controllerValue != currentQuantity) {
        controller.text = currentQuantity.toString();
      }
    }
    return _quantityControllers[productId]!;
  }

  /// Update quantity from text field input
  Future<void> _updateQuantityFromInput(
      ProductOrderSuggestion product, String value) async {
    if (product.productId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid product'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Mark that we're updating this quantity
    _isUpdatingQuantity[product.productId!] = true;

    // Parse the input value
    final newQuantity = int.tryParse(value.trim());

    if (newQuantity == null || newQuantity < 0) {
      // Invalid input - reset to current quantity
      final controller = _quantityControllers[product.productId];
      if (controller != null) {
        final basket = ref.read(basketProvider);
        final basketItem = basket.firstWhere(
          (item) => item.productId == product.productId,
          orElse: () => const POBasketItem(quantity: 0),
        );
        controller.text = (basketItem.quantity ?? 0).toString();
      }

      // Clear the updating flag for invalid input
      _isUpdatingQuantity[product.productId!] = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid quantity (0 or greater)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final basketNotifier = ref.read(basketProvider.notifier);
      final basket = ref.read(basketProvider);
      final basketItem = basket.firstWhere(
        (item) => item.productId == product.productId,
        orElse: () => const POBasketItem(quantity: 0),
      );

      if (newQuantity == 0) {
        // Remove item if quantity is 0
        if (basketItem.id != null) {
          await basketNotifier.removeItem(basketItem.id!);
        }
      } else if (basketItem.id == null) {
        // Add new item to basket
        final newBasketItem = POBasketItem(
          id: 'product_${product.productId}',
          productId: product.productId,
          name: product.productName,
          unit: product.unit,
          quantity: newQuantity,
          price: product.supplierPrice?.toInt() ?? 0,
          type: 'product',
          supplierId: product.supplierId,
          supplierName: product.supplierName,
        );

        final response = await basketNotifier.addItem(newBasketItem);
        if (!response.success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Failed to add item to basket'),
              backgroundColor: Colors.orange,
            ),
          );
          // Reset controller to current quantity
          final controller = _quantityControllers[product.productId];
          if (controller != null) {
            controller.text = '0';
          }
        } else {
          // Success - keep the controller value as user entered
          final controller = _quantityControllers[product.productId];
          if (controller != null) {
            controller.text = newQuantity.toString();
          }
        }
      } else {
        // Update existing item
        final response = await basketNotifier.updateItem(
          basketItem.copyWith(quantity: newQuantity),
        );
        if (!response.success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(response.message ?? 'Failed to update item in basket'),
              backgroundColor: Colors.orange,
            ),
          );
          // Reset controller to previous quantity
          final controller = _quantityControllers[product.productId];
          if (controller != null) {
            controller.text = (basketItem.quantity ?? 0).toString();
          }
        } else {
          // Success - keep the controller value as user entered
          final controller = _quantityControllers[product.productId];
          if (controller != null) {
            controller.text = newQuantity.toString();
          }
        }
      }

      // Clear the updating flag after a short delay to allow basket refresh
      Future.delayed(const Duration(milliseconds: 500), () {
        _isUpdatingQuantity[product.productId!] = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating quantity: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      print('Error updating quantity from input: $e');

      // Reset controller to current quantity on error
      final controller = _quantityControllers[product.productId];
      if (controller != null) {
        final basket = ref.read(basketProvider);
        final basketItem = basket.firstWhere(
          (item) => item.productId == product.productId,
          orElse: () => const POBasketItem(quantity: 0),
        );
        controller.text = (basketItem.quantity ?? 0).toString();
      }

      // Clear the updating flag on error
      _isUpdatingQuantity[product.productId!] = false;
    }
  }
}
