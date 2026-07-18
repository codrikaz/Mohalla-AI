import 'package:flutter/material.dart';

class PostFeedShimmer extends StatefulWidget {
  const PostFeedShimmer({super.key});

  @override
  State<PostFeedShimmer> createState() => _PostFeedShimmerState();
}

class _PostFeedShimmerState extends State<PostFeedShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey.shade300;
    final highlightColor = Colors.grey.shade100;

    return ExcludeSemantics(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final position = (_controller.value * 3) - 1.5;
            return ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment(position - 1, 0),
                end: Alignment(position + 1, 0),
                colors: [baseColor, highlightColor, baseColor],
                stops: const [0.15, 0.5, 0.85],
              ).createShader(bounds),
              child: child,
            );
          },
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: 4,
            itemBuilder: (_, index) => _PostSkeleton(
              showImage: index == 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _PostSkeleton extends StatelessWidget {
  final bool showImage;

  const _PostSkeleton({required this.showImage});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                _SkeletonBlock(width: 92, height: 11),
                Spacer(),
                _SkeletonBlock(width: 52, height: 20, radius: 20),
                SizedBox(width: 8),
                _SkeletonBlock(width: 28, height: 10),
              ],
            ),
            const SizedBox(height: 14),
            const _SkeletonBlock(width: double.infinity, height: 12),
            const SizedBox(height: 8),
            const FractionallySizedBox(
              widthFactor: 0.84,
              child: _SkeletonBlock(width: double.infinity, height: 12),
            ),
            const SizedBox(height: 8),
            const FractionallySizedBox(
              widthFactor: 0.58,
              child: _SkeletonBlock(width: double.infinity, height: 12),
            ),
            if (showImage) ...[
              const SizedBox(height: 12),
              const _SkeletonBlock(
                width: double.infinity,
                height: 120,
                radius: 8,
              ),
            ],
            const SizedBox(height: 14),
            const Row(
              children: [
                _SkeletonBlock(width: 62, height: 24, radius: 20),
                SizedBox(width: 8),
                _SkeletonBlock(width: 44, height: 24, radius: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBlock({
    required this.width,
    required this.height,
    this.radius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
