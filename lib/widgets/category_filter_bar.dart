import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../providers/feed_provider.dart';

class CategoryFilterBar extends ConsumerWidget {
  const CategoryFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);
    // GPS-based app — no colony type, show all urban categories
    const categories = PostCategory.urban;
    const allCategories = [null, ...categories]; // null = "All"

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: List.generate(allCategories.length * 2 - 1, (i) {
          if (i.isOdd) return const SizedBox(width: 6);
          final categoryIndex = i ~/ 2;
          final cat = allCategories[categoryIndex];
          final isSelected = selected == cat;
          return Expanded(
            child: _Chip(
              label: cat == null ? 'All' : PostCategory.shortName(cat),
              isSelected: isSelected,
              category: cat,
              onTap: () =>
                  ref.read(selectedCategoryProvider.notifier).state = cat,
            ),
          );
        }),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final String? category;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isSelected,
    required this.category,
    required this.onTap,
  });

  Color get _bg {
    return Colors.white;
  }

  Color get _fg {
    if (!isSelected) return Colors.grey.shade600;
    switch (category) {
      case PostCategory.safety:
        return AppColors.red;
      case PostCategory.info:
        return AppColors.blue;
      case PostCategory.issue:
        return AppColors.orange;
      case PostCategory.krishi:
        return AppColors.green;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 34,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? _fg.withValues(alpha: 0.65) : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: _fg,
          ),
        ),
      ),
    );
  }
}
