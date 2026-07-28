import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import 'common.dart';

class ReminderDialog extends ConsumerStatefulWidget {
  const ReminderDialog({
    required this.student,
    this.guardian,
    this.pendingAmount = 0,
    super.key,
  });

  final Student student;
  final Guardian? guardian;
  final double pendingAmount;

  @override
  ConsumerState<ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends ConsumerState<ReminderDialog> {
  ReminderChannel channel = ReminderChannel.whatsapp;
  ReminderTemplateType templateType = ReminderTemplateType.dueReminder;
  late TextEditingController messageController;

  @override
  void initState() {
    super.initState();
    messageController = TextEditingController(
      text: _generateTemplateText(ReminderTemplateType.dueReminder),
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  String _generateTemplateText(ReminderTemplateType type) {
    final guardianName = widget.guardian?.name ?? 'Parent';
    final studentName = widget.student.name;
    final amount = moneyFormat.format(
      widget.pendingAmount > 0 ? widget.pendingAmount : 4000,
    );
    final schoolName = ref.read(appControllerProvider).school.name;
    final dateStr = DateFormat(
      'dd MMM yyyy',
    ).format(DateTime.now().add(const Duration(days: 7)));

    return switch (type) {
      ReminderTemplateType.dueReminder =>
        'Dear $guardianName,\n\nThis is a friendly fee reminder from $schoolName for $studentName. An outstanding fee of $amount is due by $dateStr.\n\nYou can pay instantly via UPI: upi://pay?pa=vidyaledger.demo@upi&pn=${Uri.encodeComponent(schoolName)}&am=${widget.pendingAmount > 0 ? widget.pendingAmount : 4000}\n\nThank you,\nAccount Office, $schoolName',
      ReminderTemplateType.defaulterWarning =>
        'URGENT FEE NOTICE - $schoolName\n\nDear $guardianName,\n\nThe fee balance of $amount for $studentName is overdue. Kindly settle the payment immediately to avoid late fees or ledger hold.\n\nUPI Payment Link: upi://pay?pa=vidyaledger.demo@upi&pn=${Uri.encodeComponent(schoolName)}&am=${widget.pendingAmount > 0 ? widget.pendingAmount : 4000}\n\nContact: Office Desk, $schoolName',
      ReminderTemplateType.receiptConfirmation =>
        'PAYMENT RECEIVED ACKNOWLEDGMENT - $schoolName\n\nDear $guardianName,\n\nWe have received your payment for $studentName. Thank you for your prompt transaction. You can view your receipt on VidyaLedger portal.\n\nRegards,\n$schoolName',
      ReminderTemplateType.custom =>
        'Dear $guardianName,\n\nRegarding $studentName\'s fee balance ($amount) at $schoolName.\n\nRegards,\nAccount Office',
    };
  }

  void _onTemplateChanged(ReminderTemplateType type) {
    setState(() {
      templateType = type;
      messageController.text = _generateTemplateText(type);
    });
  }

  void _launchAndRecord() {
    final message = messageController.text;

    // Record reminder in AppController state
    ref
        .read(appControllerProvider.notifier)
        .sendReminder(
          studentId: widget.student.id,
          channel: channel,
          templateType: templateType,
          message: message,
        );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Recorded ${channel.label} reminder for ${widget.student.name} and launched messenger.',
          ),
          backgroundColor: const Color(0xFF0F766E),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final guardianName = widget.guardian?.name ?? 'Guardian';
    final guardianPhone = widget.guardian?.phone ?? widget.student.phone;
    final state = ref.watch(appControllerProvider);
    final previousLogs = state.reminderLogs
        .where((l) => l.studentId == widget.student.id)
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: channel == ReminderChannel.whatsapp
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      channel == ReminderChannel.whatsapp
                          ? Icons.chat_bubble_outline
                          : Icons.sms_outlined,
                      color: channel == ReminderChannel.whatsapp
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Send Fee Reminder',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'To $guardianName ($guardianPhone) for ${widget.student.name}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<ReminderChannel>(
                      segments: const [
                        ButtonSegment(
                          value: ReminderChannel.whatsapp,
                          label: Text('WhatsApp'),
                          icon: Icon(Icons.send_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: ReminderChannel.sms,
                          label: Text('SMS'),
                          icon: Icon(Icons.sms, size: 16),
                        ),
                      ],
                      selected: {channel},
                      onSelectionChanged: (set) =>
                          setState(() => channel = set.first),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<ReminderTemplateType>(
                initialValue: templateType,
                decoration: const InputDecoration(
                  labelText: 'Select Reminder Template',
                  prefixIcon: Icon(Icons.article_outlined),
                ),
                items: ReminderTemplateType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) _onTemplateChanged(val);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: messageController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Message Body (Editable Preview)',
                  alignLabelWithHint: true,
                ),
              ),
              if (previousLogs.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Recent Reminder Log:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.history,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Last sent ${DateFormat('dd MMM hh:mm a').format(previousLogs.first.sentAt)} via ${previousLogs.first.channel.label}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _launchAndRecord,
                    style: FilledButton.styleFrom(
                      backgroundColor: channel == ReminderChannel.whatsapp
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF2563EB),
                    ),
                    icon: Icon(
                      channel == ReminderChannel.whatsapp
                          ? Icons.chat_bubble_outline
                          : Icons.sms,
                    ),
                    label: Text('Send via ${channel.label}'),
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
