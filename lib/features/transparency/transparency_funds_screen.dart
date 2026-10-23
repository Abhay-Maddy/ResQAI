import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';
import '../ngo/ngo_management_screen.dart';

class TransparencyFundsScreen extends ConsumerStatefulWidget {
  const TransparencyFundsScreen({super.key});

  @override
  ConsumerState<TransparencyFundsScreen> createState() => _TransparencyFundsScreenState();
}

class _TransparencyFundsScreenState extends ConsumerState<TransparencyFundsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(ngoTransactionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    final filtered = transactions.where((t) {
      return t.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.entityName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.invoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.transactionRef.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return AppShell(
      currentRoute: AppRoutes.transparencyFunds,
      title: 'Audited Financial Ledger',
      breadcrumbs: const ['Public', 'Transparency', 'Funds & Ledger'],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header info
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search ledger by vendor, invoice #, bank ref, or category...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Transactions Table / Card list
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (context, index) => Divider(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final tx = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.receipt, color: AppColors.primaryBlue, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    tx.category,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDark ? Colors.white : AppColors.deepNavy,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.successGreen.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      tx.approvalStatus,
                                      style: const TextStyle(color: AppColors.successGreen, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Vendor: ${tx.entityName} • Bank Ref: ${tx.transactionRef}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              Text('Verified Tax Invoice: ${tx.invoiceNumber} (${tx.invoiceDocumentProof})', style: const TextStyle(fontSize: 11, color: AppColors.primaryBlue)),
                              Text('Timestamp: ${tx.timestamp.toLocal().toString().substring(0, 16)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Text(
                          '₹${tx.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
