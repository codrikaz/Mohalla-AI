import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class VoteButtons extends StatelessWidget {
  final int agreeCount;
  final int disagreeCount;
  final String? myVote;
  final ValueChanged<String>? onVote; // null when detail view no-op

  const VoteButtons({
    super.key,
    required this.agreeCount,
    required this.disagreeCount,
    required this.myVote,
    this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final alreadyVoted = myVote != null;

    return Row(
      children: [
        _VoteBtn(
          icon: Icons.thumb_up_outlined,
          filledIcon: Icons.thumb_up,
          count: agreeCount,
          isActive: myVote == 'agree',
          activeColor: AppColors.green,
          onTap: alreadyVoted ? null : () => onVote?.call('agree'),
        ),
        const SizedBox(width: 8),
        _VoteBtn(
          icon: Icons.thumb_down_outlined,
          filledIcon: Icons.thumb_down,
          count: disagreeCount,
          isActive: myVote == 'disagree',
          activeColor: AppColors.red,
          onTap: alreadyVoted ? null : () => onVote?.call('disagree'),
        ),
      ],
    );
  }
}

class _VoteBtn extends StatelessWidget {
  final IconData icon;
  final IconData filledIcon;
  final int count;
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onTap;

  const _VoteBtn({
    required this.icon,
    required this.filledIcon,
    required this.count,
    required this.isActive,
    required this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor.withValues(alpha: 0.4) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? filledIcon : icon,
              size: 14,
              color: isActive ? activeColor : Colors.grey.shade500,
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                color: isActive ? activeColor : Colors.grey.shade600,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
