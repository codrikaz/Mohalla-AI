import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class NameScreen extends ConsumerStatefulWidget {
  const NameScreen({super.key});

  @override
  ConsumerState<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends ConsumerState<NameScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await Supabase.instance.client.from('users').update(
          {'display_name': _nameController.text.trim()}).eq('id', userId);

      await ref.read(userProfileProvider.notifier).reload();
    }

    setState(() => _saving = false);
    if (mounted) context.go('/colony-detect');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              const SizedBox(height: 60),
              const Text('👋', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 20),
              const Text(
                'Enter your name',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your name appears only when you choose to show it',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              // Info box — naam kab dikhega / nahi dikhega
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: '🏘️',
                      title: 'In the local feed',
                      subtitle:
                          'Always anonymous, for example “Block C Neighbour”',
                      isAnon: true,
                    ),
                    const Divider(height: 16),
                    _InfoRow(
                      icon: '🌍',
                      title: 'In the country feed',
                      subtitle:
                          'Your name and area are shown when you choose to post there',
                      isAnon: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  hintText: 'Adward, Sunita, Zakir...',
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 2) {
                    return 'Enter at least 2 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Continue'),
                ),
              ),

              const SizedBox(height: 12),

              // Skip option
              Center(
                child: TextButton(
                  onPressed:
                      _saving ? null : () => context.go('/colony-detect'),
                  child: Text(
                    'Skip for now',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final bool isAnon;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isAnon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isAnon
                          ? AppColors.greenSurface
                          : AppColors.orangeSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isAnon ? '🔒 Anonymous' : '👤 Name visible',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isAnon ? AppColors.green : AppColors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
