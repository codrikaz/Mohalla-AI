import 'package:flutter_test/flutter_test.dart';
import 'package:mohalla/core/utils/crypto_utils.dart';
import 'package:mohalla/core/utils/haversine_utils.dart';
import 'package:mohalla/models/ai_post_suggestion.dart';
import 'package:mohalla/models/post.dart';

void main() {
  group('Mohalla core behavior', () {
    test('phone hashing ignores spaces and is deterministic', () {
      expect(
        CryptoUtils.hashPhone('+91 98765 43210'),
        CryptoUtils.hashPhone('+919876543210'),
      );
    });

    test('haversine returns zero for the same point', () {
      expect(
        HaversineUtils.distanceInMeters(28.6139, 77.2090, 28.6139, 77.2090),
        closeTo(0, 0.001),
      );
    });

    test('AI suggestion parses structured backend response', () {
      final suggestion = AiPostSuggestion.fromJson({
        'title': 'Water supply interruption',
        'improved_text': 'Water has not been available since this morning.',
        'category': 'issue',
        'translated_text': 'आज सुबह से पानी उपलब्ध नहीं है।',
        'language': 'Hindi',
        'remaining_requests': 2,
        'cached': false,
      });

      expect(suggestion.category, 'issue');
      expect(suggestion.remainingRequests, 2);
      expect(suggestion.postText, contains('Water supply interruption'));
    });

    test('AI-generated post text never exceeds database limit', () {
      final suggestion = AiPostSuggestion(
        title: 'Long post',
        improvedText: List.filled(600, 'a').join(),
        category: 'info',
        translatedText: '',
        language: 'Original',
        remainingRequests: 1,
        cached: false,
      );

      expect(suggestion.postText.length, 500);
    });

    test('post parses the embedded reply count', () {
      final post = Post.fromJson({
        'id': 'post-1',
        'user_id': 'user-1',
        'category': 'info',
        'text': 'Neighbourhood update',
        'agree_count': 0,
        'disagree_count': 0,
        'is_pinned': false,
        'created_at': '2026-07-16T10:00:00.000Z',
        'replies': [
          {'count': 7}
        ],
      });

      expect(post.replyCount, 7);
    });

    test('post vote can be cleared when a user taps it again', () {
      final post = Post.fromJson({
        'id': 'post-1',
        'user_id': 'user-1',
        'category': 'info',
        'text': 'Neighbourhood update',
        'agree_count': 1,
        'disagree_count': 0,
        'is_pinned': false,
        'created_at': '2026-07-16T10:00:00.000Z',
        'my_vote': 'agree',
      });

      final unvoted = post.copyWith(
        agreeCount: 0,
        clearMyVote: true,
      );

      expect(unvoted.myVote, isNull);
      expect(unvoted.agreeCount, 0);
    });
  });
}
