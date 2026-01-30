import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final EdgeInsetsGeometry margin;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.black, // This will be the base color for the shimmer
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class TimetableCardSkeleton extends StatelessWidget {
  const TimetableCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: theme.brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        elevation: 1,
        color: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLoader(width: 80, height: 12),
              SizedBox(height: 12),
              SkeletonLoader(width: 200, height: 24),
              SizedBox(height: 12),
              SkeletonLoader(width: double.infinity, height: 16),
              SizedBox(height: 16),
              SkeletonLoader(width: 120, height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class ClassListSkeleton extends StatelessWidget {
  const ClassListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: theme.brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 1,
          color: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonLoader(width: 120, height: 20),
                    SkeletonLoader(width: 20, height: 20),
                  ],
                ),
                SizedBox(height: 12),
                SkeletonLoader(width: 220, height: 24),
                SizedBox(height: 8),
                SkeletonLoader(width: double.infinity, height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
