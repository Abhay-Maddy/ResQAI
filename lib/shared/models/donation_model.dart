class DonationModel {
  final String id;
  final String transactionRef;
  final String campaignId;
  final String campaignTitle;
  final String ngoName;
  final String ngoId;
  final double amount;
  final String donorName;
  final String donorEmail;
  final String donorPhone;
  final bool isAnonymous;
  final String paymentMethod; // 'UPI', 'NETBANKING', 'CARD', 'SANDBOX_SIMULATION'
  final String paymentStatus; // 'VERIFIED', 'PENDING', 'FAILED', 'REFUNDED'
  final DateTime timestamp;
  final bool taxExempt80GEligible;
  final String receiptNumber;
  final String auditVerificationHash;
  final bool isSandboxDemo;

  const DonationModel({
    required this.id,
    required this.transactionRef,
    required this.campaignId,
    required this.campaignTitle,
    required this.ngoName,
    required this.ngoId,
    required this.amount,
    required this.donorName,
    required this.donorEmail,
    required this.donorPhone,
    this.isAnonymous = false,
    this.paymentMethod = 'UPI',
    this.paymentStatus = 'VERIFIED',
    required this.timestamp,
    this.taxExempt80GEligible = true,
    required this.receiptNumber,
    required this.auditVerificationHash,
    this.isSandboxDemo = true,
  });

  DonationModel copyWith({
    String? id,
    String? transactionRef,
    String? campaignId,
    String? campaignTitle,
    String? ngoName,
    String? ngoId,
    double? amount,
    String? donorName,
    String? donorEmail,
    String? donorPhone,
    bool? isAnonymous,
    String? paymentMethod,
    String? paymentStatus,
    DateTime? timestamp,
    bool? taxExempt80GEligible,
    String? receiptNumber,
    String? auditVerificationHash,
    bool? isSandboxDemo,
  }) {
    return DonationModel(
      id: id ?? this.id,
      transactionRef: transactionRef ?? this.transactionRef,
      campaignId: campaignId ?? this.campaignId,
      campaignTitle: campaignTitle ?? this.campaignTitle,
      ngoName: ngoName ?? this.ngoName,
      ngoId: ngoId ?? this.ngoId,
      amount: amount ?? this.amount,
      donorName: donorName ?? this.donorName,
      donorEmail: donorEmail ?? this.donorEmail,
      donorPhone: donorPhone ?? this.donorPhone,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      timestamp: timestamp ?? this.timestamp,
      taxExempt80GEligible: taxExempt80GEligible ?? this.taxExempt80GEligible,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      auditVerificationHash: auditVerificationHash ?? this.auditVerificationHash,
      isSandboxDemo: isSandboxDemo ?? this.isSandboxDemo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionRef': transactionRef,
      'campaignId': campaignId,
      'campaignTitle': campaignTitle,
      'ngoName': ngoName,
      'ngoId': ngoId,
      'amount': amount,
      'donorName': isAnonymous ? 'Anonymous Citizen Donor' : donorName,
      'donorEmail': donorEmail,
      'donorPhone': donorPhone,
      'isAnonymous': isAnonymous,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'timestamp': timestamp.toIso8601String(),
      'taxExempt80GEligible': taxExempt80GEligible,
      'receiptNumber': receiptNumber,
      'auditVerificationHash': auditVerificationHash,
      'isSandboxDemo': isSandboxDemo,
    };
  }
}
