import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_strings.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    const OnboardingPage(
      title: "LET'S EXPLORE!",
      subtitle: 'onboarding.subtitle1',
      lion: '🦁',
      middle: '🐙',
      right: '🐼',
    ),
    const OnboardingPage(
      title: "LET'S LISTEN!",
      subtitle: 'onboarding.subtitle2',
      lion: '🐶',
      middle: '🐸',
      right: '🐵',
    ),
    const OnboardingPage(
      title: "LET'S LEARN!",
      subtitle: 'onboarding.subtitle3',
      lion: '🐯',
      middle: '🐳',
      right: '🐨',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      context.go('/categories');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => _OnboardingPageView(page: _pages[index]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, _buildDot),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _currentPage == _pages.length - 1
                      ? _completeOnboarding
                      : () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOut,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1479EE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    AppStrings.t(context, 'onboarding.continue'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: 'SF Pro Rounded',
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? const Color(0xFFA8A8A8) : const Color(0xFFD0D0D0),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String lion;
  final String middle;
  final String right;

  const OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.lion,
    required this.middle,
    required this.right,
  });
}

class _OnboardingPageView extends StatelessWidget {
  final OnboardingPage page;

  const _OnboardingPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          const Spacer(),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 10,
            children: const [
              Text('🌍', style: TextStyle(fontSize: 34)),
              Text('🎵', style: TextStyle(fontSize: 30)),
              Text('⭐', style: TextStyle(fontSize: 24)),
              Text('🌿', style: TextStyle(fontSize: 26)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AnimalTile(emoji: page.lion, color: const Color(0xFFF8D470), angle: -0.1),
              const SizedBox(width: 10),
              _AnimalTile(emoji: page.middle, color: const Color(0xFFB8C7FF), angle: 0),
              const SizedBox(width: 10),
              _AnimalTile(emoji: page.right, color: const Color(0xFFC3F0B0), angle: 0.1),
            ],
          ),
          const SizedBox(height: 18),
          RichText(
            text: TextSpan(
              style: textTheme.headlineSmall?.copyWith(
                fontFamily: 'SF Pro Rounded',
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
              children: const [
                TextSpan(text: "LET'S ", style: TextStyle(color: Color(0xFFEB7FB0))),
                TextSpan(text: 'EXPLORE', style: TextStyle(color: Color(0xFF6EA4FF))),
                TextSpan(text: '!', style: TextStyle(color: Color(0xFF8CD45B))),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.t(context, page.subtitle),
            style: textTheme.bodyMedium?.copyWith(
              fontFamily: 'SF Pro Rounded',
              color: const Color(0xFF747474),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _AnimalTile extends StatelessWidget {
  final String emoji;
  final Color color;
  final double angle;

  const _AnimalTile({
    required this.emoji,
    required this.color,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 96,
        height: 120,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 58)),
      ),
    );
  }
}
