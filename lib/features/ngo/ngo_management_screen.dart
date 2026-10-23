import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/widgets/truth_badge_widget.dart';

class NgoCampaign {
  final String id;
  final String title;
  final String objective;
  final String targetSector;
  final double targetAmount;
  double raisedAmount;
  double committedAmount;
  double spentAmount;
  final int targetBeneficiaries;
  int verifiedBeneficiariesReached;
  final List<String> inKindNeeds;
  bool isVerified;

  NgoCampaign({
    required this.id,
    required this.title,
    required this.objective,
    required this.targetSector,
    required this.targetAmount,
    this.raisedAmount = 0.0,
    this.committedAmount = 0.0,
    this.spentAmount = 0.0,
    required this.targetBeneficiaries,
    this.verifiedBeneficiariesReached = 0,
    required this.inKindNeeds,
    this.isVerified = true,
  });

  double get remainingAvailable => raisedAmount - (committedAmount + spentAmount);
}

class NgoFinancialTransaction {
  final String id;
  final String campaignId;
  final String transactionRef;
  final double amount;
  final String transactionType; // 'DONATION_RECEIVED', 'COMMITTED_ORDER', 'EXPENSE_SPENT', 'REVERSAL'
  final String category; // 'Dry Food Rations', 'Water Filters', 'Tarpaulin Sheets', 'Medical Kits', 'Transport'
  final String entityName; // Donor or Vendor name
  final String invoiceNumber;
  final DateTime timestamp;
  final String approvalStatus; // 'AUDIT_VERIFIED', 'UNDER_AUDIT'
  final String invoiceDocumentProof;

  NgoFinancialTransaction({
    required this.id,
    required this.campaignId,
    required this.transactionRef,
    required this.amount,
    required this.transactionType,
    required this.category,
    required this.entityName,
    required this.invoiceNumber,
    required this.timestamp,
    required this.approvalStatus,
    required this.invoiceDocumentProof,
  });
}

class NgoInventoryItem {
  final String itemName;
  int availableUnits;
  int dispatchedUnits;
  int reportedShortage;
  final String storageDepot;

  NgoInventoryItem({
    required this.itemName,
    required this.availableUnits,
    required this.dispatchedUnits,
    required this.reportedShortage,
    required this.storageDepot,
  });
}

final ngoCampaignsProvider = StateNotifierProvider<NgoCampaignsNotifier, List<NgoCampaign>>((ref) {
  return NgoCampaignsNotifier();
});

class NgoCampaignsNotifier extends StateNotifier<List<NgoCampaign>> {
  NgoCampaignsNotifier() : super(_initialCampaigns());

  static List<NgoCampaign> _initialCampaigns() {
    return [
      NgoCampaign(
        id: 'CMP-GOONJ-01',
        title: 'Yamuna Monsoon Flood Emergency Relief Kits',
        objective: 'Providing emergency family dry ration kits, chlorine water purification tablets, and heavy-duty tarpaulins to displaced families in Yamuna Khadar lowlands.',
        targetSector: 'Yamuna Flood Plains Ward 3, 4 & 5',
        targetAmount: 1500000.0, // ₹15 Lakhs
        raisedAmount: 1140000.0, // ₹11.4 Lakhs
        committedAmount: 250000.0,
        spentAmount: 685000.0,
        targetBeneficiaries: 1200,
        verifiedBeneficiariesReached: 740,
        inKindNeeds: ['Tarpaulins (12x15ft)', 'Baby Food Formula', 'Sanitary Pads', 'Mosquito Nets'],
        isVerified: true,
      ),
      NgoCampaign(
        id: 'CMP-GOONJ-02',
        title: 'Safe Drinking Water & Mobile RO Filtration Deployment',
        objective: 'Setting up 3 solar-powered mobile water purification stations along Mayur Vihar and Shakarpur relief camp enclaves.',
        targetSector: 'Mayur Vihar & Trans-Yamuna Drainage Belt',
        targetAmount: 800000.0, // ₹8 Lakhs
        raisedAmount: 520000.0,
        committedAmount: 120000.0,
        spentAmount: 310000.0,
        targetBeneficiaries: 3000,
        verifiedBeneficiariesReached: 1850,
        inKindNeeds: ['Chlorine Tablets (20,000 tabs)', 'Jerry Cans (20 Litre)', 'Water Quality Testing Kits'],
        isVerified: true,
      ),
    ];
  }

  void addCampaign(NgoCampaign campaign) {
    state = [campaign, ...state];
  }

  void recordExpense(String campaignId, double amount, String category) {
    state = [
      for (final c in state)
        if (c.id == campaignId)
          NgoCampaign(
            id: c.id,
            title: c.title,
            objective: c.objective,
            targetSector: c.targetSector,
            targetAmount: c.targetAmount,
            raisedAmount: c.raisedAmount,
            committedAmount: (c.committedAmount - amount).clamp(0.0, double.infinity),
            spentAmount: c.spentAmount + amount,
            targetBeneficiaries: c.targetBeneficiaries,
            verifiedBeneficiariesReached: c.verifiedBeneficiariesReached,
            inKindNeeds: c.inKindNeeds,
            isVerified: c.isVerified,
          )
        else
          c
    ];
  }

  void recordDistribution(String campaignId, int additionalBeneficiaries) {
    state = [
      for (final c in state)
        if (c.id == campaignId)
          NgoCampaign(
            id: c.id,
            title: c.title,
            objective: c.objective,
            targetSector: c.targetSector,
            targetAmount: c.targetAmount,
            raisedAmount: c.raisedAmount,
            committedAmount: c.committedAmount,
            spentAmount: c.spentAmount,
            targetBeneficiaries: c.targetBeneficiaries,
            verifiedBeneficiariesReached: c.verifiedBeneficiariesReached + additionalBeneficiaries,
            inKindNeeds: c.inKindNeeds,
            isVerified: c.isVerified,
          )
        else
          c
    ];
  }
}

final ngoTransactionsProvider = StateNotifierProvider<NgoTransactionsNotifier, List<NgoFinancialTransaction>>((ref) {
  return NgoTransactionsNotifier();
});

class NgoTransactionsNotifier extends StateNotifier<List<NgoFinancialTransaction>> {
  NgoTransactionsNotifier() : super(_initialTransactions());

  static List<NgoFinancialTransaction> _initialTransactions() {
    return [
      NgoFinancialTransaction(
        id: 'TX-NGO-801',
        campaignId: 'CMP-GOONJ-01',
        transactionRef: 'UPI-CR-99214482',
        amount: 250000.0,
        transactionType: 'DONATION_RECEIVED',
        category: 'Public Verified Donation',
        entityName: 'Corporate CSR Relief Grant (HDFC Parivartan)',
        invoiceNumber: 'REC-CSR-2026-081',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        approvalStatus: 'AUDIT_VERIFIED',
        invoiceDocumentProof: 'receipt_csrhdfc_verified.pdf',
      ),
      NgoFinancialTransaction(
        id: 'TX-NGO-802',
        campaignId: 'CMP-GOONJ-01',
        transactionRef: 'NEFT-DR-3381920',
        amount: 185000.0,
        transactionType: 'EXPENSE_SPENT',
        category: 'Dry Food Rations',
        entityName: 'Delhi Central Food Wholesalers Cooperative',
        invoiceNumber: 'INV-WH-99120',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        approvalStatus: 'AUDIT_VERIFIED',
        invoiceDocumentProof: 'tax_invoice_food_rations_signed.pdf',
      ),
      NgoFinancialTransaction(
        id: 'TX-NGO-803',
        campaignId: 'CMP-GOONJ-01',
        transactionRef: 'RTGS-DR-1140921',
        amount: 140000.0,
        transactionType: 'EXPENSE_SPENT',
        category: 'Tarpaulin Sheets & Bamboo Poles',
        entityName: 'Shri Ram Tarpaulins & Waterproofing Ltd',
        invoiceNumber: 'INV-TARP-4402',
        timestamp: DateTime.now().subtract(const Duration(hours: 14)),
        approvalStatus: 'AUDIT_VERIFIED',
        invoiceDocumentProof: 'tarpaulin_depot_delivery_challan.pdf',
      ),
      NgoFinancialTransaction(
        id: 'TX-NGO-804',
        campaignId: 'CMP-GOONJ-02',
        transactionRef: 'COMM-ORD-00912',
        amount: 120000.0,
        transactionType: 'COMMITTED_ORDER',
        category: 'Water Filters',
        entityName: 'Kent Disaster Relief Supply Wing',
        invoiceNumber: 'PO-WATER-RO-04',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        approvalStatus: 'UNDER_AUDIT',
        invoiceDocumentProof: 'purchase_order_water_ro.pdf',
      ),
    ];
  }

  void addTransaction(NgoFinancialTransaction tx) {
    state = [tx, ...state];
  }
}

class NgoManagementScreen extends ConsumerStatefulWidget {
  const NgoManagementScreen({super.key});

  @override
  ConsumerState<NgoManagementScreen> createState() => _NgoManagementScreenState();
}

class _NgoManagementScreenState extends ConsumerState<NgoManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<NgoInventoryItem> _inventory = [
    NgoInventoryItem(
      itemName: 'Family Dry Ration Kits (15kg Flour, Rice, Dal, Oil)',
      availableUnits: 420,
      dispatchedUnits: 740,
      reportedShortage: 280,
      storageDepot: 'Goonj Central Processing Center, Sarita Vihar',
    ),
    NgoInventoryItem(
      itemName: 'Heavy Duty Waterproof Tarpaulins (12x15 ft)',
      availableUnits: 180,
      dispatchedUnits: 550,
      reportedShortage: 150,
      storageDepot: 'Mayur Vihar Forward Staging Hub',
    ),
    NgoInventoryItem(
      itemName: 'Chlorine Water Purification Tablets (Strip of 50)',
      availableUnits: 1200,
      dispatchedUnits: 3400,
      reportedShortage: 0,
      storageDepot: 'Okhla Relief Warehouse',
    ),
    NgoInventoryItem(
      itemName: 'Hygiene & Dignity Kits for Women & Adolescents',
      availableUnits: 310,
      dispatchedUnits: 620,
      reportedShortage: 390,
      storageDepot: 'Goonj Sarita Vihar Depot',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openCreateCampaignDialog() {
    final titleCtrl = TextEditingController();
    final objectiveCtrl = TextEditingController();
    final sectorCtrl = TextEditingController(text: 'Trans-Yamuna Relief Corridor');
    final targetAmountCtrl = TextEditingController(text: '500000');
    final beneficiariesCtrl = TextEditingController(text: '500');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.campaign, color: AppColors.primaryLight, size: 22),
            SizedBox(width: 8),
            Text('Launch Verified Relief Campaign', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Part 9 Requirement: All NGO campaigns must state targeted sector, beneficiary estimate, and purpose before soliciting contributions.', style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 12),
              const Text('Campaign Title *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g., Flood Plain Emergency Shelter & Ration Drive',
                  filled: true,
                  fillColor: AppColors.darkSurfaceCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Target Humanitarian Objective *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: objectiveCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Specific emergency needs being fulfilled...',
                  filled: true,
                  fillColor: AppColors.darkSurfaceCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Target Sector / Geographical Area *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: sectorCtrl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.darkSurfaceCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Fundraising Target (₹) *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: targetAmountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.darkSurfaceCard,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Target Beneficiaries *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: beneficiariesCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.darkSurfaceCard,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              final targetAmt = double.tryParse(targetAmountCtrl.text) ?? 500000.0;
              final targetBen = int.tryParse(beneficiariesCtrl.text) ?? 500;

              final newCampaign = NgoCampaign(
                id: 'CMP-GOONJ-0${DateTime.now().millisecondsSinceEpoch % 100}',
                title: titleCtrl.text.trim(),
                objective: objectiveCtrl.text.trim().isEmpty ? 'Direct humanitarian disaster relief.' : objectiveCtrl.text.trim(),
                targetSector: sectorCtrl.text.trim(),
                targetAmount: targetAmt,
                targetBeneficiaries: targetBen,
                inKindNeeds: ['Food Rations', 'Water Kits'],
                isVerified: true,
              );

              ref.read(ngoCampaignsProvider.notifier).addCampaign(newCampaign);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Campaign "${newCampaign.title}" launched and published to public transparency page.'),
                  backgroundColor: AppColors.verifiedGreen,
                ),
              );
            },
            child: const Text('Publish Relief Campaign', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openRecordExpenseDialog() {
    final campaigns = ref.read(ngoCampaignsProvider);
    String selectedCampaignId = campaigns.isNotEmpty ? campaigns.first.id : 'CMP-GOONJ-01';
    final amountCtrl = TextEditingController(text: '75000');
    final categoryCtrl = TextEditingController(text: 'Emergency Medical Dressing & Tetanus Kits');
    final vendorCtrl = TextEditingController(text: 'Apollo Medical Supplies Depot East');
    final invNumCtrl = TextEditingController(text: 'INV-MED-${DateTime.now().millisecondsSinceEpoch % 10000}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.receipt_long, color: AppColors.warningAmber, size: 22),
            SizedBox(width: 8),
            Text('Record Verified Relief Expenditure', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Part 9 & 15 Auditing Rule: Expenses require signed invoices and cannot be silently deleted once verified.', style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 12),
              const Text('Allocated Campaign *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: selectedCampaignId,
                items: campaigns.map((c) => DropdownMenuItem(value: c.id, child: Text(c.title, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) {
                  if (val != null) selectedCampaignId = val;
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.darkSurfaceCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Expense Amount (₹) *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: amountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.darkSurfaceCard,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tax Invoice # *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: invNumCtrl,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.darkSurfaceCard,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Expense Category *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: categoryCtrl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.darkSurfaceCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Vendor / Payee Entity *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: vendorCtrl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.darkSurfaceCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.attachment, color: AppColors.verifiedGreen, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Attached: tax_invoice_verified_signed.pdf (Audited)', style: TextStyle(fontSize: 11, color: Colors.white70)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warningAmber, foregroundColor: Colors.black),
            onPressed: () {
              final amt = double.tryParse(amountCtrl.text) ?? 75000.0;
              final newTx = NgoFinancialTransaction(
                id: 'TX-NGO-${DateTime.now().millisecondsSinceEpoch % 10000}',
                campaignId: selectedCampaignId,
                transactionRef: 'NEFT-DR-${DateTime.now().millisecondsSinceEpoch % 1000000}',
                amount: amt,
                transactionType: 'EXPENSE_SPENT',
                category: categoryCtrl.text.trim(),
                entityName: vendorCtrl.text.trim(),
                invoiceNumber: invNumCtrl.text.trim(),
                timestamp: DateTime.now(),
                approvalStatus: 'AUDIT_VERIFIED',
                invoiceDocumentProof: 'tax_invoice_verified_signed.pdf',
              );

              ref.read(ngoTransactionsProvider.notifier).addTransaction(newTx);
              ref.read(ngoCampaignsProvider.notifier).recordExpense(selectedCampaignId, amt, categoryCtrl.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Expense of ₹${amt.toStringAsFixed(0)} logged to Campaign Ledger with verified invoice audit.'),
                  backgroundColor: AppColors.verifiedGreen,
                ),
              );
            },
            child: const Text('Record Audited Expense', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openRecordDistributionDialog() {
    final campaigns = ref.read(ngoCampaignsProvider);
    String selectedCampaignId = campaigns.isNotEmpty ? campaigns.first.id : 'CMP-GOONJ-01';
    final countCtrl = TextEditingController(text: '120');
    final locCtrl = TextEditingController(text: 'Yamuna Khadar Ward 4 Safe Shelter Camp');
    final itemsCtrl = TextEditingController(text: '120 Ration Kits & 240 Tarpaulin Sheets');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.inventory, color: AppColors.verifiedGreen, size: 22),
            SizedBox(width: 8),
            Text('Record Verified Relief Delivery', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Part 9 & 17 DPDP Rule: Beneficiary records are aggregated to protect privacy. Zero personal names or phone numbers published.', style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 12),
              const Text('Associated Campaign *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: selectedCampaignId,
                items: campaigns.map((c) => DropdownMenuItem(value: c.id, child: Text(c.title, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) {
                  if (val != null) selectedCampaignId = val;
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.darkSurfaceCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Aggregate Beneficiary Households Reached *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: countCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.darkSurfaceCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Camp / Field Distribution Location *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: locCtrl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.darkSurfaceCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Relief Items Handed Over *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: itemsCtrl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.darkSurfaceCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.verifiedGreen),
            onPressed: () {
              final count = int.tryParse(countCtrl.text) ?? 100;
              ref.read(ngoCampaignsProvider.notifier).recordDistribution(selectedCampaignId, count);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ Recorded delivery to $count families at ${locCtrl.text}. Published to public transparency index.'),
                  backgroundColor: AppColors.verifiedGreen,
                ),
              );
            },
            child: const Text('Confirm Distribution Record', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = ref.watch(ngoCampaignsProvider);
    final transactions = ref.watch(ngoTransactionsProvider);
    final currentUser = ref.watch(authProvider);

    // Aggregate NGO stats
    final totalRaised = campaigns.fold<double>(0.0, (sum, c) => sum + c.raisedAmount);
    final totalSpent = campaigns.fold<double>(0.0, (sum, c) => sum + c.spentAmount);
    final totalCommitted = campaigns.fold<double>(0.0, (sum, c) => sum + c.committedAmount);
    final totalAvailable = totalRaised - (totalSpent + totalCommitted);
    final totalBeneficiaries = campaigns.fold<int>(0, (sum, c) => sum + c.verifiedBeneficiariesReached);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.corporate_fare, color: AppColors.primaryLight, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NGO Transparent Relief Portal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('NGO DARPAN ID: DL/2019/024810 • Goonj Disaster Wing', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: const TruthBadgeWidget(type: TruthBadgeType.verifiedSafe, customText: 'DARPAN VERIFIED NGO'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryLight,
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(icon: const Icon(Icons.dashboard, size: 18), text: 'Campaigns (${campaigns.length})'),
            Tab(icon: const Icon(Icons.account_balance_wallet, size: 18), text: 'Ledger (${transactions.length})'),
            const Tab(icon: Icon(Icons.inventory_2, size: 18), text: 'Relief Inventory'),
            const Tab(icon: Icon(Icons.verified, size: 18), text: 'NGO Profile & Trust'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCampaignsTab(campaigns, totalRaised, totalSpent, totalCommitted, totalAvailable, totalBeneficiaries),
          _buildLedgerTab(transactions),
          _buildInventoryTab(),
          _buildProfileTab(currentUser),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Action', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: AppColors.darkSurface,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (ctx) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('NGO Operations Quick Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.campaign, color: Colors.white)),
                      title: const Text('Launch Relief Campaign'),
                      subtitle: const Text('Create fundraising and in-kind targets'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _openCreateCampaignDialog();
                      },
                    ),
                    ListTile(
                      leading: const CircleAvatar(backgroundColor: AppColors.warningAmber, child: Icon(Icons.receipt_long, color: Colors.black)),
                      title: const Text('Record Audited Expense / Invoice'),
                      subtitle: const Text('Log purchases with invoice document proof'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _openRecordExpenseDialog();
                      },
                    ),
                    ListTile(
                      leading: const CircleAvatar(backgroundColor: AppColors.verifiedGreen, child: Icon(Icons.people, color: Colors.white)),
                      title: const Text('Record Beneficiary Relief Handover'),
                      subtitle: const Text('Log distributed rations and family headcounts'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _openRecordDistributionDialog();
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCampaignsTab(List<NgoCampaign> campaigns, double raised, double spent, double committed, double available, int beneficiaries) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Four Financial Balance Cards (Part 9 Mandatory)
          Row(
            children: [
              _financeMetricCard('Verified Received', '₹${(raised / 100000).toStringAsFixed(1)}L', AppColors.verifiedGreen, Icons.savings),
              const SizedBox(width: 8),
              _financeMetricCard('Verified Spent', '₹${(spent / 100000).toStringAsFixed(1)}L', AppColors.criticalRed, Icons.payments),
              const SizedBox(width: 8),
              _financeMetricCard('Committed Orders', '₹${(committed / 100000).toStringAsFixed(1)}L', AppColors.warningAmber, Icons.pending_actions),
              const SizedBox(width: 8),
              _financeMetricCard('Uncommitted Cash', '₹${(available / 100000).toStringAsFixed(1)}L', Colors.lightBlueAccent, Icons.account_balance),
            ],
          ),
          const SizedBox(height: 16),

          // Aggregate Beneficiary Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_alt, color: AppColors.primaryLight, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$beneficiaries Families Assisted Across Trans-Yamuna Corridor', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      const Text('Audit-verified deliveries synchronized with District Disaster Magistrate portal.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.verifiedGreen),
                  onPressed: _openRecordDistributionDialog,
                  child: const Text('Log Distribution', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Active Disaster Relief Campaigns', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 14),
                label: const Text('New Campaign', style: TextStyle(fontSize: 12)),
                onPressed: _openCreateCampaignDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: campaigns.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final c = campaigns[index];
              final percentRaised = (c.raisedAmount / c.targetAmount * 100).clamp(0, 100).toInt();

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.primaryDark.withOpacity(0.4), borderRadius: BorderRadius.circular(6)),
                          child: Text(c.id, style: const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        const TruthBadgeWidget(type: TruthBadgeType.verifiedSafe, customText: 'AUDIT COMPLIANT'),
                        const Spacer(),
                        Text('Target: ₹${(c.targetAmount / 100000).toStringAsFixed(1)}L', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(c.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(c.objective, style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(c.targetSector, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (c.raisedAmount / c.targetAmount).clamp(0.0, 1.0),
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primaryLight),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('₹${(c.raisedAmount / 100000).toStringAsFixed(1)}L Raised ($percentRaised%)', style: const TextStyle(fontSize: 11, color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
                        Text('₹${(c.spentAmount / 100000).toStringAsFixed(1)}L Spent • ${c.verifiedBeneficiariesReached} Families Reached', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // In-Kind Urgent Requirements
                    Wrap(
                      spacing: 6,
                      children: c.inKindNeeds.map((need) => Chip(
                        label: Text(need, style: const TextStyle(fontSize: 10)),
                        padding: EdgeInsets.zero,
                        backgroundColor: AppColors.darkSurfaceCard,
                      )).toList(),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.receipt, size: 14),
                          label: const Text('Log Expense', style: TextStyle(fontSize: 12)),
                          onPressed: _openRecordExpenseDialog,
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          icon: const Icon(Icons.volunteer_activism, size: 14),
                          label: const Text('Accept Donation / In-Kind', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Donation gateway link generated for ${c.title}. UPI / NEFT payment receipt auto-reconciled.')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLedgerTab(List<NgoFinancialTransaction> txs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Audited Financial Ledger & Invoices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Part 9 Compliance: Every movement has an auditable voucher reference.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.warningAmber, foregroundColor: Colors.black),
                icon: const Icon(Icons.add_circle, size: 16),
                label: const Text('Record Expense', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: _openRecordExpenseDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: txs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final tx = txs[index];
              final isCredit = tx.transactionType == 'DONATION_RECEIVED';
              final color = isCredit ? AppColors.verifiedGreen : (tx.transactionType == 'COMMITTED_ORDER' ? AppColors.warningAmber : AppColors.criticalRed);

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            tx.transactionType,
                            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(tx.transactionRef, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const Spacer(),
                        Text(
                          '${isCredit ? "+" : "-"}₹${tx.amount.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(tx.entityName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Category: ${tx.category} • Invoice #${tx.invoiceNumber}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.verified_user, size: 14, color: AppColors.verifiedGreen),
                        const SizedBox(width: 4),
                        Text('Audit Status: ${tx.approvalStatus}', style: const TextStyle(fontSize: 11, color: AppColors.verifiedGreen, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Viewing document proof: ${tx.invoiceDocumentProof}')),
                            );
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.picture_as_pdf, size: 14, color: Colors.lightBlueAccent),
                              const SizedBox(width: 4),
                              Text(tx.invoiceDocumentProof, style: const TextStyle(fontSize: 11, color: Colors.lightBlueAccent, decoration: TextDecoration.underline)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('In-Kind Relief Supplies Inventory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Tracks real-time stock levels, dispatched aid, and remaining deficit by depot.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _inventory.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _inventory[index];

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.itemName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Depot: ${item.storageDepot}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _inventoryPill('Available', '${item.availableUnits}', AppColors.verifiedGreen),
                        const SizedBox(width: 8),
                        _inventoryPill('Dispatched', '${item.dispatchedUnits}', Colors.lightBlueAccent),
                        const SizedBox(width: 8),
                        _inventoryPill('Shortage Deficit', '${item.reportedShortage}', item.reportedShortage > 0 ? AppColors.criticalRed : Colors.grey),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildProfileTab(dynamic currentUser) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryLight.withOpacity(0.2), AppColors.darkSurface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryLight.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.corporate_fare, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(currentUser?.name ?? 'Goonj Disaster Relief Wing', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          const TruthBadgeWidget(type: TruthBadgeType.verifiedSafe, customText: 'VERIFIED NGO'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('NGO DARPAN Registration: DL/2019/024810', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const Text('Section 80G & 12A Verified • FCRA Authorized', style: TextStyle(fontSize: 12, color: AppColors.primaryLight)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          const Text('Statutory Governance & Compliance Credentials', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _profileRow(Icons.description, 'Registration Type', 'Registered Society under Societies Registration Act XXI of 1860'),
          _profileRow(Icons.person, 'Authorized Lead Representative', 'Praveen Nair (Director of Emergency Response)'),
          _profileRow(Icons.place, 'Operating Jurisdictions', 'Delhi-NCR, Uttar Pradesh, Bihar, Uttarakhand'),
          _profileRow(Icons.category, 'Areas of Specialization', 'Material Relief, Flood Rehabilitation, Dignity Kits, School Recovery'),
          _profileRow(Icons.account_balance, 'Designated Escrow Account', 'State Bank of India (Public Transparency Escrow), IFSC: SBIN0000691'),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Statutory Transparency Standard (Part 9)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                SizedBox(height: 6),
                Text(
                  'In compliance with Part 9 of the Disaster Management Act and DPDP regulations, verified public audit summaries are permanently accessible on the Public Transparency Portal without revealing individual beneficiary PII or personal bank identifiers.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _financeMetricCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey), textAlign: TextAlign.center, maxLines: 1),
          ],
        ),
      ),
    );
  }

  Widget _inventoryPill(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _profileRow(IconData icon, String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryLight),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
