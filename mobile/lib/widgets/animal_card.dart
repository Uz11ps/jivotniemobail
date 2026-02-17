import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/animal.dart';
import '../utils/locale_helper.dart';

class AnimalCard extends StatefulWidget {
  final Animal animal;
  final VoidCallback onTap;

  const AnimalCard({
    super.key,
    required this.animal,
    required this.onTap,
  });

  @override
  State<AnimalCard> createState() => _AnimalCardState();
}

class _AnimalCardState extends State<AnimalCard> {
  String? _previewUrl;
  bool _isLoadingPreview = true;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    if (widget.animal.previewAssetPath == null ||
        widget.animal.previewAssetPath!.isEmpty) {
      setState(() {
        _isLoadingPreview = false;
      });
      return;
    }

    // Если уже лежит URL (мы так теперь сохраняем из админки) — используем его напрямую.
    final value = widget.animal.previewAssetPath!;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      if (mounted) {
        setState(() {
          _previewUrl = value;
          _isLoadingPreview = false;
        });
      }
      return;
    }

    try {
      final storage = FirebaseStorage.instance;
      final url = await storage
          .ref(widget.animal.previewAssetPath!)
          .getDownloadURL();
      if (mounted) {
        setState(() {
          _previewUrl = url;
          _isLoadingPreview = false;
        });
      }
    } catch (e) {
      // Превью недоступно, используем дефолтное
      if (mounted) {
        setState(() {
          _isLoadingPreview = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = LocaleHelper.getCurrentLocale(context);
    final name = widget.animal.name.getLocalized(locale);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: _isLoadingPreview
                    ? const Center(child: CircularProgressIndicator())
                    : _previewUrl != null
                        ? CachedNetworkImage(
                            imageUrl: _previewUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.pets,
                                size: 60,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.pets,
                              size: 60,
                              color: Colors.grey,
                            ),
                          ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
