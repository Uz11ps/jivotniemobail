import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/animals_provider.dart';
import '../providers/categories_provider.dart';
import '../utils/app_strings.dart';
import '../utils/locale_helper.dart';
import '../widgets/animal_card.dart';

class AnimalsListScreen extends StatefulWidget {
  final String categoryId;

  const AnimalsListScreen({
    super.key,
    required this.categoryId,
  });

  @override
  State<AnimalsListScreen> createState() => _AnimalsListScreenState();
}

class _AnimalsListScreenState extends State<AnimalsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnimalsProvider>().loadAnimals(widget.categoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final category = context.watch<CategoriesProvider>().getCategoryById(
          widget.categoryId,
        );
    final locale = LocaleHelper.getCurrentLocale(context);
    final categoryTitle =
        category?.title.getLocalized(locale) ?? AppStrings.t(context, 'animals.titleFallback');

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryTitle),
      ),
      body: Consumer<AnimalsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading(widget.categoryId)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.getError(widget.categoryId) != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.t(context, 'common.loadingError'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(provider.getError(widget.categoryId)!),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () =>
                        provider.loadAnimals(widget.categoryId),
                    child: Text(AppStrings.t(context, 'common.retry')),
                  ),
                ],
              ),
            );
          }

          final animals = provider.getAnimals(widget.categoryId);

          if (animals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pets, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.t(context, 'animals.notFound'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadAnimals(widget.categoryId),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: animals.length,
              itemBuilder: (context, index) {
                final animal = animals[index];
                return AnimalCard(
                  animal: animal,
                  onTap: () {
                    context.go(
                      '/categories/${widget.categoryId}/animals/${animal.id}',
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
