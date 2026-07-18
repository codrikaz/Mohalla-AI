import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../widgets/post_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final locationInfo = ref.watch(currentLocationProvider);
    final myPostsAsync = ref.watch(myPostsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: const Text(
          'My Profile',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: const Center(
                        child: Text('👤', style: TextStyle(fontSize: 32)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            profile.anonymousName ?? 'Anonymous',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (profile.isRwaVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified,
                              color: AppColors.primary, size: 18),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (locationInfo != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('📍', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            locationInfo.displayArea,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    if (profile.isRwaVerified) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '✓ RWA Verified',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '🔒 Your real name remains private',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Settings section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      onTap: () {},
                    ),
                    const Divider(height: 1, indent: 56),
                    _SettingsTile(
                      icon: Icons.location_on_outlined,
                      label:
                          'Location: ${locationInfo?.displayArea ?? "Not set"}',
                      onTap: () => context.go('/colony-detect'),
                    ),
                    const Divider(height: 1, indent: 56),
                    _SettingsTile(
                      icon: Icons.logout_outlined,
                      label: 'Logout',
                      isDestructive: true,
                      onTap: () => _confirmLogout(context, ref),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // My posts
              Text(
                'My Posts',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),

              myPostsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
                error: (e, _) => Text('Could not load posts: $e'),
                data: (posts) {
                  if (posts.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'You have not posted anything yet.',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: posts
                        .map(
                          (p) => PostCard(
                            post: p,
                            isMyPost: true,
                            onTap: () => context.push('/post/${p.id}'),
                            onDelete: () async {
                              await ref
                                  .read(feedProvider.notifier)
                                  .deletePost(p.id);
                              ref.invalidate(myPostsProvider);
                            },
                          ),
                        )
                        .toList(),
                  );
                },
              ),

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authFlowProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.red : Colors.grey.shade600,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: isDestructive ? AppColors.red : Colors.grey.shade800,
        ),
      ),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 13, color: Colors.grey),
      onTap: onTap,
      dense: true,
    );
  }
}
