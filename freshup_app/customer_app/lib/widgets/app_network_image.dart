import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import 'animated_widgets.dart';

/// Hybrid Image widget for Everyfy that seamlessly handles local bundled assets,
/// remote CDN URLs, and relative Hostinger backend uploads with graceful fallbacks.
class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius = 0,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    final trimmed = imageUrl.trim();

    if (trimmed.startsWith('assets/')) {
      final filename = trimmed.split('/').last;
      content = Image.asset(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) {
          // If asset is missing in local bundle, fall back to backend uploads
          final isCategory = trimmed.contains('categories');
          final serverUrl = isCategory
              ? '${ApiService.baseUrl.replaceAll('/api', '')}/uploads/categories/$filename'
              : '${ApiService.baseUrl.replaceAll('/api', '')}/uploads/products/$filename';
          return CachedNetworkImage(
            imageUrl: serverUrl,
            width: width,
            height: height,
            fit: fit,
            alignment: Alignment.center,
            placeholder: (_, __) =>
                placeholder ??
                ShimmerBox(
                  width: width ?? double.infinity,
                  height: height ?? double.infinity,
                  borderRadius: borderRadius,
                ),
            errorWidget: (_, __, ___) => _defaultError(),
          );
        },
      );
    } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      content = CachedNetworkImage(
        imageUrl: trimmed,
        width: width,
        height: height,
        fit: fit,
        alignment: Alignment.center,
        placeholder: (_, __) =>
            placeholder ??
            ShimmerBox(
              width: width ?? double.infinity,
              height: height ?? double.infinity,
              borderRadius: borderRadius,
            ),
        errorWidget: (_, __, ___) => _defaultError(),
      );
    } else if (trimmed.isNotEmpty) {
      // Relative path from backend e.g. uploads/products/xyz.jpg
      final filename = trimmed.split('/').last;
      final localAsset = trimmed.contains('categories')
          ? 'assets/images/categories/$filename'
          : 'assets/images/products/$filename';

      content = Image.asset(
        localAsset,
        width: width,
        height: height,
        fit: fit,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) {
          final serverUrl =
              '${ApiService.baseUrl.replaceAll('/api', '')}/${trimmed.replaceAll(RegExp(r'^/+'), '')}';
          return CachedNetworkImage(
            imageUrl: serverUrl,
            width: width,
            height: height,
            fit: fit,
            alignment: Alignment.center,
            placeholder: (_, __) =>
                placeholder ??
                ShimmerBox(
                  width: width ?? double.infinity,
                  height: height ?? double.infinity,
                  borderRadius: borderRadius,
                ),
            errorWidget: (_, __, ___) => _defaultError(),
          );
        },
      );
    } else {
      content = _defaultError();
    }

    content = Center(child: content);

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }
    return content;
  }

  Widget _defaultError() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: AppColors.primaryLight.withValues(alpha: 0.3),
          child: const Center(
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 26,
              color: AppColors.primary,
            ),
          ),
        );
  }
}
