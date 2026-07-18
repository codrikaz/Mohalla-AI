import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../widgets/post_card.dart';
import '../../widgets/category_filter_bar.dart';
import '../../widgets/post_feed_shimmer.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationInfo = ref.watch(currentLocationProvider);
    final feedType = ref.watch(selectedFeedTypeProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.valueOrNull;
    final myId = profile?.id;

    final countryFlag = profile?.countryFlag ?? '🌍';
    final countryName = profile?.countryName ?? 'Country';
    final areaLabel = locationInfo?.displayArea ?? 'Nearby';

    final feedAsync = feedType == 'local'
        ? ref.watch(feedProvider)
        : ref.watch(countryFeedProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mohalla',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            if (feedType == 'local')
              Text(
                '📍 $areaLabel',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              )
            else if (feedType == 'country')
              Text(
                '$countryFlag Posts from $countryName',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            color: Colors.grey.shade600,
            onPressed: () {
              if (feedType == 'local') {
                ref.read(feedProvider.notifier).refresh();
              } else {
                ref.read(countryFeedProvider.notifier).refresh();
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: _FeedTypeTabs(
            feedType: feedType,
            ref: ref,
            countryFlag: countryFlag,
            countryName: countryName,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFF8F8FB),
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 4),
            child: const CategoryFilterBar(),
          ),
          Expanded(
            child: feedAsync.when(
              loading: () => const PostFeedShimmer(),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 40, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text('Something went wrong: $e'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (feedType == 'local') {
                          ref.read(feedProvider.notifier).refresh();
                        } else {
                          ref.read(countryFeedProvider.notifier).refresh();
                        }
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (posts) {
                final filtered = selectedCat == null
                    ? posts
                    : posts.where((p) => p.category == selectedCat).toList();

                if (filtered.isEmpty) {
                  return _EmptyState(
                    feedType: feedType,
                    areaLabel: areaLabel,
                    countryFlag: countryFlag,
                    countryName: countryName,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    if (feedType == 'local') {
                      ref.read(feedProvider.notifier).refresh();
                    } else {
                      ref.read(countryFeedProvider.notifier).refresh();
                    }
                  },
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final post = filtered[i];
                      return PostCard(
                        post: post,
                        isMyPost: post.userId == myId,
                        onTap: () => context.push('/post/${post.id}'),
                        onVote: (type) => feedType == 'local'
                            ? ref
                                .read(feedProvider.notifier)
                                .vote(post.id, type)
                            : ref
                                .read(countryFeedProvider.notifier)
                                .vote(post.id, type),
                        onDelete: post.userId == myId
                            ? () async {
                                await ref
                                    .read(feedProvider.notifier)
                                    .deletePost(post.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Post deleted')));
                                }
                              }
                            : null,
                        onReport: () => _showReportDialog(context),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: feedType == 'local'
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/compose'),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              label: const Text('Create post',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Report this post?'),
        content: const Text(
            'Is this post misleading or abusive? It will be reviewed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report submitted. Thank you.')),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }
}

// ─── Feed Type Toggle Tabs ───────────────────────────────────────────────────
class _FeedTypeTabs extends StatelessWidget {
  final String feedType;
  final WidgetRef ref;
  final String countryFlag;
  final String countryName;

  const _FeedTypeTabs({
    required this.feedType,
    required this.ref,
    required this.countryFlag,
    required this.countryName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 5, 12, 7),
      child: SegmentedButton<String>(
        segments: [
          const ButtonSegment<String>(
            value: 'local',
            label: Text('🏘️ Local'),
          ),
          ButtonSegment<String>(
            value: 'country',
            label: Text('$countryFlag $countryName'),
          ),
        ],
        selected: {feedType},
        onSelectionChanged: (selection) {
          ref.read(selectedFeedTypeProvider.notifier).state = selection.first;
          ref.read(selectedCategoryProvider.notifier).state = null;
        },
        showSelectedIcon: false,
        expandedInsets: EdgeInsets.zero,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? AppColors.primary
                : Colors.white;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? Colors.white
                : Colors.grey.shade600;
          }),
          side: WidgetStatePropertyAll(
            BorderSide(color: Colors.grey.shade200),
          ),
          textStyle: WidgetStateProperty.resolveWith((states) {
            return TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            );
          }),
        ),
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String feedType;
  final String areaLabel;
  final String countryFlag;
  final String countryName;

  const _EmptyState({
    required this.feedType,
    required this.areaLabel,
    required this.countryFlag,
    required this.countryName,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              feedType == 'country' ? countryFlag : '🏘️',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              feedType == 'country'
                  ? 'The $countryName feed is empty.\nBe the first to post!'
                  : 'There are no posts in $areaLabel yet.\nBe the first to post! 👋',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
