import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/pin_code_field.dart';
import '../dashboard/dashboard_screen.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String userId;
  final String identifier;
  final bool isLogin;
  
  const OtpVerificationScreen({
    super.key,
    required this.userId,
    required this.identifier,
    this.isLogin = true,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _pinController = TextEditingController();
  Timer? _timer;
  int _remainingSeconds = 60;
  bool _canResend = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _remainingSeconds = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  Future<void> _verifyOtp() async {
    final code = _pinController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer le code à 6 chiffres')),
      );
      return;
    }
    
    setState(() => _isVerifying = true);
    
    final result = await ref.read(authProvider.notifier).verifyOtp(
      userId: widget.userId,
      code: code,
      type: 'login',
    );
    
    setState(() => _isVerifying = false);
    
    if (result['success'] == true) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    
    setState(() => _isVerifying = true);
    
    final result = await ref.read(authProvider.notifier).sendOtp(
      identifier: widget.identifier,
    );
    
    setState(() => _isVerifying = false);
    
    if (result['success'] == true) {
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nouveau code envoyé !'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vérification'), backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Code de vérification',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Nous avons envoyé un code à ${widget.identifier}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            PinCodeField(
              controller: _pinController,
              onCompleted: (_) => _verifyOtp(),
            ),
            const SizedBox(height: 32),
            Center(
              child: _isVerifying
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        if (!_canResend)
                          Text(
                            'Renvoyer dans ${_remainingSeconds ~/ 60}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        if (_canResend)
                          TextButton(
                            onPressed: _resendOtp,
                            child: const Text('Renvoyer le code', style: TextStyle(color: Color(0xFF0B6E3A))),
                          ),
                      ],
                    ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Le code a été envoyé par SMS et email. Vérifiez vos spams.',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
