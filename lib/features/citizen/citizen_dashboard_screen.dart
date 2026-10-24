import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/incident_repository.dart';
import '../../shared/models/incident_model.dart';
import '../../shared/models/shelter_model.dart';
import '../../core/router/app_router.dart';
import '../../core/layout/app_shell.dart';

class CitizenDashboardScreen extends ConsumerStatefulWidget {
  const CitizenDashboardScreen({super.key});

  @override
  ConsumerState<CitizenDashboardScreen> createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends ConsumerState<CitizenDashboardScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();

  // Location selector state
  String _selectedLocality = 'Ghaziabad, UP';
  LatLng _mapCenter = const LatLng(28.6480, 77.3450); // Ghaziabad / Hindon River

  // Map layer toggles
  bool _showHazards = true;
  bool _showShelters = true;
  bool _showHospitals = true;
  bool _showRescueTeams = true;
  bool _showRoadBlockage = true;
  bool _isLegendExpanded = false;

  // Double-tap SOS state
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isArmed = false;
  int _remainingSeconds = 5;
  Timer? _countdownTimer;
  bool _isSubmittingSos = false;

  // High Risk Polygons
  final List<LatLng> _highRiskPolygon = const [
    LatLng(28.7100, 77.3100),
    LatLng(28.6900, 77.3400),
    LatLng(28.6700, 77.3600),
    LatLng(28.6500, 77.3500),
    LatLng(28.6600, 77.3200),
    LatLng(28.6900, 77.3000),
  ];

  final List<LatLng> _kaushambiFloodPolygon = const [
    LatLng(28.6400, 77.3100),
    LatLng(28.6450, 77.3400),
    LatLng(28.6250, 77.3500),
    LatLng(28.6150, 77.3250),
    LatLng(28.6250, 77.3050),
  ];

  final List<LatLng> _moderateRiskPolygon = const [
    LatLng(28.6480, 77.3400),
    LatLng(28.6600, 77.3800),
    LatLng(28.6350, 77.3900),
    LatLng(28.6250, 77.3500),
  ];

  final List<LatLng> _safeZonePolygon = const [
    LatLng(28.6650, 77.3550),
    LatLng(28.6800, 77.3750),
    LatLng(28.6700, 77.3950),
    LatLng(28.6550, 77.3750),
  ];

  final List<LatLng> _blockedRoad = const [
    LatLng(28.6250, 77.2900),
    LatLng(28.6350, 77.3200),
    LatLng(28.6420, 77.3500),
  ];

  final List<Map<String, dynamic>> _hospitals = const [
    {
      'name': 'Max Super Speciality Hospital Vaishali',
      'point': LatLng(28.6440, 77.3350),
      'beds': '18 ICU beds available',
      'phone': '+91 120 418 8000',
    },
    {
      'name': 'Shanti Gopal Hospital Indirapuram',
      'point': LatLng(28.6380, 77.3700),
      'beds': '12 Emergency beds available',
      'phone': '+91 120 477 7000',
    },
    {
      'name': 'Yashoda Super Speciality Hospital Kaushambi',
      'point': LatLng(28.6280, 77.3180),
      'beds': '24 Trauma beds available',
      'phone': '+91 120 455 5555',
    },
  ];

  final List<Map<String, dynamic>> _rescueTeams = const [
    {
      'id': 'NDRF-BOAT-04',
      'name': 'NDRF 8th Bn Inflatable Boat Unit',
      'point': LatLng(28.6550, 77.3450),
      'status': 'Active Patrol • Hindon Basin',
    },
    {
      'id': 'SDRF-VAN-02',
      'name': 'SDRF Mobile Evacuation Van',
      'point': LatLng(28.6180, 77.3450),
      'status': 'Staged at Kaushambi Crossing',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.10).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onSosTap() {
    if (_isSubmittingSos) return;

    if (!_isArmed) {
      setState(() {
        _isArmed = true;
        _remainingSeconds = 5;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.emergency, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'SOS Armed: Tap again within 5s to transmit emergency help request with your location ($_selectedLocality).',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.emergencyRed,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );

      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 1) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          timer.cancel();
          setState(() {
            _isArmed = false;
            _remainingSeconds = 5;
          });
        }
      });
    } else {
      _countdownTimer?.cancel();
      _submitSos();
    }
  }

  Future<void> _submitSos() async {
    setState(() {
      _isSubmittingSos = true;
      _isArmed = false;
    });

    final randomId = 'RQ-SOS-${Random().nextInt(9000) + 1000}';

    try {
      ref.read(incidentsProvider.notifier).addIncident(
            IncidentModel(
              id: randomId,
              title: 'Critical Emergency SOS Transmitted by Citizen',
              descriptionOriginal:
                  'Double Confirmed Emergency SOS. Citizen requesting immediate rescue, evacuation, and medical triage.',
              descriptionTranslated:
                  'Double Confirmed Emergency SOS. Citizen requesting immediate rescue, evacuation, and medical triage.',
              category: IncidentCategory.flood,
              latitude: _mapCenter.latitude,
              longitude: _mapCenter.longitude,
              address: '$_selectedLocality (Live GPS Fix)',
              source: 'ONE_TAP_SOS',
              priorityScore: 95.0,
              priorityExplanation: 'High-urgency double-tap SOS triggered from active flood zone',
              reporterPhoneMasked: '+91 98*** **112',
              reportedAt: DateTime.now(),
              status: IncidentStatus.verified,
            ),
          );
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() {
      _isSubmittingSos = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.emergencyRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'SOS Transmitted Successfully',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Incident Reference:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  Text(randomId,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.deepNavy)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Location: $_selectedLocality (${_mapCenter.latitude.toStringAsFixed(4)}°N, ${_mapCenter.longitude.toStringAsFixed(4)}°E)',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            const Text(
              'Real-Time Dispatch Lifecycle:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            _buildTimelineStep('1. Request Received at EOC', 'Logged in NDMA Central Database', true),
            _buildTimelineStep('2. GPS Triage & Radius Match', 'Matching with nearest rescue units', true),
            _buildTimelineStep('3. NDRF / SDRF Unit Alerted', 'Pending field responder acceptance', false),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, AppRoutes.citizenSos);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Tracking & Details'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String title, String subtitle, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16, color: isDone ? AppColors.successGreen : Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, fontWeight: isDone ? FontWeight.bold : FontWeight.normal)),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider);
    final incidents = ref.watch(incidentsProvider);
    final shelters = ref.watch(sheltersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return AppShell(
      currentRoute: AppRoutes.citizenDashboard,
      title: 'Citizen Disaster Hub',
      breadcrumbs: const ['Citizen', 'Dashboard'],
      hideMobileAppBar: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 28,
          vertical: isMobile ? 8 : 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Personalized Greeting, Citizen Profile & Location Bar
            _buildGreetingLocationBar(context, currentUser, isDark, isMobile),
            const SizedBox(height: 12),

            // 2. Active Official Disaster Alerts for the Region
            _buildOfficialAlertBanner(context, isDark),
            const SizedBox(height: 14),

            // 3. Responsive Layout: Map & SOS + Immediate Action Matrix
            if (isMobile) ...[
              _buildDisasterMapCard(context, shelters, isDark, height: 420),
              const SizedBox(height: 16),
              _buildPrimaryActionsGrid(context, isDark),
              const SizedBox(height: 16),
              _buildSecondaryServicesRow(context, isDark),
              const SizedBox(height: 16),
              _buildMyRequestsSummarySection(context, incidents, isDark),
              const SizedBox(height: 16),
              _buildAssistanceHistoryCard(context, isDark),
              const SizedBox(height: 16),
              _buildCampaignsAndTransparencyCard(context, isDark),
              const SizedBox(height: 20),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left 7 Cols: Tactical Map with Circular SOS + Primary Actions
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDisasterMapCard(context, shelters, isDark, height: 500),
                        const SizedBox(height: 18),
                        _buildPrimaryActionsGrid(context, isDark),
                        const SizedBox(height: 18),
                        _buildSecondaryServicesRow(context, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Right 5 Cols: Requests Tracking, Assistance History & Giving
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildMyRequestsSummarySection(context, incidents, isDark),
                        const SizedBox(height: 18),
                        _buildAssistanceHistoryCard(context, isDark),
                        const SizedBox(height: 18),
                        _buildNearbySheltersPreview(context, shelters, isDark),
                        const SizedBox(height: 18),
                        _buildCampaignsAndTransparencyCard(context, isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 1. GREETING & LOCATION BAR
  Widget _buildGreetingLocationBar(BuildContext context, dynamic currentUser, bool isDark, bool isMobile) {
    final userName = (currentUser != null && currentUser.name.isNotEmpty)
        ? currentUser.name
        : 'Citizen';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 0, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.shield_outlined, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text(
                          'Namaste, $userName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 20,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.deepNavy,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
                          ),
                          child: const Text(
                            'Verified Citizen',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.successGreen),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Disaster Emergency Response & Relief Command',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),

              // Bell Notification
              IconButton(
                icon: Stack(
                  children: [
                    Icon(Icons.notifications_outlined, color: isDark ? Colors.white : AppColors.deepNavy, size: 24),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: AppColors.emergencyRed, shape: BoxShape.circle),
                      ),
                    ),
                  ],
                ),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.citizenAlerts),
                tooltip: 'Emergency Notifications',
              ),

              // Profile Avatar
              InkWell(
                onTap: () => Navigator.pushNamed(context, AppRoutes.citizenProfile),
                borderRadius: BorderRadius.circular(20),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.15),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'C',
                    style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Location Selector Bar & Live Sync
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _showLocalitySelector(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: AppColors.emergencyRed),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _selectedLocality,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.deepNavy,
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Weather Summary Pill
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🌧️', style: TextStyle(fontSize: 13)),
                    SizedBox(width: 4),
                    Text(
                      '28°C',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 8),

                // NDMA Live Link Pill
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_tethering, color: AppColors.successGreen, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'NDMA Live',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.successGreen),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // 2. ACTIVE OFFICIAL DISASTER ALERT BANNER
  Widget _buildOfficialAlertBanner(BuildContext context, bool isDark) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.citizenAlerts),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFECDCA), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.emergencyRed.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFD92D20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'OFFICIAL ALERT • Level-3 Flood Warning (Hindon Basin)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB42318),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD92D20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'IMD / NDMA',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Water level at Hindon Barrage exceeds danger mark (205.35m). Low-lying sectors in Kaushambi & Morta advised to move to elevated shelters.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF55160C), height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFFB42318), size: 14),
          ],
        ),
      ),
    );
  }

  // 3. TACTICAL DISASTER MAP WITH INTEGRATED CIRCULAR SOS
  Widget _buildDisasterMapCard(
    BuildContext context,
    List<ShelterModel> shelters,
    bool isDark, {
    required double height,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: 12.5,
              minZoom: 10.0,
              maxZoom: 17.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'org.resqai.disaster',
              ),
              if (_showHazards)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _highRiskPolygon,
                      color: const Color(0x55F04438),
                      borderColor: const Color(0xCCF04438),
                      borderStrokeWidth: 2.0,
                      isFilled: true,
                    ),
                    Polygon(
                      points: _kaushambiFloodPolygon,
                      color: const Color(0x55F04438),
                      borderColor: const Color(0xCCF04438),
                      borderStrokeWidth: 2.0,
                      isFilled: true,
                    ),
                    Polygon(
                      points: _moderateRiskPolygon,
                      color: const Color(0x44F79009),
                      borderColor: const Color(0xAAF79009),
                      borderStrokeWidth: 1.8,
                      isFilled: true,
                    ),
                    Polygon(
                      points: _safeZonePolygon,
                      color: const Color(0x4412B76A),
                      borderColor: const Color(0xAA12B76A),
                      borderStrokeWidth: 1.8,
                      isFilled: true,
                    ),
                  ],
                ),
              if (_showRoadBlockage)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _blockedRoad,
                      strokeWidth: 4.0,
                      color: const Color(0xFFD92D20),
                      pattern: StrokePattern.dashed(segments: const [8, 6]),
                    ),
                  ],
                ),
              if (_showShelters)
                MarkerLayer(
                  markers: shelters.take(5).map((sh) {
                    return Marker(
                      point: LatLng(sh.latitude, sh.longitude),
                      width: 32,
                      height: 32,
                      child: GestureDetector(
                        onTap: () => _showMarkerDetails(
                            context,
                            'Shelter: ${sh.name}',
                            sh.address,
                            'Capacity: ${sh.totalCapacity - sh.occupiedBeds} beds open',
                            Icons.night_shelter,
                            AppColors.primaryBlue),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1570EF),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: const Icon(Icons.night_shelter, color: Colors.white, size: 16),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              if (_showHospitals)
                MarkerLayer(
                  markers: _hospitals.map((hosp) {
                    return Marker(
                      point: hosp['point'] as LatLng,
                      width: 30,
                      height: 30,
                      child: GestureDetector(
                        onTap: () => _showMarkerDetails(
                            context,
                            hosp['name'] as String,
                            'Emergency Contact: ${hosp['phone']}',
                            hosp['beds'] as String,
                            Icons.local_hospital,
                            AppColors.emergencyRed),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.emergencyRed,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 18),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              if (_showRescueTeams)
                MarkerLayer(
                  markers: _rescueTeams.map((rt) {
                    return Marker(
                      point: rt['point'] as LatLng,
                      width: 36,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => _showMarkerDetails(
                            context,
                            rt['name'] as String,
                            rt['id'] as String,
                            rt['status'] as String,
                            Icons.directions_boat,
                            AppColors.emergencyRed),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade800,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: const Icon(Icons.directions_boat, color: Colors.white, size: 18),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),

          // Map Legend Pill
          Positioned(
            top: 12,
            left: 12,
            child: _buildMapLegend(isDark),
          ),

          // Map Controls (Layers, Locate, Recenter)
          Positioned(
            top: 12,
            right: 12,
            child: _buildMapControls(isDark),
          ),

          // Scale Bar
          Positioned(
            bottom: 12,
            left: 12,
            child: _buildScaleBar(isDark),
          ),

          // PROMINENT CIRCULAR DOUBLE-TAP SOS HERO BUTTON
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: _buildDoubleTapSosButton(),
            ),
          ),
        ],
      ),
    );
  }

  // 4. PRIMARY ACTIONS GRID (4 Core Humanitarian Relieves)
  Widget _buildPrimaryActionsGrid(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Immediate Relief & Reporting Services',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.deepNavy,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.citizenHelp),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: const Text('View Help Hub ↗',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // 1. Request Help (Humanitarian aid multi-step form)
            Expanded(
              child: _buildServiceActionCard(
                context,
                title: 'Request Help',
                subtitle: 'Food, water, medicine & rescue',
                icon: Icons.volunteer_activism_outlined,
                iconColor: const Color(0xFFD92D20),
                iconBg: const Color(0xFFFFF1F0),
                route: AppRoutes.citizenHelpRequest,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),

            // 2. Report Damage (Structural loss & claims)
            Expanded(
              child: _buildServiceActionCard(
                context,
                title: 'Report Damage',
                subtitle: 'Home, crops, livestock claims',
                icon: Icons.home_work_outlined,
                iconColor: const Color(0xFF1570EF),
                iconBg: const Color(0xFFEFF8FF),
                route: AppRoutes.citizenNewReport,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // 3. Find Safe Shelter
            Expanded(
              child: _buildServiceActionCard(
                context,
                title: 'Find Shelter',
                subtitle: 'Live bed vacancy & food hubs',
                icon: Icons.night_shelter_outlined,
                iconColor: const Color(0xFF12B76A),
                iconBg: const Color(0xFFECFDF3),
                route: AppRoutes.citizenShelters,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),

            // 4. Missing Family Member Report (Confidential DPDP SAR)
            Expanded(
              child: _buildServiceActionCard(
                context,
                title: 'Missing Family',
                subtitle: 'Confidential NDMA tracing',
                icon: Icons.person_search_outlined,
                iconColor: const Color(0xFF7C3AED),
                iconBg: const Color(0xFFF5F3FF),
                route: AppRoutes.citizenMissingPerson,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String route,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? iconColor.withOpacity(0.15) : iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 5. SECONDARY SERVICES & EMERGENCY HELPLINES ROW
  Widget _buildSecondaryServicesRow(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              const Icon(Icons.support_agent, size: 18, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Emergency Direct Lines & Quick Portals',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.deepNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Medical Assistance Dial
                _buildQuickActionChip(
                  context,
                  label: 'Medical 108',
                  icon: Icons.medical_services_outlined,
                  color: AppColors.emergencyRed,
                  onTap: () => _showEmergencyCallModal(context, 'Ambulance & Trauma', '108'),
                ),
                const SizedBox(width: 8),

                // Police / Emergency 112
                _buildQuickActionChip(
                  context,
                  label: 'Police 112',
                  icon: Icons.local_police_outlined,
                  color: AppColors.primaryBlue,
                  onTap: () => _showEmergencyCallModal(context, 'National Emergency Response', '112'),
                ),
                const SizedBox(width: 8),

                // NDMA Disaster Helpline 1078
                _buildQuickActionChip(
                  context,
                  label: 'NDMA 1078',
                  icon: Icons.shield_outlined,
                  color: AppColors.warningOrange,
                  onTap: () => _showEmergencyCallModal(context, 'NDMA National Helpline', '1078'),
                ),
                const SizedBox(width: 8),

                // Help Hub Page Link
                _buildQuickActionChip(
                  context,
                  label: '12 Help Categories',
                  icon: Icons.apps_outlined,
                  color: const Color(0xFF7C3AED),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.citizenHelp),
                ),
                const SizedBox(width: 8),

                // Relief Donations Link
                _buildQuickActionChip(
                  context,
                  label: 'Donate Relief',
                  icon: Icons.favorite_border,
                  color: AppColors.successGreen,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.citizenDonate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // 6. MY ACTIVE REQUESTS & CLAIMS (Real Backend Data)
  Widget _buildMyRequestsSummarySection(BuildContext context, List<IncidentModel> incidents, bool isDark) {
    final recentReports = incidents.take(3).toList();

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'My Active Help Requests & Claims',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.deepNavy,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.citizenReports),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: const Text('View All Tracking ↗',
                    style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (recentReports.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.assignment_turned_in_outlined, size: 36, color: Colors.grey.shade400),
                    const SizedBox(height: 6),
                    const Text('No active claims or emergency requests filed.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(height: 2),
                    const Text('Use "Request Help" or "Report Damage" above to initiate a case.',
                        style: TextStyle(fontSize: 11, color: Colors.black38)),
                  ],
                ),
              ),
            )
          else
            ...recentReports.map((inc) {
              return InkWell(
                onTap: () => Navigator.pushNamed(context, '/citizen/reports/${inc.id}'),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.description_outlined, color: AppColors.primaryBlue, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inc.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${inc.id} • ${inc.address}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.mutedText),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: inc.status == IncidentStatus.verified
                              ? AppColors.successGreen.withOpacity(0.12)
                              : AppColors.warningOrange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          inc.status.label.toUpperCase(),
                          style: TextStyle(
                            color: inc.status == IncidentStatus.verified
                                ? AppColors.successGreen
                                : AppColors.warningOrange,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // 7. MY ASSISTANCE HISTORY (Delivered Aid Summary)
  Widget _buildAssistanceHistoryCard(BuildContext context, bool isDark) {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.handshake_outlined, size: 16, color: AppColors.successGreen),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'My Assistance History',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.deepNavy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.citizenAssistance),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: const Text('Full History ↗',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Delivered Benefit Item 1: SDRF Direct Cash Relief
          _buildAssistanceRecordTile(
            title: 'SDRF Immediate Flood Ex-Gratia',
            caseId: 'RQ-SDRF-84912',
            amountOrQty: '₹50,000 Disbursed via DBT',
            status: 'Delivered',
            date: 'Oct 21, 2026',
            agency: 'District Magistrate Disaster Cell',
            isSuccess: true,
          ),
          const Divider(height: 12),

          // Delivered Benefit Item 2: NDRF Ration Kit
          _buildAssistanceRecordTile(
            title: 'Emergency Food & Water Ration (7-Day)',
            caseId: 'RQ-HLP-10492',
            amountOrQty: '2 Ration Kits Delivered',
            status: 'Delivered',
            date: 'Oct 22, 2026',
            agency: 'NDRF 8th Battalion Logistics',
            isSuccess: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAssistanceRecordTile({
    required String title,
    required String caseId,
    required String amountOrQty,
    required String status,
    required String date,
    required String agency,
    required bool isSuccess,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.successGreen.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 14, color: AppColors.successGreen),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text('$caseId • $agency', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(amountOrQty, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.successGreen)),
            Text(date, style: const TextStyle(fontSize: 9, color: Colors.black45)),
          ],
        ),
      ],
    );
  }

  // 8. NEARBY SHELTERS PREVIEW
  Widget _buildNearbySheltersPreview(BuildContext context, List<ShelterModel> shelters, bool isDark) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Nearby Safe Havens & Camps',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.deepNavy),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.citizenShelters),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: const Text('All Camps', style: TextStyle(fontSize: 11, color: AppColors.primaryBlue)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...shelters.take(3).map((s) {
            final remaining = s.totalCapacity - s.occupiedBeds;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.night_shelter, size: 14, color: AppColors.successGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(s.name,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text('$remaining beds',
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.successGreen)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 9. RELIEF CAMPAIGNS & PUBLIC TRANSPARENCY
  Widget _buildCampaignsAndTransparencyCard(BuildContext context, bool isDark) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.volunteer_activism, size: 16, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Verified Relief & Public Audit',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.deepNavy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('80G Tax-Exempt',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Support verified disaster response funds. 100% of proceeds are audited and allocated to verified beneficiaries.',
            style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.3),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.citizenDonate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.favorite, size: 14),
                  label: const Text('Donate Relief', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.transparency),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.account_balance, size: 14),
                  label: const Text('Audit Ledger', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // CIRCULAR DOUBLE-TAP SOS BUTTON (SIGNATURE)
  Widget _buildDoubleTapSosButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final scale = _isArmed ? _pulseAnimation.value : 1.0;
            return Transform.scale(
              scale: scale,
              child: GestureDetector(
                onTap: _onSosTap,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _isArmed
                            ? Colors.redAccent.withOpacity(0.6)
                            : AppColors.emergencyRed.withOpacity(0.35),
                        blurRadius: _isArmed ? 24 : 16,
                        spreadRadius: _isArmed ? 6 : 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (_isArmed ? Colors.redAccent : AppColors.emergencyRed).withOpacity(0.2),
                        ),
                      ),
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: _isArmed
                                ? const [Color(0xFFFF5252), Color(0xFFD32F2F)]
                                : const [Color(0xFFEF4444), Color(0xFFB91C1C)],
                            center: Alignment.topLeft,
                            radius: 0.85,
                          ),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '✱',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                height: 0.9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _isArmed ? '$_remainingSeconds' : 'SOS',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        if (_isArmed)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F0),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.emergencyRed, width: 1.2),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Text(
                  '⚠️ Tap again to confirm SOS (${_remainingSeconds}s)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.emergencyRed,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  _countdownTimer?.cancel();
                  setState(() => _isArmed = false);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, size: 12, color: Colors.grey),
                      SizedBox(width: 2),
                      Text('Cancel',
                          style: TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          )
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFCDD2),
                    width: 1.2,
                  ),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: const Text(
                  'Double-tap to request emergency dispatch',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB91C1C),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => Navigator.pushNamed(context, AppRoutes.citizenSos),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Motor Assist / Form SOS Mode ↗',
                    style: TextStyle(fontSize: 10, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // MAP CONTROLS & UTILITIES
  Widget _buildMapLegend(bool isDark) {
    if (!_isLegendExpanded) {
      return InkWell(
        onTap: () => setState(() => _isLegendExpanded = true),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.layers, size: 12, color: AppColors.primaryBlue),
              SizedBox(width: 4),
              Text(
                'Legend ▾',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.deepNavy),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Map Legend',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.deepNavy)),
              const SizedBox(width: 14),
              InkWell(
                onTap: () => setState(() => _isLegendExpanded = false),
                child: const Icon(Icons.close, size: 14, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildLegendRow(const Color(0xFFF04438), 'High Flood Risk', isBox: true),
          _buildLegendRow(const Color(0xFFF79009), 'Moderate Risk', isBox: true),
          _buildLegendRow(const Color(0xFF12B76A), 'Safe Zone', isBox: true),
          _buildLegendRow(const Color(0xFF1570EF), 'Shelter', icon: Icons.night_shelter),
          _buildLegendRow(AppColors.emergencyRed, 'Hospital', icon: Icons.add),
          _buildLegendRow(Colors.red.shade800, 'Rescue Team', icon: Icons.directions_boat),
          _buildLegendRow(const Color(0xFFD92D20), 'Blocked Road', isDashed: true),
        ],
      ),
    );
  }

  Widget _buildLegendRow(Color color, String text, {bool isBox = false, bool isDashed = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isBox)
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)))
          else if (isDashed)
            Row(
              children: [
                Container(width: 4, height: 2, color: color),
                const SizedBox(width: 2),
                Container(width: 4, height: 2, color: color),
              ],
            )
          else if (icon != null)
            Icon(icon, size: 11, color: color)
          else
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildMapControls(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMapControlButton(Icons.layers_outlined, 'Layers', () => _showLayersModal(context)),
          const Divider(height: 1, indent: 4, endIndent: 4),
          _buildMapControlButton(Icons.near_me_outlined, 'Locate', () {
            _mapController.move(_mapCenter, 14.0);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('GPS Centered at $_selectedLocality'), duration: const Duration(seconds: 1)),
            );
          }),
          const Divider(height: 1, indent: 4, endIndent: 4),
          _buildMapControlButton(Icons.my_location, 'Re-center', () {
            _mapController.move(const LatLng(28.6480, 77.3450), 12.5);
          }),
        ],
      ),
    );
  }

  Widget _buildMapControlButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.deepNavy),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  void _showLayersModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Toggle Tactical Map Layers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Flood Risk Zones'),
                  value: _showHazards,
                  onChanged: (v) {
                    setState(() => _showHazards = v);
                    setModalState(() {});
                  },
                ),
                SwitchListTile(
                  title: const Text('Emergency Shelters'),
                  value: _showShelters,
                  onChanged: (v) {
                    setState(() => _showShelters = v);
                    setModalState(() {});
                  },
                ),
                SwitchListTile(
                  title: const Text('Hospital & Trauma Centers'),
                  value: _showHospitals,
                  onChanged: (v) {
                    setState(() => _showHospitals = v);
                    setModalState(() {});
                  },
                ),
                SwitchListTile(
                  title: const Text('Rescue & NDRF Teams'),
                  value: _showRescueTeams,
                  onChanged: (v) {
                    setState(() => _showRescueTeams = v);
                    setModalState(() {});
                  },
                ),
                SwitchListTile(
                  title: const Text('Blocked Road Hazards'),
                  value: _showRoadBlockage,
                  onChanged: (v) {
                    setState(() => _showRoadBlockage = v);
                    setModalState(() {});
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScaleBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('0    2    4 km', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 1),
          Container(
            width: 48,
            height: 3,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black87, width: 0.8),
            ),
            child: Row(
              children: [
                Expanded(child: Container(color: Colors.black87)),
                Expanded(child: Container(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLocalitySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Text('Select Monitored Disaster Sector',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const Divider(),
              _buildLocalityTile('Ghaziabad, UP', const LatLng(28.6480, 77.3450),
                  'Hindon River Basin • High Risk Flood Watch'),
              _buildLocalityTile('East Delhi (Yamuna Khadar)', const LatLng(28.6250, 77.2650),
                  'Yamuna Floodplain • Level 3 Evacuation Alert'),
              _buildLocalityTile('Noida Sector 62', const LatLng(28.6200, 77.3650),
                  'Lowland Commercial & Residential Sector'),
              _buildLocalityTile('Patna Lowlands', const LatLng(25.6130, 85.1430),
                  'Ganga Embankment Basin'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocalityTile(String name, LatLng point, String description) {
    final isSelected = _selectedLocality == name;
    return ListTile(
      leading: Icon(Icons.location_city, color: isSelected ? AppColors.primaryBlue : Colors.grey),
      title: Text(name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
      subtitle: Text(description, style: const TextStyle(fontSize: 11)),
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primaryBlue) : null,
      onTap: () {
        setState(() {
          _selectedLocality = name;
          _mapCenter = point;
        });
        _mapController.move(point, 12.5);
        Navigator.pop(context);
      },
    );
  }

  void _showMarkerDetails(
      BuildContext context, String title, String subtitle, String details, IconData icon, Color color) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(details, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Directions to $title started.'), backgroundColor: AppColors.primaryBlue),
                        );
                      },
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('Get Directions'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Done'),
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

  void _showEmergencyCallModal(BuildContext context, String title, String number) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.emergencyRed.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_in_talk, color: AppColors.emergencyRed, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                'Connect to $title',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Toll-Free Emergency Number: $number',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Connecting emergency call to $number...'),
                            backgroundColor: AppColors.emergencyRed,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emergencyRed,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.call, size: 18),
                      label: Text('Dial $number'),
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
}
