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
    SchoolProfile? school,
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
                _reportTitle('Fee Receipt', school),
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (school != null) pw.Text(_schoolSubtitle(school)),
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
                  [
                    'Approved concession',
                    _money.format(summary.approvedConcessions),
                  ],
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
              _reportTitle('Collection Report', state.school),
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(_schoolSubtitle(state.school)),
            pw.Text(
              'Generated on ${DateFormat.yMMMd().format(DateTime.now())}',
            ),
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
            pw.Text(
              'Recent Payments',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
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

  static Future<Uint8List> buildStudentRegisterReport({
    required AppState state,
    required List<Student> students,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            pw.Text(
              _reportTitle('Student Master Register', state.school),
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(_schoolSubtitle(state.school)),
            pw.Text(
              'Generated on ${DateFormat.yMMMd().format(DateTime.now())}',
            ),
            pw.SizedBox(height: 14),
            pw.TableHelper.fromTextArray(
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
              headers: [
                'Admission',
                'Student',
                'Class',
                'Section',
                'Category',
                'Guardian',
                'Phone',
                'Demand',
                'Concession',
                'Paid',
                'Pending',
                'Status',
              ],
              data: students.map((student) {
                final guardian = _guardianFor(state, student.guardianId);
                final summary = _studentSummary(state, student.id);
                return [
                  student.admissionNo,
                  student.name,
                  student.className,
                  student.section,
                  student.category,
                  guardian?.name ?? '-',
                  student.phone.isNotEmpty
                      ? student.phone
                      : guardian?.phone ?? '-',
                  _money.format(summary.totalDemand),
                  _money.format(summary.approvedConcessions),
                  _money.format(summary.paid),
                  _money.format(summary.pending),
                  student.status,
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );
    return pdf.save();
  }

  static Guardian? _guardianFor(AppState state, String guardianId) {
    for (final guardian in state.guardians) {
      if (guardian.id == guardianId) return guardian;
    }
    return null;
  }

  static StudentFinanceSummary _studentSummary(
    AppState state,
    String studentId,
  ) {
    final demands = state.feeDemands.where(
      (item) => item.studentId == studentId,
    );
    final concessions = state.concessions.where(
      (item) =>
          item.studentId == studentId &&
          item.status == ConcessionStatus.approved,
    );
    final payments = state.payments.where(
      (item) =>
          item.studentId == studentId && item.status == PaymentStatus.completed,
    );
    final totalDemand = demands.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final concessionTotal = concessions.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final paid = payments.fold<double>(0, (sum, item) => sum + item.amount);
    final pending = (totalDemand - concessionTotal - paid).clamp(
      0,
      double.infinity,
    );
    return StudentFinanceSummary(
      totalDemand: totalDemand,
      approvedConcessions: concessionTotal,
      paid: paid,
      pending: pending.toDouble(),
      overdueDays: 0,
    );
  }

  static String _reportTitle(String title, SchoolProfile? school) {
    if (school == null) return 'VidyaLedger $title';
    return '${school.name} - $title';
  }

  static String _schoolSubtitle(SchoolProfile school) {
    return '${school.board} | ${school.locationLabel} | Academic Year ${school.academicYear}';
  }
}

class _ReportStateAdapter {
  const _ReportStateAdapter(this.state);

  final AppState state;

  DashboardStats dashboardStats() {
    final totalDemand = state.feeDemands.fold<double>(
      0,
      (sum, demand) => sum + demand.amount,
    );
    final totalConcessions = state.concessions
        .where((item) => item.status == ConcessionStatus.approved)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final totalCollected = state.payments
        .where((payment) => payment.status == PaymentStatus.completed)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final totalPending = (totalDemand - totalConcessions - totalCollected)
        .clamp(0, double.infinity);
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
