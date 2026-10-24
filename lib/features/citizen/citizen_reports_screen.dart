import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/incident_repository.dart';
import '../../shared/models/incident_model.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';

class CitizenReportsScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const CitizenReportsScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<CitizenReportsScreen> createState() => _CitizenReportsScreenState();
}

class _CitizenReportsScreenState extends ConsumerState<CitizenReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  IncidentStatus? _selectedStatus;

  // Sample delivered assistance records linked to verified government workflows
  final List<Map<String, dynamic>> _deliveredAssistance = const [
    {
      'id': 'RQ-SDRF-84912',
      'relatedCaseId': 'RQ-INC-001',
      'category': 'SDRF Immediate Ex-Gratia DBT Relief',
      'categoryType': 'CASH',
      'approvedAmount': '₹50,000',
      'deliveredAmount': '₹50,000',
      'deliveryDate': '21 Oct 2026, 14:30 IST',
      'providingAgency': 'District Disaster Management Authority, Ghaziabad',
      'status': 'Disbursed via DBT',
      'referenceNumber': 'DBT-SBI-984021948201',
      'notes': 'Direct Benefit Transfer sanctioned under SDRF Category 2A for partial residential inundation.',
    },
    {
      'id': 'RQ-HLP-10492',
      'relatedCaseId': 'RQ-HLP-10492',
      'category': 'Emergency 7-Day Food & Water Ration Kits',
      'categoryType': 'KITS',
      'approvedAmount': '2 Family Packs (14 Days)',
      'deliveredAmount': '2 Family Packs',
      'deliveryDate': '22 Oct 2026, 10:15 IST',
      'providingAgency': 'NDRF 8th Battalion Logistics Hub (Vaishali)',
      'status': 'Delivered at Relief Center',
      'referenceNumber': 'CHL-NDRF-84210',
      'notes': 'Contains drinking water jerrycans, ready-to-eat calorie meals, halogen water purifying tablets, baby food.',
    },
    {
      'id': 'RQ-MED-92041',
      'relatedCaseId': 'RQ-INC-003',
      'category': 'Trauma Care & Medical Treatment Pass',
      'categoryType': 'MEDICAL',
      'approvedAmount': 'Fully Subsidized Emergency Care',
      'deliveredAmount': 'Inpatient Care & Dressing Completed',
      'deliveryDate': '23 Oct 2026, 08:45 IST',
      'providingAgency': 'Max Super Speciality Hospital (Disaster Wing)',
      'status': 'Delivered',
      'referenceNumber': 'MED-SDRF-40291',
      'notes': 'Tetanus prophylaxis, minor laceration suturing, free antibiotic course issued under PM-JAY Disaster Provision.',
    },
    {
      'id': 'RQ-SHT-39201',
      'relatedCaseId': 'RQ-INC-002',
      'category': 'Emergency Shelter & Bed Allocation',
      'categoryType': 'SHELTER',
      'approvedAmount': '4 Beds (Household Allocation)',
      'deliveredAmount': '4 Beds Occupied',
      'deliveryDate': '20 Oct 2026, 19:00 IST',
      'providingAgency': 'Ghaziabad Municipal Community Center (Indirapuram)',
      'status': 'Active Accommodation',
      'referenceNumber': 'SHT-GZB-0941',
      'notes': 'Secure accommodation with hot meals, clean sanitation, and generator power.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeName = ModalRoute.of(context)?.settings.name;
    if (routeName == AppRoutes.citizenAssistance && _tabController.index != 1) {
      _tabController.index = 1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incidents = ref.watch(incidentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return AppShell(
      currentRoute: AppRoutes.citizenReports,
      title: 'Requests & Assistance Tracking',
      breadcrumbs: const ['Citizen', 'Requests & Assistance'],
      child: Column(
        children: [
          // Top Tab Bar
          Container(
            color: isDark ? AppColors.darkSurface : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryBlue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primaryBlue,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(
                  icon: Icon(Icons.assignment_outlined, size: 20),
                  text: 'My Requests & Claims',
                ),
                Tab(
                  icon: Icon(Icons.handshake_outlined, size: 20),
                  text: 'Delivered Assistance History',
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: My Requests & Claims
                _buildRequestsTab(context, incidents, isDark, isMobile),

                // TAB 2: Delivered Assistance History
                _buildAssistanceHistoryTab(context, isDark, isMobile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 1: MY REQUESTS & CLAIMS
  Widget _buildRequestsTab(
    BuildContext context,
    List<IncidentModel> incidents,
    bool isDark,
    bool isMobile,
  ) {
    final filtered = incidents.where((i) {
      final matchesSearch = i.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          i.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          i.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          i.category.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _selectedStatus == null || i.status == _selectedStatus;
      return matchesSearch && matchesStatus;
    }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 32,
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick Creation Actions Bar
          _buildQuickActionButtonsBar(context, isMobile),
          const SizedBox(height: 16),

          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by Case ID, category, or locality...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 14),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All Requests'),
                  selected: _selectedStatus == null,
                  onSelected: (v) => setState(() => _selectedStatus = null),
                ),
                const SizedBox(width: 8),
                for (final status in IncidentStatus.values) ...[
                  ChoiceChip(
                    label: Text(status.label),
                    selected: _selectedStatus == status,
                    onSelected: (v) => setState(() => _selectedStatus = v ? status : null),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Requests List
          if (filtered.isEmpty)
            _buildEmptyRequestsView(context, isDark)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildRequestCard(context, filtered[index], isDark, isMobile),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButtonsBar(BuildContext context, bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.citizenHelpRequest),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            icon: const Icon(Icons.volunteer_activism_outlined, size: 16),
            label: Text(
              isMobile ? 'Request Help' : 'Request Humanitarian Aid',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.citizenNewReport),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            icon: const Icon(Icons.home_work_outlined, size: 16),
            label: Text(
              isMobile ? 'Report Damage' : 'Report Property Damage',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.citizenMissingPerson),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.person_search_outlined, size: 16, color: Color(0xFF7C3AED)),
            label: Text(
              isMobile ? 'Missing Person' : 'Missing Family Member',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF7C3AED)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    IncidentModel item,
    bool isDark,
    bool isMobile,
  ) {
    // Derive department
    final department = item.category == IncidentCategory.flood
        ? 'SDRF Flood Rescue & Relief Division'
        : (item.category == IncidentCategory.fire
            ? 'State Fire & Disaster Services'
            : 'District Magistrate Disaster Response Cell');

    final isDelivered = item.status == IncidentStatus.verified;

    return InkWell(
      onTap: () => Navigator.pushNamed(context, '${AppRoutes.citizenReports}/${item.id}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: ID, Category & Verification Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.id,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.category.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.status == IncidentStatus.verified
                        ? AppColors.successGreen.withOpacity(0.12)
                        : (item.status == IncidentStatus.unverified
                            ? AppColors.emergencyRed.withOpacity(0.12)
                            : AppColors.warningOrange.withOpacity(0.12)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.status.label.toUpperCase(),
                    style: TextStyle(
                      color: item.status == IncidentStatus.verified
                          ? AppColors.successGreen
                          : (item.status == IncidentStatus.unverified
                              ? AppColors.emergencyRed
                              : AppColors.warningOrange),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              item.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 4),

            // Location & Date
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _formatDate(item.reportedAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Urgency & Assigned Team Row
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Assigned EOC Department',
                            style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          department,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 24,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Urgency Tier',
                          style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.priority_high,
                            size: 12,
                            color: item.priorityScore > 70 ? AppColors.emergencyRed : AppColors.warningOrange,
                          ),
                          Text(
                            '${item.priorityScore.toStringAsFixed(0)}/100',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: item.priorityScore > 70 ? AppColors.emergencyRed : AppColors.warningOrange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Bottom Action & Assistance Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isDelivered ? Icons.check_circle : Icons.hourglass_top,
                      size: 14,
                      color: isDelivered ? AppColors.successGreen : AppColors.warningOrange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isDelivered
                          ? 'Assistance Approved / Sanctioned'
                          : 'Under Official Field Inspection',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDelivered ? AppColors.successGreen : AppColors.warningOrange,
                      ),
                    ),
                  ],
                ),
                const Row(
                  children: [
                    Text(
                      'Open Case Details',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: AppColors.primaryBlue),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRequestsView(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No matching requests found',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'You have not submitted any claims or assistance requests under these filters.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.citizenHelpRequest),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Submit New Request'),
          ),
        ],
      ),
    );
  }

  // TAB 2: DELIVERED ASSISTANCE HISTORY
  Widget _buildAssistanceHistoryTab(
    BuildContext context,
    bool isDark,
    bool isMobile,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 32,
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFA6F4C5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF12B76A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Officially Delivered Assistance & Disbursed Relief',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF027A48),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'This ledger records disaster benefits directly received by your registered household. Includes Direct Benefit Transfers (DBT), food supply distributions, safe shelter, and medical care.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF054F31), height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary Metrics Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total DBT Cash Disbursed',
                  '₹50,000',
                  Icons.currency_rupee,
                  AppColors.successGreen,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Ration & Relief Packs',
                  '2 Delivered',
                  Icons.inventory_2_outlined,
                  AppColors.primaryBlue,
                  isDark,
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Safe Shelter Nights',
                    '3 Nights Used',
                    Icons.night_shelter_outlined,
                    const Color(0xFF7C3AED),
                    isDark,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // Delivered Items List
          Text(
            'Official Benefit Records & Delivery Challans',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _deliveredAssistance.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) => _buildDeliveredRecordCard(
              context,
              _deliveredAssistance[index],
              isDark,
              isMobile,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
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
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveredRecordCard(
    BuildContext context,
    Map<String, dynamic> item,
    bool isDark,
    bool isMobile,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, color: AppColors.successGreen, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['category'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.deepNavy,
                      ),
                    ),
                    Text(
                      'Case ID: ${item['id']} • Linked: ${item['relatedCaseId']}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item['status'] as String,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.successGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Detail Grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildInfoRow('Approved Quantity / Amount:', item['approvedAmount'] as String),
                const SizedBox(height: 6),
                _buildInfoRow('Delivered Quantity / Amount:', item['deliveredAmount'] as String, isHighlight: true),
                const SizedBox(height: 6),
                _buildInfoRow('Delivery / Payment Date:', item['deliveryDate'] as String),
                const SizedBox(height: 6),
                _buildInfoRow('Providing Agency:', item['providingAgency'] as String),
                const SizedBox(height: 6),
                _buildInfoRow('Challan / DBT Reference:', item['referenceNumber'] as String, isMono: true),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Notes
          Text(
            'Official Notes: ${item['notes']}',
            style: const TextStyle(fontSize: 11, color: Colors.black54, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),

          // Receipt Button
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _showDigitalReceipt(context, item),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.receipt_long, size: 14),
              label: const Text('View Official Receipt / Confirmation', style: TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false, bool isMono = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppColors.successGreen : Colors.black87,
            fontFamily: isMono ? 'monospace' : null,
          ),
        ),
      ],
    );
  }

  void _showDigitalReceipt(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified, color: AppColors.successGreen, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Official Assistance Receipt',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('GOVERNMENT OF INDIA • DISASTER RELIEF RECORD',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Text('Disbursement Reference: ${item['referenceNumber']}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('Case ID: ${item['id']}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Beneficiary Service:', item['category'] as String),
            const SizedBox(height: 6),
            _buildInfoRow('Amount / Items Received:', item['deliveredAmount'] as String, isHighlight: true),
            const SizedBox(height: 6),
            _buildInfoRow('Delivery Timestamp:', item['deliveryDate'] as String),
            const SizedBox(height: 6),
            _buildInfoRow('Disbursing Authority:', item['providingAgency'] as String),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check, size: 14, color: AppColors.successGreen),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Verified digitally on NDMA Interoperable Disaster Database.',
                      style: TextStyle(fontSize: 10, color: AppColors.successGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day} ${_getMonth(dt.month)} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _getMonth(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }
}
