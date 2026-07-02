import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class PowerCard extends StatelessWidget {
  final String watt;
  final String amp;
  final String dateStr;
  final bool dayView;

  const PowerCard({
    super.key,
    required this.watt,
    required this.amp,
    required this.dateStr,
    required this.dayView,
  });

  @override
  Widget build(BuildContext context) {
    final parts = dateStr.split('-');
    final formattedDate = parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : dateStr;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayView ? 'MAX/CURRENT POWER' : 'WEEK MAX POWER',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            dayView ? formattedDate : 'Last 7 Days',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    watt,
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Watt',
                      style: TextStyle(fontSize: 16, color: AppColors.textSub),
                    ),
                  ),
                ],
              ),
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardBorder, width: 1.5),
                ),
                child: Icon(Icons.bolt_rounded, color: AppColors.textSub, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
