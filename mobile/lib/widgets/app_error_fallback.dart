import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppErrorFallback extends StatelessWidget {
  final Object error;
  const AppErrorFallback({super.key, required this.error});

  static const String _imgBasePath = r'C:\Users\1\Desktop\cursor\detiiosjivotnie\img';

  String? _firstExistingPath(List<String> paths) {
    for (final path in paths) {
      if (File(path).existsSync()) return path;
    }
    return null;
  }

  bool get _isNetworkError {
    final msg = error.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('timeout') ||
        msg.contains('network') ||
        msg.contains('connection');
  }

  @override
  Widget build(BuildContext context) {
    final title = _isNetworkError ? 'The Internet is lost!' : 'Some kind of mistake';
    final subtitle = _isNetworkError
        ? 'Restore a stable internet connection\nand try to reload the page'
        : 'Reload the page, it might help :)';
    final imagePath = _isNetworkError
        ? _firstExistingPath(['$_imgBasePath\\тигр-подмигивает-и-улыбается 123.png'])
        : _firstExistingPath(['$_imgBasePath\\тигр-подмигивает-и-улыбается 11.png']);

    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => context.go('/categories'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8FA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chevron_left, size: 20),
                        SizedBox(width: 2),
                        Text(
                          'Back',
                          style: TextStyle(
                            fontFamily: 'SF Pro Rounded',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 52),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFF5CB8),
                ),
              ),
              const SizedBox(height: 18),
              if (imagePath != null)
                Image.file(
                  File(imagePath),
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                )
              else
                Text(_isNetworkError ? '📶' : '🐭', style: const TextStyle(fontSize: 120)),
              const SizedBox(height: 12),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => context.go('/categories'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text(
                    'Reload page',
                    style: TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
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

