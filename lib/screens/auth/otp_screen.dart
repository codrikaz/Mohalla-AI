import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length != 6) return;

    final success =
        await ref.read(authFlowProvider.notifier).verifyOtp(otp: _otp);

    if (success && mounted) {
      context.go('/name');
    }
  }

  void _onChanged(String val, int idx) {
    if (val.length == 1 && idx < 5) {
      _focusNodes[idx + 1].requestFocus();
    }
    if (val.isEmpty && idx > 0) {
      _focusNodes[idx - 1].requestFocus();
    }
    if (_otp.length == 6) _verify();
  }

  @override
  Widget build(BuildContext context) {
    final authFlow = ref.watch(authFlowProvider);
    final phone = authFlow.pendingPhone ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 20),
            const Text(
              'Enter OTP',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We sent a code to $phone',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 40),
            Row(
              children: List.generate(11, (index) {
                if (index.isOdd) return const SizedBox(width: 8);
                final i = index ~/ 2;
                return Expanded(
                  child: SizedBox(
                      height: 56,
                      child: TextFormField(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(1),
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                        ),
                        onChanged: (val) => _onChanged(val, i),
                      )),
                );
              }),
            ),
            if (authFlow.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.redSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        authFlow.error!,
                        style:
                            const TextStyle(color: AppColors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: authFlow.isLoading ? null : _verify,
                child: authFlow.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Verify'),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: authFlow.isLoading
                    ? null
                    : () {
                        if (authFlow.pendingPhone != null) {
                          ref
                              .read(authFlowProvider.notifier)
                              .sendOtp(authFlow.pendingPhone!);
                        }
                      },
                child: const Text('Resend OTP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
