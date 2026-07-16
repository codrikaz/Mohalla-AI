import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/post.dart';
import '../../providers/feed_provider.dart';
import '../../widgets/vote_buttons.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _replyController = TextEditingController();
  bool _sendingReply = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Post? _getPost() {
    final posts = ref.read(feedProvider).valueOrNull ?? [];
    try {
      return posts.firstWhere((p) => p.id == widget.postId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _sendingReply = true);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await Supabase.instance.client.from('replies').insert({
        'post_id': widget.postId,
        'user_id': userId,
        'text': text,
      });
      _replyController.clear();
      ref.invalidate(repliesProvider(widget.postId));
    }
    setState(() => _sendingReply = false);
  }

  @override
  Widget build(BuildContext context) {
    final post = _getPost();
    final repliesAsync = ref.watch(repliesProvider(widget.postId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          post != null
              ? PostCategory.displayName(post.category)
              : 'Post',
        ),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main post card
                  if (post != null)
                    _PostBody(
                      post: post,
                      onVote: (type) =>
                          ref.read(feedProvider.notifier).vote(post.id, type),
                    ),

                  const SizedBox(height: 16),

                  // Replies
                  Text(
                    'Replies',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  repliesAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (e, _) => Text('Replies load nahi hui: $e'),
                    data: (replies) {
                      if (replies.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'Koi reply nahi abhi tak\nPehli reply tum karo!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 13),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: replies.map((reply) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (reply.userIsVerified == true) ...[
                                      const Icon(Icons.verified,
                                          size: 12,
                                          color: AppColors.primary),
                                      const SizedBox(width: 3),
                                    ],
                                    Expanded(
                                      child: Text(
                                        reply.anonymousName ?? 'Anonymous',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      timeago.format(reply.createdAt,
                                          locale: 'en_short'),
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  reply.text,
                                  style: const TextStyle(
                                      fontSize: 13, height: 1.5),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Reply input bar
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              left: 16,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Reply likho...',
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _sendingReply
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send_rounded,
                            color: AppColors.primary),
                        onPressed: _sendReply,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostBody extends StatelessWidget {
  final Post post;
  final ValueChanged<String>? onVote;

  const _PostBody({required this.post, this.onVote});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (post.userIsVerified == true) ...[
                const Icon(Icons.verified,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
              ],
              if (post.isPinned) ...[
                const Icon(Icons.push_pin,
                    size: 13, color: AppColors.primary),
                const SizedBox(width: 4),
              ],
              Text(
                post.anonymousName ?? 'Anonymous',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: (post.userIsVerified == true)
                      ? AppColors.primary
                      : Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              Text(
                timeago.format(post.createdAt),
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            post.text,
            style: const TextStyle(fontSize: 15, height: 1.6),
          ),
          if (post.imageUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: post.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 12),
          VoteButtons(
            agreeCount: post.agreeCount,
            disagreeCount: post.disagreeCount,
            myVote: post.myVote,
            onVote: onVote,
          ),
        ],
      ),
    );
  }
}
