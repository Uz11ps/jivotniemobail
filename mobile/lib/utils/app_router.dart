import 'package:go_router/go_router.dart';
import '../screens/categories_screen.dart';
import '../screens/animals_list_screen.dart';
import '../screens/animal_detail_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_order_screen.dart';
import '../screens/settings_language_screen.dart';
import '../screens/purchases_screen.dart';
import '../screens/purchase_offer_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/rate_redirect_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/categories',
  routes: [
    GoRoute(
      path: '/categories',
      builder: (context, state) => const CategoriesScreen(),
    ),
    GoRoute(
      path: '/categories/:categoryId/animals',
      builder: (context, state) {
        final categoryId = state.pathParameters['categoryId']!;
        return AnimalsListScreen(categoryId: categoryId);
      },
    ),
    GoRoute(
      path: '/categories/:categoryId/animals/:animalId',
      builder: (context, state) {
        final categoryId = state.pathParameters['categoryId']!;
        final animalId = state.pathParameters['animalId']!;
        return AnimalDetailScreen(
          categoryId: categoryId,
          animalId: animalId,
        );
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings/order',
      builder: (context, state) => const SettingsOrderScreen(),
    ),
    GoRoute(
      path: '/settings/language',
      builder: (context, state) => const SettingsLanguageScreen(),
    ),
    GoRoute(
      path: '/purchases',
      builder: (context, state) => const PurchasesScreen(),
    ),
    GoRoute(
      path: '/purchases/offer',
      builder: (context, state) => const PurchaseOfferScreen(),
    ),
    GoRoute(
      path: '/favorites',
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/rate',
      builder: (context, state) => const RateRedirectScreen(),
    ),
  ],
);
