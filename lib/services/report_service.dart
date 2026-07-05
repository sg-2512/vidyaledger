import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/models.dart';
import '../providers/app_state.dart';

class ReportService {
  static final _money = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 0,
  );

  static Future<Uint8List> buildReceiptPdf({
    required Payment payment,
    required Student student,
    required StudentFinanceSummary summary,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'VidyaLedger Fee Receipt',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 12),
              pw.Text('Receipt No: ${payment.receiptNo}'),
              pw.Text('Date: ${DateFormat.yMMMd().format(payment.date)}'),
              pw.Divider(),
              pw.Text('Student: ${student.name} (${student.admissionNo})'),
              pw.Text('Class: ${student.classLabel}'),
              pw.Text('Payment Mode: ${payment.mode.label}'),
              pw.Text('Reference: ${payment.referenceNo}'),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headers: ['Particulars', 'Amount'],
                data: [
                  ['Amount paid', _money.format(payment.amount)],
                  ['Total demand', _money.format(summary.totalDemand)],
                  ['Approved concession', _money.format(summary.approvedConcessions)],
                  ['Balance after receipt', _money.format(summary.pending)],
                ],
              ),
              pw.Spacer(),
              pw.Text(
                'This is a system-generated demo receipt for hackathon evaluation.',
                style: const pw.TextStyle(color: PdfColors.grey700),
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  static Future<Uint8List> buildCollectionReport(AppState state) async {
    final pdf = pw.Document();
    final controllerState = _ReportStateAdapter(state);
    final stats = controllerState.dashboardStats();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            pw.Text(
              'VidyaLedger Collection Report',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('Generated on ${DateFormat.yMMMd().format(DateTime.now())}'),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: ['Metric', 'Value'],
              data: [
                ['Total Demand', _money.format(stats.totalDemand)],
                ['Collected', _money.format(stats.totalCollected)],
                ['Pending', _money.format(stats.totalPending)],
                ['Approved Concessions', _money.format(stats.totalConcessions)],
                ['Defaulters', stats.defaulters.toString()],
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text('Recent Payments', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.TableHelper.fromTextArray(
              headers: ['Receipt', 'Mode', 'Status', 'Amount'],
              data: state.payments
                  .map(
                    (payment) => [
                      payment.receiptNo,
                      payment.mode.label,
                      payment.status.label,
                      _money.format(payment.amount),
                    ],
                  )
                  .toList(),
            ),
          ];
        },
      ),
    );
    return pdf.save();
  }
}

class _ReportStateAdapter {
  const _ReportStateAdapter(this.state);

  final AppState state;

  DashboardStats dashboardStats() {
    final totalDemand =
        state.feeDemands.fold<double>(0, (sum, demand) => sum + demand.amount);
    final totalConcessions = state.concessions
        .where((item) => item.status == ConcessionStatus.approved)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final totalCollected = state.payments
        .where((payment) => payment.status == PaymentStatus.completed)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final totalPending =
        (totalDemand - totalConcessions - totalCollected).clamp(0, double.infinity);
    return DashboardStats(
      totalDemand: totalDemand,
      totalCollected: totalCollected,
      totalPending: totalPending.toDouble(),
      totalConcessions: totalConcessions,
      defaulters: 0,
      collectionRate: totalDemand == 0 ? 0 : totalCollected / totalDemand,
    );
  }
}
