import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_strings.dart';

class RateRedirectScreen extends StatelessWidget {
  const RateRedirectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/profile');
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.chevron_left, color: Color(0xFF1273EA), size: 26),
                        Text(
                          AppStrings.t(context, 'common.back'),
                          style: const TextStyle(
                            fontFamily: 'SF Pro Rounded',
                            color: Color(0xFF1273EA),
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text('🅰️', style: TextStyle(fontSize: 52)),
              ),
              const SizedBox(height: 10),
              const Text(
                'App Store',
                style: TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.t(context, 'rate.text'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
