import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';
import '../widgets/shimmer_loading.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;

  const LoadingWidget({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Row(
            children: [
              const ShimmerBox(width: 64, height: 64, borderRadius: 16),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 150, height: 16, borderRadius: 4),
                    SizedBox(height: 8),
                    ShimmerBox(width: 100, height: 12, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Large revenue card skeleton
          const ShimmerBox(width: double.infinity, height: 140, borderRadius: 20),
          const SizedBox(height: AppSpacing.lg),
          // Grid stats skeleton
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.5,
            children: const [
              ShimmerBox(width: double.infinity, height: 80, borderRadius: 20),
              ShimmerBox(width: double.infinity, height: 80, borderRadius: 20),
              ShimmerBox(width: double.infinity, height: 80, borderRadius: 20),
              ShimmerBox(width: double.infinity, height: 80, borderRadius: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          // Recent activity skeleton title
          const ShimmerBox(width: 120, height: 16, borderRadius: 4),
          const SizedBox(height: AppSpacing.md),
          // List item skeleton
          ...List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  const ShimmerBox(width: 44, height: 44, borderRadius: 12),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
                        SizedBox(height: 6),
                        ShimmerBox(width: 150, height: 10, borderRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductListSkeleton extends StatelessWidget {
  const ProductListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.base),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.hairlineSoft),
            ),
            child: Row(
              children: [
                const ShimmerBox(width: 72, height: 72, borderRadius: 14),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBox(width: 160, height: 14, borderRadius: 4),
                      SizedBox(height: 8),
                      ShimmerBox(width: 100, height: 12, borderRadius: 4),
                      SizedBox(height: 8),
                      ShimmerBox(width: 60, height: 10, borderRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
