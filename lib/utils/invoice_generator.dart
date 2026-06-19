import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/booking_model.dart';
import '../models/product_model.dart';

class InvoiceGenerator {
  static final _currencyFmt = NumberFormat('#,##0.00', 'en_IN');
  static final _dateFmt = DateFormat('dd MMM yyyy, hh:mm a');
  static final _dateOnly = DateFormat('dd MMM yyyy');

  static String _fmt(double v) => '₹${_currencyFmt.format(v)}';

  // ── Booking Invoice ──────────────────────────────────────────────────

  static Future<Uint8List> generateBookingInvoice(BookingModel booking) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader('INVOICE', booking.bookingNumber),
            pw.SizedBox(height: 24),
            _buildLabelValue('Date', _dateFmt.format(booking.createdAt.toLocal())),
            _buildLabelValue('Booking ID', booking.bookingNumber),
            _buildLabelValue('Service', booking.serviceId?.serviceName ?? '-'),
            _buildLabelValue('Category', booking.categoryId?.categoryName ?? '-'),
            _buildLabelValue('Provider', booking.providerId?.fullName ?? 'Assigned by HireBuddy'),
            _buildLabelValue(
              'Scheduled',
              '${_dateOnly.format(booking.scheduledDateTime.toLocal())} · ${booking.scheduledTimeSlot ?? ""}',
            ),
            if (booking.addressSnapshot != null)
              _buildLabelValue('Service Address', booking.addressSnapshot!.fullAddress),
            pw.SizedBox(height: 24),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 16),
            _buildSectionTitle('PRICING BREAKDOWN'),
            pw.SizedBox(height: 12),
            _buildPricingTable([
              ('Service Price', booking.pricing?.servicePrice ?? 0),
              ('Tax', booking.pricing?.tax ?? 0),
            ], booking.pricing?.totalAmount ?? 0),
            pw.SizedBox(height: 24),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 16),
            _buildLabelValue(
              'Payment Method',
              _paymentLabel(booking.payment?.method ?? 'cod'),
            ),
            _buildLabelValue(
              'Payment Status',
              (booking.payment?.status ?? 'pending').toUpperCase(),
            ),
            pw.Spacer(),
            _buildFooter(),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // ── Product Order Receipt ────────────────────────────────────────────

  static Future<Uint8List> generateOrderReceipt(ProductOrder order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader('RECEIPT', order.orderNumber),
            pw.SizedBox(height: 24),
            _buildLabelValue('Date', _dateFmt.format(order.createdAt.toLocal())),
            _buildLabelValue('Order ID', order.orderNumber),
            if (order.deliveryAddress != null)
              _buildLabelValue('Delivery Address', order.deliveryAddress!.display),
            pw.SizedBox(height: 24),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 16),
            _buildSectionTitle('ITEMS'),
            pw.SizedBox(height: 12),
            _buildItemsTable(order.items),
            pw.SizedBox(height: 16),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 16),
            _buildSectionTitle('PRICING SUMMARY'),
            pw.SizedBox(height: 12),
            _buildPricingTable([
              ('Subtotal', order.pricing.subtotal),
              ('Delivery Charge', order.pricing.deliveryCharge),
            ], order.pricing.totalAmount),
            pw.SizedBox(height: 24),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 16),
            _buildLabelValue('Payment Method', _paymentLabel(order.paymentMethod)),
            _buildLabelValue('Payment Status', order.paymentStatus.toUpperCase()),
            pw.Spacer(),
            _buildFooter(),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // ── Shared widgets ───────────────────────────────────────────────────

  static pw.Widget _buildHeader(String type, String refNumber) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'HireBuddy',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Home Services & Products',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              type,
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '#$refNumber',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildLabelValue(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.grey600,
        letterSpacing: 1.2,
      ),
    );
  }

  static pw.Widget _buildItemsTable(List<OrderItem> items) {
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FixedColumnWidth(50),
        2: const pw.FixedColumnWidth(70),
        3: const pw.FixedColumnWidth(70),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _tableCell('Item', bold: true),
            _tableCell('Qty', bold: true),
            _tableCell('Unit Price', bold: true),
            _tableCell('Total', bold: true),
          ],
        ),
        ...items.map((item) => pw.TableRow(
              children: [
                _tableCell(item.productName),
                _tableCell('${item.quantity}'),
                _tableCell(_fmt(item.pricePerUnit)),
                _tableCell(_fmt(item.totalPrice)),
              ],
            )),
      ],
    );
  }

  static pw.Widget _tableCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildPricingTable(
    List<(String, double)> lines,
    double total,
  ) {
    return pw.Column(
      children: [
        ...lines.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(line.$1, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                pw.Text(_fmt(line.$2), style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('TOTAL', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.Text(_fmt(total), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 8),
        pw.Text(
          'Thank you for using HireBuddy!',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'For support, contact us through the app.',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey400),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  static String _paymentLabel(String method) {
    switch (method) {
      case 'cod':
        return 'Cash on Delivery';
      case 'online':
        return 'Online Payment';
      default:
        return method.toUpperCase();
    }
  }
}
