import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

// GPS location permission screen
class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  bool _loading = false;
  String? _error;
  String? _detectedArea;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final locationService = ref.read(locationServiceProvider);
    final info = await locationService.getAreaInfo();

    if (!mounted) return;

    if (info == null) {
      setState(() {
        _loading = false;
        _error =
            'Location not found. Turn on GPS and allow location access in Settings.';
      });
      return;
    }

    await ref.read(currentLocationProvider.notifier).refresh();

    setState(() {
      _loading = false;
      _detectedArea = info.displayArea;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 60),
            const Text('📍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 20),
            const Text(
              'Allow location access',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Location helps show posts from neighbours near you.',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 40),
            if (_loading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    SizedBox(height: 16),
                    Text('Detecting your location...'),
                  ],
                ),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.redSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.location_off,
                        color: AppColors.red, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style:
                          const TextStyle(color: AppColors.red, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _getLocation,
                      child: const Text('Try again'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.go('/home'),
                      child: Text(
                        'Skip for now',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              )
            else if (_detectedArea != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Location found',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '📍 $_detectedArea',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle,
                        color: AppColors.green, size: 24),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Continue →'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
