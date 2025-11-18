import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../models/product_order_suggestion.dart';
import '../../providers/order_suggestions_provider.dart';
import '../../models/po_basket_item.dart';
import '../../services/api_service.dart';

class OrderSuggestionsScreen extends ConsumerStatefulWidget {
  const OrderSuggestionsScreen({super.key});

  @override
  ConsumerState<OrderSuggestionsScreen> createState() =>
      _OrderSuggestionsScreenState();
}

class _OrderSuggestionsScreenState
    extends ConsumerState<OrderSuggestionsScreen> {
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

  // Responsive sizing helpers
  double get _screenWidth => MediaQuery.of(context).size.width;
  bool get _isSmallScreen => _screenWidth < 600;
  bool get _isMediumScreen => _screenWidth >= 600 && _screenWidth < 900;

  // Responsive font sizes
  double get _titleFontSize => _isSmallScreen
      ? 16.0
      : _isMediumScreen
          ? 18.0
          : 20.0;
  double get _bodyFontSize => _isSmallScreen
      ? 12.0
      : _isMediumScreen
          ? 14.0
          : 16.0;
  double get _labelFontSize => _isSmallScreen
      ? 10.0
      : _isMediumScreen
          ? 12.0
          : 14.0;

  // Responsive spacing
  double get _smallSpacing => _isSmallScreen
      ? 4.0
      : _isMediumScreen
          ? 6.0
          : 8.0;
  double get _mediumSpacing => _isSmallScreen
      ? 8.0
      : _isMediumScreen
          ? 12.0
          : 16.0;

  // Responsive padding
  EdgeInsets get _screenPadding => EdgeInsets.symmetric(
        horizontal: _isSmallScreen
            ? 8.0
            : _isMediumScreen
                ? 12.0
                : 16.0,
        vertical: _isSmallScreen
            ? 4.0
            : _isMediumScreen
                ? 6.0
                : 8.0,
      );

  // Responsive dropdown height
  double get _dropdownHeight => _isSmallScreen
      ? 40.0
      : _isMediumScreen
          ? 45.0
          : 50.0;

  @override
  void initState() {
    super.initState();
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
        title: Text(
          'Purchase Order Manager',
          style: TextStyle(fontSize: _isSmallScreen ? 16.0 : 18.0),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            size: _isSmallScreen ? 20.0 : 24.0,
          ),
          onPressed: () {
            context.go('/');
          },
          tooltip: 'Back to Home',
        ),
        actions: [
          // Display basket count badge - clickable to navigate to basket
          Padding(
            padding: EdgeInsets.only(
              right: _isSmallScreen ? 8.0 : 16.0,
            ),
            child: InkWell(
              onTap: () {
                context.go('/order-suggestions/basket');
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: _isSmallScreen ? 4.0 : 8.0,
                  vertical: _isSmallScreen ? 2.0 : 4.0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_basket,
                      color: Colors.white,
                      size: _isSmallScreen ? 18.0 : 24.0,
                    ),
                    SizedBox(width: _isSmallScreen ? 4.0 : 8.0),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _isSmallScreen ? 6.0 : 8.0,
                        vertical: _isSmallScreen ? 2.0 : 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: basketCount > 0 ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$basketCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: _isSmallScreen ? 12.0 : 14.0,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomItemDialog(),
        icon: Icon(Icons.add, size: _isSmallScreen ? 18.0 : 24.0),
        label: Text(
          'Add Custom Item',
          style: TextStyle(fontSize: _bodyFontSize),
        ),
      ),
      bottomNavigationBar:
          _isMultiSelectMode ? _buildMultiSelectActionBar() : null,
    );
  }

  Widget _buildMultiSelectActionBar() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _isSmallScreen ? 12.0 : 16.0,
        vertical: _isSmallScreen ? 6.0 : 8.0,
      ),
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
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: _bodyFontSize,
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
                  icon: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: _isSmallScreen ? 18.0 : 24.0,
                  ),
                  label: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _bodyFontSize,
                    ),
                  ),
                ),
                SizedBox(width: _smallSpacing),
                ElevatedButton.icon(
                  onPressed: _selectedProductIds.isEmpty
                      ? null
                      : () => _addSelectedToBasket(),
                  icon: Icon(
                    Icons.add_shopping_cart,
                    size: _isSmallScreen ? 18.0 : 24.0,
                  ),
                  label: Text(
                    'Add to Basket',
                    style: TextStyle(fontSize: _bodyFontSize),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).primaryColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: _isSmallScreen ? 8.0 : 12.0,
                      vertical: _isSmallScreen ? 6.0 : 8.0,
                    ),
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

  Widget _buildFilterControls() {
    return Padding(
      padding: _screenPadding,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: TextStyle(fontSize: _bodyFontSize),
            decoration: InputDecoration(
              hintText: 'Search products...',
              hintStyle: TextStyle(fontSize: _bodyFontSize),
              prefixIcon:
                  Icon(Icons.search, size: _isSmallScreen ? 20.0 : 24.0),
              contentPadding: EdgeInsets.symmetric(
                horizontal: _mediumSpacing,
                vertical: _isSmallScreen ? 10.0 : 12.0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          SizedBox(height: _smallSpacing),
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
                SizedBox(width: _smallSpacing),
                _buildFilterChip(
                  label: 'Clear Filters',
                  selected: false,
                  onSelected: (_) => _clearAllFilters(),
                ),
                SizedBox(width: _smallSpacing),
                // Refresh button
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    size: _isSmallScreen ? 20.0 : 24.0,
                  ),
                  tooltip: 'Refresh',
                  onPressed: () => _refreshOrderSuggestions(),
                  padding: EdgeInsets.all(_isSmallScreen ? 4.0 : 8.0),
                  constraints: BoxConstraints(
                    minWidth: _isSmallScreen ? 32.0 : 40.0,
                    minHeight: _isSmallScreen ? 32.0 : 40.0,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: _smallSpacing),
          // Responsive dropdown layout
          _isSmallScreen
              ? Column(
                  children: [
                    SizedBox(
                        height: _dropdownHeight,
                        child: _buildCategoryDropdown()),
                    SizedBox(height: _smallSpacing),
                    SizedBox(
                        height: _dropdownHeight, child: _buildBrandDropdown()),
                    SizedBox(height: _smallSpacing),
                    SizedBox(
                        height: _dropdownHeight,
                        child: _buildSupplierDropdown()),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: SizedBox(
                            height: _dropdownHeight,
                            child: _buildCategoryDropdown())),
                    SizedBox(width: _smallSpacing),
                    Expanded(
                        flex: 3,
                        child: SizedBox(
                            height: _dropdownHeight,
                            child: _buildBrandDropdown())),
                    SizedBox(width: _smallSpacing),
                    Expanded(
                        flex: 3,
                        child: SizedBox(
                            height: _dropdownHeight,
                            child: _buildSupplierDropdown())),
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
      label: Text(
        label,
        style: TextStyle(fontSize: _labelFontSize),
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
      padding: EdgeInsets.symmetric(
        horizontal: _smallSpacing,
        vertical: _isSmallScreen ? 4.0 : 6.0,
      ),
      labelPadding: EdgeInsets.symmetric(
        horizontal: _smallSpacing,
      ),
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

  Future<void> _refreshOrderSuggestions() async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Refreshing items...'),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Call the refresh method from the provider
      await ref.read(orderSuggestionsProvider.notifier).loadOrderSuggestions();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Items refreshed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing items: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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

        return DropdownSearch<String>(
          selectedItem: _selectedSupplier ?? 'All Suppliers',
          items: supplierList,
          onChanged: (value) {
            setState(() => _selectedSupplier = value);
            final filter = ref.read(orderSuggestionFilterProvider);
            ref.read(orderSuggestionFilterProvider.notifier).state =
                OrderSuggestionFilter(
                    searchTerm: filter.searchTerm,
                    category: filter.category,
                    brand: filter.brand);
          },
          popupProps: PopupProps.menu(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Search supplier...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            itemBuilder: (context, item, isSelected) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 7.2, // Increased by 20% from 6px to 7.2px
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: _bodyFontSize *
                        0.9, // Increased by 20% from 0.75 to 0.9
                  ),
                ),
              );
            },
          ),
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: _smallSpacing,
                vertical: _isSmallScreen ? 8.0 : 10.0,
              ),
              border: const OutlineInputBorder(),
              labelText: 'Supplier',
              labelStyle: TextStyle(fontSize: _labelFontSize),
              isDense: true,
            ),
          ),
        );
      },
      loading: () => DropdownSearch<String>(
        selectedItem: 'All Suppliers',
        items: const ['All Suppliers'],
        enabled: false,
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            border: OutlineInputBorder(),
            hintText: 'Loading...',
          ),
        ),
      ),
      error: (_, __) => DropdownSearch<String>(
        selectedItem: 'All Suppliers',
        items: const ['All Suppliers'],
        enabled: false,
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            border: OutlineInputBorder(),
          ),
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
        return DropdownSearch<String>(
          selectedItem: _selectedCategory,
          items: categoryList,
          onChanged: (value) {
            setState(() => _selectedCategory = value);
            final filter = ref.read(orderSuggestionFilterProvider);
            ref.read(orderSuggestionFilterProvider.notifier).state =
                OrderSuggestionFilter(
                    searchTerm: filter.searchTerm,
                    category: value,
                    brand: filter.brand);
          },
          popupProps: PopupProps.menu(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Search category...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            itemBuilder: (context, item, isSelected) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 7.2, // Increased by 20% from 6px to 7.2px
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: _bodyFontSize *
                        0.9, // Increased by 20% from 0.75 to 0.9
                  ),
                ),
              );
            },
          ),
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: _smallSpacing,
                vertical: _isSmallScreen ? 8.0 : 10.0,
              ),
              border: const OutlineInputBorder(),
              labelText: 'Category',
              labelStyle: TextStyle(fontSize: _labelFontSize),
              isDense: true,
            ),
          ),
        );
      },
      loading: () => DropdownSearch<String>(
        selectedItem: 'All Categories',
        items: const ['All Categories'],
        enabled: false,
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            border: OutlineInputBorder(),
            hintText: 'Loading...',
          ),
        ),
      ),
      error: (error, stack) => DropdownSearch<String>(
        selectedItem: 'All Categories',
        items: const ['All Categories'],
        enabled: false,
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            border: OutlineInputBorder(),
          ),
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
        return DropdownSearch<String>(
          selectedItem: _selectedBrand,
          items: brandList,
          onChanged: (value) {
            setState(() => _selectedBrand = value);
            final filter = ref.read(orderSuggestionFilterProvider);
            ref.read(orderSuggestionFilterProvider.notifier).state =
                OrderSuggestionFilter(
                    searchTerm: filter.searchTerm,
                    category: filter.category,
                    brand: value);
          },
          popupProps: PopupProps.menu(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Search brand...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            itemBuilder: (context, item, isSelected) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 7.2, // Increased by 20% from 6px to 7.2px
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: _bodyFontSize *
                        0.9, // Increased by 20% from 0.75 to 0.9
                  ),
                ),
              );
            },
          ),
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: _smallSpacing,
                vertical: _isSmallScreen ? 8.0 : 10.0,
              ),
              border: const OutlineInputBorder(),
              labelText: 'Brand',
              labelStyle: TextStyle(fontSize: _labelFontSize),
              isDense: true,
            ),
          ),
        );
      },
      loading: () => DropdownSearch<String>(
        selectedItem: 'All Brands',
        items: const ['All Brands'],
        enabled: false,
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            border: OutlineInputBorder(),
            hintText: 'Loading...',
          ),
        ),
      ),
      error: (error, stack) => DropdownSearch<String>(
        selectedItem: 'All Brands',
        items: const ['All Brands'],
        enabled: false,
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            border: OutlineInputBorder(),
          ),
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
      margin: EdgeInsets.symmetric(
        horizontal: _smallSpacing,
        vertical: _isSmallScreen ? 3.0 : 4.0,
      ),
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
          padding: EdgeInsets.all(_isSmallScreen ? 8.0 : _mediumSpacing),
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
                    Text(
                      product.productName ?? 'No Name',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: _titleFontSize,
                          ),
                    ),
                    SizedBox(height: _smallSpacing),
                    Wrap(
                      spacing: _isSmallScreen ? 4.0 : 8.0,
                      runSpacing: _isSmallScreen ? 2.0 : 4.0,
                      children: [
                        if (product.categoryName != null)
                          Chip(
                            label: Text(
                              product.categoryName!,
                              style: TextStyle(fontSize: _labelFontSize),
                            ),
                            backgroundColor: Colors.blue.shade100,
                            padding: EdgeInsets.symmetric(
                              horizontal: _smallSpacing,
                            ),
                          ),
                        if (product.brandName != null)
                          Chip(
                            label: Text(
                              product.brandName!,
                              style: TextStyle(fontSize: _labelFontSize),
                            ),
                            backgroundColor: Colors.purple.shade100,
                            padding: EdgeInsets.symmetric(
                              horizontal: _smallSpacing,
                            ),
                          ),
                        if (product.supplierName != null)
                          Chip(
                            label: Text(
                              product.supplierName!,
                              style: TextStyle(fontSize: _labelFontSize),
                            ),
                            backgroundColor: Colors.orange.shade100,
                            padding: EdgeInsets.symmetric(
                              horizontal: _smallSpacing,
                            ),
                          ),
                        if (isLowStock)
                          Chip(
                            label: Text(
                              'LOW STOCK',
                              style: TextStyle(
                                fontSize: _labelFontSize,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(
                              horizontal: _smallSpacing,
                            ),
                          ),
                        if (product.mrp != null)
                          Chip(
                            label: Text(
                              'MRP: ₹${product.mrp}',
                              style: TextStyle(fontSize: _labelFontSize),
                            ),
                            backgroundColor: Colors.green.shade100,
                            padding: EdgeInsets.symmetric(
                              horizontal: _smallSpacing,
                            ),
                          ),
                        if (product.currentStock != null)
                          Chip(
                            label: Text(
                              'Stock: ${product.currentStock}',
                              style: TextStyle(fontSize: _labelFontSize),
                            ),
                            backgroundColor: Colors.grey.shade200,
                            padding: EdgeInsets.symmetric(
                              horizontal: _smallSpacing,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: _smallSpacing),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order Quantity',
                          style: TextStyle(fontSize: _bodyFontSize),
                        ),
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
          padding: EdgeInsets.all(_isSmallScreen ? 16.0 : 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.productName ?? 'Select Quantity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: _titleFontSize,
                    ),
              ),
              SizedBox(height: _smallSpacing),
              if (product.brandName != null)
                Text(
                  'Brand: ${product.brandName}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: _bodyFontSize,
                      ),
                ),
              if (product.supplierName != null)
                Text(
                  'Supplier: ${product.supplierName}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: _bodyFontSize,
                      ),
                ),
              SizedBox(height: _mediumSpacing),
              TextField(
                controller: quantityController,
                style: TextStyle(fontSize: _bodyFontSize),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  labelStyle: TextStyle(fontSize: _labelFontSize),
                  suffixText: product.unit ?? 'Piece',
                  suffixStyle: TextStyle(fontSize: _bodyFontSize),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: _mediumSpacing,
                    vertical: _isSmallScreen ? 10.0 : 12.0,
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              SizedBox(height: _mediumSpacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(fontSize: _bodyFontSize),
                    ),
                  ),
                  SizedBox(width: _smallSpacing),
                  ElevatedButton(
                    onPressed: () {
                      final quantity =
                          int.tryParse(quantityController.text) ?? 0;
                      if (quantity > 0) {
                        Navigator.pop(context);
                        _addProductToBasket(product, quantity);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: _mediumSpacing,
                        vertical: _isSmallScreen ? 10.0 : 12.0,
                      ),
                    ),
                    child: Text(
                      'Add to Basket',
                      style: TextStyle(fontSize: _bodyFontSize),
                    ),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.remove_circle,
            size: _isSmallScreen ? 20.0 : 24.0,
          ),
          padding: EdgeInsets.all(_isSmallScreen ? 4.0 : 8.0),
          constraints: BoxConstraints(
            minWidth: _isSmallScreen ? 32.0 : 40.0,
            minHeight: _isSmallScreen ? 32.0 : 40.0,
          ),
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
          width: _isSmallScreen ? 60.0 : 80.0,
          child: TextField(
            controller:
                _getQuantityController(product.productId, quantityInBasket),
            style: TextStyle(fontSize: _bodyFontSize),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: _isSmallScreen ? 4.0 : 8.0,
                vertical: _isSmallScreen ? 6.0 : 8.0,
              ),
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
        SizedBox(width: _isSmallScreen ? 4.0 : 8.0),
        Text(
          product.unit ?? 'Piece',
          style: TextStyle(fontSize: _bodyFontSize),
        ),
        SizedBox(width: _isSmallScreen ? 4.0 : 8.0),
        IconButton(
          icon: Icon(
            Icons.add_circle,
            size: _isSmallScreen ? 20.0 : 24.0,
          ),
          padding: EdgeInsets.all(_isSmallScreen ? 4.0 : 8.0),
          constraints: BoxConstraints(
            minWidth: _isSmallScreen ? 32.0 : 40.0,
            minHeight: _isSmallScreen ? 32.0 : 40.0,
          ),
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

  Future<void> _showAddCustomItemDialog() async {
    List<Map<String, dynamic>> brandsList = [];

    // Get all brands from API
    try {
      final apiService = ref.read(apiServiceProvider);
      brandsList = await apiService.getBrands();
    } catch (e) {
      print('Error fetching brands: $e');
      // Fallback to brands from suggestions if API fails
      final suggestionsAsync = ref.read(orderSuggestionsProvider);
      final suggestions = suggestionsAsync.value ?? [];
      final brandsFromSuggestions = suggestions
          .where((s) => s.brandName != null)
          .map((s) => s.brandName!)
          .toSet()
          .toList()
        ..sort();
      brandsList = brandsFromSuggestions.map((name) => {'name': name}).toList();
    }

    final brands = brandsList.where((b) => b['name'] != null).toList()
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => _AddCustomItemDialog(
        brands: brands,
      ),
    );

    // Process result after dialog is closed
    if (result != null) {
      final productName = result['productName'] as String?;
      final quantity = result['quantity'] as int?;
      final brand = result['brand'] as Map<String, dynamic>?;

      if (productName != null && quantity != null) {
        _addCustomItemToBasket(
          productName: productName,
          brand: brand,
          quantity: quantity,
        );
      }
    }
  }

  Future<void> _addCustomItemToBasket({
    required String productName,
    Map<String, dynamic>? brand,
    required int quantity,
  }) async {
    try {
      final basketNotifier = ref.read(basketProvider.notifier);
      final apiService = ref.read(apiServiceProvider);

      // If brand is selected, get all suppliers for that brand
      List<Map<String, dynamic>> suppliers = [];
      if (brand != null && brand['id'] != null) {
        try {
          final brandId = (brand['id'] as num?)?.toInt();
          if (brandId != null) {
            suppliers = await apiService.getSuppliers(brandId: brandId);
          }
        } catch (e) {
          print('Error fetching suppliers for brand: $e');
        }
      }

      // If no suppliers found for the brand (or no brand selected), add as single item without supplier
      if (suppliers.isEmpty) {
        final customItem = POBasketItem(
          type: 'custom',
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: productName,
          unit: 'Piece',
          quantity: quantity,
          price: 0, // Custom items don't have a price initially
          supplierId: null,
          supplierName: null,
        );

        await basketNotifier.addItem(customItem);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$productName added to basket'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Add one item per supplier (so it appears in all supplier groups)
        int addedCount = 0;
        for (var supplier in suppliers) {
          final supplierId = (supplier['id'] as num?)?.toInt();
          final supplierName = supplier['name'] as String?;

          final customItem = POBasketItem(
            type: 'custom',
            id: '${DateTime.now().millisecondsSinceEpoch}_${supplierId ?? addedCount}',
            name: productName,
            unit: 'Piece',
            quantity: quantity,
            price: 0, // Custom items don't have a price initially
            supplierId: supplierId,
            supplierName: supplierName,
          );

          await basketNotifier.addItem(customItem);
          addedCount++;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                addedCount > 1
                    ? '$productName added to basket for $addedCount suppliers'
                    : '$productName added to basket',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding custom item: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _removeCustomItem(POBasketItem item) async {
    try {
      if (item.id != null) {
        final basketNotifier = ref.read(basketProvider.notifier);
        await basketNotifier.removeItem(item.id!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name ?? 'Item'} removed from basket'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing item: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class _AddCustomItemDialog extends StatefulWidget {
  final List<Map<String, dynamic>> brands;

  const _AddCustomItemDialog({
    required this.brands,
  });

  @override
  State<_AddCustomItemDialog> createState() => _AddCustomItemDialogState();
}

class _AddCustomItemDialogState extends State<_AddCustomItemDialog> {
  late final TextEditingController _productNameController;
  late final TextEditingController _quantityController;
  Map<String, dynamic>? _selectedBrand;

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController();
    _quantityController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Custom Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _productNameController,
              decoration: const InputDecoration(
                labelText: 'Product Name *',
                hintText: 'Enter product name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Map<String, dynamic>>(
              decoration: const InputDecoration(
                labelText: 'Brand (Optional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<Map<String, dynamic>>(
                  value: null,
                  child: Text('None'),
                ),
                ...widget.brands
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
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity *',
                hintText: 'Enter quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
          onPressed: () {
            final productName = _productNameController.text.trim();
            final quantityStr = _quantityController.text.trim();
            final quantity = int.tryParse(quantityStr);

            if (productName.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Product name is required'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            if (quantity == null || quantity <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a valid quantity'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            // Return result with all values
            Navigator.pop(context, {
              'productName': productName,
              'quantity': quantity,
              'brand': _selectedBrand,
            });
          },
          child: const Text('Add to Basket'),
        ),
      ],
    );
  }
}
