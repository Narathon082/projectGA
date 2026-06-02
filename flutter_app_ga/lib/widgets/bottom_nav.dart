import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class BottomNav extends StatelessWidget {
  final int navIndex;
  final ValueChanged<int> onNavChanged;

  const BottomNav({
    Key? key,
    required this.navIndex,
    required this.onNavChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          _navItem(0, Icons.home_outlined, 'หน้าหลัก'),
          _navItem(1, Icons.history_rounded, 'ประวัติ'),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = navIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onNavChanged(index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: active ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.primary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
