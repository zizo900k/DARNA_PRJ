import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import '../services/transaction_service.dart';
import '../theme/auth_provider.dart';
import '../theme/app_theme.dart';
import '../theme/language_provider.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _sales = [];
  List<dynamic> _rents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final salesData = await TransactionService.getSales();
      final rentsData = await TransactionService.getRents();
      setState(() {
        _sales = salesData;
        _rents = rentsData;
      });
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUser = Provider.of<AuthProvider>(context).user;
    final currentUserId = currentUser?['id'];

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('my_transactions'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final mesAchats = _sales.where((s) => s['buyer_id'] == currentUserId).toList();
    final mesVentes = _sales.where((s) => s['seller_id'] == currentUserId).toList();
    final mesLocations = _rents.where((r) => r['tenant_id'] == currentUserId).toList();
    final biensLoues = _rents.where((r) => r['owner_id'] == currentUserId).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('my_transactions'), style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.iconTheme.color),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: theme.textTheme.bodyMedium?.color,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: context.tr('mes_achats')),
            Tab(text: context.tr('mes_locations')),
            Tab(text: context.tr('mes_ventes')),
            Tab(text: context.tr('biens_loues')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransactionList(mesAchats, isDark, isSale: true, isOwner: false),
          _buildTransactionList(mesLocations, isDark, isSale: false, isOwner: false),
          _buildTransactionList(mesVentes, isDark, isSale: true, isOwner: true),
          _buildTransactionList(biensLoues, isDark, isSale: false, isOwner: true),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<dynamic> items, bool isDark, {required bool isSale, required bool isOwner}) {
    if (items.isEmpty) {
      return Center(child: Text(context.tr('trans_no_found')));
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final property = item['property'] ?? {};
          final photos = property['photos'] as List<dynamic>? ?? [];
          final imageUrl = photos.isNotEmpty ? photos[0]['url']?.toString() : null;

          final status = item['status']?.toString() ?? 'unknown';
          final price = isSale ? item['price'] : item['price_per_month'];

          final buyerOrTenant = isSale ? item['buyer'] : item['tenant'];
          final sellerOrOwner = isSale ? item['seller'] : item['owner'];
          
          final buyerName = buyerOrTenant != null ? (buyerOrTenant['full_name'] ?? buyerOrTenant['name']) : 'Unknown';
          final sellerName = sellerOrOwner != null ? (sellerOrOwner['full_name'] ?? sellerOrOwner['name']) : 'Unknown';

          return Card(
            color: isDark ? DarkColors.backgroundSecondary : LightColors.backgroundSecondary,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Image Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl != null 
                      ? Image.network(
                          imageUrl, 
                          width: 80, 
                          height: 80, 
                          fit: BoxFit.cover, 
                          errorBuilder: (context, error, stackTrace) => Container(width: 80, height: 80, color: Colors.grey.withAlpha(50), child: const Icon(Icons.image_not_supported)),
                        )
                      : Container(
                          width: 80, 
                          height: 80, 
                          color: Colors.grey.withAlpha(50), 
                          child: const Icon(Icons.image_not_supported),
                        ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Details Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                property['title']?.toString() ?? 'Property',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getLocalizedStatus(context, status).toUpperCase(),
                                style: TextStyle(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(context.tr('trans_price'), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(width: 4),
                            Text(
                              '$price ${context.tr('mad')}${!isSale ? " / ${context.tr('month')}" : ""}',
                              textDirection: ui.TextDirection.ltr,
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('${isSale ? context.tr('trans_seller') : context.tr('trans_owner')}: $sellerName', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
                        Text('${isSale ? context.tr('trans_buyer') : context.tr('trans_tenant')}: $buyerName', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
                        
                        if (!isSale) ...[
                          const SizedBox(height: 2),
                          Text('${context.tr('trans_from')} ${_formatDate(item['start_date']?.toString())} ${context.tr('trans_to')} ${_formatDate(item['end_date']?.toString())}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],

                        const SizedBox(height: 8),

                        // Action Buttons  
                        if (isOwner && status == 'pending') ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _updateStatus(item['id'], isSale, isSale ? 'canceled' : 'canceled'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(context.tr('trans_reject'), style: const TextStyle(color: Colors.red, fontSize: 13)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _updateStatus(item['id'], isSale, isSale ? 'completed' : 'active'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(context.tr('trans_accept'), style: const TextStyle(color: Colors.white, fontSize: 13)),
                              ),
                            ],
                          ),
                        ],
                        if (isOwner && !isSale && status == 'active') ...[
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _updateStatus(item['id'], isSale, 'terminated'),
                              style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              child: Text(context.tr('trans_terminate'), style: const TextStyle(color: Colors.red, fontSize: 12)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'active': return Colors.green;
      case 'completed': return Colors.blue;
      case 'terminated': return Colors.red;
      case 'canceled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return 'N/A';
    try {
      final date = DateTime.parse(isoString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }

  Future<void> _updateStatus(int id, bool isSale, String newStatus) async {
    try {
      if (isSale) {
        await TransactionService.updateSaleStatus(id, newStatus);
      } else {
        await TransactionService.updateRentStatus(id, newStatus);
      }
      _loadTransactions();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
  String _getLocalizedStatus(BuildContext context, String status) {
    String key = 'status_${status.toLowerCase()}';
    String translated = context.tr(key);
    return translated == key ? status : translated;
  }
}
