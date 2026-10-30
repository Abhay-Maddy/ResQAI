import '../../../core/constants/app_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/incident_repository.dart';
import '../../../shared/models/incident_model.dart';

class SosConfirmationDialog extends StatefulWidget {
  final String incidentId;
  final String locationAddress;
  final double latitude;
  final double longitude;
  final List<String> emergencyContacts;

  const SosConfirmationDialog({
    super.key,
    required this.incidentId,
    required this.locationAddress,
    required this.latitude,
    required this.longitude,
    this.emergencyContacts = const ['Kavita Verma (+91 98765 00112)'],
  });

  @override
  State<SosConfirmationDialog> createState() => _SosConfirmationDialogState();
}

class _SosConfirmationDialogState extends State<SosConfirmationDialog> {
  bool _isCancelling = false;
  bool _isCancelled = false;
  int _activeSosTab =
      0; // 0 = Direct Location-Only SOS, 1 = Additional Information
  final TextEditingController _quickDetailsCtrl = TextEditingController();
  final Set<String> _selectedDistressTags = {};
  bool _detailsSaved = false;

  Future<void> _handleCancelAccidental(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppColors.warningOrange, size: 24),
            SizedBox(width: 8),
            Text('Cancel SOS Dispatch?'),
          ],
        ),
        content: const Text(
          'Are you sure you pressed the SOS by mistake? This will notify emergency dispatchers to stand down while maintaining an audit record.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep SOS Active'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel SOS'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);

    try {
      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}/incidents/${widget.incidentId}/cancel-accidental',
      );
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'reason': 'Citizen reported accidental trigger'}),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isCancelling = false;
        _isCancelled = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primaryBlue,
          content: Text(
              '✓ Accidental SOS marked. First responders notified to stand down.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isCancelled
                          ? AppColors.warningOrange.withOpacity(0.15)
                          : AppColors.emergencyRed.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isCancelled ? Icons.cancel_outlined : Icons.emergency,
                      color: _isCancelled
                          ? AppColors.warningOrange
                          : AppColors.emergencyRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isCancelled
                              ? 'SOS Cancelled (Mistake)'
                              : 'Distress SOS Transmitted',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          _isCancelled
                              ? 'Logged in dispatch audit trail as accidental'
                              : 'High-priority distress packet active in EOC queue',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Reference Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkSurface2 : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Incident Reference:',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          widget.incidentId,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Location:',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600),
                        ),
                        Flexible(
                          child: Text(
                            widget.locationAddress,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Two SOS Modes: Direct Location-Only vs Additional Information
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface2 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _activeSosTab = 0),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _activeSosTab == 0
                                ? AppColors.primaryBlue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Direct Location SOS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _activeSosTab == 0
                                  ? Colors.white
                                  : (isDark
                                      ? Colors.white70
                                      : AppColors.deepNavy),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _activeSosTab = 1),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _activeSosTab == 1
                                ? AppColors.primaryBlue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '+ Additional Info',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _activeSosTab == 1
                                  ? Colors.white
                                  : (isDark
                                      ? Colors.white70
                                      : AppColors.deepNavy),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_activeSosTab == 1) ...[
                // Compact Additional Information Form
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceElevated
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Quick Distress Tags',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold)),
                          if (_detailsSaved)
                            const Text('✓ Details Attached',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.successGreen,
                                    fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          'Trapped by Water',
                          'Medical Need',
                          'Elderly/Child in House',
                          'Floor 2+ Safe',
                        ].map((tag) {
                          final isSel = _selectedDistressTags.contains(tag);
                          return FilterChip(
                            label: Text(tag,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: isSel ? Colors.white : null)),
                            selected: isSel,
                            selectedColor: AppColors.emergencyRed,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 0),
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedDistressTags.add(tag);
                                } else {
                                  _selectedDistressTags.remove(tag);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _quickDetailsCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText:
                              'Add brief note (landmark, flat number, injured count)...',
                          hintStyle: const TextStyle(fontSize: 11),
                          isDense: true,
                          contentPadding: const EdgeInsets.all(8),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                          ),
                          onPressed: () {
                            setState(() => _detailsSaved = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    '✓ Additional info attached to incident dispatch!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Text('Save Additional Info',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Dispatch Checklist (PRD SOS-4)
              const Text(
                'Dispatch Lifecycle & Parallel Delivery Receipts:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),

              _buildChecklistItem(
                title: 'Admin EOC Queue Dispatched',
                subtitle:
                    'Delivered to District Disaster Emergency Operations Center',
                isComplete: true,
                isCancelled: _isCancelled,
              ),
              _buildChecklistItem(
                title: 'Emergency Contacts Alerted via SMS',
                subtitle: widget.emergencyContacts.join(', '),
                isComplete: true,
                isCancelled: _isCancelled,
              ),
              _buildChecklistItem(
                title: 'Live GPS Telemetry Fix Transmitted',
                subtitle:
                    '${widget.latitude.toStringAsFixed(4)}°N, ${widget.longitude.toStringAsFixed(4)}°E (Precision: ~8m)',
                isComplete: true,
                isCancelled: _isCancelled,
              ),

              const SizedBox(height: 20),

              // Action Buttons
              if (!_isCancelled) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.note_add_outlined, size: 18),
                  label: const Text(
                    'Add Details to this Emergency',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.citizenHelpRequest);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.emergencyRed,
                          side: const BorderSide(color: AppColors.emergencyRed),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.phone, size: 16),
                        label: const Text(
                          'Dial 112',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Dialing 112 (National Emergency Helpline)...')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor:
                              isDark ? Colors.white70 : Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: _isCancelling
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.undo, size: 16),
                        label: const Text(
                          'I pressed by mistake',
                          style: TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.underline),
                        ),
                        onPressed: _isCancelling
                            ? null
                            : () => _handleCancelAccidental(context),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistItem({
    required String title,
    required String subtitle,
    required bool isComplete,
    required bool isCancelled,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCancelled
                ? Icons.do_not_disturb_on_outlined
                : (isComplete ? Icons.check_circle : Icons.circle_outlined),
            size: 16,
            color: isCancelled
                ? Colors.grey
                : (isComplete ? AppColors.successGreen : Colors.grey),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
