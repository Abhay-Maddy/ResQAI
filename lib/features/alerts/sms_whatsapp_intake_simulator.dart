import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/models/incident_model.dart';
import '../../data/repositories/incident_repository.dart';

class SmsWhatsappIntakeSimulator extends ConsumerStatefulWidget {
  const SmsWhatsappIntakeSimulator({super.key});

  @override
  ConsumerState<SmsWhatsappIntakeSimulator> createState() => _SmsWhatsappIntakeSimulatorState();
}

class _SmsWhatsappIntakeSimulatorState extends ConsumerState<SmsWhatsappIntakeSimulator> {
  final _phoneController = TextEditingController(text: '+91 98765 43210');
  final _messageController = TextEditingController(
    text: 'FLOOD HELP: 6 people including pregnant lady stuck on 1st floor water rising fast Yamuna Khadar Sector 4',
  );
  String _channel = 'WHATSAPP';

  void _simulateIntake() {
    final rawMessage = _messageController.text.trim();
    if (rawMessage.isEmpty) return;

    final newId = 'RQ-${(100 + ref.read(incidentsProvider).length + 1)}';

    // Automatic keyword parsing (Feature 4 & 16)
    final bool hasFlood = rawMessage.toLowerCase().contains('flood') || rawMessage.toLowerCase().contains('water');
    final bool hasPregnant = rawMessage.toLowerCase().contains('pregnant');
    final bool hasChildren = rawMessage.toLowerCase().contains('child') || rawMessage.toLowerCase().contains('kid');

    final vulnerable = <String>[];
    if (hasPregnant) vulnerable.add('Pregnant Individual');
    if (hasChildren) vulnerable.add('Children');

    final incomingIncident = IncidentModel(
      id: newId,
      title: 'Inbound $_channel Emergency: Sector 4',
      descriptionOriginal: rawMessage,
      descriptionTranslated: rawMessage,
      category: hasFlood ? IncidentCategory.flood : IncidentCategory.medical,
      latitude: 28.6140,
      longitude: 77.2095,
      address: 'Parsed Address: Yamuna Khadar Sector 4 (Inbound SMS/WhatsApp Gateway)',
      status: IncidentStatus.received,
      priorityScore: hasPregnant ? 94.0 : 82.0,
      priorityExplanation: 'Automated Twilio/WhatsApp webhook intake parser. Priority escalated due to vulnerable tags ($vulnerable).',
      vulnerableGroups: vulnerable,
      reporterPhoneMasked: '+91 98*** **210',
      reportedAt: DateTime.now(),
      source: _channel,
    );

    ref.read(incidentsProvider.notifier).addIncident(incomingIncident);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.verifiedGreen,
        content: Text('Simulated $_channel intake received! Ingested as $newId into Command Center queue.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mark_chat_unread, color: AppColors.primaryLight, size: 24),
                const SizedBox(width: 8),
                const Text('Inbound SMS & WhatsApp Gateway Simulator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'WHATSAPP', label: Text('WhatsApp', style: TextStyle(fontSize: 11))),
                    ButtonSegment(value: 'SMS', label: Text('SMS Gateway', style: TextStyle(fontSize: 11))),
                  ],
                  selected: {_channel},
                  onSelectionChanged: (set) => setState(() => _channel = set.first),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Demonstrates intake of low-bandwidth citizen emergency messages received via Twilio or WhatsApp Business webhook API.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Sender Number', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(labelText: 'Inbound Message Payload', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  icon: const Icon(Icons.send_and_archive, size: 16, color: Colors.white),
                  label: Text('Simulate Ingest via $_channel', style: const TextStyle(color: Colors.white)),
                  onPressed: _simulateIntake,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
