import Foundation
import FirebaseCore
import FirebaseStorage
import UIKit

class AssetService: ObservableObject {
    // Lazy: only resolves when Firebase has been configured (Storage.storage()
    // asserts on the default app, which doesn't exist without a bundled
    // GoogleService-Info.plist).
    private var storage: Storage? {
        guard FirebaseApp.app() != nil else { return nil }
        return Storage.storage()
    }
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    
    private var cacheDirectory: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Assets")
    }
    
    init() {
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func loadImage(from path: String) async throws -> UIImage {
        // Проверяем кэш в памяти
        if let cached = cache.object(forKey: path as NSString) {
            return cached
        }
        
        // Проверяем кэш на диске
        let fileName = (path as NSString).lastPathComponent
        let localURL = cacheDirectory.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: localURL.path),
           let data = try? Data(contentsOf: localURL),
           let image = UIImage(data: data) {
            cache.setObject(image, forKey: path as NSString)
            return image
        }
        
        // Загружаем из Storage
        guard let storage else { throw AssetError.firebaseUnavailable }
        let storageRef = storage.reference(forURL: path)
        let data = try await storageRef.data(maxSize: 10 * 1024 * 1024)
        
        guard let image = UIImage(data: data) else {
            throw AssetError.invalidImage
        }
        
        // Сохраняем в кэш
        cache.setObject(image, forKey: path as NSString)
        try? data.write(to: localURL)
        
        return image
    }
    
    func loadAudioData(from path: String) async throws -> Data {
        let fileName = (path as NSString).lastPathComponent
        let localURL = cacheDirectory.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: localURL.path) {
            return try Data(contentsOf: localURL)
        }
        
        guard let storage else { throw AssetError.firebaseUnavailable }
        let storageRef = storage.reference(forURL: path)
        let data = try await storageRef.data(maxSize: 50 * 1024 * 1024)
        
        try? data.write(to: localURL)
        
        return data
    }
    
    enum AssetError: Error {
        case invalidImage
        case firebaseUnavailable
    }
}
