import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/alerts_provider.dart';
import '../../providers/auth_provider.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final canBroadcast = profile?.isRwaVerified == true;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: const Text(
          '🚨 Alerts',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.red),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            color: Colors.grey.shade600,
            onPressed: () => ref.read(alertsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Emergency button (visible to all)
          Padding(
            padding: const EdgeInsets.all(16),
            child: _EmergencyButton(
              canBroadcast: canBroadcast,
            ),
          ),

          // Alerts list
          Expanded(
            child: alertsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.red),
                ),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (alerts) {
                if (alerts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('✅', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          'Koi alert nahi — sab theek hai!',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: alerts.length,
                  itemBuilder: (ctx, i) {
                    final alert = alerts[i];
                    final isNew = DateTime.now()
                            .difference(alert.createdAt)
                            .inHours <
                        24;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isNew
                            ? AppColors.redSurface
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isNew
                              ? AppColors.red.withValues(alpha: 0.3)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  AlertType.displayName(alert.type),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isNew
                                        ? AppColors.red
                                        : Colors.grey.shade700,
                                  ),
                                ),
                                const Spacer(),
                                if (isNew)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.red,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'NEW',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              alert.message,
                              style: const TextStyle(
                                  fontSize: 14, height: 1.5),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  alert.senderName ?? 'Anonymous',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500),
                                ),
                                const Spacer(),
                                Text(
                                  timeago.format(alert.createdAt),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyButton extends ConsumerWidget {
  final bool canBroadcast;

  const _EmergencyButton({required this.canBroadcast});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showAlertDialog(context, ref),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.redSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.red.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🚨', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Emergency Alert bhejo',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.red,
                    ),
                  ),
                  Text(
                    canBroadcast
                        ? 'Aas paas ke logon ke phones par turant notification'
                        : 'Ek tap — poore mohalle ko pata chal jaata hai',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.red),
          ],
        ),
      ),
    );
  }

  void _showAlertDialog(BuildContext context, WidgetRef ref) {
    final types = AlertType.urban;
    String selectedType = types.first;
    final msgController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🚨 Emergency Alert',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Aas paas ke logon ko turant notification jaayegi',
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),

              // Alert type chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: types.map((t) {
                  final isSelected = selectedType == t;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedType = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.redSurface
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.red
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        AlertType.displayName(t),
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? AppColors.red
                              : Colors.grey.shade700,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Message field
              TextField(
                controller: msgController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Kya hua? Briefly batao...',
                  hintStyle: TextStyle(
                      color: Colors.grey.shade400, fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.red, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Warning text
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.orangeSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_outlined,
                        color: AppColors.orange, size: 16),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Sirf asli emergency mein use karo — neighbours ko disturb mat karo, misuse pe account band hoga',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.orange),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final msg = msgController.text.trim();
                        if (msg.isEmpty) return;
                        Navigator.pop(ctx);
                        final ok = await ref
                            .read(alertsProvider.notifier)
                            .sendAlert(
                              type: selectedType,
                              message: msg,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? '✅ Alert bhej diya'
                                  : '❌ Alert nahi gaya — dobara try karo'),
                              backgroundColor:
                                  ok ? AppColors.green : AppColors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                      ),
                      child: const Text(
                        '🚨 Alert bhejo',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
