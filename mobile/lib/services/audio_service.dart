import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  FirebaseStorage? _storage;
  String? _currentSoundPath;

  AudioService() {
    try {
      _storage = FirebaseStorage.instance;
    } catch (_) {
      _storage = null;
    }
  }

  Future<void> playSound(String? soundPath) async {
    if (soundPath == null || soundPath.isEmpty) {
      return;
    }

    try {
      // Если звук уже играет, останавливаем его
      if (_currentSoundPath == soundPath && _audioPlayer.state == PlayerState.playing) {
        await stopSound();
        return;
      }

      // Поддержка 2 форматов:
      // - Storage path (animals/audio/xxx.mp3) -> нужно получить downloadURL
      // - готовый URL (legacy) -> играем напрямую
      final String url;
      if (soundPath.startsWith('http://') || soundPath.startsWith('https://')) {
        url = soundPath;
      } else {
        if (_storage == null) {
          return;
        }
        url = await _storage!.ref(soundPath).getDownloadURL();
      }

      // Воспроизводим звук
      await _audioPlayer.play(UrlSource(url));
      _currentSoundPath = soundPath;
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
      _currentSoundPath = null;
    } catch (e) {
      debugPrint('Error stopping sound: $e');
    }
  }

  Future<void> pauseSound() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint('Error pausing sound: $e');
    }
  }

  Future<void> resumeSound() async {
    try {
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('Error resuming sound: $e');
    }
  }

  bool get isPlaying => _audioPlayer.state == PlayerState.playing;

  void dispose() {
    _audioPlayer.dispose();
  }
}
