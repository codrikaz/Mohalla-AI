import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feed_provider.dart';
import '../../services/ai_post_service.dart';

class ComposeScreen extends ConsumerStatefulWidget {
  const ComposeScreen({super.key});

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  final _textController = TextEditingController();
  String _selectedCategory = PostCategory.info;
  XFile? _image;
  bool _isPosting = false;
  bool _isImproving = false;
  bool _postToCountry = false;
  String _targetLanguage = 'Original';
  int? _remainingAiRequests;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _improveWithAi() async {
    if (_isImproving) return;
    setState(() => _isImproving = true);

    try {
      final suggestion = await AiPostService().improvePost(
        text: _textController.text,
        targetLanguage: _targetLanguage,
      );
      if (!mounted) return;

      final apply = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(child: Text('AI suggestion')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  suggestion.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Chip(label: Text(PostCategory.shortName(suggestion.category))),
                const SizedBox(height: 8),
                Text(suggestion.improvedText),
                if (suggestion.translatedText.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    '${suggestion.language} translation',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(suggestion.translatedText),
                ],
                const SizedBox(height: 12),
                Text(
                  suggestion.cached
                      ? 'Cached result—the daily limit was not used.'
                      : '${suggestion.remainingRequests} AI requests remaining today.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Apply'),
            ),
          ],
        ),
      );

      if (apply == true && mounted) {
        _textController.text = suggestion.postText;
        _textController.selection = TextSelection.collapsed(
          offset: _textController.text.length,
        );
        setState(() {
          if (PostCategory.urban.contains(suggestion.category)) {
            _selectedCategory = suggestion.category;
          }
          _remainingAiRequests = suggestion.remainingRequests;
        });
      } else if (mounted) {
        setState(() => _remainingAiRequests = suggestion.remainingRequests);
      }
    } on AiPostException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImproving = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 800,
    );
    if (img != null) setState(() => _image = img);
  }

  Future<void> _post() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPosting = true);

    final profile = ref.read(userProfileProvider).valueOrNull;
    final locationInfo = ref.read(currentLocationProvider);
    final ok = await ref.read(feedProvider.notifier).createPost(
          category: _selectedCategory,
          text: text,
          image: _image,
          isCountryFeed: _postToCountry,
          posterDisplayName: _postToCountry ? profile?.displayName : null,
          countryCode: _postToCountry ? profile?.countryCode : null,
          locationLat: locationInfo?.lat,
          locationLng: locationInfo?.lng,
          areaName: locationInfo?.areaName,
          cityName: locationInfo?.cityName,
          stateName: locationInfo?.stateName,
        );

    if (!mounted) return;
    setState(() => _isPosting = false);

    if (ok) {
      if (_postToCountry) {
        await ref.read(countryFeedProvider.notifier).refresh();
      }
      ref.invalidate(myPostsProvider);
      if (!mounted) return;
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The post could not be published. Please try again.'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const categories = PostCategory.urban;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final remaining = AppConstants.maxPostLength - _textController.text.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('New post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: (_isPosting || _textController.text.trim().isEmpty)
                  ? null
                  : _post,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                minimumSize: Size.zero,
              ),
              child: _isPosting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Post'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Anonymous name display
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: Text('👤', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.anonymousName ?? 'Anonymous',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '🔒 Your real name remains private',
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Category selector
            const Text(
              'Category',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(PostCategory.displayName(cat)),
                  selected: isSelected,
                  selectedColor: AppColors.primarySurface,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color:
                        isSelected ? AppColors.primary : Colors.grey.shade700,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Text input
            TextField(
              controller: _textController,
              maxLines: 6,
              maxLength: AppConstants.maxPostLength,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 15, height: 1.6),
              decoration: InputDecoration(
                hintText: 'What would you like to share with your neighbours?',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                counterText: '$remaining characters',
                counterStyle: TextStyle(
                  fontSize: 11,
                  color: remaining < 50 ? AppColors.red : Colors.grey.shade500,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primarySurface,
                    Colors.purple.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Mohalla AI Post Assistant',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppConstants.aiAssistantEnabled
                        ? 'Improve clarity, choose a category, and refine your post.'
                        : 'Live AI generation is disabled in this test build because API billing is not enabled.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  if (!AppConstants.aiAssistantEnabled) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You can still write and publish posts normally.',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final languagePicker = DropdownButtonFormField<String>(
                        initialValue: _targetLanguage,
                        isDense: true,
                        decoration: const InputDecoration(
                          labelText: 'Output language',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Original',
                            child: Text('Keep original'),
                          ),
                          DropdownMenuItem(
                            value: 'English',
                            child: Text('English'),
                          ),
                          DropdownMenuItem(
                            value: 'Hindi',
                            child: Text('Hindi'),
                          ),
                        ],
                        onChanged:
                            (_isImproving || !AppConstants.aiAssistantEnabled)
                                ? null
                                : (value) => setState(
                                      () => _targetLanguage = value!,
                                    ),
                      );
                      final improveButton = FilledButton.icon(
                        onPressed: (!AppConstants.aiAssistantEnabled ||
                                _isImproving ||
                                _textController.text.trim().length < 10)
                            ? null
                            : _improveWithAi,
                        icon: _isImproving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.auto_awesome, size: 17),
                        label: Text(
                          !AppConstants.aiAssistantEnabled
                              ? 'Unavailable'
                              : (_isImproving ? 'Improving...' : 'Improve'),
                        ),
                      );

                      if (constraints.maxWidth < 340) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            languagePicker,
                            const SizedBox(height: 10),
                            improveButton,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: languagePicker),
                          const SizedBox(width: 10),
                          improveButton,
                        ],
                      );
                    },
                  ),
                  if (_remainingAiRequests != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '$_remainingAiRequests of 3 AI requests remaining today',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Image attachment
            if (_image != null) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(_image!.path),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => setState(() => _image = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Attach image button
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_outlined, size: 18),
              label: Text(_image == null ? 'Add photo' : 'Change photo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),

            const SizedBox(height: 20),

            // Country feed toggle
            Builder(builder: (context) {
              final countryFlag = profile?.countryFlag ?? '🌍';
              final countryName = profile?.countryName ?? 'Country';
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _postToCountry
                      ? AppColors.primarySurface
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _postToCountry
                        ? AppColors.primaryLight
                        : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Text(countryFlag, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Also post to the $countryName feed',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            _postToCountry
                                ? 'Your name and location will be visible'
                                : 'People across $countryName can see this post and your name',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _postToCountry,
                      onChanged: (val) => setState(() => _postToCountry = val),
                      activeThumbColor: AppColors.primary,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
