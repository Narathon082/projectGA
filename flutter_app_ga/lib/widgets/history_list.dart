import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class HistoryList extends StatelessWidget {
  final List<String> dates;
  final String? selectedDate;
  final ValueChanged<String> onDateSelected;

  const HistoryList({
    super.key,
    required this.dates,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (dates.isEmpty) {
       return Center(child: Text("No history data", style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      itemCount: dates.length,
      itemBuilder: (context, i) {
        final date = dates[i];
        final isSelected = date == (selectedDate ?? (dates.isNotEmpty ? dates.first : ''));
        final parts = date.split('-');
        final formattedDate = parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : date;
        return GestureDetector(
          onTap: () => onDateSelected(date),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryBg : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: isSelected ? AppColors.primary : AppColors.textSub, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      formattedDate, 
                      style: TextStyle(
                        fontSize: 15, 
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, 
                        color: isSelected ? AppColors.primary : AppColors.textDark
                      )
                    ),
                  ],
                ),
                Icon(Icons.chevron_right, color: isSelected ? AppColors.primary : AppColors.textMuted),
              ]
            )
          )
        );
      }
    );
  }
}
