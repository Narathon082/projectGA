import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class InOutCard extends StatelessWidget {
  final double vin;
  final double iin;
  final double pin;
  final double vout;
  final double iout;
  final double pout;

  const InOutCard({
    Key? key,
    required this.vin,
    required this.iin,
    required this.pin,
    required this.vout,
    required this.iout,
    required this.pout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horizontal_circle_outlined, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'REAL-TIME POWER FLOW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Left Column: Input (ขาเข้า)
              Expanded(
                child: _buildColumn(
                  title: 'ขาเข้า (Solar Input)',
                  icon: Icons.solar_power_rounded,
                  iconColor: Colors.amber,
                  volt: vin,
                  amp: iin,
                  watt: pin,
                ),
              ),
              Container(
                height: 90,
                width: 1,
                color: AppColors.divider,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              // Right Column: Output (ขาออก)
              Expanded(
                child: _buildColumn(
                  title: 'ขาออก (Battery Out)',
                  icon: Icons.battery_charging_full_rounded,
                  iconColor: Colors.green,
                  volt: vout,
                  amp: iout,
                  watt: pout,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColumn({
    required String title,
    required IconData icon,
    required Color iconColor,
    required double volt,
    required double amp,
    required double watt,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildMetricRow('กำลังไฟ', watt.toStringAsFixed(2), 'W', isBold: true),
        const SizedBox(height: 6),
        _buildMetricRow('แรงดันไฟ', volt.toStringAsFixed(2), 'V'),
        const SizedBox(height: 6),
        _buildMetricRow('กระแสไฟ', amp.toStringAsFixed(2), 'A'),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, String unit, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textSub, fontWeight: FontWeight.w500),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: isBold ? 14 : 12,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
