import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/category_model.dart';
import '../utils/app_colors.dart';
import 'animated_widgets.dart';

class CategoryChip extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;
  final bool isSelected;

  const CategoryChip({
    super.key,
    required this.category,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      onTap: onTap,
      child: SizedBox(
        width: 78,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 66,
              height: 66,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryLight : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.cardBorder,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.textPrimary.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: category.image,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const ShimmerBox(
                    width: 60,
                    height: 60,
                    borderRadius: 30,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.primaryLight,
                    child: const Icon(
                      Icons.eco_rounded,
                      size: 26,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
