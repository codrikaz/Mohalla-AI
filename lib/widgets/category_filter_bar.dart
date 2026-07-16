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

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (ctx, i) {
          final cat = allCategories[i];
          final isSelected = selected == cat;
          return _Chip(
            label: cat == null ? 'All' : PostCategory.shortName(cat),
            isSelected: isSelected,
            category: cat,
            onTap: () =>
                ref.read(selectedCategoryProvider.notifier).state = cat,
          );
        },
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
    if (!isSelected) return Colors.grey.shade100;
    switch (category) {
      case PostCategory.safety:
        return AppColors.redSurface;
      case PostCategory.info:
        return AppColors.blueSurface;
      case PostCategory.issue:
        return AppColors.orangeSurface;
      case PostCategory.krishi:
        return AppColors.greenSurface;
      default:
        return AppColors.primarySurface;
    }
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _fg.withValues(alpha: 0.4) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
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
