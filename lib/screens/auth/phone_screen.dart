import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:country_picker/country_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Default: India
  Country _selectedCountry = Country(
    phoneCode: '91',
    countryCode: 'IN',
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: 'India',
    example: '9876543210',
    displayName: 'India',
    displayNameNoCountryCode: 'India',
    e164Key: '91-IN-0',
  );

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _openCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        flagSize: 22,
        backgroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 15),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        inputDecoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: 'Search for your country...',
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country;
          _phoneController.clear();
        });
      },
    );
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final phone =
        '+${_selectedCountry.phoneCode}${_phoneController.text.trim()}';
    final success = await ref.read(authFlowProvider.notifier).sendOtp(
          phone,
          countryCode: _selectedCountry.countryCode,
          countryName: _selectedCountry.name,
        );
    if (success && mounted) {
      context.push('/otp');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authFlow = ref.watch(authFlowProvider);

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              const SizedBox(height: 60),
              const Text('🏘️', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 20),
              const Text(
                'Welcome to your\nneighbourhood',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Verify your number—no password required',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              // Country selector
              GestureDetector(
                onTap: _openCountryPicker,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      Text(
                        _selectedCountry.flagEmoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedCountry.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '+${_selectedCountry.phoneCode}',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.expand_more,
                          color: Colors.grey.shade500, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Phone number input
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ],
                style: const TextStyle(fontSize: 20, letterSpacing: 2),
                decoration: InputDecoration(
                  prefixText: '+${_selectedCountry.phoneCode}  ',
                  prefixStyle: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade700,
                  ),
                  hintText: _selectedCountry.example,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    letterSpacing: 1,
                    fontSize: 16,
                  ),
                  counterText: '',
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 5) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),

              if (authFlow.error != null) ...[
                const SizedBox(height: 12),
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
                          style: const TextStyle(
                              color: AppColors.red, fontSize: 13),
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
                  onPressed: authFlow.isLoading ? null : _sendOtp,
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
                      : const Text('Send OTP'),
                ),
              ),

              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  '🔒 Your phone number stays private. Location is used only to show nearby posts.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
