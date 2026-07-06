// lib/screens/auth/otp_verification_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../utils/constants.dart';
import 'reset_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String destination;
  final String type;
  final String purpose;

  const OtpVerificationScreen({
    super.key,
    required this.destination,
    required this.type,
    required this.purpose,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  // Countdown value lives in a ValueNotifier so the timer tick
  // only rebuilds the small countdown text widget, NOT the whole
  // screen (which was stealing focus/keystrokes from the OTP boxes
  // on every 1-second tick).
  final ValueNotifier<int> _secondsLeft = ValueNotifier<int>(60);
  final ValueNotifier<bool> _canResendNotifier = ValueNotifier<bool>(false);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();

    for (int i = 0; i < _otpControllers.length; i++) {
      _otpControllers[i].addListener(() {
        _checkAutoVerify();
      });
    }

    // Autofocus the first box after the first frame renders,
    // so the keyboard is ready before the user starts typing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  void _checkAutoVerify() {
    String otp = _otpControllers.map((e) => e.text).join();
    if (otp.length == 6) {
      _verifyOtp();
    }
  }

  void _startTimer() {
    _secondsLeft.value = 60;
    _canResendNotifier.value = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft.value > 0) {
        _secondsLeft.value--;
      } else {
        _canResendNotifier.value = true;
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _secondsLeft.dispose();
    _canResendNotifier.dispose();

    for (var controller in _otpControllers) {
      controller.removeListener(_checkAutoVerify);
      controller.dispose();
    }

    for (var node in _focusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    }

    if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }

    _checkAutoVerify();
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((e) => e.text).join();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    // PASSWORD RESET FLOW
    if (widget.purpose == 'reset') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            email: widget.destination,
            otp: otp,
          ),
        ),
      );
      return;
    }

    // ✅ FIXED: BACKEND COMPATIBLE PAYLOAD (IMPORTANT FIX)
    final success = await authProvider.verifyOtp(
      widget.type == 'email' ? widget.destination : null,
      otp,
      otpType: widget.type,
      phone: widget.type == 'phone' ? widget.destination : null,
    );

    if (success && mounted) {
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.error ?? 'OTP verification failed',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    _startTimer();

    final authProvider = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    bool success = false;

    try {
      if (widget.purpose == 'verification') {
        if (widget.type == 'email') {
          success = await authProvider.sendVerificationOtp(
            widget.destination,
          );
        } else {
          success = await authProvider.sendPhoneVerificationOtp(
            widget.destination,
          );
        }
      } else {
        success = await authProvider.forgotPassword(widget.destination);
      }

      if (success && mounted) {
        for (var controller in _otpControllers) {
          controller.clear();
        }

        _focusNodes[0].requestFocus();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'OTP resent successfully to ${widget.destination}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.error ?? 'Failed to resend OTP',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resending OTP: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 70,
              ),
              const SizedBox(height: 16),
              Text(
                'Verification Successful!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            'Your ${widget.type} has been verified successfully.\n\nYou can now login to your account.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'CONTINUE TO LOGIN',
                onPressed: () {
                  Navigator.of(context).popAndPushNamed('/login');
                },
                isFullWidth: true,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      key: ValueKey('otp_box_$index'),
      width: 50,
      height: 60,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        autofocus: index == 0,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppConstants.primaryColor,
              width: 2,
            ),
          ),
        ),
        onChanged: (value) => _onOtpChanged(index, value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.purpose == 'verification'
              ? 'Verify ${widget.type == 'email' ? 'Email' : 'Phone'}'
              : 'Verify OTP',
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppConstants.primaryColor.withValues(alpha: 0.1),
                      ),
                      child: Icon(
                        widget.type == 'email'
                            ? Icons.mark_email_read
                            : Icons.phone_android,
                        size: 60,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    widget.purpose == 'verification'
                        ? 'Verify Your ${widget.type == 'email' ? 'Email' : 'Phone'}'
                        : 'Verify OTP',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.purpose == 'verification'
                        ? 'We sent a verification code to'
                        : 'We sent a password reset code to',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.destination,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 35),
                  if (authProvider.error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        authProvider.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) => _buildOtpBox(index)),
                  ),
                  const SizedBox(height: 35),
                  CustomButton(
                    text: 'VERIFY OTP',
                    onPressed: _verifyOtp,
                    isLoading: authProvider.isLoading,
                    isFullWidth: true,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Didn\'t receive code? ',
                          style: GoogleFonts.poppins(color: Colors.grey[600])),
                      ValueListenableBuilder<bool>(
                        valueListenable: _canResendNotifier,
                        builder: (context, canResend, _) {
                          if (canResend) {
                            return GestureDetector(
                              onTap: _resendOtp,
                              child: Text(
                                'Resend',
                                style: GoogleFonts.poppins(
                                  color: AppConstants.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }
                          return ValueListenableBuilder<int>(
                            valueListenable: _secondsLeft,
                            builder: (context, seconds, _) {
                              return Text(
                                'Resend in $seconds s',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Use different ${widget.type}?',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
