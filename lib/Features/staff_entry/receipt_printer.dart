import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ═══════════════════════════════════════════════════════════════
// 🖨️ RECEIPT PRINTER UTILITY
// Yeh file sirf printing ke liye hai - alag aur clean
// ═══════════════════════════════════════════════════════════════

class ReceiptPrinter {
  /// Normal services ka receipt print karta hai
  static Future<void> printReceipt({
    required String staffName,
    String? clientName,                    // ← NEW: Client Name (Optional)
    required List<Map<String, dynamic>> services,
    required double totalAmount,
    String? packageName,
    bool isPackage = false,
    DateTime? date,
  }) async {
    final pdf = pw.Document();
    final printDate = date ?? DateTime.now();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity),
        margin: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ─── Header ───
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      "SALON RECEIPT",
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      "Thank you for visiting us!",
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),

              // ─── Divider ───
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 6),

              // ─── Info Section ───
              if (clientName != null && clientName.isNotEmpty)
                _buildInfoRow("Client", clientName),   // ← Client Name Added Here

              _buildInfoRow("Date", DateFormat('dd MMM yyyy').format(printDate)),
              _buildInfoRow("Time", DateFormat('hh:mm a').format(DateTime.now())),
              _buildInfoRow("Staff", staffName),

              if (packageName != null && packageName.isNotEmpty)
                _buildInfoRow("Package", packageName),

              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.SizedBox(height: 4),

              // ─── Services Header ───
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("SERVICE", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.grey700)),
                  pw.Text("PRICE", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5, color: PdfColors.grey200),

              // ─── Services List ───
              ...services.map((s) {
                final String name = s['name']?.toString() ?? 'Unknown Service';
                final double price = (s['price'] as num?)?.toDouble() ?? 0.0;
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(child: pw.Text(name, style: const pw.TextStyle(fontSize: 9))),
                      pw.Text("Rs ${price.toStringAsFixed(0)}", style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 4),

              // ─── Total ───
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("TOTAL", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text("Rs ${totalAmount.toStringAsFixed(0)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                ],
              ),

              pw.SizedBox(height: 12),

              // ─── Footer ───
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                    pw.SizedBox(height: 4),
                    pw.Text("Thank You! Please Visit Again", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                    pw.SizedBox(height: 2),
                    pw.Text(DateFormat('dd MMM yyyy | hh:mm a').format(DateTime.now()), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  /// Package receipt - multiple staff ke saath (No Change)
  static Future<void> printPackageReceipt({
    required String packageName,
    required List<Map<String, dynamic>> services,
    required double originalPrice,
    required double discountedPrice,
    required Map<String, String> serviceToStaffMap,
    DateTime? date,
  }) async {
    final pdf = pw.Document();
    final printDate = date ?? DateTime.now();
    final int discountPct = originalPrice > 0
        ? (((originalPrice - discountedPrice) / originalPrice) * 100).round()
        : 0;

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity),
        margin: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ─── Header ───
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      "SALON RECEIPT",
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text("Package Receipt", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 6),

              // ─── Info ───
              _buildInfoRow("Date", DateFormat('dd MMM yyyy').format(printDate)),
              _buildInfoRow("Time", DateFormat('hh:mm a').format(DateTime.now())),
              _buildInfoRow("Package", packageName),
              if (discountPct > 0) _buildInfoRow("Discount", "$discountPct% OFF"),

              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.SizedBox(height: 4),

              // ─── Services + Staff ───
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("SERVICE", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.grey700)),
                  pw.Text("STAFF", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5, color: PdfColors.grey200),

              ...services.map((s) {
                final String serviceName = s['name']?.toString() ?? s.toString();
                final String assignedStaff = serviceToStaffMap[serviceName] ?? 'Unassigned';
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(child: pw.Text(serviceName, style: const pw.TextStyle(fontSize: 9))),
                      pw.Text(assignedStaff, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.SizedBox(height: 4),

              // ─── Price Summary ───
              if (originalPrice > 0 && originalPrice != discountedPrice)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Original", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    pw.Text("Rs ${originalPrice.toStringAsFixed(0)}", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
              if (discountPct > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Discount ($discountPct%)", style: const pw.TextStyle(fontSize: 9, color: PdfColors.green)),
                    pw.Text("- Rs ${(originalPrice - discountedPrice).toStringAsFixed(0)}", style: const pw.TextStyle(fontSize: 9, color: PdfColors.green)),
                  ],
                ),

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 4),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("TOTAL", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text("Rs ${discountedPrice.toStringAsFixed(0)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                ],
              ),

              pw.SizedBox(height: 12),

              // ─── Footer ───
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                    pw.SizedBox(height: 4),
                    pw.Text("Thank You! Please Visit Again", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                    pw.SizedBox(height: 2),
                    pw.Text(DateFormat('dd MMM yyyy | hh:mm a').format(DateTime.now()), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // ─── Helper: Info Row ───
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 55,
            child: pw.Text("$label:", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          ),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}