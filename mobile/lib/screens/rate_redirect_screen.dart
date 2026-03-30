import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';

class RateRedirectScreen extends StatefulWidget {
  const RateRedirectScreen({super.key});

  @override
  State<RateRedirectScreen> createState() => _RateRedirectScreenState();
}

class _RateRedirectScreenState extends State<RateRedirectScreen> {
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openRateFlow();
    });
  }

  Future<void> _openRateFlow() async {
    try {
      final review = InAppReview.instance;
      final available = await review.isAvailable();
      if (available) {
        await review.requestReview();
      } else {
        await review.openStoreListing();
      }
      if (!mounted) return;
      context.go('/profile');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось открыть App Store';
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      body: Center(
        child: _busy
            ? const CircularProgressIndicator()
            : Text(
                _error ?? 'Спасибо за оценку!',
                style: const TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
