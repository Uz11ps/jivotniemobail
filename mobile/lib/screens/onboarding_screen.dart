import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../utils/app_strings.dart';
import '../services/firebase_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final FirebaseService _firebaseService = FirebaseService();
  static const String _contentBaseUrl = 'http://168.222.193.86';
  static const String _introVideoUrl =
      'http://168.222.193.86/uploads/categories/hero/seed_pets_hero.mp4';
  int _currentPage = 0;
  final Map<int, VideoPlayerController> _videoControllers = {};
  VideoPlayerController? _introController;
  bool _showIntroVideo = true;

  List<OnboardingPage> _pages = [
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
  void initState() {
    super.initState();
    _initIntroVideo();
    _loadOnboardingFromAdmin();
  }

  Future<void> _initIntroVideo() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(_introVideoUrl));
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _introController = c;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _showIntroVideo = false;
      });
    }
  }

  Future<void> _loadOnboardingFromAdmin() async {
    final slides = await _firebaseService.getOnboardingSlides();
    if (slides.isEmpty || !mounted) return;
    final mapped = slides.map((s) {
      final titleMap = s['title'] as Map<String, dynamic>?;
      final subtitleMap = s['subtitle'] as Map<String, dynamic>?;
      return OnboardingPage(
        title: (titleMap?['en'] as String?)?.isNotEmpty == true
            ? (titleMap!['en'] as String)
            : "LET'S EXPLORE!",
        subtitle: '',
        subtitleRu: (subtitleMap?['ru'] as String?) ?? '',
        subtitleEn: (subtitleMap?['en'] as String?) ?? '',
        lion: '🦁',
        middle: '🐙',
        right: '🐼',
        imageAssetPath: () {
          final raw = (s['imageAssetPath'] as String?) ?? '';
          if (raw.startsWith('/')) return '$_contentBaseUrl$raw';
          return raw;
        }(),
        backgroundColorHex: (s['backgroundColorHex'] as String?) ?? '#F0F2F5',
      );
    }).toList();
    if (mapped.isNotEmpty) {
      setState(() {
        _pages = mapped;
        _currentPage = 0;
      });
    }
  }

  @override
  void dispose() {
    _introController?.dispose();
    for (final c in _videoControllers.values) {
      c.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  Future<VideoPlayerController?> _controllerForPage(int index) async {
    final existing = _videoControllers[index];
    if (existing != null) return existing;
    if (index < 0 || index >= _pages.length) return null;
    final path = _pages[index].imageAssetPath;
    if (!(path.endsWith('.mp4') || path.contains('.mp4?'))) return null;
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(path));
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
      _videoControllers[index] = c;
      return c;
    } catch (_) {
      return null;
    }
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
    if (_showIntroVideo && _introController != null && _introController!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _introController!.value.size.width,
                  height: _introController!.value.size.height,
                  child: VideoPlayer(_introController!),
                ),
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _showIntroVideo = false),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 36,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => setState(() => _showIntroVideo = false),
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
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<VideoPlayerController?>>(
                future: Future.wait(
                  List.generate(_pages.length, (i) => _controllerForPage(i)),
                ),
                builder: (context, snapshot) {
                  final ctrls = snapshot.data ?? const <VideoPlayerController?>[];
                  return PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemBuilder: (context, index) => _OnboardingPageView(
                      page: _pages[index],
                      videoController: index < ctrls.length ? ctrls[index] : null,
                    ),
                  );
                },
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
  final String subtitleRu;
  final String subtitleEn;
  final String lion;
  final String middle;
  final String right;
  final String imageAssetPath;
  final String backgroundColorHex;

  const OnboardingPage({
    required this.title,
    required this.subtitle,
    this.subtitleRu = '',
    this.subtitleEn = '',
    required this.lion,
    required this.middle,
    required this.right,
    this.imageAssetPath = '',
    this.backgroundColorHex = '#F0F2F5',
  });
}

class _OnboardingPageView extends StatelessWidget {
  final OnboardingPage page;
  final VideoPlayerController? videoController;

  const _OnboardingPageView({required this.page, this.videoController});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bgHex = page.backgroundColorHex.replaceAll('#', '');
    final bgColor = bgHex.length == 6
        ? Color(int.tryParse('FF$bgHex', radix: 16) ?? 0xFFF0F2F5)
        : const Color(0xFFF0F2F5);
    final subtitle = page.subtitle.isNotEmpty
        ? AppStrings.t(context, page.subtitle)
        : (Localizations.localeOf(context).languageCode == 'ru'
            ? (page.subtitleRu.isNotEmpty ? page.subtitleRu : AppStrings.t(context, 'onboarding.subtitle1'))
            : (page.subtitleEn.isNotEmpty ? page.subtitleEn : AppStrings.t(context, 'onboarding.subtitle1')));
    return ColoredBox(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          children: [
          const Spacer(),
          if (videoController != null && videoController!.value.isInitialized)
            SizedBox(
              height: 260,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: videoController!.value.size.width,
                  height: videoController!.value.size.height,
                  child: VideoPlayer(videoController!),
                ),
              ),
            )
          else if (page.imageAssetPath.isNotEmpty)
            CachedNetworkImage(
              imageUrl: page.imageAssetPath,
              fit: BoxFit.contain,
              placeholder: (context, url) => const SizedBox(height: 240),
              errorWidget: (context, url, error) => const SizedBox.shrink(),
            )
          else ...[
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
          ],
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
            subtitle,
            style: textTheme.bodyMedium?.copyWith(
              fontFamily: 'SF Pro Rounded',
              color: const Color(0xFF747474),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
        ],
        ),
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
