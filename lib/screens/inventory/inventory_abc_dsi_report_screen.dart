import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/inventory_abc_dsi_models.dart';
import '../../providers/order_suggestions_provider.dart';

class InventoryAbcDsiReportScreen extends ConsumerStatefulWidget {
  const InventoryAbcDsiReportScreen({super.key});

  @override
  ConsumerState<InventoryAbcDsiReportScreen> createState() =>
      _InventoryAbcDsiReportScreenState();
}

class _InventoryAbcDsiReportScreenState
    extends ConsumerState<InventoryAbcDsiReportScreen> {
  int _windowDays = 90;
  final int _weeklySnapshots = 13;

  final Map<int, bool> _dustTest = {};
  final Map<int, bool> _hangerOrBoxGap = {};
  final Map<int, bool> _oldTagDetected = {};
  final Map<int, TextEditingController> _shelfQtyControllers = {};
  final Map<int, TextEditingController> _remarksControllers = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(inventoryAbcDsiReportProvider.notifier).loadReport(
            windowDays: _windowDays,
            weeklySnapshotCount: _weeklySnapshots,
          );
    });
  }

  @override
  void dispose() {
    for (final controller in _shelfQtyControllers.values) {
      controller.dispose();
    }
    for (final controller in _remarksControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(inventoryAbcDsiReportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ABC + DSI Report'),
        actions: [
          PopupMenuButton<int>(
            initialValue: _windowDays,
            onSelected: (days) {
              setState(() => _windowDays = days);
              _reload();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 90, child: Text('Last 90 days')),
              PopupMenuItem(value: 120, child: Text('Last 120 days')),
              PopupMenuItem(value: 180, child: Text('Last 180 days')),
            ],
          ),
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: reportAsync.when(
        data: (report) => _buildBody(context, report),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Failed to load report: $error'),
          ),
        ),
      ),
    );
  }

  Future<void> _reload() {
    return ref.read(inventoryAbcDsiReportProvider.notifier).loadReport(
          windowDays: _windowDays,
          weeklySnapshotCount: _weeklySnapshots,
        );
  }

  Widget _buildBody(BuildContext context, InventoryAbcDsiReport report) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _summaryCard(context, report),
          const SizedBox(height: 12),
          _metricsCard(report),
          const SizedBox(height: 16),
          Text(
            'Category C Audit Focus (${report.categoryCAuditItems.length})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (report.categoryCAuditItems.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No Category C items pending audit by current rules.'),
              ),
            )
          else
            ...report.categoryCAuditItems.map((row) => _auditItemCard(context, row)),
        ],
      ),
    );
  }

  Widget _summaryCard(BuildContext context, InventoryAbcDsiReport report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Classification Snapshot',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('A', report.categoryACount, Colors.green),
                _chip('B', report.categoryBCount, Colors.orange),
                _chip('C', report.categoryCCount, Colors.redAccent),
                _chip('Dead 90+', report.deadStock90PlusCount, Colors.deepOrange),
                _chip('Dead 120+', report.deadStock120PlusCount, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricsCard(InventoryAbcDsiReport report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Financial Metrics', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Revenue (${report.windowDays}d): ₹${report.totalRevenueLast90Days.toStringAsFixed(2)}'),
            Text('COGS (${report.windowDays}d): ₹${report.totalCogsLast90Days.toStringAsFixed(2)}'),
            Text('On-hand value: ₹${report.totalOnHandValue.toStringAsFixed(2)}'),
            Text('Store Avg DSI: ${report.storeAverageDsi.toStringAsFixed(2)} days'),
          ],
        ),
      ),
    );
  }

  Widget _auditItemCard(BuildContext context, InventoryAbcDsiSkuRow row) {
    final productId = row.productId ?? row.hashCode;
    _shelfQtyControllers.putIfAbsent(
      productId,
      () => TextEditingController(text: row.onHandQty.toString()),
    );
    _remarksControllers.putIfAbsent(productId, () => TextEditingController());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(row.productName ?? 'Unnamed SKU'),
        subtitle: Text(
          'On-hand: ${row.onHandQty} ${row.unit ?? ''}  |  Last sold: ${_formatLastSold(row)}',
        ),
        trailing: Wrap(
          spacing: 6,
          children: [
            if (row.deadStock90Plus)
              const Chip(
                label: Text('Dead 90+'),
                visualDensity: VisualDensity.compact,
              ),
            if (row.deadStock120Plus)
              const Chip(
                label: Text('Critical 120+'),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _line('Category', row.category),
          _line('Revenue (${_windowDays}d)', '₹${row.revenueLast90Days.toStringAsFixed(2)}'),
          _line('COGS (${_windowDays}d)', '₹${row.cogsLast90Days.toStringAsFixed(2)}'),
          _line('DSI', '${row.dsi.toStringAsFixed(2)} days'),
          _line('Turnover', row.turnoverRate.toStringAsFixed(2)),
          const SizedBox(height: 12),
          Text(
            'Move it or Lose it Actions',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          ...row.suggestedActions.map((e) => Text('• $e')),
          const Divider(height: 24),
          Text(
            'Dust Test & Visual Audit',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _dustTest[productId] ?? false,
            onChanged: (value) => setState(() => _dustTest[productId] = value ?? false),
            title: const Text('Dust/faded packaging observed'),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _hangerOrBoxGap[productId] ?? false,
            onChanged: (value) =>
                setState(() => _hangerOrBoxGap[productId] = value ?? false),
            title: const Text('Hanger/box pushed to back (low visibility)'),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _oldTagDetected[productId] ?? false,
            onChanged: (value) =>
                setState(() => _oldTagDetected[productId] = value ?? false),
            title: const Text('Old tag month/quarter still visible'),
          ),
          const Divider(height: 24),
          Text(
            'Ghost Inventory Check',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _shelfQtyControllers[productId],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Physical shelf qty',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: row.onHandQty.toString(),
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'System qty',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _remarksControllers[productId],
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Audit remarks',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _chip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$label: $value'),
    );
  }

  String _formatLastSold(InventoryAbcDsiSkuRow row) {
    if (row.lastSoldDate == null) return 'Never sold';
    final formatted = DateFormat('dd MMM yyyy').format(row.lastSoldDate!);
    final age = row.daysSinceLastSold != null ? ' (${row.daysSinceLastSold}d)' : '';
    return '$formatted$age';
  }
}
