import 'package:flutter/material.dart';
import 'constants/app_colors.dart';

class InOutPage extends StatelessWidget {
  final double vin;
  final double iin;
  final double pin;
  final double vout;
  final double iout;
  final double pout;

  const InOutPage({
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
    // Calculate charging efficiency safely
    final double efficiency = pin > 0 ? (pout / pin) * 100 : 0.0;
    final double loss = pin > pout ? pin - pout : 0.0;
    final double constrainedEfficiency = efficiency.clamp(0.0, 100.0);

    // Determine charging status based on power and voltage
    String chargingStatus = 'ระบบไม่ทำงาน';
    Color statusColor = AppColors.textMuted;
    IconData statusIcon = Icons.stop_circle_rounded;

    if (pin > 0.5) {
      if (efficiency > 90) {
        chargingStatus = 'กำลังชาร์จประสิทธิภาพสูง (Bulk)';
        statusColor = Colors.green;
        statusIcon = Icons.bolt_rounded;
      } else if (efficiency > 70) {
        chargingStatus = 'กำลังชาร์จปกติ (Absorption)';
        statusColor = AppColors.primary;
        statusIcon = Icons.battery_charging_full_rounded;
      } else {
        chargingStatus = 'ประคองประจุชาร์จ (Float)';
        statusColor = Colors.amber;
        statusIcon = Icons.battery_saver_rounded;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Status Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    chargingStatus,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Realtime',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Efficiency Gauge Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Text(
                  'ประสิทธิภาพการประจุไฟ (Charging Efficiency)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSub,
                  ),
                ),
                const SizedBox(height: 24),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: constrainedEfficiency / 100,
                        strokeWidth: 12,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          constrainedEfficiency > 85
                              ? Colors.green
                              : constrainedEfficiency > 60
                                  ? AppColors.primary
                                  : Colors.amber,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${efficiency.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Efficiency',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMiniMetric('กำลังไฟสูญเสีย', '${loss.toStringAsFixed(2)} W', Icons.trending_down_rounded, Colors.red),
                    Container(width: 1, height: 30, color: AppColors.divider),
                    _buildMiniMetric('กำลังไฟฝั่งจ่าย', '${pout.toStringAsFixed(2)} W', Icons.bolt_rounded, Colors.green),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Side-by-Side Detailed Breakdown
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Solar Input Details
              Expanded(
                child: _buildDetailsCard(
                  title: 'แผงโซลาร์ (Solar Input)',
                  icon: Icons.solar_power_rounded,
                  headerBgColor: Colors.amber.shade700,
                  volt: vin,
                  amp: iin,
                  watt: pin,
                ),
              ),
              const SizedBox(width: 12),
              // Battery Output Details
              Expanded(
                child: _buildDetailsCard(
                  title: 'แบตเตอรี่ (Battery Output)',
                  icon: Icons.battery_charging_full_rounded,
                  headerBgColor: Colors.green.shade600,
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

  Widget _buildMiniMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard({
    required String title,
    required IconData icon,
    required Color headerBgColor,
    required double volt,
    required double amp,
    required double watt,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: headerBgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildCardParam('กำลังวัตต์', watt.toStringAsFixed(2), 'W', isMain: true),
                const Divider(height: 16, thickness: 0.5),
                _buildCardParam('แรงดันไฟฟ้า', volt.toStringAsFixed(2), 'V'),
                const SizedBox(height: 8),
                _buildCardParam('กระแสไฟฟ้า', amp.toStringAsFixed(2), 'A'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardParam(String label, String value, String unit, {bool isMain = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSub,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: isMain ? 15 : 12,
                fontWeight: isMain ? FontWeight.w800 : FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: TextStyle(
                fontSize: 8,
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
