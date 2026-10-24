import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/donation_model.dart';

final donationsProvider = StateNotifierProvider<DonationsNotifier, List<DonationModel>>((ref) {
  return DonationsNotifier();
});

class DonationsNotifier extends StateNotifier<List<DonationModel>> {
  DonationsNotifier() : super(_initialDonations());

  static List<DonationModel> _initialDonations() {
    final now = DateTime.now();
    return [
      DonationModel(
        id: 'DON-2026-901',
        transactionRef: 'UPI-TXN-88192019',
        campaignId: 'CMP-GOONJ-01',
        campaignTitle: 'Yamuna Monsoon Flood Emergency Relief Kits',
        ngoName: 'Goonj Disaster Relief Wing',
        ngoId: 'NGO-DARPAN-DL-024810',
        amount: 5000.0,
        donorName: 'Rahul Verma',
        donorEmail: 'rahul.verma@example.com',
        donorPhone: '+91 98111 22334',
        isAnonymous: false,
        paymentMethod: 'UPI (Google Pay / PhonePe)',
        paymentStatus: 'VERIFIED',
        timestamp: now.subtract(const Duration(hours: 3)),
        taxExempt80GEligible: true,
        receiptNumber: '80G-DEL-2026-00412',
        auditVerificationHash: 'SHA256:7a8b9c0d1e2f3a4b5c6d7e8f',
        isSandboxDemo: true,
      ),
      DonationModel(
        id: 'DON-2026-902',
        transactionRef: 'NETBANK-TXN-1102934',
        campaignId: 'CMP-GOONJ-01',
        campaignTitle: 'Yamuna Monsoon Flood Emergency Relief Kits',
        ngoName: 'Goonj Disaster Relief Wing',
        ngoId: 'NGO-DARPAN-DL-024810',
        amount: 25000.0,
        donorName: 'Sunita Mehra (CSR Fund)',
        donorEmail: 'sunita.csr@apexcorp.org',
        donorPhone: '+91 98222 33445',
        isAnonymous: false,
        paymentMethod: 'NetBanking (HDFC Bank)',
        paymentStatus: 'VERIFIED',
        timestamp: now.subtract(const Duration(hours: 18)),
        taxExempt80GEligible: true,
        receiptNumber: '80G-DEL-2026-00411',
        auditVerificationHash: 'SHA256:1a2b3c4d5e6f7a8b9c0d1e2f',
        isSandboxDemo: true,
      ),
      DonationModel(
        id: 'DON-2026-903',
        transactionRef: 'UPI-TXN-44910239',
        campaignId: 'CMP-GOONJ-02',
        campaignTitle: 'Safe Drinking Water & Mobile RO Filtration Deployment',
        ngoName: 'Goonj Disaster Relief Wing',
        ngoId: 'NGO-DARPAN-DL-024810',
        amount: 2100.0,
        donorName: 'Anonymous Citizen',
        donorEmail: 'citizen@resqai.org',
        donorPhone: '+91 98*** **210',
        isAnonymous: true,
        paymentMethod: 'UPI (Paytm)',
        paymentStatus: 'VERIFIED',
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        taxExempt80GEligible: true,
        receiptNumber: '80G-DEL-2026-00409',
        auditVerificationHash: 'SHA256:3c4d5e6f7a8b9c0d1e2f3a4b',
        isSandboxDemo: true,
      ),
    ];
  }

  DonationModel createVerifiedDonation({
    required String campaignId,
    required String campaignTitle,
    required String ngoName,
    required String ngoId,
    required double amount,
    required String donorName,
    required String donorEmail,
    required String donorPhone,
    required bool isAnonymous,
    required String paymentMethod,
  }) {
    final randId = Random().nextInt(9000) + 1000;
    final now = DateTime.now();
    final newDonation = DonationModel(
      id: 'DON-${now.year}-$randId',
      transactionRef: 'TXN-RAZORPAY-SANDBOX-${now.millisecondsSinceEpoch}',
      campaignId: campaignId,
      campaignTitle: campaignTitle,
      ngoName: ngoName,
      ngoId: ngoId,
      amount: amount,
      donorName: isAnonymous ? 'Anonymous Citizen Donor' : donorName,
      donorEmail: donorEmail,
      donorPhone: donorPhone,
      isAnonymous: isAnonymous,
      paymentMethod: paymentMethod,
      paymentStatus: 'VERIFIED',
      timestamp: now,
      taxExempt80GEligible: true,
      receiptNumber: '80G-RESQAI-${now.year}-$randId',
      auditVerificationHash: 'SHA256:${now.millisecondsSinceEpoch.toRadixString(16)}8f4c2e',
      isSandboxDemo: true,
    );

    state = [newDonation, ...state];
    return newDonation;
  }
}
