import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/repositories/auth_repository.dart';
import '../../shared/models/user_model.dart';

class AdminVerificationModal extends ConsumerWidget {
  const AdminVerificationModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const AdminVerificationModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingList = ref.watch(pendingApprovalsProvider);
    final pendingCount = pendingList.where((u) => u.verificationStatus == 'PENDING').length;

    return Dialog(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.admin_panel_settings, color: Colors.purpleAccent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DDMA & State Admin Authorization Queue',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          '$pendingCount privileged role applications awaiting credential verification',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Security Policy Alert
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.security, size: 18, color: AppColors.primaryLight),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Governance Mandate (Master Prompt Part 4): Privileged accounts (NGO, Govt, Medical, Rescue) require verified registration numbers (NGO DARPAN, MCI/NMC, Govt ID) before access to alert dispatch or funding approvals is un-gated.',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Applications List
              Expanded(
                child: pendingList.isEmpty
                    ? const Center(
                        child: Text('No applications in queue.', style: TextStyle(color: Colors.grey)),
                      )
                    : ListView.builder(
                        itemCount: pendingList.length,
                        itemBuilder: (context, index) {
                          final user = pendingList[index];
                          return _buildApplicantCard(context, ref, user);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApplicantCard(BuildContext context, WidgetRef ref, UserModel user) {
    Color statusColor;
    if (user.verificationStatus == 'APPROVED') {
      statusColor = AppColors.verifiedGreen;
    } else if (user.verificationStatus == 'REJECTED') {
      statusColor = AppColors.criticalRed;
    } else {
      statusColor = AppColors.warningAmber;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.darkSurfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Icon(_getRoleIcon(user.role), color: AppColors.primaryLight, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(user.role.title, style: const TextStyle(color: AppColors.primaryLight, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      Text(
                        'Org: ${user.organization ?? user.badgeOrJurisdiction} • Reg/Govt ID: ${user.regNumber ?? "Pending Documentation"}',
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    user.verificationStatus,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.email, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(user.email, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(width: 12),
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Jurisdiction: ${user.serviceArea ?? user.badgeOrJurisdiction}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (user.skills.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: user.skills.map((s) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(s, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                  );
                }).toList(),
              ),
            ],
            const Divider(height: 20, color: AppColors.darkBorder),

            // Actions for Pending Users
            if (user.verificationStatus == 'PENDING')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.criticalRed,
                      side: const BorderSide(color: AppColors.criticalRed),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 14),
                    label: const Text('Reject Application', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      ref.read(pendingApprovalsProvider.notifier).rejectUser(user.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Application for ${user.name} rejected.')),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.verifiedGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.verified, size: 14),
                    label: const Text('Approve & Authorize Role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      ref.read(pendingApprovalsProvider.notifier).approveUser(user.id);
                      // If active user is this user, update active user state
                      final activeUser = ref.read(authProvider);
                      if (activeUser != null && activeUser.id == user.id) {
                        ref.read(authProvider.notifier).updateProfile(
                              activeUser.copyWith(isVerified: true, verificationStatus: 'APPROVED'),
                            );
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.verifiedGreen,
                          content: Text('✓ ${user.name} officially verified and authorized as ${user.role.title}!'),
                        ),
                      );
                    },
                  ),
                ],
              )
            else
              Text(
                'Action recorded: Marked as ${user.verificationStatus} by SDMA Authority Desk',
                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.citizen:
        return Icons.person;
      case UserRole.volunteer:
        return Icons.handshake;
      case UserRole.ngoLead:
        return Icons.volunteer_activism;
      case UserRole.govtOfficial:
        return Icons.account_balance;
      case UserRole.doctor:
        return Icons.local_hospital;
      case UserRole.rescueTeam:
        return Icons.fire_truck;
      case UserRole.incidentCommander:
        return Icons.military_tech;
      case UserRole.fieldResponder:
        return Icons.emergency;
      case UserRole.admin:
        return Icons.admin_panel_settings;
      default:
        return Icons.badge;
    }
  }
}
