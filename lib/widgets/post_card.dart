import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/post.dart';
import 'vote_buttons.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;
  final ValueChanged<String>? onVote;
  final VoidCallback? onReport;
  final VoidCallback? onReply;
  final bool isMyPost;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onVote,
    this.onReport,
    this.onReply,
    this.isMyPost = false,
    this.onDelete,
  });

  Color get _catColor {
    switch (post.category) {
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

  Color get _catBg {
    switch (post.category) {
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

  @override
  Widget build(BuildContext context) {
    final hidden = post.isHidden;

    return Opacity(
      opacity: hidden ? 0.35 : 1.0,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Pinned badge
                    if (post.isPinned) ...[
                      const Icon(Icons.push_pin,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                    ],
                    // Verified badge
                    if (post.userIsVerified == true) ...[
                      const Icon(Icons.verified,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        post.displayLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: (post.userIsVerified == true)
                              ? AppColors.primary
                              : Colors.grey.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Category chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _catBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        PostCategory.shortName(post.category),
                        style: TextStyle(
                            fontSize: 10,
                            color: _catColor,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Time
                    Text(
                      timeago.format(post.createdAt, locale: 'en_short'),
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    if (isMyPost) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onDelete,
                        child: const Icon(Icons.delete_outline,
                            size: 16, color: Colors.grey),
                      ),
                    ] else ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onReport,
                        child: Icon(Icons.flag_outlined,
                            size: 15, color: Colors.grey.shade400),
                      ),
                    ],
                  ],
                ),

                // Post text
                const SizedBox(height: 8),
                Text(
                  post.text,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),

                // Image
                if (post.imageUrl != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: post.imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 180,
                        color: Colors.grey.shade200,
                        child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 180,
                        color: Colors.grey.shade200,
                        child: const Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                  ),
                ],

                // Vote bar
                const SizedBox(height: 10),
                Row(
                  children: [
                    VoteButtons(
                      agreeCount: post.agreeCount,
                      disagreeCount: post.disagreeCount,
                      myVote: post.myVote,
                      onVote: onVote,
                    ),
                    const SizedBox(width: 8),
                    _ReplyButton(
                      count: post.replyCount,
                      onTap: onReply ?? onTap,
                    ),
                    const Spacer(),
                    if (hidden)
                      Row(
                        children: [
                          Icon(Icons.visibility_off,
                              size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 3),
                          Text(
                            'Hidden by the community',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReplyButton extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const _ReplyButton({required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
