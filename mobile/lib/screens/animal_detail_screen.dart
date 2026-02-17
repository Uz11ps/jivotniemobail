import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../providers/animals_provider.dart';
import '../services/audio_service.dart';
import '../services/firebase_service.dart';
import '../utils/app_strings.dart';
import '../utils/locale_helper.dart';

class AnimalDetailScreen extends StatefulWidget {
  final String categoryId;
  final String animalId;

  const AnimalDetailScreen({
    super.key,
    required this.categoryId,
    required this.animalId,
  });

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  final AudioService _audioService = AudioService();
  final FirebaseService _firebaseService = FirebaseService();
  String? _bgImageUrl;
  String? _previewImageUrl;
  String? _bgVideoUrl;
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  bool _hasStartedAudio = false;
  bool _isLoadingAssets = true;
  File? _downloadedVideoFile;
  String? _soundPathResolved;
  static const String _devImgDir = r'C:\Users\1\Desktop\cursor\detiiosjivotnie\img';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAssets();
    });
  }

  Future<void> _loadAssets() async {
    final provider = context.read<AnimalsProvider>();
    if (provider.getAnimals(widget.categoryId).isEmpty) {
      await provider.loadAnimals(widget.categoryId);
    }
    var animal = provider.getAnimalById(widget.categoryId, widget.animalId);
    try {
      // На Windows берём свежий документ из REST-данных, чтобы не зависеть от кеша провайдера.
      final freshAnimals = await _firebaseService.getAnimals(widget.categoryId);
      final fresh = freshAnimals.where((a) => a.id == widget.animalId);
      if (fresh.isNotEmpty) {
        animal = fresh.first;
      }
    } catch (_) {}

    if (animal == null) {
      setState(() {
        _isLoadingAssets = false;
      });
      return;
    }

    try {
      await _firebaseService.logEvent('animal_open', {
        'categoryId': widget.categoryId,
        'animalId': widget.animalId,
        'animalNameRu': animal.name.ru,
      });
    } catch (_) {}

    FirebaseStorage? storage;
    try {
      storage = FirebaseStorage.instance;
    } catch (_) {
      storage = null;
    }

    if (animal.bgAssetPath != null && animal.bgAssetPath!.isNotEmpty) {
      try {
        _bgImageUrl = await _resolveStorageOrUrl(storage, animal.bgAssetPath!);
      } catch (_) {
        // Игнорируем ошибки загрузки фона
      }
    }

    if (animal.previewAssetPath != null && animal.previewAssetPath!.isNotEmpty) {
      try {
        _previewImageUrl = await _resolveStorageOrUrl(storage, animal.previewAssetPath!);
      } catch (_) {}
    }

    if (animal.bgVideoAssetPath != null && animal.bgVideoAssetPath!.isNotEmpty) {
      try {
        _bgVideoUrl = await _resolveStorageOrUrl(storage, animal.bgVideoAssetPath!);
      } catch (_) {}
    }
    _soundPathResolved = animal.soundAssetPath;

    await _ensureVideoControllerInitialized();
    if (_videoController == null) {
      await _tryInitFromLocalDevVideo();
    }

    if (mounted) {
      setState(() {
        _isLoadingAssets = false;
      });
    }
  }

  Future<String> _resolveStorageOrUrl(FirebaseStorage? storage, String value) async {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (storage == null) {
      throw Exception('Firebase Storage not available for non-url asset');
    }
    return storage.ref(value).getDownloadURL();
  }

  Future<File?> _tryPrepareLocalVideo(String url) async {
    try {
      final uri = Uri.parse(url);
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final file = File('${Directory.systemTemp.path}\\animal_${widget.animalId}_bg.mp4');
      await file.writeAsBytes(res.bodyBytes, flush: true);
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureVideoControllerInitialized() async {
    if (_videoController != null) return;
    final url = _bgVideoUrl;
    if (url == null || url.isEmpty) return;

    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      await _syncVideoVolume();
      await _videoController!.pause();
      if (mounted) {
        setState(() {});
      }
      return;
    } catch (_) {
      _videoController?.dispose();
      _videoController = null;
    }

    final downloaded = await _tryPrepareLocalVideo(url);
    if (downloaded == null) {
      _bgVideoUrl = null;
      return;
    }
    try {
      _videoController = VideoPlayerController.file(downloaded);
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      await _syncVideoVolume();
      await _videoController!.pause();
      _downloadedVideoFile = downloaded;
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      _videoController?.dispose();
      _videoController = null;
      _bgVideoUrl = null;
    }
  }

  Future<void> _tryInitFromLocalDevVideo() async {
    // Dev fallback for Windows when network decoding fails.
    final localPath = _localVideoPathByAnimalId(widget.animalId);
    if (localPath == null) return;
    final f = File(localPath);
    if (!f.existsSync()) return;
    try {
      _videoController?.dispose();
      _videoController = VideoPlayerController.file(f);
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      await _syncVideoVolume();
      await _videoController!.pause();
      _downloadedVideoFile = null;
      _bgVideoUrl = null;
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      _videoController?.dispose();
      _videoController = null;
    }
  }

  String? _localVideoPathByAnimalId(String animalId) {
    switch (animalId) {
      case 'cat':
        return '$_devImgDir\\Cat.mp4';
      case 'guinea':
        return '$_devImgDir\\Guinea Pig.mp4';
      case 'white_mouse':
        return '$_devImgDir\\Guinea Pig 2.mp4';
      case 'parrot':
        return '$_devImgDir\\Parrot.mp4';
      case 'ferret':
        return '$_devImgDir\\Сhinchilla.mp4';
      default:
        return null;
    }
  }

  Future<void> _togglePlay() async {
    if (_videoController == null && _bgVideoUrl != null) {
      await _ensureVideoControllerInitialized();
    }
    if (_videoController == null) {
      await _tryInitFromLocalDevVideo();
    }
    final soundPath = _soundPathResolved;
    final hasSound = soundPath != null && soundPath.isNotEmpty;
    await _syncVideoVolume();

    final willPlay = !_isPlaying;
    setState(() => _isPlaying = willPlay);

    // Видео
    if (_videoController != null) {
      if (willPlay) {
        await _videoController!.play();
      } else {
        await _videoController!.pause();
      }
    }

    // Аудио
    if (!hasSound) {
      return;
    }
    if (willPlay) {
      if (_hasStartedAudio) {
        await _audioService.resumeSound();
      } else {
        _hasStartedAudio = true;
        await _audioService.playSound(soundPath);
      }
    } else {
      await _audioService.pauseSound();
    }
  }

  Future<void> _syncVideoVolume() async {
    if (_videoController == null) return;
    final hasExternalSound =
        _soundPathResolved != null && _soundPathResolved!.isNotEmpty;
    // Если отдельного аудиофайла нет — используем звук из mp4.
    await _videoController!.setVolume(hasExternalSound ? 0.0 : 1.0);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    final f = _downloadedVideoFile;
    if (f != null && f.existsSync()) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnimalsProvider>(
      builder: (context, provider, child) {
        final animal = provider.getAnimalById(widget.categoryId, widget.animalId);

        if (animal == null) {
          return Scaffold(
            appBar: AppBar(title: Text(AppStrings.t(context, 'animal.title'))),
            body: Center(child: Text(AppStrings.t(context, 'animal.notFound'))),
          );
        }

        final locale = LocaleHelper.getCurrentLocale(context);
        final title = (animal.topText ?? animal.name).getLocalized(locale);

        return Scaffold(
          body: Stack(
            children: [
              // Фон: видео > картинка > градиент
              if (_videoController != null && _videoController!.value.isInitialized)
                Positioned.fill(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController!.value.size.width,
                      height: _videoController!.value.size.height,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                )
              else if (_bgImageUrl != null)
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: _bgImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey.shade200),
                  ),
                )
              else
                Container(color: const Color(0xFF66AEF8)),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                  return;
                                }
                                context.go('/categories');
                              },
                              icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 34),
                            ),
                          ),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'SF Pro Rounded',
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Center(
                        child: _isLoadingAssets
                            ? const CircularProgressIndicator(color: Colors.white)
                            : GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _togglePlay,
                                child: Builder(
                                  builder: (context) {
                                    if (_videoController != null &&
                                        _videoController!.value.isInitialized) {
                                      // Когда видео доступно, не перекрываем его лапкой.
                                      return const SizedBox.expand();
                                    }
                                    if (_previewImageUrl != null) {
                                      return CachedNetworkImage(
                                        imageUrl: _previewImageUrl!,
                                        fit: BoxFit.contain,
                                      );
                                    }
                                    return const Icon(Icons.pets, size: 220, color: Colors.white);
                                  },
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
