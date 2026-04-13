import 'package:flutter/material.dart';
import '../employee/expances/expance_history.dart';
import 'employee/manage_employee.dart';
import 'manage_packages.dart';
import 'manage_services.dart'; // ← Packages screen (baad mein banayenge)

class AppDrawer extends StatelessWidget {
  final String selectedFilter;
  final String todayDate;
  final String currentMonth;
  final DateTimeRange? customRange;

  const AppDrawer({
    super.key,
    required this.selectedFilter,
    required this.todayDate,
    required this.currentMonth,
    this.customRange,
  });

  static const Color kGoldPrimary = Color(0xFFD4AF37);
  static const Color kGoldDark = Color(0xFFAA8C2C);
  static const Color kGoldLight = Color(0xFFF8E9B0);
  static const Color kCharcoal = Color(0xFF1F1F1F);
  static const Color kBg = Color(0xFFFDFAF3);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: kBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                color: kCharcoal,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: kGoldPrimary.withValues(alpha: 0.2),
                    child: const Icon(Icons.person_rounded,
                        color: kGoldPrimary, size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Admin Panel",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Barber Pro",
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Menu Items ──
            _drawerItem(
              context,
              icon: Icons.people_alt_rounded,
              label: "Staff",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ManageEmployees()),
                );
              },
            ),
            _drawerItem(
              context,
              icon: Icons.content_cut_rounded,
              label: "Services",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ManageServices()),
                );
              },
            ),
            _drawerItem(
              context,
              icon: Icons.receipt_long_rounded,
              label: "Expenses",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExpenseHistoryScreen(
                      filterType: selectedFilter,
                      todayDate: todayDate,
                      currentMonth: currentMonth,
                      customRange: customRange,
                    ),
                  ),
                );
              },
            ),

            // ── Divider ──
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: Divider(
                  color: kGoldPrimary.withValues(alpha: 0.2), thickness: 1),
            ),

            // ── Packages ──
            _drawerItem(
              context,
              icon: Icons.inventory_2_rounded,
              label: "Packages",
              isHighlighted: true,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ManagePackages()),
                );
              },
            ),

            const Spacer(),

            // ── Version ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Barber Pro v1.0",
                style: TextStyle(
                    color: kCharcoal.withValues(alpha: 0.3),
                    fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
        bool isHighlighted = false,
      }) {
    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isHighlighted
              ? kGoldPrimary.withValues(alpha: 0.15)
              : kGoldLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isHighlighted ? kGoldDark : kCharcoal,
          size: 20,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight:
          isHighlighted ? FontWeight.bold : FontWeight.w500,
          color: isHighlighted ? kGoldDark : kCharcoal,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isHighlighted
            ? kGoldDark.withValues(alpha: 0.5)
            : kCharcoal.withValues(alpha: 0.3),
        size: 18,
      ),
      onTap: onTap,
    );
  }
}