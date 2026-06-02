import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class TopBar extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const TopBar({Key? key, required this.isDark, required this.onToggleTheme}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                'Energy Monitor',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onToggleTheme,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
