import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../widgets/post_card.dart';
import '../../widgets/category_filter_bar.dart';

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
    final areaLabel = locationInfo?.displayArea ?? 'Aas paas';

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
                '$countryFlag $countryName se posts',
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
          preferredSize: const Size.fromHeight(44),
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
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const CategoryFilterBar(),
          ),
          const Divider(height: 1),

          Expanded(
            child: feedAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 40, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text('Kuch gadbad: $e'),
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
                    padding:
                        const EdgeInsets.only(top: 8, bottom: 100),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final post = filtered[i];
                      return PostCard(
                        post: post,
                        isMyPost: post.userId == myId,
                        onTap: () => context.push('/post/${post.id}'),
                        onVote: feedType == 'local'
                            ? (type) => ref
                                .read(feedProvider.notifier)
                                .vote(post.id, type)
                            : null,
                        onDelete: post.userId == myId
                            ? () async {
                                await ref
                                    .read(feedProvider.notifier)
                                    .deletePost(post.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                          content:
                                              Text('Post delete ho gayi')));
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
              label: const Text('Post karo',
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
        title: const Text('Report karo?'),
        content:
            const Text('Ye post fake ya abusive hai? Review hoga.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Report bhej diya — shukriya')),
              );
            },
            child: const Text('Report karo'),
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
      color: Colors.white,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Row(
        children: [
          _Tab(
            label: '🏘️ Local',
            isSelected: feedType == 'local',
            onTap: () {
              ref.read(selectedFeedTypeProvider.notifier).state = 'local';
              ref.read(selectedCategoryProvider.notifier).state = null;
            },
          ),
          const SizedBox(width: 8),
          _Tab(
            label: '$countryFlag $countryName',
            isSelected: feedType == 'country',
            onTap: () {
              ref.read(selectedFeedTypeProvider.notifier).state = 'country';
              ref.read(selectedCategoryProvider.notifier).state = null;
            },
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
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
                  ? '$countryName feed abhi khali hai\nPehli post tum karo!'
                  : '$areaLabel mein abhi koi post nahi\nPehli post tum karo! 👋',
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
