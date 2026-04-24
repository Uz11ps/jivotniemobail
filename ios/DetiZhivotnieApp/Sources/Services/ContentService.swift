import Foundation
import FirebaseCore
import FirebaseFirestore

class ContentService: ObservableObject {
    /// Lazy so that `Firestore.firestore()` is only resolved when a Firebase
    /// app has been configured. Without a bundled `GoogleService-Info.plist`
    /// the SDK throws — we detect that via `FirebaseApp.app()` and silently
    /// skip network calls, letting the UI render empty state.
    private var db: Firestore? {
        guard FirebaseApp.app() != nil else { return nil }
        return Firestore.firestore()
    }

    @Published var categories: [Category] = []
    @Published var animals: [String: [Animal]] = [:]
    @Published var offers: [Offer] = []

    func loadCategories() async throws {
        guard let db else {
            // No Firebase — surface demo content so the app is explorable.
            await MainActor.run { self.categories = DemoContent.categories }
            return
        }
        let snapshot = try await db.collection("categories")
            .whereField("isVisible", isEqualTo: true)
            .order(by: "order")
            .getDocuments()

        categories = snapshot.documents.compactMap { doc -> Category? in
            guard var category = try? doc.data(as: Category.self) else { return nil }
            category.id = doc.documentID
            return category
        }

        // Still empty after a successful call? Fall back to demo too.
        if categories.isEmpty {
            await MainActor.run { self.categories = DemoContent.categories }
        }
    }

    func loadAnimals(for categoryId: String) async throws {
        guard let db else {
            await MainActor.run {
                self.animals[categoryId] = DemoContent.animals(for: categoryId)
            }
            return
        }
        let snapshot = try await db.collection("categories")
            .document(categoryId)
            .collection("animals")
            .whereField("isVisible", isEqualTo: true)
            .order(by: "order")
            .getDocuments()

        let animalsList = snapshot.documents.compactMap { doc -> Animal? in
            guard var animal = try? doc.data(as: Animal.self) else { return nil }
            animal.id = doc.documentID
            return animal
        }

        await MainActor.run {
            animals[categoryId] = animalsList.isEmpty
                ? DemoContent.animals(for: categoryId)
                : animalsList
        }
    }

    func loadOffers() async throws {
        guard let db else { return }
        let snapshot = try await db.collection("offers")
            .whereField("isActive", isEqualTo: true)
            .getDocuments()

        offers = snapshot.documents.compactMap { doc -> Offer? in
            guard var offer = try? doc.data(as: Offer.self) else { return nil }
            offer.id = doc.documentID
            return offer
        }
    }
}
