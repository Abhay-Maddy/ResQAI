import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/donation_repository.dart';
import '../../shared/models/donation_model.dart';
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
  final List<String> categories;
  final int durationDays;
  final DateTime createdDate;
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
    this.categories = const ['Emergency Rations', 'Temporary Shelter'],
    this.durationDays = 45,
    DateTime? createdDate,
    this.isVerified = true,
  }) : createdDate = createdDate ?? DateTime.now().subtract(const Duration(days: 7));

  double get remainingAvailable => (raisedAmount - (committedAmount + spentAmount)).clamp(0.0, double.infinity);
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

class NgoDistributionDelivery {
  final String id;
  final String campaignId;
  final String campaignTitle;
  final int householdsReached;
  final String distributionLocation;
  final String reliefItems;
  final DateTime deliveryDate;
  final String responsibleTeam;
  final String evidenceChallan;
  final String verificationStatus; // 'AUDIT_VERIFIED', 'FIELD_CONFIRMED'

  NgoDistributionDelivery({
    required this.id,
    required this.campaignId,
    required this.campaignTitle,
    required this.householdsReached,
    required this.distributionLocation,
    required this.reliefItems,
    required this.deliveryDate,
    required this.responsibleTeam,
    required this.evidenceChallan,
    this.verificationStatus = 'AUDIT_VERIFIED',
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
        categories: ['Dry Food Rations', 'Waterproof Tarpaulins', 'Sanitation Kits'],
        durationDays: 45,
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
        categories: ['Clean Drinking Water', 'Mobile RO Filtration'],
        durationDays: 30,
        isVerified: true,
      ),
    ];
  }

  void addCampaign(NgoCampaign campaign) {
    state = [campaign, ...state];
  }

  void recordDonation(String campaignId, double amount) {
    state = [
      for (final c in state)
        if (c.id == campaignId)
          NgoCampaign(
            id: c.id,
            title: c.title,
            objective: c.objective,
            targetSector: c.targetSector,
            targetAmount: c.targetAmount,
            raisedAmount: c.raisedAmount + amount,
            committedAmount: c.committedAmount,
            spentAmount: c.spentAmount,
            targetBeneficiaries: c.targetBeneficiaries,
            verifiedBeneficiariesReached: c.verifiedBeneficiariesReached,
            inKindNeeds: c.inKindNeeds,
            categories: c.categories,
            durationDays: c.durationDays,
            createdDate: c.createdDate,
            isVerified: c.isVerified,
          )
        else
          c
    ];
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
            categories: c.categories,
            durationDays: c.durationDays,
            createdDate: c.createdDate,
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
            categories: c.categories,
            durationDays: c.durationDays,
            createdDate: c.createdDate,
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

final ngoDeliveriesProvider = StateNotifierProvider<NgoDeliveriesNotifier, List<NgoDistributionDelivery>>((ref) {
  return NgoDeliveriesNotifier();
});

class NgoDeliveriesNotifier extends StateNotifier<List<NgoDistributionDelivery>> {
  NgoDeliveriesNotifier() : super(_initialDeliveries());

  static List<NgoDistributionDelivery> _initialDeliveries() {
    final now = DateTime.now();
    return [
      NgoDistributionDelivery(
        id: 'DEL-2026-101',
        campaignId: 'CMP-GOONJ-01',
        campaignTitle: 'Yamuna Monsoon Flood Emergency Relief Kits',
        householdsReached: 380,
        distributionLocation: 'Yamuna Khadar Ward 4 Safe Embankment Camp',
        reliefItems: '380 Dry Ration Kits & 760 Waterproof Tarpaulins',
        deliveryDate: now.subtract(const Duration(days: 2)),
        responsibleTeam: 'Goonj East Delhi Logistics Team Beta',
        evidenceChallan: 'challan_ward4_signed_patwari.pdf',
        verificationStatus: 'AUDIT_VERIFIED',
      ),
      NgoDistributionDelivery(
        id: 'DEL-2026-102',
        campaignId: 'CMP-GOONJ-01',
        campaignTitle: 'Yamuna Monsoon Flood Emergency Relief Kits',
        householdsReached: 360,
        distributionLocation: 'Mayur Vihar Phase 1 Flood Relief Transit Hub',
        reliefItems: '360 Food Rations, 120 Dignity Kits, 720 Chlorine Strips',
        deliveryDate: now.subtract(const Duration(days: 1)),
        responsibleTeam: 'Goonj Trans-Yamuna Operations Squadron',
        evidenceChallan: 'mayur_vihar_relief_challan_402.pdf',
        verificationStatus: 'AUDIT_VERIFIED',
      ),
      NgoDistributionDelivery(
        id: 'DEL-2026-103',
        campaignId: 'CMP-GOONJ-02',
        campaignTitle: 'Safe Drinking Water & Mobile RO Filtration Deployment',
        householdsReached: 1850,
        distributionLocation: 'Shakarpur & Geeta Colony Lowland Drainage Outpost',
        reliefItems: '3 Solar Mobile RO Water Purification Tanks (15,000L/day)',
        deliveryDate: now.subtract(const Duration(hours: 16)),
        responsibleTeam: 'SafeWater Field Engineering Unit',
        evidenceChallan: 'water_plant_inspection_delhi_jal_board.pdf',
        verificationStatus: 'AUDIT_VERIFIED',
      ),
    ];
  }

  void addDelivery(NgoDistributionDelivery delivery) {
    state = [delivery, ...state];
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
    // 7 Complete Functional Tabs
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // C. NEW CAMPAIGN MODAL (Part 3 C)
  void _openCreateCampaignDialog() {
    final titleCtrl = TextEditingController();
    final objectiveCtrl = TextEditingController();
    final sectorCtrl = TextEditingController(text: 'Trans-Yamuna Relief Corridor');
    final targetAmountCtrl = TextEditingController(text: '500000');
    final beneficiariesCtrl = TextEditingController(text: '500');
    final durationCtrl = TextEditingController(text: '45');
    final selectedCategories = <String>['Emergency Rations', 'Temporary Shelter'];
    final availableCategories = [
      'Emergency Rations',
      'Safe Drinking Water',
      'Temporary Shelter',
      'Medical Triage',
      'Sanitation & Hygiene',
      'Clothing & Blankets',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final screenHeight = MediaQuery.of(ctx).size.height;

          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.campaign, color: AppColors.primaryLight, size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Launch Verified Relief Campaign',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.75,
                maxWidth: 540,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.25)),
                      ),
                      child: const Text(
                        'Statutory Governance Notice: Under National Disaster Management Guidelines, all NGO relief drives require distinct objectives, target sectors, and transparent public budgeting.',
                        style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.3),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('Campaign Title *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g., Flood Plain Emergency Shelter & Ration Drive',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('Humanitarian Relief Objective *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: objectiveCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Describe specific urgent needs being fulfilled for affected population...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('Target Geographical Sector / Ward *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: sectorCtrl,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Target Budget (₹ INR) *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: targetAmountCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  prefixText: '₹ ',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                  suffixText: 'Families',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    const Text('Campaign Duration (Days):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: durationCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        suffixText: 'Days',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('Assistance Categories *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: availableCategories.map((cat) {
                        final isSelected = selectedCategories.contains(cat);
                        return FilterChip(
                          label: Text(cat, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : null)),
                          selected: isSelected,
                          selectedColor: AppColors.primaryBlue,
                          onSelected: (val) {
                            setDialogState(() {
                              if (val) {
                                selectedCategories.add(cat);
                              } else {
                                selectedCategories.remove(cat);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid campaign title.'), backgroundColor: AppColors.criticalRed),
                    );
                    return;
                  }
                  final targetAmt = double.tryParse(targetAmountCtrl.text) ?? 500000.0;
                  final targetBen = int.tryParse(beneficiariesCtrl.text) ?? 500;
                  final duration = int.tryParse(durationCtrl.text) ?? 45;

                  final newCampaign = NgoCampaign(
                    id: 'CMP-GOONJ-0${DateTime.now().millisecondsSinceEpoch % 1000}',
                    title: title,
                    objective: objectiveCtrl.text.trim().isEmpty ? 'Direct humanitarian disaster relief.' : objectiveCtrl.text.trim(),
                    targetSector: sectorCtrl.text.trim(),
                    targetAmount: targetAmt,
                    targetBeneficiaries: targetBen,
                    inKindNeeds: ['Food Rations', 'Water Kits'],
                    categories: selectedCategories.isEmpty ? ['Emergency Relief'] : selectedCategories,
                    durationDays: duration,
                    isVerified: true,
                  );

                  ref.read(ngoCampaignsProvider.notifier).addCampaign(newCampaign);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✓ Campaign "${newCampaign.title}" published with live verified ledger!'),
                      backgroundColor: AppColors.verifiedGreen,
                    ),
                  );
                },
                child: const Text('Publish Relief Campaign', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // D. RECORD VERIFIED RELIEF DELIVERY MODAL (Part 3 D)
  void _openRecordDistributionDialog() {
    final campaigns = ref.read(ngoCampaignsProvider);
    String selectedCampaignId = campaigns.isNotEmpty ? campaigns.first.id : 'CMP-GOONJ-01';
    final countCtrl = TextEditingController(text: '120');
    final locCtrl = TextEditingController(text: 'Yamuna Khadar Ward 4 Safe Shelter Camp');
    final itemsCtrl = TextEditingController(text: '120 Dry Ration Kits & 240 Heavy Tarpaulins');
    final teamCtrl = TextEditingController(text: 'Goonj East Delhi Logistics Squadron');
    final challanCtrl = TextEditingController(text: 'CHALLAN-DEL-${DateTime.now().millisecondsSinceEpoch % 10000}.pdf');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.verifiedGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory, color: AppColors.verifiedGreen, size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Record Verified Relief Delivery',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DPDP Compliance: Delivery audits track aggregate household counts. Zero individual recipient names or phone numbers are publicly exposed.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 12),

                  const Text('Associated Relief Campaign *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: selectedCampaignId,
                    items: campaigns.map((c) => DropdownMenuItem(value: c.id, child: Text(c.title, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCampaignId = val);
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Text('Beneficiary Households Reached *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: countCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      suffixText: 'Households',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Text('Distribution Camp Location *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: locCtrl,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Text('Relief Items Handed Over *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: itemsCtrl,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Text('Responsible Logistics Team *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: teamCtrl,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Text('Delivery Challan / Proof Ref *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: challanCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.attachment, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.verifiedGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final count = int.tryParse(countCtrl.text) ?? 100;
                  final matchingCampaign = campaigns.firstWhere((c) => c.id == selectedCampaignId, orElse: () => campaigns.first);

                  final delivery = NgoDistributionDelivery(
                    id: 'DEL-2026-${DateTime.now().millisecondsSinceEpoch % 10000}',
                    campaignId: selectedCampaignId,
                    campaignTitle: matchingCampaign.title,
                    householdsReached: count,
                    distributionLocation: locCtrl.text.trim(),
                    reliefItems: itemsCtrl.text.trim(),
                    deliveryDate: DateTime.now(),
                    responsibleTeam: teamCtrl.text.trim(),
                    evidenceChallan: challanCtrl.text.trim(),
                    verificationStatus: 'AUDIT_VERIFIED',
                  );

                  ref.read(ngoDeliveriesProvider.notifier).addDelivery(delivery);
                  ref.read(ngoCampaignsProvider.notifier).recordDistribution(selectedCampaignId, count);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✓ Verified distribution to $count households recorded at ${locCtrl.text}. Published to public transparency ledger.'),
                      backgroundColor: AppColors.verifiedGreen,
                    ),
                  );
                },
                child: const Text('Confirm Distribution Record', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // RECORD AUDITED EXPENSE MODAL
  void _openRecordExpenseDialog() {
    final campaigns = ref.read(ngoCampaignsProvider);
    String selectedCampaignId = campaigns.isNotEmpty ? campaigns.first.id : 'CMP-GOONJ-01';
    final amountCtrl = TextEditingController(text: '75000');
    final categoryCtrl = TextEditingController(text: 'Emergency Medical Dressing & Tetanus Kits');
    final vendorCtrl = TextEditingController(text: 'Apollo Medical Supplies Depot East');
    final invNumCtrl = TextEditingController(text: 'INV-MED-${DateTime.now().millisecondsSinceEpoch % 10000}');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final currentCamp = campaigns.firstWhere((c) => c.id == selectedCampaignId, orElse: () => campaigns.first);

          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.warningOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_long, color: AppColors.warningOrange, size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Record Audited Relief Expenditure',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warningOrange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warningOrange.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Available Uncommitted Funds: ₹${currentCamp.remainingAvailable.toStringAsFixed(0)} (Expenses cannot exceed available uncommitted funds).',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warningOrange),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text('Allocated Campaign *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: selectedCampaignId,
                    items: campaigns.map((c) => DropdownMenuItem(value: c.id, child: Text(c.title, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCampaignId = val);
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
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
                                prefixText: '₹ ',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                isDense: true,
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
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                isDense: true,
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Text('Vendor / Payee Entity *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: vendorCtrl,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warningOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final amt = double.tryParse(amountCtrl.text) ?? 75000.0;
                  if (amt > currentCamp.remainingAvailable) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: Expense of ₹$amt exceeds uncommitted balance of ₹${currentCamp.remainingAvailable.toStringAsFixed(0)}.'),
                        backgroundColor: AppColors.criticalRed,
                      ),
                    );
                    return;
                  }

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
                      content: Text('✓ Audited expense of ₹${amt.toStringAsFixed(0)} successfully logged with invoice verification.'),
                      backgroundColor: AppColors.verifiedGreen,
                    ),
                  );
                },
                child: const Text('Record Audited Expense', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ACCEPT DONATION DIALOG
  void _openAcceptDonationDialog(NgoCampaign campaign) {
    final amountCtrl = TextEditingController(text: '5000');
    final donorNameCtrl = TextEditingController(text: 'Aarav Sharma');
    final emailCtrl = TextEditingController(text: 'donor@resqai.org');
    String paymentMethod = 'UPI';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.volunteer_activism, color: AppColors.primaryBlue, size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Process Verified Campaign Donation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Campaign: ${campaign.title}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryBlue)),
                  const SizedBox(height: 10),
                  const Text('Donation Amount (₹ INR) *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Donor Full Name *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: donorNameCtrl,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Donor Email (for Section 80G Receipt) *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Verified Payment Rail *:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    items: const [
                      DropdownMenuItem(value: 'UPI', child: Text('UPI (Google Pay / PhonePe / BHIM)')),
                      DropdownMenuItem(value: 'NetBanking', child: Text('NetBanking (NEFT / RTGS)')),
                      DropdownMenuItem(value: 'Card', child: Text('Debit / Credit Card (RuPay / Visa)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => paymentMethod = val);
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final amt = double.tryParse(amountCtrl.text) ?? 5000.0;
                  final donation = ref.read(donationsProvider.notifier).createVerifiedDonation(
                        campaignId: campaign.id,
                        campaignTitle: campaign.title,
                        ngoName: 'Goonj Disaster Relief Wing',
                        ngoId: 'NGO-DARPAN-DL-024810',
                        amount: amt,
                        donorName: donorNameCtrl.text.trim(),
                        donorEmail: emailCtrl.text.trim(),
                        donorPhone: '+91 98*** **210',
                        isAnonymous: false,
                        paymentMethod: paymentMethod,
                      );

                  // Update campaign raised amount
                  ref.read(ngoCampaignsProvider.notifier).recordDonation(campaign.id, amt);

                  // Record in transaction ledger
                  final newTx = NgoFinancialTransaction(
                    id: 'TX-CR-${DateTime.now().millisecondsSinceEpoch % 10000}',
                    campaignId: campaign.id,
                    transactionRef: donation.transactionRef,
                    amount: amt,
                    transactionType: 'DONATION_RECEIVED',
                    category: 'Public Verified Donation',
                    entityName: donorNameCtrl.text.trim(),
                    invoiceNumber: donation.receiptNumber,
                    timestamp: DateTime.now(),
                    approvalStatus: 'AUDIT_VERIFIED',
                    invoiceDocumentProof: 'receipt_${donation.receiptNumber}.pdf',
                  );
                  ref.read(ngoTransactionsProvider.notifier).addTransaction(newTx);

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✓ Payment of ₹${amt.toStringAsFixed(0)} confirmed! Receipt #${donation.receiptNumber} generated.'),
                      backgroundColor: AppColors.verifiedGreen,
                    ),
                  );
                },
                child: const Text('Confirm Verified Payment', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = ref.watch(ngoCampaignsProvider);
    final transactions = ref.watch(ngoTransactionsProvider);
    final deliveries = ref.watch(ngoDeliveriesProvider);
    final donations = ref.watch(donationsProvider);
    final currentUser = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    // Aggregate NGO stats
    final totalRaised = campaigns.fold<double>(0.0, (sum, c) => sum + c.raisedAmount);
    final totalSpent = campaigns.fold<double>(0.0, (sum, c) => sum + c.spentAmount);
    final totalCommitted = campaigns.fold<double>(0.0, (sum, c) => sum + c.committedAmount);
    final totalAvailable = totalRaised - (totalSpent + totalCommitted);
    final totalBeneficiaries = campaigns.fold<int>(0, (sum, c) => sum + c.verifiedBeneficiariesReached);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        titleSpacing: isMobile ? 8 : 16,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'NGO Transparent Relief Portal',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.deepNavy,
                    ),
                  ),
                  Text(
                    'DARPAN: DL/2019/024810 • Goonj Disaster Wing',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
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
          isScrollable: true,
          indicatorColor: AppColors.primaryLight,
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(icon: const Icon(Icons.campaign, size: 18), text: 'Campaigns (${campaigns.length})'),
            Tab(icon: const Icon(Icons.receipt_long, size: 18), text: 'Ledger (${transactions.length})'),
            Tab(icon: const Icon(Icons.inventory_2, size: 18), text: 'Relief Inventory (${_inventory.length})'),
            Tab(icon: const Icon(Icons.local_shipping, size: 18), text: 'Distribution History (${deliveries.length})'),
            Tab(icon: const Icon(Icons.volunteer_activism, size: 18), text: 'Donations (${donations.length})'),
            const Tab(icon: Icon(Icons.analytics, size: 18), text: 'Reports & Transparency'),
            const Tab(icon: Icon(Icons.verified, size: 18), text: 'NGO Profile & Trust'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCampaignsTab(campaigns, totalRaised, totalSpent, totalCommitted, totalAvailable, totalBeneficiaries, isMobile, isDark),
          _buildLedgerTab(transactions, isMobile, isDark),
          _buildInventoryTab(isMobile, isDark),
          _buildDistributionHistoryTab(deliveries, isMobile, isDark),
          _buildDonationsTab(donations, isMobile, isDark),
          _buildReportsTransparencyTab(campaigns, totalRaised, totalSpent, totalCommitted, totalAvailable, totalBeneficiaries, isMobile, isDark),
          _buildProfileTab(currentUser, isMobile, isDark),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Action', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
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
                      leading: const CircleAvatar(backgroundColor: AppColors.primaryBlue, child: Icon(Icons.campaign, color: Colors.white)),
                      title: const Text('Launch Relief Campaign'),
                      subtitle: const Text('Create fundraising and in-kind targets'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _openCreateCampaignDialog();
                      },
                    ),
                    ListTile(
                      leading: const CircleAvatar(backgroundColor: AppColors.warningOrange, child: Icon(Icons.receipt_long, color: Colors.white)),
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

  // TAB 1: CAMPAIGNS TAB (Part 3 B & E)
  Widget _buildCampaignsTab(
    List<NgoCampaign> campaigns,
    double raised,
    double spent,
    double committed,
    double available,
    int beneficiaries,
    bool isMobile,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Responsive Four Financial Balance Cards (Part 3 B)
          LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth;
              if (constraints.maxWidth >= 900) {
                cardWidth = (constraints.maxWidth - 36) / 4;
              } else if (constraints.maxWidth >= 480) {
                cardWidth = (constraints.maxWidth - 12) / 2;
              } else {
                cardWidth = constraints.maxWidth;
              }

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _responsiveFinanceCard('Verified Received', '₹${(raised / 100000).toStringAsFixed(1)} L', 'Audited Public & CSR Grants', AppColors.verifiedGreen, Icons.savings, cardWidth, isDark),
                  _responsiveFinanceCard('Verified Spent', '₹${(spent / 100000).toStringAsFixed(1)} L', '100% Tax Invoices Logged', AppColors.criticalRed, Icons.payments, cardWidth, isDark),
                  _responsiveFinanceCard('Committed Orders', '₹${(committed / 100000).toStringAsFixed(1)} L', 'Active Purchase Orders', AppColors.warningOrange, Icons.pending_actions, cardWidth, isDark),
                  _responsiveFinanceCard('Uncommitted Cash', '₹${(available / 100000).toStringAsFixed(1)} L', 'Available for Immediate Relief', AppColors.primaryBlue, Icons.account_balance, cardWidth, isDark),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Aggregate Beneficiary Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.verifiedGreen,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: _openRecordDistributionDialog,
                  child: const Text('Log Delivery', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final c = campaigns[index];
              final percentRaised = (c.raisedAmount / c.targetAmount * 100).clamp(0, 100).toInt();

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                          child: Text(c.id, style: const TextStyle(color: AppColors.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        const TruthBadgeWidget(type: TruthBadgeType.verifiedSafe, customText: 'AUDIT COMPLIANT'),
                        const Spacer(),
                        Text('Target: ₹${(c.targetAmount / 100000).toStringAsFixed(1)}L', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(c.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(c.objective, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText, height: 1.4)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(child: Text(c.targetSector, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (c.raisedAmount / c.targetAmount).clamp(0.0, 1.0),
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation(AppColors.primaryLight),
                        minHeight: 7,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Text('₹${(c.raisedAmount / 100000).toStringAsFixed(1)}L Raised ($percentRaised%)', style: const TextStyle(fontSize: 11, color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
                        Text('Spent: ₹${(c.spentAmount / 100000).toStringAsFixed(1)}L • Reached: ${c.verifiedBeneficiariesReached} Families', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // In-Kind Urgent Requirements
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: c.inKindNeeds.map((need) => Chip(
                        label: Text(need, style: const TextStyle(fontSize: 10)),
                        padding: EdgeInsets.zero,
                        backgroundColor: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                      )).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Action Buttons (Wrap on Mobile)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.receipt, size: 14),
                          label: const Text('Log Expense', style: TextStyle(fontSize: 12)),
                          onPressed: _openRecordExpenseDialog,
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                          icon: const Icon(Icons.volunteer_activism, size: 14),
                          label: const Text('Accept Donation / Gateway', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () => _openAcceptDonationDialog(c),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.open_in_new, size: 14),
                          label: const Text('View Ledger', style: TextStyle(fontSize: 12)),
                          onPressed: () => _tabController.animateTo(1),
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

  // TAB 2: AUDITED FINANCIAL LEDGER TAB (Part 4 B)
  Widget _buildLedgerTab(List<NgoFinancialTransaction> txs, bool isMobile, bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Audited Financial Ledger & Invoices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Statutory Compliance: Every financial movement has an immutable voucher reference.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.warningOrange, foregroundColor: Colors.white),
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
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final tx = txs[index];
              final isCredit = tx.transactionType == 'DONATION_RECEIVED';
              final color = isCredit ? AppColors.verifiedGreen : (tx.transactionType == 'COMMITTED_ORDER' ? AppColors.warningOrange : AppColors.criticalRed);

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            tx.transactionType,
                            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(tx.transactionRef, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
                        ),
                        Text(
                          '${isCredit ? "+" : "-"}₹${tx.amount.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(tx.entityName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Category: ${tx.category} • Invoice #${tx.invoiceNumber}', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText)),
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
                              SnackBar(content: Text('Viewing verified document proof: ${tx.invoiceDocumentProof}')),
                            );
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.picture_as_pdf, size: 14, color: AppColors.primaryBlue),
                              const SizedBox(width: 4),
                              Text(tx.invoiceDocumentProof, style: const TextStyle(fontSize: 11, color: AppColors.primaryBlue, decoration: TextDecoration.underline)),
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

  // TAB 3: RELIEF INVENTORY TAB
  Widget _buildInventoryTab(bool isMobile, bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: 18),
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
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _inventory[index];

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
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
                        _inventoryPill('Available', '${item.availableUnits}', AppColors.verifiedGreen, isDark),
                        const SizedBox(width: 8),
                        _inventoryPill('Dispatched', '${item.dispatchedUnits}', AppColors.primaryBlue, isDark),
                        const SizedBox(width: 8),
                        _inventoryPill('Shortage Deficit', '${item.reportedShortage}', item.reportedShortage > 0 ? AppColors.criticalRed : Colors.grey, isDark),
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

  // TAB 4: DISTRIBUTION HISTORY TAB (Part 3 G)
  Widget _buildDistributionHistoryTab(List<NgoDistributionDelivery> deliveries, bool isMobile, bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Verified Field Relief Distribution History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Permanent delivery records verified by Revenue Officials & Patwaris.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.verifiedGreen, foregroundColor: Colors.white),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Log Handover', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: _openRecordDistributionDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: deliveries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final d = deliveries[index];

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.verifiedGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            d.id,
                            style: const TextStyle(color: AppColors.verifiedGreen, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${d.householdsReached} Families Reached', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.verifiedGreen)),
                        const Spacer(),
                        const TruthBadgeWidget(type: TruthBadgeType.verifiedSafe, customText: 'AUDITED DELIVERY'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Camp: ${d.distributionLocation}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Relief Items: ${d.reliefItems}', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText)),
                    const SizedBox(height: 4),
                    Text('Delivered By: ${d.responsibleTeam} • Date: ${d.deliveryDate.toString().substring(0, 10)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.file_present, size: 14, color: AppColors.primaryBlue),
                        const SizedBox(width: 4),
                        Text('Challan Proof: ${d.evidenceChallan}', style: const TextStyle(fontSize: 11, color: AppColors.primaryBlue)),
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

  // TAB 5: DONATIONS TAB (Part 4 A & Part 5)
  Widget _buildDonationsTab(List<DonationModel> donations, bool isMobile, bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Verified Public & Corporate Donations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Donations are reconciled via Razorpay/UPI gateway and eligible for Section 80G tax deductions.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 16),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: donations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final don = donations[index];

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.verifiedGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            don.paymentStatus,
                            style: const TextStyle(color: AppColors.verifiedGreen, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(don.transactionRef, style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
                        ),
                        Text(
                          '₹${don.amount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.verifiedGreen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(don.donorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('Campaign: ${don.campaignTitle}', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText)),
                    const SizedBox(height: 4),
                    Text('Payment Mode: ${don.paymentMethod} • Receipt #${don.receiptNumber}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.lock, size: 12, color: AppColors.primaryBlue),
                        const SizedBox(width: 4),
                        Expanded(child: Text('Hash: ${don.auditVerificationHash}', style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                          icon: const Icon(Icons.picture_as_pdf, size: 12),
                          label: const Text('80G Receipt', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Section 80G Tax Exemption Receipt'),
                                content: Text('Receipt #${don.receiptNumber}\nDonor: ${don.donorName}\nAmount: ₹${don.amount.toStringAsFixed(0)}\nStatus: VERIFIED IMMUTABLE\nHash: ${don.auditVerificationHash}'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                                ],
                              ),
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

  // TAB 6: REPORTS & TRANSPARENCY TAB (Part 4 D)
  Widget _buildReportsTransparencyTab(
    List<NgoCampaign> campaigns,
    double raised,
    double spent,
    double committed,
    double available,
    int beneficiaries,
    bool isMobile,
    bool isDark,
  ) {
    final conversionRatio = raised > 0 ? ((spent + committed) / raised * 100).toInt() : 0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Statutory Transparency & Audit Compliance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('All figures are reconciled against statutory banking ledgers and verified vendor tax invoices.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 16),

          // High Level Metrics
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Public Trust & Fund Utilization Index', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('$conversionRatio%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                        const Text('Relief Utilization', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('100%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.verifiedGreen)),
                        const Text('Invoice Audited', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('0.0%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.warningOrange)),
                        const Text('Admin Overhead Leakage', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Public Link Action Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.public, color: AppColors.primaryBlue, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Published to Citizen Transparency Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      SizedBox(height: 2),
                      Text('Citizens can inspect real-time campaign expenses, invoices, and distribution records without PII exposure.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.transparency),
                  child: const Text('Open Portal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // TAB 7: NGO PROFILE & TRUST TAB
  Widget _buildProfileTab(dynamic currentUser, bool isMobile, bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryLight.withOpacity(0.2), isDark ? AppColors.darkSurface : Colors.white],
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
                  backgroundColor: AppColors.primaryBlue,
                  child: Icon(Icons.corporate_fare, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              currentUser?.name ?? 'Goonj Disaster Relief Wing',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
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
              color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
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

  Widget _responsiveFinanceCard(
    String label,
    String value,
    String sub,
    Color color,
    IconData icon,
    double width,
    bool isDark,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _inventoryPill(String label, String val, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey), textAlign: TextAlign.center, maxLines: 1),
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
