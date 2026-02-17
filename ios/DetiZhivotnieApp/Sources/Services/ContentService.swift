import Foundation
import FirebaseFirestore

class ContentService: ObservableObject {
    private let db = Firestore.firestore()
    
    @Published var categories: [Category] = []
    @Published var animals: [String: [Animal]] = [:]
    @Published var offers: [Offer] = []
    
    func loadCategories() async throws {
        let snapshot = try await db.collection("categories")
            .whereField("isVisible", isEqualTo: true)
            .order(by: "order")
            .getDocuments()
        
        categories = snapshot.documents.compactMap { doc -> Category? in
            guard var category = try? doc.data(as: Category.self) else { return nil }
            category.id = doc.documentID
            return category
        }
    }
    
    func loadAnimals(for categoryId: String) async throws {
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
            animals[categoryId] = animalsList
        }
    }
    
    func loadOffers() async throws {
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
